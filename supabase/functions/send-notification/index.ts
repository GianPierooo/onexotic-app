// Edge Function: send-notification
// Envía push via Firebase Cloud Messaging HTTP v1 API.
//
// Secret requerido en Supabase Dashboard → Edge Functions → Secrets:
//   FIREBASE_SERVICE_ACCOUNT → JSON completo de la cuenta de servicio
//   (Firebase Console → Configuración → Cuentas de servicio → Generar clave)
//
// El project_id se lee automáticamente desde el JSON del service account.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Config ───────────────────────────────────────────────────────────────────
const SA             = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);
const FCM_PROJECT_ID = SA.project_id as string;
const SUPABASE_URL   = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_KEY   = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ─── JWT → OAuth2 access token ────────────────────────────────────────────────
async function getFcmAccessToken(): Promise<string> {
  const now     = Math.floor(Date.now() / 1000);
  const header  = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss:   SA.client_email,
    sub:   SA.client_email,
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
  const pem = SA.private_key
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
  fcmToken: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<{ ok: boolean; error?: string }> {
  const accessToken = await getFcmAccessToken();

  const fcmRes = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
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

// ─── Handler ──────────────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const {
      user_id,
      titulo,
      mensaje = "",
      tipo = "sistema",
      notification_id,
    } = body as {
      user_id: string;
      titulo: string;
      mensaje?: string;
      tipo?: string;
      notification_id?: string;
    };

    if (!user_id || !titulo) {
      return new Response(
        JSON.stringify({ error: "user_id y titulo son requeridos" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

    // Leer fcm_token del usuario destino
    const { data: user, error: userErr } = await supabase
      .from("users")
      .select("fcm_token, nombre")
      .eq("id", user_id)
      .maybeSingle();

    if (userErr) {
      console.error("[send-notification] DB error:", userErr.message);
      return new Response(
        JSON.stringify({ sent: false, error: userErr.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!user?.fcm_token) {
      console.log(`[send-notification] ${user_id} sin fcm_token — omitiendo push`);
      return new Response(
        JSON.stringify({ sent: false, reason: "sin_token" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { ok, error } = await sendFcmPush({
      fcmToken: user.fcm_token,
      title: titulo,
      body: mensaje,
      data: {
        tipo,
        notification_id: notification_id ?? "",
        user_id,
      },
    });

    return new Response(
      JSON.stringify({ sent: ok, error }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("[send-notification] ERROR:", e);
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
