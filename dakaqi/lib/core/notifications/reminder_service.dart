import 'dart:async';

import 'package:dakaqi/core/utils/date_utils.dart';
import 'package:dakaqi/core/utils/time_utils.dart';
import 'package:dakaqi/data/db/database.dart';
import 'package:dakaqi/data/repositories/habit_repository.dart';
import 'package:dakaqi/domain/rules/check_in_rules.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract final class ReminderService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static Timer? _rescheduleDebounce;
  static Habit? _pendingRescheduleHabit;

  static bool get _supportsNativeReminders =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const _androidChannel = AndroidNotificationChannel(
    'habit_reminders',
    '习惯提醒',
    description: '乱七八糟打卡器 · 习惯打卡提醒',
    importance: Importance.defaultImportance,
  );

  static Future<void> initialize() async {
    if (_initialized) return;
    if (!_supportsNativeReminders) {
      _initialized = true;
      return;
    }

    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } on Object catch (e) {
      debugPrint('ReminderService: timezone fallback ($e)');
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(initSettings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_androidChannel);
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    _initialized = true;
  }

  static Future<void> rescheduleAll(HabitRepository repo) async {
    if (!_supportsNativeReminders) return;
    if (!_initialized) await initialize();
    await _plugin.cancelAll();

    final habits = await repo.watchHabitsWithTags().first;
    final now = DateTime.now();
    for (final item in habits) {
      await _scheduleHabit(item.habit, now);
    }
  }

  static Future<void> rescheduleHabit(Habit habit) async {
    if (!_supportsNativeReminders) return;
    _pendingRescheduleHabit = habit;
    _rescheduleDebounce?.cancel();
    _rescheduleDebounce = Timer(const Duration(milliseconds: 500), () async {
      final target = _pendingRescheduleHabit;
      if (target == null) return;
      if (!_initialized) await initialize();
      await _cancelHabit(target.id);
      await _scheduleHabit(target, DateTime.now());
    });
  }

  static Future<void> cancelHabit(int habitId) async {
    if (!_supportsNativeReminders) return;
    if (!_initialized) await initialize();
    await _cancelHabit(habitId);
  }

  static Future<void> _cancelHabit(int habitId) async {
    for (var offset = 0; offset < 31; offset++) {
      await _plugin.cancel(_notificationId(habitId, offset));
    }
  }

  static Future<void> _scheduleHabit(Habit habit, DateTime from) async {
    if (!habit.reminderEnabled) return;
    final reminder = TimeUtils.parseTime(habit.reminderTime);
    if (reminder == null) return;

    final today = AppDateUtils.today();
    for (var offset = 0; offset < 31; offset++) {
      final date = today.add(Duration(days: offset));
      if (!CheckInRules.canCheckInOn(habit, date)) continue;

      final scheduled = DateTime(
        date.year,
        date.month,
        date.day,
        reminder.hour,
        reminder.minute,
      );
      if (!scheduled.isAfter(from)) continue;

      final tzTime = tz.TZDateTime.from(scheduled, tz.local);
      await _plugin.zonedSchedule(
        _notificationId(habit.id, offset),
        '打卡提醒',
        '该「${habit.name}」啦',
        tzTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static int _notificationId(int habitId, int dayOffset) =>
      habitId * 1000 + dayOffset;
}
