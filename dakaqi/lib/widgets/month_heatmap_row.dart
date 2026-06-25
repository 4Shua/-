import 'package:dakaqi/core/utils/date_utils.dart';
import 'package:flutter/material.dart';

/// 按月分组的热力图，横向滚动。
class MonthHeatmapRow extends StatelessWidget {
  const MonthHeatmapRow({
    super.key,
    required this.data,
    required this.maxCount,
    required this.color,
    this.monthsBack = 6,
    this.cellSize = 10,
    this.cellGap = 2,
  });

  /// date (yyyy-MM-dd) -> count
  final Map<String, int> data;
  final int maxCount;
  final Color color;
  final int monthsBack;
  final double cellSize;
  final double cellGap;

  @override
  Widget build(BuildContext context) {
    final today = AppDateUtils.today();
    final start = AppDateUtils.monthsAgo(monthsBack - 1);
    final months = AppDateUtils.monthsInRange(start, today);

    return SizedBox(
      height: cellSize * 7 + cellGap * 6 + 18,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _MonthColumn(
            month: months[index],
            today: today,
            data: data,
            maxCount: maxCount,
            color: color,
            cellSize: cellSize,
            cellGap: cellGap,
          );
        },
      ),
    );
  }
}

class _MonthColumn extends StatelessWidget {
  const _MonthColumn({
    required this.month,
    required this.today,
    required this.data,
    required this.maxCount,
    required this.color,
    required this.cellSize,
    required this.cellGap,
  });

  final DateTime month;
  final DateTime today;
  final Map<String, int> data;
  final int maxCount;
  final Color color;
  final double cellSize;
  final double cellGap;

  @override
  Widget build(BuildContext context) {
    final days = AppDateUtils.daysInMonth(month);
    final firstWeekday = AppDateUtils.weekdayIndex(DateTime(month.year, month.month, 1));
    final totalCells = firstWeekday + days;
    final rows = (totalCells / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppDateUtils.formatMonthLabel(month),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        ...List.generate(rows, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: row < rows - 1 ? cellGap : 0),
            child: Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNum = cellIndex - firstWeekday + 1;
                if (dayNum < 1 || dayNum > days) {
                  return SizedBox(width: cellSize, height: cellSize);
                }
                final date = DateTime(month.year, month.month, dayNum);
                if (date.isAfter(today)) {
                  return Padding(
                    padding: EdgeInsets.only(right: col < 6 ? cellGap : 0),
                    child: SizedBox(width: cellSize, height: cellSize),
                  );
                }
                final key = AppDateUtils.formatDate(date);
                final count = data[key] ?? 0;
                return Padding(
                  padding: EdgeInsets.only(right: col < 6 ? cellGap : 0),
                  child: _HeatCell(
                    count: count,
                    maxCount: maxCount,
                    color: color,
                    size: cellSize,
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.count,
    required this.maxCount,
    required this.color,
    required this.size,
  });

  final int count;
  final int maxCount;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;
    final bg = count == 0
        ? const Color(0xFFEBEBEF)
        : color.withValues(alpha: 0.15 + ratio * 0.85);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }
}
