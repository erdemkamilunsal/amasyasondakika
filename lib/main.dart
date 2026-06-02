import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'core/startup/app_start_controller.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel hourlyNewsChannel = AndroidNotificationChannel(
  'hourly_news_channel_v1',
  'Saatlik Haberler',
  description: 'Saatlik haber bildirimleri',
  importance: Importance.high,
  sound: RawResourceAndroidNotificationSound('hourly_news_sound'),
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(hourlyNewsChannel);

  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    print("Permission error >>> $e");
  }

  unawaited(_initFcm());

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            hourlyNewsChannel.id,
            hourlyNewsChannel.name,
            channelDescription: hourlyNewsChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            sound: const RawResourceAndroidNotificationSound(
              'hourly_news_sound',
            ),
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } else {
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      print("Foreground notification: $title | $body");
    }
  });

  runApp(const MyApp());
}

Future<void> _initFcm() async {
  final delays = [0, 5, 15, 30, 60, 120];

  for (final sec in delays) {
    try {
      if (sec > 0) await Future.delayed(Duration(seconds: sec));

      final token = await FirebaseMessaging.instance.getToken();
      print("FCM TOKEN >>> $token");

      await FirebaseMessaging.instance.subscribeToTopic("daily_digest");
      print("✅ Subscribed to topic: daily_digest");

      await FirebaseMessaging.instance.subscribeToTopic("hourly_news");
      print("✅ Subscribed to topic: hourly_news");

      break;
    } catch (e) {
      print("⚠️ Topic subscribe denemesi başarısız (sec=$sec): $e");
    }
  }
}

void unawaited(Future<void> future) {}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const AppStartController(),
    );
  }
}