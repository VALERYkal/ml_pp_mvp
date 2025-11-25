/* ===========================================================
   ML_PP MVP  Modern Reception List Screen
   Rôle: Écran moderne pour lister les réceptions avec design Material 3,
   filtres avancés, recherche et animations fluides
   =========================================================== */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ModernReceptionListScreen extends ConsumerStatefulWidget {
  const ModernReceptionListScreen({super.key});

  @override
  ConsumerState<ModernReceptionListScreen> createState() =>
      _ModernReceptionListScreenState();
}

class _ModernReceptionListScreenState
    extends ConsumerState<ModernReceptionListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (BuildContext context, Widget? child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildAppBar(theme),
                  _buildSearchAndFilters(theme),
                  Expanded(child: _buildReceptionsList(theme)),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Réceptions',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Implémenter l'export
          },
          icon: Icon(
            Icons.download_rounded,
            color: theme.colorScheme.onSurface,
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: Implémenter les paramètres
          },
          icon: Icon(
            Icons.settings_rounded,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSearchBar(theme),
          const SizedBox(height: 12),
          _buildFilters(theme),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Rechercher une réception...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: Icon(
                    Icons.clear_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildFilterChip(theme, 'Toutes', 'all', Icons.list_rounded),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterChip(
            theme,
            'Monaluxe',
            'monaluxe',
            Icons.business_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterChip(
            theme,
            'Partenaires',
            'partenaires',
            Icons.handshake_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterChip(
            theme,
            'Aujourd\'hui',
            'today',
            Icons.today_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceptionsList(ThemeData theme) {
    // TODO: Remplacer par les vraies données
    final receptions = _getMockReceptions();

    if (receptions.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: receptions.length,
      itemBuilder: (context, index) {
        return _buildReceptionCard(theme, receptions[index], index);
      },
    );
  }

  Widget _buildReceptionCard(
    ThemeData theme,
    Map<String, dynamic> reception,
    int index,
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            // TODO: Naviguer vers les détails
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReceptionHeader(theme, reception),
                const SizedBox(height: 12),
                _buildReceptionDetails(theme, reception),
                const SizedBox(height: 12),
                _buildReceptionFooter(theme, reception),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceptionHeader(
    ThemeData theme,
    Map<String, dynamic> reception,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(reception['status']).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(reception['status']),
            color: _getStatusColor(reception['status']),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reception['id'] ?? 'Réception #${reception['id']}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                reception['date'] ?? 'Date inconnue',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(theme, reception['status']),
      ],
    );
  }

  Widget _buildReceptionDetails(
    ThemeData theme,
    Map<String, dynamic> reception,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            theme,
            'Produit',
            reception['produit'] ?? 'ESS',
            Icons.local_gas_station_rounded,
            Colors.blue,
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            theme,
            'Volume',
            '${reception['volume'] ?? 0} L',
            Icons.water_drop_rounded,
            Colors.green,
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            theme,
            'Citerne',
            reception['citerne'] ?? 'Citerne A',
            Icons.storage_rounded,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildReceptionFooter(
    ThemeData theme,
    Map<String, dynamic> reception,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            reception['owner'] == 'MONALUXE' ? 'Monaluxe' : 'Partenaire',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          reception['time'] ?? '12:30',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    final (color, label) = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune réception trouvée',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par créer votre première réception',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/receptions/new');
            },
            icon: Icon(Icons.add_rounded),
            label: Text('Nouvelle réception'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: () {
        context.go('/receptions/new');
      },
      icon: Icon(Icons.add_rounded),
      label: Text('Nouvelle réception'),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 4,
    );
  }

  // Méthodes utilitaires
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'validee':
        return Colors.green;
      case 'brouillon':
        return Colors.orange;
      case 'erreur':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'validee':
        return Icons.check_circle_rounded;
      case 'brouillon':
        return Icons.edit_rounded;
      case 'erreur':
        return Icons.error_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  (Color, String) _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'validee':
        return (Colors.green, 'Validée');
      case 'brouillon':
        return (Colors.orange, 'Brouillon');
      case 'erreur':
        return (Colors.red, 'Erreur');
      default:
        return (Colors.grey, 'Inconnu');
    }
  }

  List<Map<String, dynamic>> _getMockReceptions() {
    return [
      {
        'id': 'REC-001',
        'date': '17/09/2025',
        'time': '14:30',
        'status': 'validee',
        'produit': 'ESS',
        'volume': 15000,
        'citerne': 'Citerne A',
        'owner': 'MONALUXE',
      },
      {
        'id': 'REC-002',
        'date': '17/09/2025',
        'time': '12:15',
        'status': 'validee',
        'produit': 'AGO',
        'volume': 12000,
        'citerne': 'Citerne B',
        'owner': 'PARTENAIRE',
      },
      {
        'id': 'REC-003',
        'date': '16/09/2025',
        'time': '16:45',
        'status': 'brouillon',
        'produit': 'ESS',
        'volume': 8000,
        'citerne': 'Citerne C',
        'owner': 'MONALUXE',
      },
    ];
  }
}

