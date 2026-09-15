import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

interface NoticePayload {
  record: {
    id: string;
    title: string;
    description: string;
    event_date: string;
    venue: string;
    club_id: string;
    created_by: string;
    created_at: string;
  };
}

interface FCMMessage {
  message: {
    token: string;
    notification: {
      title: string;
      body: string;
    };
    data: {
      notice_id: string;
      club_id: string;
    };
  };
}

/**
 * Sends FCM notification to all students
 */
async function sendFCMNotification(
  fcmTokens: string[],
  notice: NoticePayload["record"]
) {
  if (!fcmTokens.length) {
    console.log("No FCM tokens found. Skipping notification.");
    return;
  }

  const messages = fcmTokens.map((token) => ({
    message: {
      token,
      notification: {
        title: notice.title,
        body: `${notice.venue || "Event"} on ${new Date(notice.event_date).toLocaleDateString()}`,
      },
      data: {
        notice_id: notice.id,
        club_id: notice.club_id || "",
      },
    },
  }));

  try {
    for (const msg of messages) {
      const response = await fetch(
        "https://fcm.googleapis.com/v1/projects/YOUR_FCM_PROJECT_ID/messages:send",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${FCM_SERVER_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(msg),
        }
      );

      if (!response.ok) {
        console.error(
          `FCM error for token ${msg.message.token}:`,
          await response.text()
        );
      } else {
        console.log(`FCM sent successfully to token ${msg.message.token}`);
      }
    }
  } catch (error) {
    console.error("FCM send error:", error);
    throw error;
  }
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const payload: NoticePayload = await req.json();
    const notice = payload.record;

    console.log("New notice created:", notice.id, notice.title);

    // Fetch all FCM tokens from students
    const { data: tokens, error: fetchError } = await supabase
      .from("profiles")
      .select("fcm_token")
      .eq("role", "student")
      .not("fcm_token", "is", null);

    if (fetchError) {
      throw new Error(`Failed to fetch FCM tokens: ${fetchError.message}`);
    }

    const fcmTokens = tokens
      .map((p: { fcm_token: string | null }) => p.fcm_token)
      .filter((token: string | null): token is string => token !== null);

    // Send notifications
    await sendFCMNotification(fcmTokens, notice);

    return new Response(
      JSON.stringify({
        success: true,
        message: `Notification sent to ${fcmTokens.length} students`,
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
