import 'package:dakaqi/core/constants/habit_assets.dart';
import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:dakaqi/domain/models/habit_with_tag.dart';
import 'package:dakaqi/domain/rules/check_in_rules.dart';
import 'package:dakaqi/core/utils/date_utils.dart';
import 'package:dakaqi/features/habit_form/pages/habit_form_screen.dart';
import 'package:dakaqi/features/home/providers/check_in_provider.dart';
import 'package:dakaqi/widgets/month_heatmap_row.dart';
import 'package:dakaqi/widgets/segmented_ring_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HabitCard extends ConsumerWidget {
  const HabitCard({
    super.key,
    required this.item,
  });

  final HabitWithTag item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habit = item.habit;
    final color = HabitColors.parse(habit.colorHex);
    final habitId = habit.id;

    final todayCount = ref.watch(todayCheckInProvider(habitId)).maybeWhen(
          data: (v) => v,
          orElse: () => 0,
        );
    final heatmap = ref.watch(heatmapDataProvider(habitId)).maybeWhen(
          data: (v) => v,
          orElse: () => const <String, int>{},
        );

    final canCheckIn = CheckInRules.canCheckInOn(habit, AppDateUtils.today());

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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openEdit(context, habitId),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            HabitIcons.resolve(habit.iconKey),
                            color: color,
                          ),
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
                              if (habit.description
                                  case final desc? when desc.isNotEmpty)
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
                      ],
                    ),
                  ),
                ),
                SegmentedRingButton(
                  segments: habit.completionsPerPeriod,
                  count: todayCount,
                  color: color,
                  enabled: canCheckIn,
                  onTap: () => _onCheckIn(context, ref, habitId),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _openEdit(context, habitId),
              child: MonthHeatmapRow(
                data: heatmap,
                maxCount: habit.completionsPerPeriod,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, int habitId) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HabitFormScreen(habitId: habitId),
      ),
    );
  }

  Future<void> _onCheckIn(
    BuildContext context,
    WidgetRef ref,
    int habitId,
  ) async {
    final result = await ref.read(checkInActionProvider).tap(habitId);
    if (!context.mounted) return;
    if (result == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('今天不在打卡日范围内'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
