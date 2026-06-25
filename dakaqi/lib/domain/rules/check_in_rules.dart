import 'package:dakaqi/core/constants/habit_assets.dart';
import 'package:dakaqi/core/utils/time_utils.dart';
import 'package:dakaqi/data/db/database.dart';
import 'package:dakaqi/domain/models/enums.dart';

abstract final class CheckInRules {
  static bool canCheckInOn(Habit habit, DateTime date) {
    return switch (habit.activeDaysType) {
      ActiveDaysType.everyDay => true,
      ActiveDaysType.weekdays =>
        date.weekday >= DateTime.monday && date.weekday <= DateTime.friday,
      ActiveDaysType.weekends =>
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday,
      ActiveDaysType.holidays => false, // Phase rules-holiday 接入节假日表
    };
  }

  static bool hasCheckInWindow(Habit habit) =>
      habit.checkInWindowStartMinutes != null &&
      habit.checkInWindowEndMinutes != null;

  /// 综合打卡日 + 有效时间段（未设置时间段则视为全天）。
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

  /// 点击圆环被拦截时的提示文案。
  static String blockedMessage(Habit habit, DateTime moment) {
    if (!canCheckInOn(habit, moment)) {
      return '今日无需打卡（${habit.activeDaysType.label}）';
    }
    if (hasCheckInWindow(habit) && !isWithinTimeWindow(habit, moment)) {
      return '当前不在时间范围内（${TimeUtils.formatWindow(habit.checkInWindowStartMinutes, habit.checkInWindowEndMinutes)}）';
    }
    return '当前无法打卡';
  }

  /// 卡片副标题：今日状态（极简一行，null 则不显示）。
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
}
