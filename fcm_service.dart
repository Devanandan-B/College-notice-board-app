import 'package:firebase_messaging/firebase_messaging.dart';
import 'supabase_service.dart';

class FcmService {
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Every student device subscribes to one shared topic — this is what
    // keeps push notifications 100% free: one FCM send reaches everyone,
    // no per-user server logic needed.
    await messaging.subscribeToTopic('all_students');

    final token = await messaging.getToken();
    if (token != null) {
      await SupabaseService.instance.saveFcmToken(token);
    }

    FirebaseMessaging.onTokenRefresh.listen((newToken) {
      SupabaseService.instance.saveFcmToken(newToken);
    });

    // Foreground messages: show your own in-app banner/snackbar here if
    // desired. flutter_local_notifications can be added later for a
    // native-looking heads-up banner while the app is open.
    FirebaseMessaging.onMessage.listen((message) {
      // ignore: avoid_print
      print('Foreground notice push: ${message.notification?.title}');
    });
  }
}
