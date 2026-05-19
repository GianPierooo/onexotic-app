// Edge Function: send-push
// Envía una notificación push via Firebase Cloud Messaging (HTTP v1 API).
//
// Secrets requeridos (Supabase Dashboard → Edge Functions → Secrets):
//   FCM_PROJECT_ID          → Firebase Console → Configuración → ID del proyecto
//   FCM_SERVICE_ACCOUNT_JSON → Firebase Console → Configuración → Cuentas de servicio
//                              → Generar nueva clave privada → copiar todo el JSON

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FCM_PROJECT_ID   = Deno.env.get("FCM_PROJECT_ID")!;
const SERVICE_ACCOUNT  = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!);
const SUPABASE_URL     = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SVC_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ─── Genera un OAuth2 access token usando JWT de cuenta de servicio ───────────
async function getFcmAccessToken(): Promise<string> {
  const now  = Math.floor(Date.now() / 1000);
  const header  = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss:   SERVICE_ACCOUNT.client_email,
    sub:   SERVICE_ACCOUNT.client_email,
    aud:   "https://oauth2.googleapis.com/token",
    iat:   now,
    exp:   now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const signingInput = `${encode(header)}.${encode(payload)}`;

  // Importar la clave privada RSA del service account
  const pemKey = SERVICE_ACCOUNT.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");

  const keyBytes = Uint8Array.from(atob(pemKey), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8", keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false, ["sign"],
  );

  const signatureBytes = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );

  const signature = btoa(String.fromCharCode(...new Uint8Array(signatureBytes)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const jwt = `${signingInput}.${signature}`;

  // Intercambiar JWT por access token
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  const { access_token } = await tokenRes.json();
  return access_token;
}

// ─── Enviar push via FCM HTTP v1 API ─────────────────────────────────────────
async function sendPush(params: {
  fcmToken: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<boolean> {
  const accessToken = await getFcmAccessToken();

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: params.fcmToken,
          notification: { title: params.title, body: params.body },
          data: params.data ?? {},
          webpush: {
            notification: {
              icon: "/icons/Icon-192.png",
              badge: "/icons/Icon-192.png",
            },
          },
          android: {
            notification: {
              icon: "ic_notification",
              color: "#FF4500",
              sound: "default",
            },
          },
        },
      }),
    },
  );

  if (!res.ok) {
    const err = await res.text();
    console.error("[send-push] FCM error:", err);
    return false;
  }
  return true;
}

// ─── Handler principal ────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { user_id, titulo, mensaje, tipo, notification_id } = await req.json();

    if (!user_id || !titulo) {
      return new Response(
        JSON.stringify({ error: "user_id y titulo son requeridos" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SVC_KEY);

    // Obtener el FCM token del usuario
    const { data: user } = await supabase
      .from("users")
      .select("fcm_token, nombre")
      .eq("id", user_id)
      .maybeSingle();

    if (!user?.fcm_token) {
      return new Response(
        JSON.stringify({ sent: false, reason: "usuario sin fcm_token" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const enviado = await sendPush({
      fcmToken: user.fcm_token,
      title: titulo,
      body: mensaje ?? "",
      data: {
        tipo: tipo ?? "sistema",
        notification_id: notification_id ?? "",
      },
    });

    return new Response(
      JSON.stringify({ sent: enviado }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("[send-push] ERROR:", e);
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
