import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String primaryValue;
  final String? primaryLabel;
  final String subLeftLabel;
  final String subLeftValue;
  final String subRightLabel;
  final String subRightValue;
  final Color tintColor;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.icon,
    required this.title,
    required this.primaryValue,
    this.primaryLabel,
    required this.subLeftLabel,
    required this.subLeftValue,
    required this.subRightLabel,
    required this.subRightValue,
    required this.tintColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: t.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              color: Colors.black.withOpacity(0.06),
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // header
              Row(
                children: [
                  _IconTint(icon: icon, color: tintColor),
                  const SizedBox(width: 12),
                  Text(title, style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              // primary value
              Text(
                primaryValue,
                style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (primaryLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  primaryLabel!,
                  style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 12),
              // bottom band
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: t.colorScheme.surfaceVariant.withOpacity(0.25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _Mini(label: subLeftLabel, value: subLeftValue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _Mini(label: subRightLabel, value: subRightValue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTint extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconTint({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;

  const _Mini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
