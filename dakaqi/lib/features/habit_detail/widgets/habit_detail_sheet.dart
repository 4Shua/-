import 'package:dakaqi/core/constants/habit_assets.dart';
import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:dakaqi/core/utils/date_utils.dart';
import 'package:dakaqi/domain/models/habit_with_tag.dart';
import 'package:dakaqi/features/habit_detail/widgets/read_only_month_calendar.dart';
import 'package:dakaqi/features/habit_form/pages/habit_form_screen.dart';
import 'package:dakaqi/features/home/providers/check_in_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showHabitDetailSheet(
  BuildContext context,
  HabitWithTag item,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HabitDetailSheet(item: item),
  );
}

class HabitDetailSheet extends ConsumerStatefulWidget {
  const HabitDetailSheet({super.key, required this.item});

  final HabitWithTag item;

  @override
  ConsumerState<HabitDetailSheet> createState() => _HabitDetailSheetState();
}

class _HabitDetailSheetState extends ConsumerState<HabitDetailSheet> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = AppDateUtils.today();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      );
    });
  }

  Future<void> _openEdit() async {
    final habitId = widget.item.habit.id;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HabitFormScreen(habitId: habitId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.item.habit;
    final color = HabitColors.parse(habit.colorHex);
    final checkIns = ref.watch(allCheckInsProvider(habit.id)).maybeWhen(
          data: (v) => v,
          orElse: () => const <String, int>{},
        );

    final monthLabel = AppDateUtils.formatYearMonth(_visibleMonth);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.chipBackground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      HabitIcons.resolve(habit.iconKey),
                      color: color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (habit.description case final desc?
                            when desc.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              desc,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _MetaChip(
                    label: habit.frequencyType.label,
                    color: color,
                  ),
                  const Spacer(),
                  _IconActionButton(
                    icon: Icons.edit_outlined,
                    onTap: _openEdit,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ReadOnlyMonthCalendar(
                month: _visibleMonth,
                habit: habit,
                checkIns: checkIns,
                maxCount: habit.completionsPerPeriod,
                color: color,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: color.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        monthLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      final now = AppDateUtils.today();
                      final next = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month + 1,
                      );
                      if (next.year > now.year ||
                          (next.year == now.year && next.month > now.month)) {
                        return;
                      }
                      _shiftMonth(1);
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.chipBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
