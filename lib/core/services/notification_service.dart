import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  static const int restTimerNotificationId = 999;
  static const String _channelId = 'liftlog_rest_timer_channel';
  static const String _channelName = 'Rest Timer Alerts';
  static const String _channelDescription =
      'Alerts when your workout rest timer has completed.';

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notificationsPlugin.initialize(initSettings);

      final androidPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
      }

      _initialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  Future<void> scheduleRestTimerNotification({
    required DateTime scheduledEndTime,
    String title = 'Rest Finished!',
    String body = 'Time to begin your next set.',
  }) async {
    try {
      await initialize();

      // Cancel any existing rest timer notification before scheduling a new one
      await cancelRestTimerNotification();

      final now = DateTime.now();
      if (scheduledEndTime.isBefore(now)) return;

      final tzScheduledTime = tz.TZDateTime.from(scheduledEndTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.zonedSchedule(
        restTimerNotificationId,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling notification: $e');
    }
  }

  Future<void> showRestTimerCompletedNotification({
    String title = 'Rest Finished!',
    String body = 'Time to begin your next set.',
  }) async {
    try {
      await initialize();

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        restTimerNotificationId,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('[NotificationService] Error showing notification: $e');
    }
  }

  Future<void> cancelRestTimerNotification() async {
    try {
      await _notificationsPlugin.cancel(restTimerNotificationId);
    } catch (e) {
      debugPrint('[NotificationService] Error cancelling notification: $e');
    }
  }
}
