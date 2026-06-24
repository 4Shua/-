import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:dakaqi/data/db/database.dart';
import 'package:dakaqi/domain/models/habit_with_tag.dart';
import 'package:flutter/material.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.item,
  });

  final HabitWithTag item;

  @override
  Widget build(BuildContext context) {
    final habit = item.habit;
    final color = _parseColor(habit.colorHex);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFromKey(habit.iconKey), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (habit.description case final desc? when desc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          desc,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _CheckInPlaceholder(
                color: color,
                segments: habit.completionsPerPeriod,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _HeatmapPlaceholder(color: color),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final value = hex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }

  IconData _iconFromKey(String key) {
    return switch (key) {
      'piano' => Icons.piano,
      'favorite' => Icons.favorite_border,
      _ => Icons.circle_outlined,
    };
  }
}

class _CheckInPlaceholder extends StatelessWidget {
  const _CheckInPlaceholder({
    required this.color,
    required this.segments,
  });

  final Color color;
  final int segments;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.add, color: color, size: 28),
    );
  }
}

class _HeatmapPlaceholder extends StatelessWidget {
  const _HeatmapPlaceholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        '月热力图占位 · Phase 2',
        style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13),
      ),
    );
  }
}
