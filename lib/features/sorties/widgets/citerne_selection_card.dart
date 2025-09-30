import 'package:flutter/material.dart';
import '../models/citerne_with_stock.dart';

/// Carte moderne pour la sélection de citerne avec stock
class CiterneSelectionCard extends StatelessWidget {
  final CiterneWithStockForSortie citerne;
  final bool selected;
  final VoidCallback? onTap;

  const CiterneSelectionCard({
    super.key,
    required this.citerne,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: selected 
              ? colorScheme.primaryContainer.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected 
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.2),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(selected ? 0.08 : 0.04),
              blurRadius: selected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec nom et statut
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selected 
                          ? colorScheme.primary.withOpacity(0.1)
                          : colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.storage,
                      size: 16,
                      color: selected 
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          citerne.nom,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: selected 
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                        if (citerne.capaciteTotale != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Capacité: ${citerne.capaciteTotale!.toStringAsFixed(0)} L',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Informations de stock
              if (citerne.stockAmbiant != null || citerne.stock15c != null) ...[
                Row(
                  children: [
                    if (citerne.stockAmbiant != null) ...[
                      Expanded(
                        child: _StockInfo(
                          label: 'Stock ambiant',
                          value: '${citerne.stockAmbiant!.toStringAsFixed(1)} L',
                          icon: Icons.water_drop,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (citerne.stock15c != null) ...[
                      Expanded(
                        child: _StockInfo(
                          label: 'Stock 15°C',
                          value: '${citerne.stock15c!.toStringAsFixed(1)} L',
                          icon: Icons.thermostat,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
                
                if (citerne.date != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Mis à jour le ${_formatDate(citerne.date!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Aucune information de stock disponible',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _StockInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StockInfo({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
