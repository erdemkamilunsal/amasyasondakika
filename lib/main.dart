import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'pages/navigation/main_navigation_page.dart';
import 'pages/district_selection_page.dart';

/// ✅ MUST be top-level and annotated for AOT (release) background execution.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase init required in background isolate
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Debug:
  // print("BG message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Register background handler as early as possible
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Permission (iOS + Android 13+)
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    print("Permission error >>> $e");
  }

  // ✅ Token + topic subscribe (retry)
  unawaited(_initFcm());

  // ✅ Foreground messages (only logs)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title ?? "";
    final body = message.notification?.body ?? "";
    print("Foreground notification: $title | $body");
  });

  runApp(const MyApp());
}

/// Separate function to keep main clean + easier debug.
Future<void> _initFcm() async {
  final delays = [0, 5, 15, 30, 60, 120];

  for (final sec in delays) {
    try {
      if (sec > 0) await Future.delayed(Duration(seconds: sec));

      final token = await FirebaseMessaging.instance.getToken();
      print("FCM TOKEN >>> $token");

      await FirebaseMessaging.instance.subscribeToTopic("daily_digest");
      print("✅ Subscribed to topic: daily_digest");

      break;
    } catch (e) {
      print("⚠️ Topic subscribe denemesi başarısız (sec=$sec): $e");
    }
  }
}

/// Minimal unawaited helper (no extra package needed)
void unawaited(Future<void> f) {}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("hasSeenDistrictSelection") ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: checkFirstRun(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final isSeen = snapshot.data!;
          return isSeen
              ? const MainNavigationPage()
              : const DistrictSelectionPage();
        },
      ),
    );
  }
}