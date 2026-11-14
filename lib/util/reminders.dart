import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

/// Daily habit reminders.
///
/// Every enabled habit owns one notification slot, rescheduled whenever the
/// habit list changes. Scheduling is intentionally forgiving: a host without
/// notification support (or with permission denied) simply gets no alarm, and
/// the habit keeps its reminder time for later.
class ReminderScheduler {
  const ReminderScheduler._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _ready = false;

  /// False on platforms that cannot deliver a local notification.
  static bool get supported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static Future<void> sync(List<Habit> habits) async {
    if (!supported) return;
    final withReminders = habits
        .where((habit) => habit.reminderMinutes != null)
        .toList();
    try {
      await _ensureReady();
      await _plugin.cancelAll();
      if (withReminders.isEmpty) return;
      if (!await _requestPermission()) return;
      for (final habit in withReminders) {
        await _schedule(habit);
      }
    } catch (_) {
      // A reminder that cannot be scheduled must never break saving a habit.
    }
  }

  static Future<void> cancelAll() async {
    if (!supported) return;
    try {
      await _ensureReady();
      await _plugin.cancelAll();
    } catch (_) {}
  }

  static Future<void> _ensureReady() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Falls back to UTC; the daily repeat still fires at that offset.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      ),
    );
    _ready = true;
  }

  static Future<bool> _requestPermission() async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final granted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? true;
  }

  static Future<void> _schedule(Habit habit) async {
    final minutes = habit.reminderMinutes;
    if (minutes == null) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'habit_reminders',
        'Habit reminders',
        channelDescription: 'Daily reminders for the habits you choose.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      id: _idFor(habit),
      title: habit.name,
      body: 'A gentle nudge for ${habit.name}.',
      scheduledDate: _nextInstance(minutes),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: habit.id,
    );
  }

  static tz.TZDateTime _nextInstance(int minuteOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  static int _idFor(Habit habit) => habit.id.hashCode & 0x7fffffff;
}
