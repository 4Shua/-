import 'package:dakaqi/core/constants/habit_assets.dart';
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

  bool _loading = false;
  bool _saving = false;
  bool _advancedExpanded = false;

  String _iconKey = HabitIcons.defaultKey;
  String _colorHex = HabitColors.defaultHex;
  FrequencyType _frequency = FrequencyType.daily;
  int _completions = 1;
  ActiveDaysType _activeDays = ActiveDaysType.everyDay;
  int? _selectedTagId;

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
      _frequency = habit.frequencyType;
      _completions = habit.completionsPerPeriod;
      _activeDays = habit.activeDaysType;
      _selectedTagId = habit.tagId;
      if (tag != null) _tagController.text = tag.name;
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
    final repo = ref.read(habitRepositoryProvider);

    int? tagId;
    final tagText = _tagController.text.trim();
    if (tagText.isNotEmpty) {
      tagId = await repo.resolveTagId(tagText);
    } else {
      tagId = _selectedTagId;
    }

    try {
      if (widget.isEditing) {
        await repo.updateHabit(
          id: widget.habitId!,
          name: name,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          iconKey: _iconKey,
          colorHex: _colorHex,
          frequencyType: _frequency,
          completionsPerPeriod: _completions,
          activeDaysType: _activeDays,
          tagId: tagId,
          clearTag: tagId == null,
        );
      } else {
        await repo.createHabit(
          name: name,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          iconKey: _iconKey,
          colorHex: _colorHex,
          frequencyType: _frequency,
          completionsPerPeriod: _completions,
          activeDaysType: _activeDays,
          tagId: tagId,
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
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: _themeColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            HabitIcons.resolve(_iconKey),
                            size: 40,
                            color: _themeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                        '图标',
                        IconPickerGrid(
                          selectedKey: _iconKey,
                          color: _themeColor,
                          onSelected: (k) => setState(() => _iconKey = k),
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
                  const Text('周期',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  SegmentedButton<FrequencyType>(
                    segments: FrequencyType.values
                        .map(
                          (f) => ButtonSegment(
                            value: f,
                            label: Text(f.label),
                          ),
                        )
                        .toList(),
                    selected: {_frequency},
                    onSelectionChanged: (s) =>
                        setState(() => _frequency = s.first),
                  ),
                  const SizedBox(height: 16),
                  const Text('每周期次数',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: _completions > 1
                            ? () => setState(() => _completions--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$_completions 次 / ${_frequency.label}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _completions < 20
                            ? () => setState(() => _completions++)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('打卡日',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ActiveDaysType.values.map((type) {
                      return ChoiceChip(
                        label: Text(type.label),
                        selected: _activeDays == type,
                        onSelected: (_) =>
                            setState(() => _activeDays = type),
                      );
                    }).toList(),
                  ),
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
}
