College Notice Board 📱🔔

A secure, zero-cost self-hosted mobile and web notice board application built for colleges. It features strict role-based access control, real-time push notifications, Google Calendar sync, and a hidden Termux-style terminal easter egg.

🗂️ Project Structure

 * supabase/schema.sql — Run once in the Supabase SQL editor
 * supabase/functions/notify-new-notice/ — Free push notification edge function
 * lib/main.dart — App entry point & configuration
 * lib/screens/auth_gate.dart — Routes logged-in vs. logged-out users
 * lib/screens/login_screen.dart — Student and admin authentication
 * lib/screens/notice_feed_screen.dart — Live scrolling feed (long-press logo for Secret Mode)
 * lib/screens/admin_post_screen.dart — Admin-only notice publishing form
 * lib/widgets/notice_card.dart — Notice card UI + Google Calendar export button
 * lib/services/supabase_service.dart — Database and authentication handlers
 * lib/services/calendar_service.dart — Google Calendar template URL generator
 * lib/services/fcm_service.dart — Push notification handler
 * lib/terminal/secret_terminal_screen.dart — Termux-style CLI easter egg interface
 * lib/terminal/terminal_commands.dart — CLI command logic (man / clubs / events / exit)
   
🚀 Setup & Deployment Guide

1. Database Configuration (Supabase)
 * Create a free project on Supabase.
 * Go to Project Settings -> API to copy your Project URL and anon public key, then paste them into lib/main.dart.
 * Open the SQL Editor, create a new query, paste the contents of supabase/schema.sql, and run it. This initializes the database tables (profiles, clubs, notices), sets up Row Level Security (RLS), and limits admin roles.
 * To assign an admin/faculty account: Navigate to Table Editor -> profiles, locate the target user row, and update their role from student to admin.
> Security Note: All database tables are protected via RLS. Student accounts (role = student) are restricted to SELECT permissions. The is_admin() SQL function validates execution rights at the PostgreSQL database level, preventing any client-side overrides.

2. Push Notifications (Firebase)
 * Create a project on the Firebase Console.
 * Register an Android/Web application inside the project and download the configuration file into android/app/.
 * Retrieve your Server Key from Project Settings -> Cloud Messaging (Spark plan provides free, unlimited FCM messaging).
3. Flutter Environment Setup
Run the following command using the Flutter SDK to generate configuration bindings automatically:

flutterfire configure

4. Deploying the Notification Webhook
Deploy the edge function and set your Firebase secret key via the Supabase CLI:

supabase login

supabase link --project-ref YOUR-PROJECT-REF

supabase functions deploy notify-new-notice --no-verify-jwt

supabase secrets set 

FCM_SERVER_KEY=your_firebase_server_key

In the Supabase Dashboard, create a Database Webhook listening to the notices table on INSERT events routed to the notify-new-notice edge function.
5. Hosting the Frontend ($0 Cost)
Build the web release package:

flutter build web --release

Deploy using either option:

 * Vercel (Recommended): Run vercel --prod from inside the build/web directory.
 * GitHub Pages: Push the build contents to a designated branch and enable Pages in repository settings.
For Android builds, run flutter build apk --release to generate a shareable installer package.

📱 Building Entirely From a Mobile Phone

You can develop, build, and deploy this project without a laptop using cloud environments:
 * GitHub Mobile / Web: Initialize your repository and structure the project files.
 * GitHub Codespaces: Open your repository in a mobile browser via GitHub Codespaces (offers free containerized VS Code with a Linux terminal). Install Flutter inside the container terminal to build releases or run flutter build web --release.
 * Termux (Optional On-Device Alternative): Install Termux via F-Droid, configure Git, and run a local Flutter Linux environment directly on your Android device.
   
💡 Free Tier Constraints

 * Supabase: Free projects pause after 1 week of complete inactivity (visiting the dashboard instantly reactivates them).
 * Firebase Spark Plan: Permanent free-tier coverage for FCM push notifications.
 * Hosting: Static deployment options (Vercel/GitHub Pages) remain permanently free with zero credit card requirements.
