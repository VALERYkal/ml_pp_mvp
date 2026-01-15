import 'package:flutter/material.dart';

/// Grille moderne pour organiser les cartes KPI avec design professionnel
///
/// **Breakpoints MVP Responsive** :
/// - Mobile (< 600px) : 1 colonne → 1 carte par ligne
/// - Tablet (600-1199px) : 2 colonnes
/// - Desktop (1200-1599px) : 3 colonnes
/// - Large Desktop (>= 1600px) : 4 colonnes
///
/// Aspect ratios ajustés par taille pour éviter overflow
class DashboardGrid extends StatelessWidget {
  final List<Widget> children;
  final int? crossAxisCount;
  final double childAspectRatio;
  final double spacing;
  final double runSpacing;
  final bool enableStaggeredAnimation;

  const DashboardGrid({
    super.key,
    required this.children,
    this.crossAxisCount,
    this.childAspectRatio = 0.85, // Réduit pour plus de hauteur
    this.spacing = 20.0,
    this.runSpacing = 20.0,
    this.enableStaggeredAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // Calculer le nombre de colonnes en fonction de la largeur disponible
        final int columns = crossAxisCount ?? _calculateColumns(maxWidth);

        // Ajuster l'aspect ratio selon la largeur et le nombre de colonnes
        final double aspectRatio = _calculateAspectRatio(maxWidth, columns);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) {
            if (enableStaggeredAnimation) {
              return _buildAnimatedCard(children[index], index);
            }
            return children[index];
          },
        );
      },
    );
  }

  Widget _buildAnimatedCard(Widget child, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  int _calculateColumns(double maxWidth) {
    // Breakpoints MVP responsive
    if (maxWidth >= 1600) return 4; // Très large écran (4K+)
    if (maxWidth >= 1200) return 3; // Desktop large
    if (maxWidth >= 600) return 2;  // Tablet/Desktop (600-1199px)
    return 1; // Mobile (< 600px) - MVP: 1 carte par ligne
  }

  double _calculateAspectRatio(double maxWidth, int columns) {
    // Aspect ratio plus petit = carte plus haute (meilleur pour contenu vertical)
    // MVP: Ajusté pour éviter overflow sur mobile (< 600px)

    if (columns == 1) {
      // Mobile (< 600px) : cartes en colonne unique
      // Aspect ratio généreux pour éviter overflow vertical
      if (maxWidth < 360) return 0.75; // Très petit mobile (Galaxy Fold, etc.)
      if (maxWidth < 400) return 0.85; // Petit mobile
      if (maxWidth < 500) return 0.95; // Mobile standard
      return 1.0; // Mobile large (< 600px mais proche de tablet)
    }
    if (columns == 2) {
      // Tablet (600-1199px) : 2 colonnes
      if (maxWidth < 800) return 0.85;  // Tablet portrait
      if (maxWidth < 1000) return 0.90; // Tablet paysage
      return 1.0; // Desktop étroit
    }
    if (columns == 3) return 1.1; // Desktop large (1200-1599px)
    return 1.2; // Très large écran (>= 1600px) : plus compact
  }
}

/// Widget pour créer des sections avec titre moderne
class DashboardSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  final EdgeInsetsGeometry? padding;
  final Color? accentColor;

  const DashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
    this.padding,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;

    return Container(
      margin: padding ?? const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, accent),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          // Indicateur visuel avec couleur d'accent
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 16), action!],
        ],
      ),
    );
  }
}

/// Palette de couleurs professionnelle pour les KPIs
class KpiColorPalette {
  // Couleurs principales avec variations
  static const Color primary = Color(0xFF2563EB); // Bleu professionnel
  static const Color success = Color(0xFF059669); // Vert succès
  static const Color warning = Color(0xFFD97706); // Orange attention
  static const Color danger = Color(0xFFDC2626); // Rouge danger
  static const Color info = Color(0xFF0891B2); // Cyan info
  static const Color purple = Color(0xFF7C3AED); // Violet premium

  // Couleurs secondaires
  static const Color teal = Color(0xFF0D9488); // Teal élégant
  static const Color indigo = Color(0xFF4F46E5); // Indigo moderne
  static const Color emerald = Color(0xFF10B981); // Emerald frais
  static const Color rose = Color(0xFFE11D48); // Rose moderne

  // Couleurs neutres
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  /// Retourne une couleur d'accent basée sur le type de KPI
  static Color getAccentColor(String kpiType) {
    switch (kpiType.toLowerCase()) {
      case 'receptions':
      case 'reception':
        return success;
      case 'sorties':
      case 'sortie':
        return danger;
      case 'stock':
      case 'stocks':
        return warning;
      case 'balance':
        return teal;
      case 'tendance':
      case 'trend':
        return purple;
      case 'camions':
      case 'trucks':
        return primary;
      default:
        return primary;
    }
  }

  /// Retourne une couleur avec opacité pour les arrière-plans
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}
