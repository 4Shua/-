import 'package:dakaqi/core/theme/app_theme.dart';
import 'package:dakaqi/data/db/database.dart';
import 'package:flutter/material.dart';

class TagFilterBar extends StatelessWidget {
  const TagFilterBar({
    super.key,
    required this.tags,
    required this.selectedTagId,
    required this.onSelected,
  });

  final List<Tag> tags;
  final int? selectedTagId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: '全部',
            selected: selectedTagId == null,
            onTap: () => onSelected(null),
          ),
          for (final tag in tags) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: tag.name,
              selected: selectedTagId == tag.id,
              onTap: () => onSelected(tag.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
