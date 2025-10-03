import 'package:flutter/material.dart';

class KpiSplitCard extends StatelessWidget {
  final String title;
  final IconData icon;

  final String leftLabel;
  final String leftValue;
  final String? leftSubLabel; // NEW (optionnel)
  final String? leftSubValue; // NEW (optionnel)

  final String rightLabel;
  final String rightValue;
  final String? rightSubLabel; // NEW (optionnel)
  final String? rightSubValue; // NEW (optionnel)

  final Color? leftAccent; // NEW
  final Color? rightAccent; // NEW

  final VoidCallback? onTap;

  const KpiSplitCard({
    super.key,
    required this.title,
    required this.icon,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    this.leftSubLabel,
    this.leftSubValue,
    this.rightSubLabel,
    this.rightSubValue,
    this.leftAccent,
    this.rightAccent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _metric(
                      context,
                      leftLabel,
                      leftValue,
                      leftSubLabel,
                      leftSubValue,
                      accent: leftAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metric(
                      context,
                      rightLabel,
                      rightValue,
                      rightSubLabel,
                      rightSubValue,
                      accent: rightAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    String? subLabel,
    String? subValue, {
    Color? accent,
  }) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.headlineSmall!.copyWith(
      color: accent ?? theme.textTheme.headlineSmall!.color,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: valueStyle),
          if (subLabel != null && subValue != null) ...[
            const SizedBox(height: 6),
            Text(subLabel, style: theme.textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(subValue, style: theme.textTheme.titleSmall),
          ],
        ],
      ),
    );
  }
}
