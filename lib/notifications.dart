import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Simple wrapper around flutter_local_notifications for the daily "log your
/// expenses" reminder. No server; scheduled on-device.
class Notifs {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'spendly_reminder';
  static const _dailyId = 1001;
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    // App targets India; use IST for scheduling.
    try { tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(settings: const InitializationSettings(android: android));
    _ready = true;
  }

  static Future<void> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }

  static Future<void> scheduleDaily(int hour, int minute) async {
    await init();
    await _plugin.cancel(id: _dailyId);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId, 'Daily Reminder',
        channelDescription: 'Reminds you to log your expenses',
        importance: Importance.high, priority: Priority.high,
      ),
    );
    await _plugin.zonedSchedule(
      id: _dailyId,
      title: 'Spendly',
      body: "Don't forget to log today's expenses 💸",
      scheduledDate: _nextInstance(hour, minute),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  static Future<void> cancelDaily() async {
    await init();
    await _plugin.cancel(id: _dailyId);
  }

  static tz.TZDateTime _nextInstanceOfDay(int day, int hour) {
    final now = tz.TZDateTime.now(tz.local);
    final d = day.clamp(1, 28);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, d, hour);
    if (scheduled.isBefore(now)) scheduled = tz.TZDateTime(tz.local, now.year, now.month + 1, d, hour);
    return scheduled;
  }

  /// Monthly reminder for a bill on its due day at 10 AM.
  static Future<void> scheduleBill(int id, int dueDay, String name, String amountLabel) async {
    await init();
    await _plugin.cancel(id: id);
    const details = NotificationDetails(
      android: AndroidNotificationDetails('spendly_bills', 'Bill Reminders',
        channelDescription: 'Reminds you about upcoming bills',
        importance: Importance.high, priority: Priority.high),
    );
    await _plugin.zonedSchedule(
      id: id,
      title: 'Bill due: $name',
      body: '$amountLabel is due today. Tap to record it.',
      scheduledDate: _nextInstanceOfDay(dueDay, 10),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime, // monthly
    );
  }

  static Future<void> cancelId(int id) async { await init(); await _plugin.cancel(id: id); }
}
