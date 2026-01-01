import 'package:flutter/material.dart';
import 'dashboard_grid.dart';

/// Carte KPI moderne avec design Material 3 et animations professionnelles
/// Design amélioré pour une meilleure lisibilité et professionnalisme
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
  final bool isMultiLine;
  final bool showGradient;
  final bool enableHoverEffects;
  final double? elevation;

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
    this.isMultiLine = false,
    this.showGradient = true,
    this.enableHoverEffects = true,
    this.elevation,
  });

  @override
  State<ModernKpiCard> createState() => _ModernKpiCardState();
}

class _ModernKpiCardState extends State<ModernKpiCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _elevationAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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
    final accentColor =
        widget.accentColor ?? KpiColorPalette.getAccentColor(widget.title);

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
    return MouseRegion(
      onEnter: widget.enableHoverEffects
          ? (_) {
              setState(() => _isHovered = true);
              _animationController.forward();
            }
          : null,
      onExit: widget.enableHoverEffects
          ? (_) {
              setState(() => _isHovered = false);
              _animationController.reverse();
            }
          : null,
      child: GestureDetector(
        onTapDown: widget.onTap != null
            ? (_) => _animationController.forward()
            : null,
        onTapUp: widget.onTap != null
            ? (_) => _animationController.reverse()
            : null,
        onTapCancel: widget.onTap != null
            ? () => _animationController.reverse()
            : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            gradient: widget.showGradient
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                    ],
                  )
                : null,
            color: widget.showGradient ? null : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _isHovered
                  ? accentColor.withValues(alpha: 0.2)
                  : accentColor.withValues(alpha: 0.1),
              width: _isHovered ? 2.5 : 1.5,
            ),
            boxShadow: [
              // Ombre principale avec effet hover
              BoxShadow(
                color: accentColor.withValues(alpha: _isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 40 : 28,
                offset: Offset(0, _isHovered ? 20 : 14),
                spreadRadius: 0,
              ),
              // Ombre de profondeur
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
              // Ombre subtile pour la profondeur
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(theme, accentColor),
                const SizedBox(height: 20),
                _buildContent(theme, accentColor),
                if (widget.metrics != null && widget.metrics!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildMetrics(theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color accentColor) {
    return Row(
      children: [
        // Icône avec design amélioré et animations
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: _isHovered ? 0.2 : 0.15),
                accentColor.withValues(alpha: _isHovered ? 0.15 : 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(alpha: _isHovered ? 0.25 : 0.15),
              width: _isHovered ? 2.0 : 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: AnimatedRotation(
            turns: _isHovered ? 0.08 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Icon(widget.icon, color: accentColor, size: 28),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre avec style amélioré et animation
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style:
                    theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _isHovered
                          ? accentColor.withValues(alpha: 0.9)
                          : theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ) ??
                    const TextStyle(),
                child: Text(widget.title),
              ),
              if (widget.trend != null) ...[
                const SizedBox(height: 6),
                _buildTrend(theme),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrend(ThemeData theme) {
    final trend = widget.trend!;
    final isPositive = trend.value > 0;
    final icon = isPositive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final color = isPositive ? KpiColorPalette.success : KpiColorPalette.danger;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isHovered ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: _isHovered ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedRotation(
            turns: _isHovered ? 0.1 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${trend.value.toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, Color accentColor) {
    if (widget.isMultiLine && widget.secondaryValue != null) {
      // Affichage multi-lignes pour une meilleure lisibilité
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Valeur principale avec label
          _buildPrimarySection(theme, accentColor),
          const SizedBox(height: 16),
          // Valeur secondaire avec label
          _buildSecondarySection(theme),
        ],
      );
    } else {
      // Affichage traditionnel sur une ligne
      return Row(
        children: [
          Expanded(child: _buildPrimarySection(theme, accentColor)),
          if (widget.secondaryValue != null) ...[
            const SizedBox(width: 16),
            _buildSecondarySection(theme),
          ],
        ],
      );
    }
  }

  Widget _buildPrimarySection(ThemeData theme, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Valeur principale avec style amélioré et animation
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style:
              theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: _isHovered ? accentColor.withValues(alpha: 0.9) : accentColor,
                letterSpacing: -0.8,
                height: 1.0,
                fontSize: 32,
              ) ??
              const TextStyle(),
          child: Text(widget.primaryValue),
        ),
        const SizedBox(height: 8),
        // Label principal avec style amélioré
        if (widget.primaryLabel != null)
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style:
                theme.textTheme.bodyLarge?.copyWith(
                  color: _isHovered
                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9)
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  fontSize: 16,
                ) ??
                const TextStyle(),
            child: Text(widget.primaryLabel!),
          ),
      ],
    );
  }

  Widget _buildSecondarySection(ThemeData theme) {
    if (widget.secondaryValue == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: widget.isMultiLine
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        // Valeur secondaire avec style amélioré et animation
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style:
              theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: _isHovered
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.9)
                    : theme.colorScheme.onSurface,
                letterSpacing: -0.3,
                height: 1.1,
                fontSize: 20,
              ) ??
              const TextStyle(),
          child: Text(widget.secondaryValue!),
        ),
        const SizedBox(height: 6),
        // Label secondaire avec style amélioré
        if (widget.secondaryLabel != null)
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style:
                theme.textTheme.bodyMedium?.copyWith(
                  color: _isHovered
                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  fontSize: 14,
                ) ??
                const TextStyle(),
            child: Text(widget.secondaryLabel!),
          ),
      ],
    );
  }

  Widget _buildMetrics(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: widget.metrics!
            .map((metric) => _buildMetricRow(theme, metric))
            .toList(),
      ),
    );
  }

  Widget _buildMetricRow(ThemeData theme, KpiMetric metric) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              metric.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            metric.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              fontSize: 14,
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

  const KpiMetric({required this.label, required this.value});
}

/// Classe pour représenter une tendance
class KpiTrend {
  final double value;
  final String? description;

  const KpiTrend({required this.value, this.description});
}
