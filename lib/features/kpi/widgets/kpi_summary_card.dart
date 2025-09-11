import 'package:flutter/material.dart';
import '../models/kpi_models.dart';

class KpiSummaryCard extends StatelessWidget {
  final String title;
  final String totalValue;
  final List<KpiLabelValue> details; // ex: [("En route","3"),("En attente de déchargement","1")]
  final IconData icon;
  final Color? tint;
  final VoidCallback? onTap;

  const KpiSummaryCard({
    super.key,
    required this.title,
    required this.totalValue,
    required this.details,
    required this.icon,
    this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = tint ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0,6))],
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.2)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).hintColor)),
                  const SizedBox(height: 6),
                  Text(totalValue, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  for (final d in details)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Text('${d.label}: ', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
                          Text(d.value, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
