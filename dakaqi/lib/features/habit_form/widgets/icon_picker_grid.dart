import 'package:dakaqi/core/constants/habit_assets.dart';
import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// 紧凑展示：居中预览 + 背景 2～3 行；点击打开完整图标层。
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

  static const _previewSize = 76.0;
  static const _collapsedRows = 3;
  static const _crossAxisCount = 8;

  Future<void> _openPickerSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IconPickerSheet(
        selectedKey: selectedKey,
        color: color,
        onSelected: (key) {
          onSelected(key);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = HabitIcons.entries.keys.toList();
    const spacing = 8.0;
    const hPad = 12.0;
    final cellWidth =
        (MediaQuery.sizeOf(context).width - AppSpacing.page * 2 - hPad * 2 -
                spacing * (_crossAxisCount - 1)) /
            _crossAxisCount;
    final rowHeight = cellWidth + spacing;
    final collapsedHeight =
        hPad * 2 + rowHeight * _collapsedRows - spacing + _previewSize * 0.35;

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPickerSheet(context),
        child: SizedBox(
          height: collapsedHeight,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(hPad, hPad, hPad, hPad),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _crossAxisCount,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: 1,
                    ),
                    itemCount: keys.length.clamp(0, _crossAxisCount * _collapsedRows),
                    itemBuilder: (context, index) {
                      final key = keys[index];
                      final selected = key == selectedKey;
                      return _IconCell(
                        iconKey: key,
                        color: color,
                        selected: selected,
                        onTap: () => _openPickerSheet(context),
                        compact: true,
                      );
                    },
                  ),
                ),
              ),
              _FloatingPreview(
                iconKey: selectedKey,
                color: color,
                size: _previewSize,
                onTap: () => _openPickerSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconPickerSheet extends StatelessWidget {
  const _IconPickerSheet({
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
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.88,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _FloatingPreview(
                iconKey: selectedKey,
                color: color,
                size: 88,
              ),
              const SizedBox(height: 12),
              const Text(
                '选择图标',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    return _IconCell(
                      iconKey: key,
                      color: color,
                      selected: key == selectedKey,
                      onTap: () => onSelected(key),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingPreview extends StatelessWidget {
  const _FloatingPreview({
    required this.iconKey,
    required this.color,
    required this.size,
    this.onTap,
  });

  final String iconKey;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final inner = size * 0.82;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cardBackground,
            border: Border.all(
              color: color.withValues(alpha: 0.28),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: inner,
              height: inner,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(
                HabitIcons.resolve(iconKey),
                size: size * 0.42,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconCell extends StatelessWidget {
  const _IconCell({
    required this.iconKey,
    required this.color,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String iconKey;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? color.withValues(alpha: compact ? 0.12 : 0.16)
          : AppColors.chipBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Opacity(
          opacity: compact && selected ? 0.35 : 1,
          child: Icon(
            HabitIcons.resolve(iconKey),
            size: compact ? 20 : 22,
            color: selected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
