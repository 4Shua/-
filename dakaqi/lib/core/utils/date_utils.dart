import 'package:intl/intl.dart';

abstract final class AppDateUtils {
  static String formatDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static String formatMonthLabel(DateTime date) => '${date.month}月';

  static String formatYearMonth(DateTime date) => '${date.year}年${date.month}月';

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime monthsAgo(int months) {
    final t = today();
    return DateTime(t.year, t.month - months, 1);
  }

  /// 从 start 到 end（含）按天迭代
  static Iterable<DateTime> daysInRange(DateTime start, DateTime end) sync* {
    var current = start;
    while (!current.isAfter(end)) {
      yield current;
      current = current.add(const Duration(days: 1));
    }
  }

  static List<DateTime> monthsInRange(DateTime start, DateTime end) {
    final months = <DateTime>[];
    var current = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);
    while (!current.isAfter(endMonth)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }
    return months;
  }

  static int daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  /// 周一=0 … 周日=6
  static int weekdayIndex(DateTime date) => date.weekday - 1;
}
