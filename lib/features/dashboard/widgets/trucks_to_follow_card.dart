import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';

/// Widget personnalisé pour afficher les camions à suivre
/// Design moderne avec animations fluides et interactions avancées
class TrucksToFollowCard extends StatefulWidget {
  final KpiTrucksToFollow data;
  final VoidCallback? onTap;

  const TrucksToFollowCard({super.key, required this.data, this.onTap});

  @override
  State<TrucksToFollowCard> createState() => _TrucksToFollowCardState();
}

class _TrucksToFollowCardState extends State<TrucksToFollowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
    const accentColor = Colors.blue;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _isHovered = true);
                _animationController.forward();
              },
              onExit: (_) {
                setState(() => _isHovered = false);
                _animationController.reverse();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isHovered
                        ? accentColor.withOpacity(0.15)
                        : accentColor.withOpacity(0.08),
                    width: _isHovered ? 2.0 : 1.5,
                  ),
                  boxShadow: [
                    // Ombre principale avec effet hover
                    BoxShadow(
                      color: accentColor.withOpacity(_isHovered ? 0.12 : 0.06),
                      blurRadius: _isHovered ? 32 : 24,
                      offset: Offset(0, _isHovered ? 16 : 12),
                      spreadRadius: 0,
                    ),
                    // Ombre de profondeur
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    // Ombre subtile pour la profondeur
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: widget.onTap ?? () => context.go('/cours'),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16), // Réduit de 18 à 16
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Header avec icône et titre amélioré avec animations
                        Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    accentColor.withOpacity(
                                      _isHovered ? 0.18 : 0.12,
                                    ),
                                    accentColor.withOpacity(
                                      _isHovered ? 0.12 : 0.08,
                                    ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: accentColor.withOpacity(
                                    _isHovered ? 0.2 : 0.1,
                                  ),
                                  width: _isHovered ? 1.5 : 1,
                                ),
                                boxShadow: _isHovered
                                    ? [
                                        BoxShadow(
                                          color: accentColor.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: AnimatedRotation(
                                turns: _isHovered ? 0.05 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.local_shipping_outlined,
                                  color: accentColor,
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style:
                                    theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: _isHovered
                                          ? accentColor.withOpacity(0.9)
                                          : theme.colorScheme.onSurface,
                                      letterSpacing: -0.2,
                                      height: 1.2,
                                    ) ??
                                    const TextStyle(),
                                child: const Text('Camions à suivre'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Réduit de 20 à 16
                        // Métriques principales avec animations
                        Row(
                          children: [
                            // Total camions avec animation
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    style:
                                        theme.textTheme.headlineLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: _isHovered
                                              ? accentColor.withOpacity(0.8)
                                              : accentColor,
                                          letterSpacing: -0.5,
                                          height: 1.0,
                                        ) ??
                                        const TextStyle(),
                                    child: Text('${widget.data.totalTrucks}'),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Camions total',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Volume total prévu avec animation
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    style:
                                        theme.textTheme.headlineLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: _isHovered
                                              ? theme.colorScheme.onSurface
                                                    .withOpacity(0.8)
                                              : theme.colorScheme.onSurface,
                                          letterSpacing: -0.5,
                                          height: 1.0,
                                        ) ??
                                        const TextStyle(),
                                    child: Text(
                                      _formatVolume(
                                        widget.data.totalPlannedVolume,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Volume total prévu',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Réduit de 20 à 16
                        // Détails avec animations et effets visuels (zone flexible/scrollable)
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            // padding externe conservé via SingleChildScrollView
                            decoration: BoxDecoration(
                              color: _isHovered
                                  ? theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(0.4)
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isHovered
                                    ? theme.colorScheme.outline.withOpacity(0.2)
                                    : theme.colorScheme.outline.withOpacity(
                                        0.1,
                                      ),
                                width: _isHovered ? 1.5 : 1,
                              ),
                              boxShadow: _isHovered
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.shadow
                                            .withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Ligne 1 : Au chargement
                                    _CamionStatRow(
                                      label: 'Au chargement',
                                      count: widget.data.trucksLoading,
                                      volumeLabel: _formatVolume(
                                        widget.data.volumeLoading,
                                      ),
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(height: 10),
                                    // Ligne 2 : En route
                                    _CamionStatRow(
                                      label: 'En route',
                                      count: widget.data.trucksOnRoute,
                                      volumeLabel: _formatVolume(
                                        widget.data.volumeOnRoute,
                                      ),
                                      color: accentColor,
                                    ),
                                    const SizedBox(height: 10),
                                    // Ligne 3 : Arrivés
                                    _CamionStatRow(
                                      label: 'Arrivés',
                                      count: widget.data.trucksArrived,
                                      volumeLabel: _formatVolume(
                                        widget.data.volumeArrived,
                                      ),
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Formatage des volumes avec séparateur de milliers - défensif
  String _formatVolume(double volume) {
    if (volume.isNaN || volume.isInfinite) return '0 L';

    final formatted = volume
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]} ',
        );

    return '$formatted L';
  }
}

/// Widget privé pour afficher une ligne de statistique (label + count + volume)
class _CamionStatRow extends StatelessWidget {
  final String label;
  final int count;
  final String volumeLabel;
  final Color color;

  const _CamionStatRow({
    required this.label,
    required this.count,
    required this.volumeLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // Pastille colorée pour rappeler le statut
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        // Contenu texte avec Flexible pour éviter overflow
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count ${count > 1 ? 'camions' : 'camion'} · $volumeLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
