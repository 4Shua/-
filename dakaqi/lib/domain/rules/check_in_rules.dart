import 'package:dakaqi/core/constants/habit_assets.dart';
import 'package:dakaqi/core/utils/date_utils.dart';
import 'package:dakaqi/core/utils/time_utils.dart';
import 'package:dakaqi/data/db/database.dart';
import 'package:dakaqi/domain/models/enums.dart';

abstract final class CheckInRules {
  static bool canCheckInOn(Habit habit, DateTime date) {
    return switch (habit.effectiveDayCategory) {
      EffectiveDayCategory.everyDay => true,
      EffectiveDayCategory.weekdayWeekend =>
        switch (habit.effectiveDayVariant) {
          EffectiveDayVariant.weekday =>
            date.weekday >= DateTime.monday && date.weekday <= DateTime.friday,
          EffectiveDayVariant.weekend =>
            date.weekday == DateTime.saturday || date.weekday == DateTime.sunday,
        },
    };
  }

  static bool hasCheckInWindow(Habit habit) =>
      habit.checkInWindowStartMinutes != null &&
      habit.checkInWindowEndMinutes != null;

  static bool canCheckInNow(Habit habit, DateTime moment) {
    if (!canCheckInOn(habit, moment)) return false;
    return TimeUtils.isWithinWindow(
      moment,
      habit.checkInWindowStartMinutes,
      habit.checkInWindowEndMinutes,
    );
  }

  static bool isWithinTimeWindow(Habit habit, DateTime moment) {
    return TimeUtils.isWithinWindow(
      moment,
      habit.checkInWindowStartMinutes,
      habit.checkInWindowEndMinutes,
    );
  }

  /// 当日是否打满频率（计入月度有效次数）。
  static bool isValidCompletionDay(Habit habit, DateTime date, int count) {
    if (!canCheckInOn(habit, date)) return false;
    return count >= habit.timesPerDay;
  }

  static int validDaysInMonth(
    Habit habit,
    int year,
    int month,
    Map<String, int> checkIns,
  ) {
    final days = AppDateUtils.daysInMonth(DateTime(year, month));
    var total = 0;
    for (var day = 1; day <= days; day++) {
      final date = DateTime(year, month, day);
      final key = AppDateUtils.formatDate(date);
      final count = checkIns[key] ?? 0;
      if (isValidCompletionDay(habit, date, count)) total++;
    }
    return total;
  }

  static int validDaysInVisibleMonth(
    Habit habit,
    DateTime month,
    Map<String, int> checkIns,
  ) {
    return validDaysInMonth(habit, month.year, month.month, checkIns);
  }

  static String effectiveDaySummary(Habit habit) {
    return switch (habit.effectiveDayCategory) {
      EffectiveDayCategory.everyDay => '每天',
      EffectiveDayCategory.weekdayWeekend =>
        habit.effectiveDayVariant.shortLabel,
    };
  }

  static String blockedMessage(Habit habit, DateTime moment) {
    if (!canCheckInOn(habit, moment)) {
      return '今日无需打卡（${effectiveDaySummary(habit)}）';
    }
    if (hasCheckInWindow(habit) && !isWithinTimeWindow(habit, moment)) {
      return '当前不在有效打卡时间内（${TimeUtils.formatWindow(habit.checkInWindowStartMinutes, habit.checkInWindowEndMinutes)}）';
    }
    return '当前无法打卡';
  }

  static String? todayStatusHint(Habit habit, DateTime moment) {
    if (!canCheckInOn(habit, moment)) return '今日无需打卡';
    if (hasCheckInWindow(habit) && !isWithinTimeWindow(habit, moment)) {
      return TimeUtils.formatWindow(
        habit.checkInWindowStartMinutes,
        habit.checkInWindowEndMinutes,
      );
    }
    return null;
  }

  static String frequencySummary(Habit habit) =>
      '${habit.timesPerDay}次/天 · ${habit.monthlyTarget}次/月';
}
