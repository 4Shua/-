import 'package:dakaqi/core/constants/habit_assets.dart';
import 'package:dakaqi/core/utils/time_utils.dart';
import 'package:dakaqi/core/providers/database_provider.dart';
import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:dakaqi/data/db/database.dart';
import 'package:dakaqi/domain/models/enums.dart';
import 'package:dakaqi/features/habit_form/widgets/color_picker_grid.dart';
import 'package:dakaqi/features/habit_form/widgets/icon_picker_grid.dart';
import 'package:dakaqi/features/home/providers/habit_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({super.key, this.habitId});

  final int? habitId;

  bool get isEditing => habitId != null;

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _tagController = TextEditingController();
  final _timesPerDayController = TextEditingController(text: '1');
  final _monthlyTargetController = TextEditingController(text: '20');

  bool _loading = false;
  bool _saving = false;
  bool _advancedExpanded = false;

  String _iconKey = HabitIcons.defaultKey;
  String _colorHex = HabitColors.defaultHex;
  int _timesPerDay = 1;
  int _monthlyTarget = 20;
  EffectiveDayCategory _effectiveDayCategory = EffectiveDayCategory.everyDay;
  EffectiveDayVariant _effectiveDayVariant = EffectiveDayVariant.weekday;
  int? _selectedTagId;

  bool _windowRestricted = false;
  TimeOfDay _windowStart = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _windowEnd = const TimeOfDay(hour: 22, minute: 0);
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadHabit());
    }
  }

  Future<void> _loadHabit() async {
    final repo = ref.read(habitRepositoryProvider);
    final habit = await repo.getHabit(widget.habitId!);
    if (habit == null || !mounted) {
      Navigator.pop(context);
      return;
    }
    Tag? tag;
    if (habit.tagId != null) {
      tag = await repo.getTag(habit.tagId!);
    }
    setState(() {
      _nameController.text = habit.name;
      _descController.text = habit.description ?? '';
      _iconKey = habit.iconKey;
      _colorHex = habit.colorHex;
      _timesPerDay = habit.timesPerDay;
      _timesPerDayController.text = '${habit.timesPerDay}';
      _monthlyTarget = habit.monthlyTarget;
      _monthlyTargetController.text = '${habit.monthlyTarget}';
      _effectiveDayCategory = habit.effectiveDayCategory;
      _effectiveDayVariant = habit.effectiveDayVariant;
      _selectedTagId = habit.tagId;
      if (tag != null) _tagController.text = tag.name;
      _reminderEnabled = habit.reminderEnabled;
      _reminderTime =
          TimeUtils.parseTime(habit.reminderTime) ?? _reminderTime;
      if (habit.checkInWindowStartMinutes != null &&
          habit.checkInWindowEndMinutes != null) {
        _windowRestricted = true;
        _windowStart = TimeUtils.fromMinutes(habit.checkInWindowStartMinutes!);
        _windowEnd = TimeUtils.fromMinutes(habit.checkInWindowEndMinutes!);
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写习惯名称')),
      );
      return;
    }

    setState(() => _saving = true);
    _normalizeTimesPerDayInput();
    _normalizeMonthlyTargetInput();
    final repo = ref.read(habitRepositoryProvider);

    int? tagId;
    final tagText = _tagController.text.trim();
    if (tagText.isNotEmpty) {
      tagId = await repo.resolveTagId(tagText);
    } else {
      tagId = _selectedTagId;
    }

    try {
      final windowStart = _windowRestricted ? TimeUtils.toMinutes(_windowStart) : null;
      final windowEnd = _windowRestricted ? TimeUtils.toMinutes(_windowEnd) : null;
      final reminderTime =
          _reminderEnabled ? TimeUtils.formatTimeOfDay(_reminderTime) : null;

      if (widget.isEditing) {
        await repo.updateHabit(
          id: widget.habitId!,
          name: name,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          iconKey: _iconKey,
          colorHex: _colorHex,
          timesPerDay: _timesPerDay,
          monthlyTarget: _monthlyTarget,
          effectiveDayCategory: _effectiveDayCategory,
          effectiveDayVariant: _effectiveDayVariant,
          tagId: tagId,
          clearTag: tagId == null,
          reminderEnabled: _reminderEnabled,
          reminderTime: reminderTime,
          checkInWindowStartMinutes: windowStart,
          checkInWindowEndMinutes: windowEnd,
        );
      } else {
        await repo.createHabit(
          name: name,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          iconKey: _iconKey,
          colorHex: _colorHex,
          timesPerDay: _timesPerDay,
          monthlyTarget: _monthlyTarget,
          effectiveDayCategory: _effectiveDayCategory,
          effectiveDayVariant: _effectiveDayVariant,
          tagId: tagId,
          reminderEnabled: _reminderEnabled,
          reminderTime: reminderTime,
          checkInWindowStartMinutes: windowStart,
          checkInWindowEndMinutes: windowEnd,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _tagController.dispose();
    _timesPerDayController.dispose();
    _monthlyTargetController.dispose();
    super.dispose();
  }

  Color get _themeColor => HabitColors.parse(_colorHex);

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagListProvider).maybeWhen(
          data: (List<Tag> v) => v,
          orElse: () => const <Tag>[],
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isEditing ? '编辑习惯' : '新建习惯'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    children: [
                      FloatingIconPicker(
                        selectedKey: _iconKey,
                        color: _themeColor,
                        onSelected: (k) => setState(() => _iconKey = k),
                      ),
                      const SizedBox(height: 24),
                      _fieldSection(
                        '名称',
                        TextField(
                          controller: _nameController,
                          decoration: _inputDecoration('习惯名称'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fieldSection(
                        '描述',
                        TextField(
                          controller: _descController,
                          decoration: _inputDecoration('可选描述'),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fieldSection(
                        '颜色',
                        ColorPickerGrid(
                          selectedHex: _colorHex,
                          onSelected: (h) => setState(() => _colorHex = h),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAdvancedPanel(tags),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.cardBackground,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                '保存',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _fieldSection(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildAdvancedPanel(List<Tag> tags) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _advancedExpanded = !_advancedExpanded),
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Text(
                    '高级选项',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _advancedExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_advancedExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('频率',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _buildTimesPerDayRow(),
                  const SizedBox(height: 16),
                  const Text('目标',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _buildMonthlyTargetRow(),
                  const SizedBox(height: 16),
                  const Text('有效打卡日',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _buildEffectiveDaySelector(),
                  const SizedBox(height: 16),
                  _buildCheckInWindowSection(),
                  const SizedBox(height: 16),
                  _buildReminderSection(),
                  const SizedBox(height: 16),
                  const Text('类型（标签）',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  if (tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('无'),
                          selected: _selectedTagId == null &&
                              _tagController.text.trim().isEmpty,
                          onSelected: (_) => setState(() {
                            _selectedTagId = null;
                            _tagController.clear();
                          }),
                        ),
                        for (final tag in tags)
                          ChoiceChip(
                            label: Text(tag.name),
                            selected: _selectedTagId == tag.id,
                            onSelected: (_) => setState(() {
                              _selectedTagId = tag.id;
                              _tagController.text = tag.name;
                            }),
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tagController,
                    decoration: _inputDecoration('输入新类型名称'),
                    onChanged: (_) {
                      if (_selectedTagId != null) {
                        setState(() => _selectedTagId = null);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimesPerDayRow() {
    return Row(
      children: [
        _CompactCountStepper(
          controller: _timesPerDayController,
          onDecrement: _timesPerDay > 1
              ? () => _setTimesPerDay(_timesPerDay - 1)
              : null,
          onIncrement: _timesPerDay < 20
              ? () => _setTimesPerDay(_timesPerDay + 1)
              : null,
          onChanged: (parsed) => setState(() => _timesPerDay = parsed),
          onNormalize: _normalizeTimesPerDayInput,
          maxValue: 20,
        ),
        const SizedBox(width: 10),
        const Text(
          '次 / 天',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMonthlyTargetRow() {
    return Row(
      children: [
        _CompactCountStepper(
          controller: _monthlyTargetController,
          onDecrement: _monthlyTarget > 1
              ? () => _setMonthlyTarget(_monthlyTarget - 1)
              : null,
          onIncrement: _monthlyTarget < 99
              ? () => _setMonthlyTarget(_monthlyTarget + 1)
              : null,
          onChanged: (parsed) => setState(() => _monthlyTarget = parsed),
          onNormalize: _normalizeMonthlyTargetInput,
          maxValue: 99,
        ),
        const SizedBox(width: 10),
        const Text(
          '次 / 月',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEffectiveDaySelector() {
    final color = _themeColor;
    return Row(
      children: [
        ChoiceChip(
          label: const Text('每天'),
          selected: _effectiveDayCategory == EffectiveDayCategory.everyDay,
          onSelected: (_) => setState(
            () => _effectiveDayCategory = EffectiveDayCategory.everyDay,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Material(
            color: _effectiveDayCategory == EffectiveDayCategory.weekdayWeekend
                ? color.withValues(alpha: 0.14)
                : AppColors.chipBackground,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  if (_effectiveDayCategory ==
                      EffectiveDayCategory.weekdayWeekend) {
                    _effectiveDayVariant =
                        _effectiveDayVariant == EffectiveDayVariant.weekday
                            ? EffectiveDayVariant.weekend
                            : EffectiveDayVariant.weekday;
                  } else {
                    _effectiveDayCategory =
                        EffectiveDayCategory.weekdayWeekend;
                  }
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '周中',
                      style: TextStyle(
                        fontWeight: _effectiveDayCategory ==
                                    EffectiveDayCategory.weekdayWeekend &&
                                _effectiveDayVariant ==
                                    EffectiveDayVariant.weekday
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _effectiveDayCategory ==
                                EffectiveDayCategory.weekdayWeekend
                            ? color
                            : AppColors.textSecondary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.swap_horiz,
                        size: 16,
                        color: _effectiveDayCategory ==
                                EffectiveDayCategory.weekdayWeekend
                            ? color.withValues(alpha: 0.8)
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      '周末',
                      style: TextStyle(
                        fontWeight: _effectiveDayCategory ==
                                    EffectiveDayCategory.weekdayWeekend &&
                                _effectiveDayVariant ==
                                    EffectiveDayVariant.weekend
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _effectiveDayCategory ==
                                EffectiveDayCategory.weekdayWeekend
                            ? color
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _setTimesPerDay(int value) {
    final clamped = value.clamp(1, 20);
    setState(() {
      _timesPerDay = clamped;
      _timesPerDayController.text = '$clamped';
    });
  }

  void _normalizeTimesPerDayInput() {
    final parsed = int.tryParse(_timesPerDayController.text.trim());
    _setTimesPerDay(parsed ?? _timesPerDay);
  }

  void _setMonthlyTarget(int value) {
    final clamped = value.clamp(1, 99);
    setState(() {
      _monthlyTarget = clamped;
      _monthlyTargetController.text = '$clamped';
    });
  }

  void _normalizeMonthlyTargetInput() {
    final parsed = int.tryParse(_monthlyTargetController.text.trim());
    _setMonthlyTarget(parsed ?? _monthlyTarget);
  }

  Widget _buildCheckInWindowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '有效打卡时间',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Switch.adaptive(
              value: _windowRestricted,
              onChanged: (v) => setState(() => _windowRestricted = v),
            ),
          ],
        ),
        if (_windowRestricted) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimeBox(
                  label: '开始',
                  time: _windowStart,
                  onTap: () async {
                    final picked = await _pickTime(initial: _windowStart);
                    if (picked != null) setState(() => _windowStart = picked);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeBox(
                  label: '结束',
                  time: _windowEnd,
                  onTap: () async {
                    final picked = await _pickTime(initial: _windowEnd);
                    if (picked != null) setState(() => _windowEnd = picked);
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '打卡提醒',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Switch.adaptive(
              value: _reminderEnabled,
              onChanged: (v) => setState(() => _reminderEnabled = v),
            ),
          ],
        ),
        if (_reminderEnabled) ...[
          const SizedBox(height: 8),
          _TimeBox(
            label: '提醒',
            time: _reminderTime,
            onTap: () async {
              final picked = await _pickTime(initial: _reminderTime);
              if (picked != null) setState(() => _reminderTime = picked);
            },
          ),
        ],
      ],
    );
  }

  Future<TimeOfDay?> _pickTime({
    required TimeOfDay initial,
  }) async {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.chipBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                TimeUtils.formatTimeOfDay(time),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactCountStepper extends StatelessWidget {
  const _CompactCountStepper({
    required this.controller,
    required this.onDecrement,
    required this.onIncrement,
    required this.onChanged,
    required this.onNormalize,
    this.maxValue = 20,
  });

  final TextEditingController controller;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final ValueChanged<int> onChanged;
  final VoidCallback onNormalize;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperIconButton(icon: Icons.remove, onTap: onDecrement),
          Container(
            width: 1,
            height: 22,
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          SizedBox(
            width: 44,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (text) {
                final parsed = int.tryParse(text.trim());
                if (parsed != null && parsed >= 1 && parsed <= maxValue) {
                  onChanged(parsed);
                }
              },
              onSubmitted: (_) => onNormalize(),
              onTapOutside: (_) => onNormalize(),
            ),
          ),
          Container(
            width: 1,
            height: 22,
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          _StepperIconButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  const _StepperIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: 40,
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? AppColors.textPrimary
                : AppColors.textSecondary.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
