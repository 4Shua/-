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
  EffectiveDayMode _effectiveDayMode = EffectiveDayMode.anyDay;
  int? _selectedTagId;

  bool _windowRestricted = false;
  TimeOfDay _windowStart = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _windowEnd = const TimeOfDay(hour: 22, minute: 0);
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    _advancedExpanded = widget.isEditing;
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
      _effectiveDayMode = habit.effectiveDayMode;
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
          effectiveDayMode: _effectiveDayMode,
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
          effectiveDayMode: _effectiveDayMode,
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
                      const SizedBox(height: 16),
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
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _themeColor,
                                ),
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
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _advancedExpanded = !_advancedExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FadeDividerLine(
                  fadeOut: AxisDirection.left,
                  accent: _themeColor,
                ),
                const SizedBox(width: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '复杂的',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _advancedExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: AppColors.textSecondary.withValues(alpha: 0.55),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                _FadeDividerLine(
                  fadeOut: AxisDirection.right,
                  accent: _themeColor,
                ),
              ],
            ),
          ),
        ),
        if (_advancedExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
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
                          selectedColor: _themeColor.withValues(alpha: 0.16),
                          labelStyle: TextStyle(
                            color: _selectedTagId == null &&
                                    _tagController.text.trim().isEmpty
                                ? _themeColor
                                : AppColors.textPrimary,
                            fontWeight: _selectedTagId == null &&
                                    _tagController.text.trim().isEmpty
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: _selectedTagId == null &&
                                    _tagController.text.trim().isEmpty
                                ? _themeColor.withValues(alpha: 0.35)
                                : Colors.transparent,
                          ),
                          showCheckmark: false,
                          onSelected: (_) => setState(() {
                            _selectedTagId = null;
                            _tagController.clear();
                          }),
                        ),
                        for (final tag in tags)
                          ChoiceChip(
                            label: Text(tag.name),
                            selected: _selectedTagId == tag.id,
                            selectedColor: _themeColor.withValues(alpha: 0.16),
                            labelStyle: TextStyle(
                              color: _selectedTagId == tag.id
                                  ? _themeColor
                                  : AppColors.textPrimary,
                              fontWeight: _selectedTagId == tag.id
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                            side: BorderSide(
                              color: _selectedTagId == tag.id
                                  ? _themeColor.withValues(alpha: 0.35)
                                  : Colors.transparent,
                            ),
                            showCheckmark: false,
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
    );
  }

  Widget _buildTimesPerDayRow() {
    return Row(
      children: [
        _CompactCountStepper(
          controller: _timesPerDayController,
          accent: _themeColor,
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
          accent: _themeColor,
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
    return _TripleDayChip(
      mode: _effectiveDayMode,
      accent: _themeColor,
      onSelected: (mode) => setState(() => _effectiveDayMode = mode),
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
            _themedSwitch(
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
                  accent: _themeColor,
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
                  accent: _themeColor,
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
            _themedSwitch(
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
            accent: _themeColor,
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
        final scheme = Theme.of(context).colorScheme.copyWith(
              primary: _themeColor,
              onPrimary: Colors.white,
            );
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: scheme),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Widget _themedSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _themeColor,
            ),
      ),
      child: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.label,
    required this.time,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.08),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: accent,
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
    required this.accent,
    this.maxValue = 20,
  });

  final TextEditingController controller;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final ValueChanged<int> onChanged;
  final VoidCallback onNormalize;
  final Color accent;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperIconButton(
            icon: Icons.remove,
            onTap: onDecrement,
            accent: accent,
          ),
          Container(
            width: 1,
            height: 22,
            color: accent.withValues(alpha: 0.18),
          ),
          SizedBox(
            width: 44,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: accent,
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
            color: accent.withValues(alpha: 0.18),
          ),
          _StepperIconButton(
            icon: Icons.add,
            onTap: onIncrement,
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  const _StepperIconButton({
    required this.icon,
    required this.onTap,
    required this.accent,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color accent;

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
                ? accent
                : AppColors.textSecondary.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

/// 从文字向两侧渐变消失的分隔线。
class _FadeDividerLine extends StatelessWidget {
  const _FadeDividerLine({
    required this.fadeOut,
    this.accent,
  });

  final AxisDirection fadeOut;
  final Color? accent;

  static const _length = 84.0;

  @override
  Widget build(BuildContext context) {
    final peak = (accent ?? AppColors.textSecondary).withValues(alpha: 0.32);
    final (begin, end) = switch (fadeOut) {
      AxisDirection.left => (Alignment.centerRight, Alignment.centerLeft),
      _ => (Alignment.centerLeft, Alignment.centerRight),
    };

    return SizedBox(
      width: _length,
      height: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            stops: const [0, 0.55, 1],
            colors: [
              peak,
              peak.withValues(alpha: 0.12),
              peak.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripleDayChip extends StatelessWidget {
  const _TripleDayChip({
    required this.mode,
    required this.accent,
    required this.onSelected,
  });

  final EffectiveDayMode mode;
  final Color accent;
  final ValueChanged<EffectiveDayMode> onSelected;

  static const _height = 36.0;
  static const _labels = ['周中', '周末', '管他周几'];
  static const _modes = [
    EffectiveDayMode.weekday,
    EffectiveDayMode.weekend,
    EffectiveDayMode.anyDay,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: AppColors.chipBackground,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: _TripleSegmentClipper(
                  segment: _modes.indexOf(mode),
                ),
                child: ColoredBox(color: accent.withValues(alpha: 0.16)),
              ),
              CustomPaint(
                painter: _TripleDividerPainter(
                  color: accent.withValues(alpha: 0.32),
                ),
              ),
              Row(
                children: List.generate(3, (index) {
                  final selected = mode == _modes[index];
                  return Expanded(
                    child: InkWell(
                      onTap: () => onSelected(_modes[index]),
                      child: Center(
                        child: Text(
                          _labels[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: index == 2 ? 11.5 : 13,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? accent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripleSegmentClipper extends CustomClipper<Path> {
  const _TripleSegmentClipper({required this.segment});

  final int segment;

  static const _skew = 0.04;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final b1Top = w / 3 + w * _skew;
    final b1Bottom = w / 3 - w * _skew;
    final b2Top = w * 2 / 3 + w * _skew;
    final b2Bottom = w * 2 / 3 - w * _skew;

    return switch (segment) {
      0 => Path()
        ..moveTo(0, 0)
        ..lineTo(b1Top, 0)
        ..lineTo(b1Bottom, h)
        ..lineTo(0, h)
        ..close(),
      1 => Path()
        ..moveTo(b1Top, 0)
        ..lineTo(b2Top, 0)
        ..lineTo(b2Bottom, h)
        ..lineTo(b1Bottom, h)
        ..close(),
      _ => Path()
        ..moveTo(b2Top, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h)
        ..lineTo(b2Bottom, h)
        ..close(),
    };
  }

  @override
  bool shouldReclip(covariant _TripleSegmentClipper oldClipper) =>
      oldClipper.segment != segment;
}

class _TripleDividerPainter extends CustomPainter {
  const _TripleDividerPainter({required this.color});

  final Color color;

  static const _skew = 0.04;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final lines = [
      (Offset(w / 3 + w * _skew, 2), Offset(w / 3 - w * _skew, h - 2)),
      (Offset(w * 2 / 3 + w * _skew, 2), Offset(w * 2 / 3 - w * _skew, h - 2)),
    ];
    for (final (start, end) in lines) {
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TripleDividerPainter oldDelegate) =>
      oldDelegate.color != color;
}
