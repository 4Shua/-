import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:dakaqi/data/db/database.dart';
import 'package:dakaqi/domain/models/habit_with_tag.dart';
import 'package:dakaqi/features/habit_form/pages/habit_form_screen.dart';
import 'package:dakaqi/features/settings/pages/settings_page.dart';
import 'package:dakaqi/features/home/providers/habit_list_provider.dart';
import 'package:dakaqi/features/home/widgets/habit_card.dart';
import 'package:dakaqi/features/home/widgets/tag_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);
    final tagsAsync = ref.watch(tagListProvider);
    final selectedTagId = ref.watch(selectedTagIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '乱七八糟打卡器',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
          icon: const Icon(Icons.settings_outlined),
        ),
        actions: [
          IconButton(
            onPressed: () => _openCreate(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
        data: (habits) {
          final filtered = _filterHabits(habits, selectedTagId);
          final tags = tagsAsync.maybeWhen(
            data: (List<Tag> value) => value,
            orElse: () => const <Tag>[],
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              0,
              AppSpacing.page,
              AppSpacing.page,
            ),
            children: [
              TagFilterBar(
                tags: tags,
                selectedTagId: selectedTagId,
                onSelected: ref.read(selectedTagIdProvider.notifier).select,
              ),
              const SizedBox(height: AppSpacing.cardGap),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      '暂无习惯，点击右上角 + 创建',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...filtered.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
                    child: HabitCard(item: item),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const HabitFormScreen(),
      ),
    );
  }

  List<HabitWithTag> _filterHabits(
    List<HabitWithTag> habits,
    int? selectedTagId,
  ) {
    if (selectedTagId == null) return habits;
    return habits.where((item) => item.habit.tagId == selectedTagId).toList();
  }
}
