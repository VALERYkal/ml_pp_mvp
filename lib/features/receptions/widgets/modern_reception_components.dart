/* ===========================================================
   ML_PP MVP  Modern Reception Components
   Rôle: Composants modernes pour le formulaire de réception
   avec design Material 3 et animations fluides
   =========================================================== */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget moderne pour la sélection de produit avec animations
class ModernProductSelector extends StatefulWidget {
  final String? selectedProductId;
  final Function(String?) onProductSelected;
  final List<Map<String, dynamic>> products;
  final bool isLoading;

  const ModernProductSelector({
    super.key,
    required this.selectedProductId,
    required this.onProductSelected,
    required this.products,
    this.isLoading = false,
  });

  @override
  State<ModernProductSelector> createState() => _ModernProductSelectorState();
}

class _ModernProductSelectorState extends State<ModernProductSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    final selectedProduct = widget.products.firstWhere(
      (p) => p['id'] == widget.selectedProductId,
      orElse: () => {},
    );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                      if (_isExpanded) {
                        _animationController.forward();
                      } else {
                        _animationController.reverse();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.local_gas_station_rounded,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedProduct.isNotEmpty
                                      ? selectedProduct['libelle'] ??
                                            'Produit sélectionné'
                                      : 'Sélectionner un produit',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                if (selectedProduct.isNotEmpty)
                                  Text(
                                    selectedProduct['code'] ?? '',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isExpanded) ...[
                    const Divider(height: 1),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: widget.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: widget.products.length,
                              itemBuilder: (context, index) {
                                final product = widget.products[index];
                                final isSelected =
                                    product['id'] == widget.selectedProductId;

                                return InkWell(
                                  onTap: () {
                                    widget.onProductSelected(product['id']);
                                    setState(() {
                                      _isExpanded = false;
                                    });
                                    _animationController.reverse();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primaryContainer
                                                .withValues(alpha: 0.3)
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.outline
                                                      .withValues(alpha: 0.3),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product['libelle'] ?? '',
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight: isSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                              ),
                                              Text(
                                                product['code'] ?? '',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: theme.colorScheme.primary,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget moderne pour la sélection de citerne avec état de stock
class ModernTankSelector extends StatefulWidget {
  final String? selectedTankId;
  final Function(String?) onTankSelected;
  final List<Map<String, dynamic>> tanks;
  final bool isLoading;

  const ModernTankSelector({
    super.key,
    required this.selectedTankId,
    required this.onTankSelected,
    required this.tanks,
    this.isLoading = false,
  });

  @override
  State<ModernTankSelector> createState() => _ModernTankSelectorState();
}

class _ModernTankSelectorState extends State<ModernTankSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    final selectedTank = widget.tanks.firstWhere(
      (t) => t['id'] == widget.selectedTankId,
      orElse: () => {},
    );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                      if (_isExpanded) {
                        _animationController.forward();
                      } else {
                        _animationController.reverse();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.storage_rounded,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedTank.isNotEmpty
                                      ? selectedTank['libelle'] ??
                                            'Citerne sélectionnée'
                                      : 'Sélectionner une citerne',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                if (selectedTank.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _buildStockIndicator(
                                        theme,
                                        selectedTank['stock_15c'] ?? 0.0,
                                        selectedTank['capacity'] ?? 1.0,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${((selectedTank['stock_15c'] ?? 0.0) / (selectedTank['capacity'] ?? 1.0) * 100).toStringAsFixed(0)}%',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isExpanded) ...[
                    const Divider(height: 1),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: widget.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: widget.tanks.length,
                              itemBuilder: (context, index) {
                                final tank = widget.tanks[index];
                                final isSelected =
                                    tank['id'] == widget.selectedTankId;
                                final stockRatio =
                                    (tank['stock_15c'] ?? 0.0) /
                                    (tank['capacity'] ?? 1.0);

                                return InkWell(
                                  onTap: () {
                                    widget.onTankSelected(tank['id']);
                                    setState(() {
                                      _isExpanded = false;
                                    });
                                    _animationController.reverse();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primaryContainer
                                                .withValues(alpha: 0.3)
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.outline
                                                      .withValues(alpha: 0.3),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tank['libelle'] ?? '',
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight: isSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  _buildStockIndicator(
                                                    theme,
                                                    tank['stock_15c'] ?? 0.0,
                                                    tank['capacity'] ?? 1.0,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${(stockRatio * 100).toStringAsFixed(0)}%  ${tank['capacity']?.toStringAsFixed(0) ?? 0} L',
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: theme.colorScheme.primary,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockIndicator(ThemeData theme, double stock, double capacity) {
    final ratio = capacity > 0 ? stock / capacity : 0.0;
    Color color;

    if (ratio < 0.2) {
      color = Colors.red;
    } else if (ratio < 0.5) {
      color = Colors.orange;
    } else if (ratio < 0.8) {
      color = Colors.yellow.shade700;
    } else {
      color = Colors.green;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
    );
  }
}

/// Widget moderne pour l'affichage des calculs de volume
class ModernVolumeCalculator extends StatefulWidget {
  final double indexAvant;
  final double indexApres;
  final double temperature;
  final double densite;
  final bool isVisible;

  const ModernVolumeCalculator({
    super.key,
    required this.indexAvant,
    required this.indexApres,
    required this.temperature,
    required this.densite,
    this.isVisible = true,
  });

  @override
  State<ModernVolumeCalculator> createState() => _ModernVolumeCalculatorState();
}

class _ModernVolumeCalculatorState extends State<ModernVolumeCalculator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ModernVolumeCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _animationController.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    // Calculs de volume
    final volumeBrut = widget.indexApres - widget.indexAvant;
    final volumeAmbiant = volumeBrut; // Approximation MVP
    final volume15c = volumeAmbiant * 0.98; // Approximation MVP

    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calculate_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Calculs automatiques',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildVolumeCard(
                          theme,
                          'Volume brut',
                          '${volumeBrut.toStringAsFixed(0)} L',
                          Icons.water_drop_rounded,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildVolumeCard(
                          theme,
                          'Volume 15°C',
                          '${volume15c.toStringAsFixed(0)} L',
                          Icons.thermostat_rounded,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVolumeCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget moderne pour les messages de validation
class ModernValidationMessage extends StatefulWidget {
  final String message;
  final ValidationType type;
  final bool isVisible;
  final VoidCallback? onDismiss;

  const ModernValidationMessage({
    super.key,
    required this.message,
    required this.type,
    this.isVisible = true,
    this.onDismiss,
  });

  @override
  State<ModernValidationMessage> createState() =>
      _ModernValidationMessageState();
}

class _ModernValidationMessageState extends State<ModernValidationMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ModernValidationMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _animationController.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final (color, icon) = _getValidationStyle(theme);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, Widget? child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(_slideAnimation),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.onDismiss != null)
                    IconButton(
                      onPressed: widget.onDismiss,
                      icon: Icon(Icons.close_rounded, color: color, size: 18),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  (Color, IconData) _getValidationStyle(ThemeData theme) {
    switch (widget.type) {
      case ValidationType.success:
        return (Colors.green, Icons.check_circle_rounded);
      case ValidationType.warning:
        return (Colors.orange, Icons.warning_rounded);
      case ValidationType.error:
        return (theme.colorScheme.error, Icons.error_rounded);
      case ValidationType.info:
        return (theme.colorScheme.primary, Icons.info_rounded);
    }
  }
}

enum ValidationType { success, warning, error, info }

