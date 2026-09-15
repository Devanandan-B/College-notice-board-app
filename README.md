# College Notice Board — Flutter + Supabase (100% free tier)

## What's in this project
```
supabase/schema.sql                          -> run once in Supabase SQL editor
supabase/functions/notify-new-notice/        -> free push notification edge function
lib/main.dart                                -> app entry point
lib/screens/auth_gate.dart                   -> routes logged-in vs logged-out
lib/screens/login_screen.dart                -> student/admin login & signup
lib/screens/notice_feed_screen.dart          -> live scrolling feed (long-press logo = Secret Mode)
lib/screens/admin_post_screen.dart           -> admin-only "post notice" form
lib/widgets/notice_card.dart                 -> notice card + Add to Google Calendar button
lib/services/supabase_service.dart           -> all DB/auth calls
lib/services/calendar_service.dart           -> builds the Google Calendar template link
lib/services/fcm_service.dart                -> push notification registration
lib/terminal/secret_terminal_screen.dart     -> the Termux-style easter egg UI
lib/terminal/terminal_commands.dart          -> man / clubs / events --club / exit
```

---

## 1. Supabase setup (free tier, do this in your phone's browser)

1. Go to supabase.com -> New project (free tier: 500MB DB, 50k monthly active
   users, unlimited API requests — plenty for a college).
2. Project Settings -> API -> copy the **Project URL** and **anon public key**.
   Paste them into `lib/main.dart` (`supabaseUrl`, `supabaseAnonKey`).
3. SQL Editor -> New query -> paste the entire contents of
   `supabase/schema.sql` -> Run. This creates `profiles`, `clubs`, `notices`,
   turns on Row Level Security, and caps admin accounts at 30.
4. To make someone an Admin/Faculty: Table Editor -> `profiles` -> find their
   row -> change `role` from `student` to `admin`. (Never do this from a
   client-facing button — it must stay a manual, trusted action.)

**How the security actually works:** every table has RLS enabled. Students
(`role = student`) can only `SELECT`. The `is_admin()` SQL function checks the
caller's own profile row, and the insert/update/delete policies on `notices`
require `is_admin() = true`. A student's Supabase API key can never bypass
this — it's enforced by Postgres itself, not by the Flutter app.

## 2. Firebase (free) for push notifications

1. console.firebase.google.com -> Add project.
2. Add an Android app (and/or Web app) inside it, download `google-services.json`
   into `android/app/`.
3. Project settings -> Cloud Messaging -> copy the **Server key** (legacy) —
   Spark (free) plan supports FCM with no limits.
4. Deploy the edge function (see step 4 below) and set that key as a secret.

## 3. FlutterFire config
Run once from any terminal with the Flutter SDK (Codespaces works fine, see
below): `flutterfire configure` — this generates `lib/firebase_options.dart`
automatically. Don't hand-write it.

## 4. Free push notifications: DB Webhook -> Edge Function -> FCM
```bash
supabase login
supabase link --project-ref YOUR-PROJECT-REF
supabase functions deploy notify-new-notice --no-verify-jwt
supabase secrets set FCM_SERVER_KEY=your_firebase_server_key
```
Then in the Supabase Dashboard: Database -> Webhooks -> Create a new webhook
-> Table: `notices`, Event: `INSERT`, Type: **Supabase Edge Function** ->
`notify-new-notice`. Now every new notice fires a push to all students who
have the app installed — no paid server needed.

## 5. Hosting the Flutter web build for $0
```bash
flutter build web --release
```
Then either:
- **Vercel** (recommended): `npm i -g vercel` -> `vercel --prod` from inside
  `build/web`. Free tier is plenty for a college-sized notice board.
- **GitHub Pages**: push `build/web` to a `gh-pages` branch, enable Pages in
  repo settings.

For Android, `flutter build apk --release` produces an installable APK you
can share directly (or upload to Google Play's free-tier developer account
for ₹/one-time $25 if you want it store-listed — optional, not required).

---

## Doing all of this from your phone (no laptop)

You don't need a computer at any point — here's the realistic path:

1. **GitHub mobile app** (or browser) — create a new repo, e.g.
   `college-notice-board`, and upload this project's files to it (GitHub's
   mobile web UI lets you create/edit files and upload folders as a zip then
   extract via Codespaces — see next step).

2. **GitHub Codespaces** (free: 60 core-hours/month, works entirely in a
   mobile browser at github.com — no app install needed):
   - Open your repo -> green "Code" button -> Codespaces tab -> Create
     codespace. This gives you a full VS Code + Linux terminal running in
     the browser, on your phone.
   - In the Codespaces terminal:
     ```bash
     sudo snap install flutter --classic   # or use the official install script
     flutter doctor
     flutter pub get
     flutter build web --release
     ```
   - Codespaces forwards ports automatically, so you can even run
     `flutter run -d web-server --web-port 8080` and get a live preview link
     you can open in another tab on your phone.
   - Run the `vercel --prod` or GitHub Pages steps from that same terminal.

3. **Supabase and Firebase dashboards** are both fully usable from a mobile
   browser (desktop-site mode makes them easier to read) — steps 1–4 above
   need nothing but a browser.

4. **Alternative if you want everything on-device**: install **Termux** from
   F-Droid on an Android phone, then `pkg install git` and follow Flutter's
   official Linux install instructions inside Termux. This lets you edit,
   build, and even `flutter build apk` directly on the phone without any
   cloud IDE — slower and more fiddly than Codespaces, but fully offline-capable
   once set up.

5. To actually **write/edit code** comfortably on a phone, GitHub Codespaces'
   browser VS Code (with an attached Bluetooth keyboard if you have one) is
   by far the least painful option — it's the same editor you'd use on a
   laptop, just running in a tab.

---

## Notes on "100% free"
- Supabase free tier: no time limit, project pauses after 1 week of
  inactivity (a visit to the dashboard un-pauses it) — fine for a semester
  project, mention this if uptime matters.
- Firebase Spark plan: FCM is unlimited and free permanently.
- Vercel/GitHub Pages: free static hosting, no card required.
- The only manual step with no automation is promoting a user to
  `admin` — that's intentional, so the 30-seat cap stays under human control.
