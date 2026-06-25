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
}
