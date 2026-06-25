import 'package:dakaqi/core/constants/habit_assets.dart';
import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class IconPickerGrid extends StatelessWidget {
  const IconPickerGrid({
    super.key,
    required this.selectedKey,
    required this.color,
    required this.onSelected,
  });

  final String selectedKey;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final keys = HabitIcons.entries.keys.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final selected = key == selectedKey;
        return Material(
          color: selected ? color.withValues(alpha: 0.15) : AppColors.chipBackground,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => onSelected(key),
            borderRadius: BorderRadius.circular(10),
            child: Icon(
              HabitIcons.resolve(key),
              size: 22,
              color: selected ? color : AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}
