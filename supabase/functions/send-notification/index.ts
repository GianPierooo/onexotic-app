// Edge Function: send-notification
// Envía push via Firebase Cloud Messaging HTTP v1 API.
//
// Secret requerido en Supabase Dashboard → Edge Functions → Secrets:
//   FIREBASE_SERVICE_ACCOUNT → JSON completo de la cuenta de servicio
//   (Firebase Console → Configuración → Cuentas de servicio → Generar clave)
//
// El project_id se lee automáticamente desde el JSON del service account.
//
// Diseño defensivo: TODO lo que pueda fallar (parseo del SA, lectura de
// secrets, generación de JWT, envío FCM) se ejecuta dentro del handler con
// try/catch granular y se devuelve como JSON con `stage` para saber en qué
// punto exacto se rompió. NUNCA crashear a nivel módulo — eso solo produce
// WORKER_ERROR opaco.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

// ─── Carga del service account (dentro del handler, nunca top-level) ──────────
function loadServiceAccount(): ServiceAccount {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT no está configurado en los secrets");
  }
  let parsed: ServiceAccount;
  try {
    parsed = JSON.parse(raw) as ServiceAccount;
  } catch (e) {
    throw new Error(
      `FIREBASE_SERVICE_ACCOUNT no es JSON válido: ${(e as Error).message}. ` +
      `Longitud del secret: ${raw.length}. ` +
      `Primeros 40 chars: ${JSON.stringify(raw.slice(0, 40))}`,
    );
  }
  if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
    throw new Error(
      `FIREBASE_SERVICE_ACCOUNT incompleto. Campos presentes: ` +
      `${Object.keys(parsed).join(", ")}. Faltan project_id, client_email o private_key.`,
    );
  }
  return parsed;
}

// ─── JWT → OAuth2 access token ────────────────────────────────────────────────
async function getFcmAccessToken(sa: ServiceAccount): Promise<string> {
  const now     = Math.floor(Date.now() / 1000);
  const header  = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss:   sa.client_email,
    sub:   sa.client_email,
    aud:   "https://oauth2.googleapis.com/token",
    iat:   now,
    exp:   now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const b64url = (obj: unknown) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const signingInput = `${b64url(header)}.${b64url(payload)}`;

  // Importar clave privada RSA del service account
  const pem = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----\n?/, "")
    .replace(/\n?-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");

  const keyBytes  = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sigBytes = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );

  const sig = btoa(String.fromCharCode(...new Uint8Array(sigBytes)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const jwt = `${signingInput}.${sig}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  const json = await res.json();
  if (!json.access_token) {
    throw new Error(`OAuth token error: ${JSON.stringify(json)}`);
  }
  return json.access_token as string;
}

// ─── Enviar push ──────────────────────────────────────────────────────────────
async function sendFcmPush(params: {
  sa: ServiceAccount;
  fcmToken: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<{ ok: boolean; error?: string }> {
  const accessToken = await getFcmAccessToken(params.sa);

  const fcmRes = await fetch(
    `https://fcm.googleapis.com/v1/projects/${params.sa.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type":  "application/json",
        "Authorization": `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: params.fcmToken,
          notification: {
            title: params.title,
            body:  params.body,
          },
          data: params.data ?? {},
          android: {
            priority: "high",
            notification: {
              icon:  "ic_notification",
              color: "#FF4500",
              sound: "default",
              channel_id: "onexotic_default",
            },
          },
          webpush: {
            headers: { Urgency: "high" },
            notification: {
              icon:  "/icons/Icon-192.png",
              badge: "/icons/Icon-192.png",
              vibrate: [200, 100, 200],
            },
            fcm_options: { link: "/" },
          },
          apns: {
            payload: {
              aps: { sound: "default", badge: 1 },
            },
          },
        },
      }),
    },
  );

  if (!fcmRes.ok) {
    const errText = await fcmRes.text();
    console.error("[send-notification] FCM error:", errText);
    return { ok: false, error: errText };
  }

  return { ok: true };
}

// ─── Respuesta de error estandarizada ────────────────────────────────────────
function errResponse(stage: string, error: unknown, status = 500): Response {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`[send-notification] stage=${stage} error=${message}`);
  return new Response(
    JSON.stringify({ sent: false, stage, error: message }),
    { status, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
}

// ─── Handler ──────────────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // 1. Parse body
  let body: {
    user_id?: string;
    titulo?: string;
    mensaje?: string;
    tipo?: string;
    notification_id?: string;
  };
  try {
    body = await req.json();
  } catch (e) {
    return errResponse("parse_body", e, 400);
  }

  const {
    user_id,
    titulo,
    mensaje = "",
    tipo = "sistema",
    notification_id,
  } = body;

  if (!user_id || !titulo) {
    return new Response(
      JSON.stringify({ error: "user_id y titulo son requeridos" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // 2. Cargar service account (donde antes crasheaba el módulo)
  let sa: ServiceAccount;
  try {
    sa = loadServiceAccount();
  } catch (e) {
    return errResponse("load_service_account", e);
  }

  // 3. Validar secrets de Supabase
  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!SUPABASE_URL || !SUPABASE_KEY) {
    return errResponse(
      "load_supabase_secrets",
      new Error("SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY no están configurados"),
    );
  }

  // 4. Leer fcm_token del usuario destino
  let fcmToken: string | null = null;
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
    const { data: user, error: userErr } = await supabase
      .from("users")
      .select("fcm_token, nombre")
      .eq("id", user_id)
      .maybeSingle();
    if (userErr) throw new Error(`DB: ${userErr.message}`);
    fcmToken = user?.fcm_token ?? null;
  } catch (e) {
    return errResponse("read_user_token", e);
  }

  if (!fcmToken) {
    console.log(`[send-notification] ${user_id} sin fcm_token — omitiendo push`);
    return new Response(
      JSON.stringify({ sent: false, reason: "sin_token" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // 5. Enviar push via FCM
  try {
    const { ok, error } = await sendFcmPush({
      sa,
      fcmToken,
      title: titulo,
      body: mensaje,
      data: {
        tipo,
        notification_id: notification_id ?? "",
        user_id,
      },
    });

    if (!ok) {
      return new Response(
        JSON.stringify({ sent: false, stage: "fcm_send", error }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ sent: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return errResponse("fcm_send_exception", e);
  }
});
