import 'package:flutter/material.dart';

/// Grille moderne pour organiser les cartes KPI
class DashboardGrid extends StatelessWidget {
  final List<Widget> children;
  final int? crossAxisCount;
  final double childAspectRatio;
  final double spacing;
  final double runSpacing;

  const DashboardGrid({
    super.key,
    required this.children,
    this.crossAxisCount,
    this.childAspectRatio = 1.2,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculer le nombre de colonnes en fonction de la largeur d'écran
    int columns = crossAxisCount ?? _calculateColumns(screenWidth);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  int _calculateColumns(double screenWidth) {
    if (screenWidth >= 1200) return 3;
    if (screenWidth >= 800) return 2;
    return 1;
  }
}

/// Widget pour créer des sections avec titre
class DashboardSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  const DashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: padding ?? const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
