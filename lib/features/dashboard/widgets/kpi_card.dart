import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/shared/utils/volume_formatter.dart';

/// Widget pour afficher une carte KPI moderne
class KpiCard extends StatelessWidget {
  final String title;
  final num value;
  final IconData icon;
  final String? subtitle; // ex: "aujourd'hui", "this week"
  final Color? color;
  final String? unit; // ex: "L", "L @15°C", etc
  final bool warning;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.color,
    this.unit,
    this.warning = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = warning 
        ? theme.colorScheme.error 
        : color ?? theme.colorScheme.primary;
    final formatted = unit == null
        ? VolumeFormatter.formatVolumeCompact(value) // 12 345 → 12.3k
        : '${VolumeFormatter.formatVolumeCompact(value)} $unit';

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                foreground.withOpacity(.08),
                foreground.withOpacity(.02),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: foreground.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: foreground, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatted,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
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

/// Widget pour afficher une carte KPI avec volume
class VolumeKpiCard extends StatelessWidget {
  final String title;
  final double volume;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final bool warning;

  const VolumeKpiCard({
    super.key,
    required this.title,
    required this.volume,
    this.subtitle,
    this.icon,
    this.color,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: title,
      value: volume, // le widget attend un num, pas un String
      subtitle: subtitle,
      icon: icon ?? Icons.info_outline,
      color: color,
      warning: warning,
    );
  }
}

/// Widget pour afficher une carte KPI avec pourcentage
class PercentageKpiCard extends StatelessWidget {
  final String title;
  final double percentage;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final bool warning;

  const PercentageKpiCard({
    super.key,
    required this.title,
    required this.percentage,
    this.subtitle,
    this.icon,
    this.color,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: title,
      value: (percentage * 100), // num attendu
      subtitle: subtitle,
      icon: icon ?? Icons.info_outline,
      color: color,
      warning: warning,
    );
  }
}
