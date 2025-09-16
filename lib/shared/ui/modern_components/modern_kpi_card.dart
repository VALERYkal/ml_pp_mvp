import 'package:flutter/material.dart';

/// Carte KPI moderne avec design Material 3 et animations
class ModernKpiCard extends StatefulWidget {
  final String title;
  final String primaryValue;
  final String? primaryLabel;
  final String? secondaryValue;
  final String? secondaryLabel;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback? onTap;
  final List<KpiMetric>? metrics;
  final KpiTrend? trend;

  const ModernKpiCard({
    super.key,
    required this.title,
    required this.primaryValue,
    required this.icon,
    this.primaryLabel,
    this.secondaryValue,
    this.secondaryLabel,
    this.accentColor,
    this.onTap,
    this.metrics,
    this.trend,
  });

  @override
  State<ModernKpiCard> createState() => _ModernKpiCardState();
}

class _ModernKpiCardState extends State<ModernKpiCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.accentColor ?? theme.colorScheme.primary;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildCard(context, theme, accentColor),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, ThemeData theme, Color accentColor) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _animationController.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _animationController.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _animationController.reverse() : null,
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(theme, accentColor),
              const SizedBox(height: 12),
              _buildContent(theme, accentColor),
              if (widget.metrics != null && widget.metrics!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildMetrics(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color accentColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.1),
                accentColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.icon,
            color: accentColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (widget.trend != null)
                _buildTrend(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrend(ThemeData theme) {
    final trend = widget.trend!;
    final isPositive = trend.value > 0;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final color = isPositive ? Colors.green : Colors.red;
    
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '${isPositive ? '+' : ''}${trend.value.toStringAsFixed(1)}%',
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, Color accentColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.primaryValue,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              if (widget.primaryLabel != null)
                Text(
                  widget.primaryLabel!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (widget.secondaryValue != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.secondaryValue!,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (widget.secondaryLabel != null)
                Text(
                  widget.secondaryLabel!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildMetrics(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: widget.metrics!.map((metric) => _buildMetricRow(theme, metric)).toList(),
      ),
    );
  }

  Widget _buildMetricRow(ThemeData theme, KpiMetric metric) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            metric.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            metric.value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Classe pour représenter une métrique KPI
class KpiMetric {
  final String label;
  final String value;

  const KpiMetric({
    required this.label,
    required this.value,
  });
}

/// Classe pour représenter une tendance
class KpiTrend {
  final double value;
  final String? description;

  const KpiTrend({
    required this.value,
    this.description,
  });
}
