import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

abstract interface class TimerNotificationGateway {
  Future<bool> scheduleTimerEndNotification({
    required int seconds,
    required String title,
    required String body,
  });

  Future<void> cancelScheduledNotification();
}

class NotificationService implements TimerNotificationGateway {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _scheduledNotificationId = 99;

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  @override
  Future<bool> scheduleTimerEndNotification({
    required int seconds,
    required String title,
    required String body,
  }) async {
    if (seconds <= 0) return false;

    await cancelScheduledNotification();

    final scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: seconds));

    final androidDetails = AndroidNotificationDetails(
      'pomodoro_elite_timer_channel',
      'Pomodoro Elite',
      channelDescription: 'notification_channel_description'.tr(),
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'timer_done',
      icon: 'notification_check',
      largeIcon: const DrawableResourceAndroidBitmap('notification_check'),
      color: const Color(0xFF4CAF50),
      playSound: true,
      enableVibration: true,
    );
    final details = NotificationDetails(android: androidDetails);

    try {
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final canScheduleExactly =
          await androidPlugin?.canScheduleExactNotifications() ?? false;

      await _notificationsPlugin.zonedSchedule(
        _scheduledNotificationId,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: canScheduleExactly
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
      debugPrint('Bildirim planlandı: $seconds sn sonra ($scheduledTime)');
      return true;
    } catch (error, stackTrace) {
      debugPrint('Zamanlanmış bildirim hatası: $error\n$stackTrace');
      return false;
    }
  }

  @override
  Future<void> cancelScheduledNotification() async {
    try {
      await _notificationsPlugin.cancel(_scheduledNotificationId);
      if (kDebugMode) {
        debugPrint('Zamanlanmış timer bildirimi iptal edildi');
      }
    } catch (error, stackTrace) {
      debugPrint('Timer bildirimi iptal edilemedi: $error\n$stackTrace');
    }
  }
}
