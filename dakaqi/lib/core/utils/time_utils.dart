import 'package:flutter/material.dart';

abstract final class TimeUtils {
  static const minutesPerDay = 24 * 60;

  static int toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static TimeOfDay fromMinutes(int minutes) {
    final normalized = minutes % minutesPerDay;
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }

  static String formatMinutes(int minutes) {
    final time = fromMinutes(minutes);
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String formatTimeOfDay(TimeOfDay time) => formatMinutes(toMinutes(time));

  static TimeOfDay? parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String formatWindow(int? startMinutes, int? endMinutes) {
    if (startMinutes == null || endMinutes == null) return '全天';
    return '${formatMinutes(startMinutes)} – ${formatMinutes(endMinutes)}';
  }

  /// 当前时刻是否在 [startMinutes, endMinutes] 内；null 表示不限制。
  static bool isWithinWindow(
    DateTime moment,
    int? startMinutes,
    int? endMinutes,
  ) {
    if (startMinutes == null || endMinutes == null) return true;

    final now = moment.hour * 60 + moment.minute;
    if (startMinutes == endMinutes) return true;
    if (startMinutes < endMinutes) {
      return now >= startMinutes && now <= endMinutes;
    }
    // 跨午夜，例如 22:00 – 06:00
    return now >= startMinutes || now <= endMinutes;
  }
}
