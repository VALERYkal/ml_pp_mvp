import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/shared/utils/date_formatter.dart';
import 'package:ml_pp_mvp/shared/utils/volume_formatter.dart';

/// Widget moderne pour afficher un élément de sortie dans la liste
class SortieListItem extends StatelessWidget {
  final Map<String, dynamic> sortie;
  final VoidCallback? onTap;

  const SortieListItem({super.key, required this.sortie, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final date = DateFormatter.formatDate(
      sortie['date_sortie'] ?? sortie['created_at'],
    );
    final prop = (sortie['proprietaire_type'] ?? 'MONALUXE').toString();
    final prod =
        '${sortie['produit_code'] ?? ''} ${sortie['produit_nom'] ?? ''}'.trim();
    final cit = (sortie['citerne_nom'] ?? '').toString();
    final v15 = VolumeFormatter.formatVolume(sortie['volume_corrige_15c']);
    final vAmb = VolumeFormatter.formatVolume(sortie['volume_ambiant']);
    final benef = sortie['client_nom'] ?? sortie['partenaire_nom'] ?? '';

    final isMonaluxe = prop == 'MONALUXE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec date et propriété
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isMonaluxe
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isMonaluxe
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : colorScheme.secondary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMonaluxe ? Icons.business : Icons.handshake,
                            size: 12,
                            color: isMonaluxe
                                ? colorScheme.primary
                                : colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            prop,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isMonaluxe
                                  ? colorScheme.primary
                                  : colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Informations principales
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Citerne: $cit',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _VolumeDisplay(
                            label: '15°C',
                            value: v15,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 4),
                          _VolumeDisplay(
                            label: 'Ambiant',
                            value: vAmb,
                            color: colorScheme.secondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (benef.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            benef,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VolumeDisplay extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _VolumeDisplay({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

