// Supabase Edge Function: notify-new-notice
// Triggered by a Database Webhook on INSERT into public.notices.
// Sends a push notification to the "all_students" FCM topic.
//
// Deploy (from Codespaces/Termux terminal):
//   supabase functions deploy notify-new-notice --no-verify-jwt
//   supabase secrets set FCM_SERVER_KEY=your_firebase_server_key
//
// Then in Supabase Dashboard -> Database -> Webhooks:
//   Table: notices | Event: INSERT
//   Type: Supabase Edge Function -> notify-new-notice

import { serve } from "https://deno.land/std@0.192.0/http/server.ts";

const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!;

serve(async (req) => {
  try {
    const payload = await req.json();
    const notice = payload.record; // the newly inserted row

    const message = {
      to: "/topics/all_students",
      notification: {
        title: `📌 New Notice: ${notice.title}`,
        body: notice.venue
          ? `${notice.venue} — ${new Date(notice.event_date).toLocaleString()}`
          : new Date(notice.event_date).toLocaleString(),
      },
      data: {
        notice_id: notice.id,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    const fcmRes = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify(message),
    });

    const result = await fcmRes.json();
    return new Response(JSON.stringify({ ok: true, result }), { status: 200 });
  } catch (err) {
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      status: 500,
    });
  }
});
