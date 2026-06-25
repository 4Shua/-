import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:dakaqi/core/utils/date_utils.dart';
import 'package:flutter/material.dart';

/// 只读月历：展示打卡记录，不可点击日期。
class ReadOnlyMonthCalendar extends StatelessWidget {
  const ReadOnlyMonthCalendar({
    super.key,
    required this.month,
    required this.checkIns,
    required this.maxCount,
    required this.color,
  });

  final DateTime month;
  final Map<String, int> checkIns;
  final int maxCount;
  final Color color;

  static const _weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  Widget build(BuildContext context) {
    final today = AppDateUtils.today();
    final daysInMonth = AppDateUtils.daysInMonth(month);
    final firstWeekday =
        AppDateUtils.weekdayIndex(DateTime(month.year, month.month, 1));
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < rows; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _buildDayCell(
                      row: row,
                      col: col,
                      firstWeekday: firstWeekday,
                      daysInMonth: daysInMonth,
                      today: today,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDayCell({
    required int row,
    required int col,
    required int firstWeekday,
    required int daysInMonth,
    required DateTime today,
  }) {
    final cellIndex = row * 7 + col;
    final dayNum = cellIndex - firstWeekday + 1;

    if (dayNum < 1 || dayNum > daysInMonth) {
      return const SizedBox(height: 44);
    }

    final date = DateTime(month.year, month.month, dayNum);
    final key = AppDateUtils.formatDate(date);
    final count = checkIns[key] ?? 0;
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isFuture = date.isAfter(today);
    final ratio = maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      height: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: count > 0
                  ? color.withValues(alpha: 0.12 + ratio * 0.35)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday
                  ? Border.all(color: AppColors.textPrimary, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$dayNum',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isFuture
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppColors.textPrimary,
              ),
            ),
          ),
          if (count > 0) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                count.clamp(1, maxCount),
                (_) => Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
