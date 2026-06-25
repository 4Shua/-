import 'package:dakaqi/core/constants/habit_assets.dart';
import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ColorPickerGrid extends StatelessWidget {
  const ColorPickerGrid({
    super.key,
    required this.selectedHex,
    required this.onSelected,
  });

  final String selectedHex;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final hex in HabitColors.palette)
          GestureDetector(
            onTap: () => onSelected(hex),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: HabitColors.parse(hex),
                shape: BoxShape.circle,
                border: selectedHex == hex
                    ? Border.all(color: AppColors.textPrimary, width: 2.5)
                    : null,
              ),
              child: selectedHex == hex
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
      ],
    );
  }
}
