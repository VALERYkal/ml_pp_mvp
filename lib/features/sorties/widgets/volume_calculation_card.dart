import 'package:flutter/material.dart';

/// Carte d'affichage des calculs de volume avec design moderne
class VolumeCalculationCard extends StatelessWidget {
  final double volumeAmbiant;
  final double volume15C;
  final double? temperature;
  final double? densite;

  const VolumeCalculationCard({
    super.key,
    required this.volumeAmbiant,
    required this.volume15C,
    this.temperature,
    this.densite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.1),
            colorScheme.secondaryContainer.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calculate,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Calculs automatiques',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _VolumeDisplayItem(
                  label: 'Volume ambiant',
                  value: '${volumeAmbiant.toStringAsFixed(2)} L',
                  icon: Icons.water_drop,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _VolumeDisplayItem(
                  label: 'Volume 15°C',
                  value: '${volume15C.toStringAsFixed(2)} L',
                  icon: Icons.thermostat,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          if (temperature != null || densite != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (temperature != null) ...[
                  Expanded(
                    child: _InfoItem(
                      label: 'Température',
                      value: '${temperature!.toStringAsFixed(1)}°C',
                      icon: Icons.thermostat_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (densite != null) ...[
                  Expanded(
                    child: _InfoItem(
                      label: 'Densité',
                      value: densite!.toStringAsFixed(3),
                      icon: Icons.scale,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VolumeDisplayItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _VolumeDisplayItem({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
