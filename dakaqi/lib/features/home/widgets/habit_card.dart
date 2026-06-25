import 'dart:async';

import 'package:dakaqi/core/constants/habit_assets.dart';
import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:dakaqi/domain/models/enums.dart';
import 'package:dakaqi/domain/models/habit_with_tag.dart';
import 'package:dakaqi/domain/rules/check_in_rules.dart';
import 'package:dakaqi/features/habit_detail/widgets/habit_detail_sheet.dart';
import 'package:dakaqi/features/home/providers/check_in_provider.dart';
import 'package:dakaqi/widgets/month_heatmap_row.dart';
import 'package:dakaqi/widgets/segmented_ring_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 打卡受限提示：同一时刻只显示一条 SnackBar。
abstract final class CheckInHint {
  static bool _showing = false;

  static void show(BuildContext context, String message) {
    if (_showing) return;
    _showing = true;
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        )
        .closed
        .whenComplete(() => _showing = false);
  }
}

class HabitCard extends ConsumerStatefulWidget {
  const HabitCard({
    super.key,
    required this.item,
  });

  final HabitWithTag item;

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard> {
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startClockIfNeeded();
  }

  @override
  void didUpdateWidget(HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.habit.id != widget.item.habit.id ||
        oldWidget.item.habit.checkInWindowStartMinutes !=
            widget.item.habit.checkInWindowStartMinutes ||
        oldWidget.item.habit.checkInWindowEndMinutes !=
            widget.item.habit.checkInWindowEndMinutes ||
        oldWidget.item.habit.activeDaysType !=
            widget.item.habit.activeDaysType) {
      _startClockIfNeeded();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClockIfNeeded() {
    _clockTimer?.cancel();
    final habit = widget.item.habit;
    final needsClock = CheckInRules.hasCheckInWindow(habit) ||
        habit.activeDaysType != ActiveDaysType.everyDay;
    if (!needsClock) return;

    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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

    final canCheckIn = CheckInRules.canCheckInNow(habit, _now);
    final statusHint = CheckInRules.todayStatusHint(habit, _now);
    final showSchedule =
        habit.activeDaysType != ActiveDaysType.everyDay && statusHint == null;

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
                    onTap: () => showHabitDetailSheet(context, item),
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
                              if (statusHint != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    statusHint,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: color.withValues(alpha: 0.75),
                                    ),
                                  ),
                                )
                              else if (showSchedule)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    habit.activeDaysType.label,
                                    style: const TextStyle(
                                      fontSize: 12,
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
                  onTap: () => _onRingTap(context, ref, item, canCheckIn),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => showHabitDetailSheet(context, item),
              child: MonthHeatmapRow(
                data: heatmap,
                habit: habit,
                maxCount: habit.completionsPerPeriod,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onRingTap(
    BuildContext context,
    WidgetRef ref,
    HabitWithTag item,
    bool canCheckIn,
  ) async {
    if (!canCheckIn) {
      CheckInHint.show(context, CheckInRules.blockedMessage(item.habit, _now));
      return false;
    }

    final result = await ref.read(checkInActionProvider).tap(item.habit.id);
    if (!context.mounted) return result >= 0;
    if (result == -1) {
      CheckInHint.show(
        context,
        CheckInRules.blockedMessage(item.habit, DateTime.now()),
      );
    } else if (result == -2) {
      CheckInHint.show(
        context,
        CheckInRules.blockedMessage(item.habit, DateTime.now()),
      );
    }
    return result >= 0;
  }
}
