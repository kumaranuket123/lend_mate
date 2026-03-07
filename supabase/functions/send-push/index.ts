import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const PROJECT_ID   = Deno.env.get("FCM_PROJECT_ID")!;
const CLIENT_EMAIL = Deno.env.get("FCM_CLIENT_EMAIL")!;
const PRIVATE_KEY  = Deno.env.get("FCM_PRIVATE_KEY")!.replace(/\\n/g, "\n");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// ── Base64url helpers ──────────────────────────────────────
function base64url(data: Uint8Array | string): string {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : data;
  let bin = "";
  bytes.forEach((b) => (bin += String.fromCharCode(b)));
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

// ── Build & sign a JWT using Web Crypto (no external deps) ─
async function getAccessToken(): Promise<string> {
  const header  = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const now     = Math.floor(Date.now() / 1000);
  const payload = base64url(JSON.stringify({
    iss:   CLIENT_EMAIL,
    sub:   CLIENT_EMAIL,
    aud:   "https://oauth2.googleapis.com/token",
    iat:   now,
    exp:   now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  }));

  const signingInput = `${header}.${payload}`;

  // Strip PEM headers and decode
  const pemBody = PRIVATE_KEY
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/-----BEGIN RSA PRIVATE KEY-----/g, "")
    .replace(/-----END RSA PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");

  const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput)
  );

  const jwt = `${signingInput}.${base64url(new Uint8Array(signature))}`;

  // Exchange for OAuth2 token
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const json = await res.json();
  if (!json.access_token) {
    throw new Error(`OAuth token error: ${JSON.stringify(json)}`);
  }
  return json.access_token;
}

// ── Main handler ───────────────────────────────────────────
serve(async (req) => {
  try {
    const payload = await req.json();

    // Support both Database Webhook { record: {...} } and direct call
    const record  = payload.record ?? payload;
    const user_id = record.user_id;
    const title   = record.title;
    const body    = record.body;
    const loan_id = record.loan_id;
    console.log("Received request for user:", user_id);

    // 1. Get FCM token from profiles
    const profileRes = await fetch(
      `${SUPABASE_URL}/rest/v1/profiles?id=eq.${user_id}&select=fcm_token`,
      {
        headers: {
          apikey:        SERVICE_KEY,
          Authorization: `Bearer ${SERVICE_KEY}`,
        },
      }
    );
    const profiles = await profileRes.json();
    const fcmToken = profiles?.[0]?.fcm_token;
    console.log("FCM token found:", !!fcmToken);

    if (!fcmToken) {
      return new Response(
        JSON.stringify({ skipped: "no_fcm_token_for_user" }),
        { status: 200 }
      );
    }

    // 2. Get OAuth2 access token
    console.log("Getting access token...");
    const accessToken = await getAccessToken();
    console.log("Access token obtained ✓");

    // 3. Send push via FCM V1
    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization:  `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: fcmToken,
            notification: {
              title: title ?? "LendMate",
              body:  body  ?? "You have a new notification",
            },
            android: {
              priority: "high",
              notification: { sound: "default" },
            },
            apns: {
              payload: { aps: { sound: "default", badge: 1 } },
            },
            data: {
              loan_id:      loan_id ?? "",
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
        }),
      }
    );

    const fcmJson = await fcmRes.json();
    console.log("FCM response:", JSON.stringify(fcmJson));
    return new Response(JSON.stringify(fcmJson), { status: 200 });

  } catch (e) {
    console.error("Edge function error:", e.message);
    return new Response(JSON.stringify({ error: e.message }), { status: 500 });
  }
});