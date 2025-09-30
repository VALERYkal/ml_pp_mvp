import 'package:flutter/material.dart';

/// Choice chip moderne avec design amélioré
class ModernChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final IconData? icon;
  final Color? selectedColor;
  final Color? unselectedColor;

  const ModernChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.icon,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final effectiveSelectedColor = selectedColor ?? colorScheme.primary;
    final effectiveUnselectedColor = unselectedColor ?? colorScheme.surfaceVariant;

    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected 
              ? effectiveSelectedColor.withOpacity(0.1)
              : effectiveUnselectedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected 
                ? effectiveSelectedColor
                : colorScheme.outline.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: effectiveSelectedColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: selected 
                    ? effectiveSelectedColor
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected 
                    ? effectiveSelectedColor
                    : colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
