import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Zamanlanmış bildirimler için sabit ID (aynı anda sadece 1 tane olabilir)
  static const int _scheduledNotificationId = 99;

  Future<void> init() async {
    // Başlatma ayarları (Burası standart kalabilir)
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_elite_channel_v4', //
      'Pomodoro Elite Bildirimleri',
      channelDescription: 'Sayaç bitince gelen bildirimler',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: 'notification_check',
      largeIcon: DrawableResourceAndroidBitmap('notification_check'),
      color: Color(0xFF4CAF50),
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      0,
      title,
      body,
      details,
    );
  }

  /// Timer başladığında çağrılır — bitiş anı için bildirim planlar.
  /// Uygulama arka planda olsa veya tamamen kapatılsa bile bildirim gelir.
  Future<void> scheduleTimerEndNotification({
    required int seconds,
    required String title,
    required String body,
  }) async {
    // Önce eski zamanlanmış bildirimi iptal et
    await cancelScheduledNotification();

    final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_elite_timer_channel',
      'Pomodoro Timer Bildirimleri',
      channelDescription: 'Sayaç arka planda bittiğinde gelen bildirimler',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'timer_done',
      icon: 'notification_check',
      largeIcon: DrawableResourceAndroidBitmap('notification_check'),
      color: Color(0xFF4CAF50),
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        _scheduledNotificationId,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
      debugPrint("📅 Bildirim planlandı: $seconds sn sonra ($scheduledTime)");
    } catch (e) {
      debugPrint("❌ Zamanlanmış bildirim hatası: $e");
    }
  }

  /// Zamanlanmış bildirimi iptal eder (timer durdurulduğunda/sıfırlandığında).
  Future<void> cancelScheduledNotification() async {
    await _notificationsPlugin.cancel(_scheduledNotificationId);
    debugPrint("🚫 Zamanlanmış bildirim iptal edildi");
  }
}