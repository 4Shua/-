import 'package:dakaqi/core/constants/habit_assets.dart';
import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// 已选图标悬浮于图标网格之上。
class FloatingIconPicker extends StatelessWidget {
  const FloatingIconPicker({
    super.key,
    required this.selectedKey,
    required this.color,
    required this.onSelected,
  });

  final String selectedKey;
  final Color color;
  final ValueChanged<String> onSelected;

  static const _previewSize = 88.0;
  static const _previewOverlap = 44.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _previewOverlap),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              12,
              _previewOverlap + 12,
              12,
              16,
            ),
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
            child: _IconGridLayer(
              selectedKey: selectedKey,
              color: color,
              onSelected: onSelected,
            ),
          ),
        ),
        _FloatingPreview(
          iconKey: selectedKey,
          color: color,
        ),
      ],
    );
  }
}

class _FloatingPreview extends StatelessWidget {
  const _FloatingPreview({
    required this.iconKey,
    required this.color,
  });

  final String iconKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: FloatingIconPicker._previewSize,
      height: FloatingIconPicker._previewSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardBackground,
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
          ),
          child: Icon(
            HabitIcons.resolve(iconKey),
            size: 38,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _IconGridLayer extends StatelessWidget {
  const _IconGridLayer({
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
        childAspectRatio: 1,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final selected = key == selectedKey;

        return Material(
          color: AppColors.chipBackground,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => onSelected(key),
            borderRadius: BorderRadius.circular(10),
            child: Opacity(
              opacity: selected ? 0.25 : 1,
              child: Icon(
                HabitIcons.resolve(key),
                size: 22,
                color: selected ? color : AppColors.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }
}
