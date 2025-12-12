import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stocks_providers.dart';
import '../../dashboard/widgets/placeholders.dart';
import '../../../shared/formatters.dart';
import '../../profil/providers/profil_provider.dart';
import '../../stocks/widgets/stocks_kpi_cards.dart';
import '../../stocks/data/stocks_kpi_providers.dart';
import '../../stocks/domain/depot_stocks_snapshot.dart';
import '../../../data/repositories/stocks_kpi_repository.dart';

class StocksListScreen extends ConsumerStatefulWidget {
  const StocksListScreen({super.key});

  @override
  ConsumerState<StocksListScreen> createState() => _StocksListScreenState();
}

class _StocksListScreenState extends ConsumerState<StocksListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stocks = ref.watch(stocksListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildModernAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(stocksListProvider),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER — fixe (filters)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 1,
              ), // élimine toute ligne résiduelle
              child: _buildStickyFiltersFixed(context),
            ),
            const SizedBox(height: 8),

            // BODY — scrollable (content)
            Expanded(child: _buildContent(context, stocks, theme)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: theme.colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stocks Journaliers',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'Suivi des stocks par citerne',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => ref.invalidate(stocksListProvider),
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualiser',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStickyFilters(BuildContext context) {
    final theme = Theme.of(context);
    final date = ref.watch(stocksSelectedDateProvider);
    final produitsRef = ref.watch(stocksProduitsRefProvider);
    final citernesRef = ref.watch(stocksCiternesRefProvider);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _ModernStickyFilters(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Ligne principale des filtres
                Row(
                  children: [
                    // Sélecteur de date moderne
                    Flexible(
                      flex: 1,
                      child: _buildDateSelector(context, date, theme),
                    ),
                    const SizedBox(width: 16),

                    // Filtre produit
                    Expanded(
                      flex: 2,
                      child: _buildProduitFilter(context, produitsRef, theme),
                    ),
                    const SizedBox(width: 16),

                    // Filtre citerne
                    Expanded(
                      flex: 2,
                      child: _buildCiterneFilter(context, citernesRef, theme),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Version fixe pour la nouvelle structure
  Widget _buildStickyFiltersFixed(BuildContext context) {
    final theme = Theme.of(context);
    final date = ref.watch(stocksSelectedDateProvider);
    final produitsRef = ref.watch(stocksProduitsRefProvider);
    final citernesRef = ref.watch(stocksCiternesRefProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 44, // hauteur fixe → plus de débordement
            child: Material(
              color: Colors.transparent,
              child: DefaultTextStyle(
                style: theme.textTheme.bodyMedium!,
                child: Row(
                  children: [
                    // Sélecteur de date moderne
                    Flexible(
                      flex: 1,
                      child: _buildDateSelector(context, date, theme),
                    ),
                    const SizedBox(width: 16),

                    // Filtre produit
                    Expanded(
                      flex: 2,
                      child: _buildProduitFilter(context, produitsRef, theme),
                    ),
                    const SizedBox(width: 16),

                    // Filtre citerne
                    Expanded(
                      flex: 2,
                      child: _buildCiterneFilter(context, citernesRef, theme),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    BuildContext context,
    DateTime date,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: theme.copyWith(
                    colorScheme: theme.colorScheme.copyWith(
                      primary: theme.colorScheme.primary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              ref.read(stocksSelectedDateProvider.notifier).state = picked;
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _fmtDate(date),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProduitFilter(
    BuildContext context,
    AsyncValue produitsRef,
    ThemeData theme,
  ) {
    return produitsRef.when(
      data: (items) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Produit',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: ref.watch(stocksSelectedProduitIdProvider),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Row(
                children: [
                  Icon(
                    Icons.all_inclusive,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tous les produits',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            ...items.map(
              (e) => DropdownMenuItem<String>(
                value: e['id'],
                child: Row(
                  children: [
                    Icon(
                      Icons.local_gas_station,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(e['nom'] ?? ''),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (v) =>
              ref.read(stocksSelectedProduitIdProvider.notifier).state = v,
        ),
      ),
      loading: () => Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.error),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Erreur produits',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildCiterneFilter(
    BuildContext context,
    AsyncValue citernesRef,
    ThemeData theme,
  ) {
    return citernesRef.when(
      data: (items) {
        final selectedProduitId = ref.watch(stocksSelectedProduitIdProvider);
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Citerne',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            value: ref.watch(stocksSelectedCiterneIdProvider),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      Icons.storage,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Toutes les citernes',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ...items
                  .where(
                    (e) =>
                        selectedProduitId == null ||
                        (e['produit_id'] ?? '') == selectedProduitId,
                  )
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e['id'],
                      child: Row(
                        children: [
                          Icon(
                            Icons.storage,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(e['nom'] ?? ''),
                        ],
                      ),
                    ),
                  ),
            ],
            onChanged: (v) =>
                ref.read(stocksSelectedCiterneIdProvider.notifier).state = v,
          ),
        );
      },
      loading: () => Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.error),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Erreur citernes',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<StocksDataWithMeta> stocks,
    ThemeData theme,
  ) {
    return stocks.when(
      loading: () => _buildLoadingState(context, theme),
      error: (e, _) => _buildErrorState(context, e, theme),
      data: (data) => data.stocks.isEmpty
          ? _buildEmptyState(context, theme)
          : _buildDataTable(context, data, theme),
    );
  }

  Widget _buildLoadingState(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Chargement des stocks...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
        ),
        child: ErrorTile(
          'Erreur de chargement des stocks',
          onRetry: () => ref.invalidate(stocksListProvider),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Aucun stock trouvé',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucun stock n\'a été trouvé pour cette date et ces filtres.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackWarning(
    BuildContext context,
    StocksDataWithMeta data,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.tertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                children: [
                  const TextSpan(text: 'Aucun mouvement le '),
                  TextSpan(
                    text: _fmtDate(DateTime.parse(data.requestedDate)),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const TextSpan(text: '. Affichage des stocks du '),
                  TextSpan(
                    text: _fmtDate(DateTime.parse(data.actualDataDate)),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const TextSpan(text: ' (dernière date disponible).'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(
    BuildContext context,
    StocksDataWithMeta data,
    ThemeData theme,
  ) {
    // Obtenir le depotId depuis le profil pour afficher les KPI
    final profil = ref.watch(profilProvider).valueOrNull;
    final depotId = profil?.depotId;
    final selectedDate = ref.watch(stocksSelectedDateProvider);

    // Utiliser depotStocksSnapshotProvider pour les données agrégées (comme le dashboard)
    // data est conservé uniquement pour isFallback et actualDataDate (affichage du message)
    final snapshotAsync = depotId != null && depotId.isNotEmpty
        ? ref.watch(
            depotStocksSnapshotProvider(
              DepotStocksSnapshotParams(
                depotId: depotId,
                dateJour: selectedDate,
              ),
            ),
          )
        : null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section KPI "Vue d'ensemble" (si depotId disponible)
              if (depotId != null && depotId.isNotEmpty) ...[
                Text(
                  'Vue d\'ensemble',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                OwnerStockBreakdownCard(
                  depotId: depotId,
                  dateJour: selectedDate,
                ),
                const SizedBox(height: 24),
              ],

              // Tableau de stocks
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: snapshotAsync != null
                    ? snapshotAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stack) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Erreur de chargement: $error',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                        data: (snapshot) => Column(
                          children: [
                            // Avertissement fallback si nécessaire (basé sur data, pas snapshot)
                            if (data.isFallback)
                              _buildFallbackWarning(context, data, theme),

                            // Bandeau de stats (basé sur snapshot KPI)
                            _buildStatsHeaderFromSnapshot(
                              context,
                              snapshot,
                              theme,
                            ),

                            // Tableau scrollable horizontalement (basé sur snapshot KPI)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(0.5),
                                  ),
                                  headingTextStyle: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                  dataTextStyle:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  columns: [
                                    _buildDataColumn(
                                      'Citerne',
                                      Icons.storage,
                                      theme,
                                    ),
                                    _buildDataColumn(
                                      'Produit',
                                      Icons.local_gas_station,
                                      theme,
                                    ),
                                    _buildDataColumn(
                                      'Ambiant (L)',
                                      Icons.water_drop_outlined,
                                      theme,
                                    ),
                                    _buildDataColumn(
                                      '15°C (L)',
                                      Icons.thermostat,
                                      theme,
                                    ),
                                    _buildDataColumn(
                                      'Capacité (L)',
                                      Icons.straighten,
                                      theme,
                                    ),
                                    _buildDataColumn(
                                      'Sécurité (L)',
                                      Icons.warning_outlined,
                                      theme,
                                    ),
                                    _buildDataColumn(
                                      'Ratio',
                                      Icons.percent,
                                      theme,
                                    ),
                                    _buildDataColumn(
                                      'Alerte',
                                      Icons.notifications_active,
                                      theme,
                                    ),
                                  ],
                                  rows: [
                                    // Lignes de données (basées sur snapshot.citerneRows)
                                    ...snapshot.citerneRows
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final index = entry.key;
                                      final citerne = entry.value;
                                      return _buildDataRowFromSnapshot(
                                        citerne,
                                        index,
                                        theme,
                                      );
                                    }),
                                    // Ligne de total (basée sur snapshot.citerneRows)
                                    _buildTotalRowFromSnapshot(
                                      snapshot.citerneRows,
                                      theme,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Avertissement fallback si nécessaire
                          if (data.isFallback)
                            _buildFallbackWarning(context, data, theme),

                          // Bandeau de stats (fallback sur data.stocks si pas de depotId)
                          _buildStatsHeader(context, data.stocks, theme),

                          // Tableau scrollable horizontalement (fallback sur data.stocks)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  theme.colorScheme.surfaceContainerHighest
                                      .withOpacity(0.5),
                                ),
                                headingTextStyle: theme.textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                dataTextStyle:
                                    theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                                columns: [
                                  _buildDataColumn(
                                    'Citerne',
                                    Icons.storage,
                                    theme,
                                  ),
                                  _buildDataColumn(
                                    'Produit',
                                    Icons.local_gas_station,
                                    theme,
                                  ),
                                  _buildDataColumn(
                                    'Ambiant (L)',
                                    Icons.water_drop_outlined,
                                    theme,
                                  ),
                                  _buildDataColumn(
                                    '15°C (L)',
                                    Icons.thermostat,
                                    theme,
                                  ),
                                  _buildDataColumn(
                                    'Capacité (L)',
                                    Icons.straighten,
                                    theme,
                                  ),
                                  _buildDataColumn(
                                    'Sécurité (L)',
                                    Icons.warning_outlined,
                                    theme,
                                  ),
                                  _buildDataColumn(
                                    'Ratio',
                                    Icons.percent,
                                    theme,
                                  ),
                                  _buildDataColumn(
                                    'Alerte',
                                    Icons.notifications_active,
                                    theme,
                                  ),
                                ],
                                rows: [
                                  // Lignes de données
                                  ...data.stocks.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final s = entry.value;
                                    return _buildDataRow(s, index, theme);
                                  }),
                                  // Ligne de total
                                  _buildTotalRow(data.stocks, theme),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(String label, IconData icon, ThemeData theme) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(StockRowView s, int index, ThemeData theme) {
    final ratio = s.capaciteTotale > 0
        ? s.stockAmbiant / s.capaciteTotale
        : 0.0;
    final isLowStock = s.stockAmbiant <= s.capaciteSecurite;

    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);
        }
        return index.isEven
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.1)
            : null;
      }),
      cells: [
        DataCell(_buildCiterneCell(s.citerneNom, theme)),
        DataCell(_buildProduitCell(s.produitNom, theme)),
        DataCell(_buildVolumeCell(s.stockAmbiant, theme)),
        DataCell(_buildVolumeCell(s.stock15c, theme)),
        DataCell(_buildVolumeCell(s.capaciteTotale, theme)),
        DataCell(_buildVolumeCell(s.capaciteSecurite, theme)),
        DataCell(_buildRatioCell(ratio, theme)),
        DataCell(_buildAlertCell(isLowStock, theme)),
      ],
    );
  }

  Widget _buildCiterneCell(String nom, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storage, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            nom,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProduitCell(String nom, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_gas_station,
            size: 14,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            nom,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCell(double volume, ThemeData theme) {
    return Text(
      _formatVolume(volume),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        fontFeatures: [const FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _buildRatioCell(double ratio, ThemeData theme) {
    final percentage = (ratio * 100).clamp(0.0, 100.0);
    final color = percentage > 80
        ? theme.colorScheme.error
        : percentage > 60
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAlertCell(bool isLowStock, ThemeData theme) {
    if (!isLowStock) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning,
            size: 14,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Stock bas',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une ligne de données à partir d'un snapshot de citerne
  DataRow _buildDataRowFromSnapshot(
    CiterneGlobalStockSnapshot citerne,
    int index,
    ThemeData theme,
  ) {
    final ratio = citerne.capaciteTotale > 0
        ? citerne.stockAmbiantTotal / citerne.capaciteTotale
        : 0.0;
    final isLowStock =
        citerne.stockAmbiantTotal <= citerne.capaciteSecurite;

    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);
        }
        return index.isEven
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.1)
            : null;
      }),
      cells: [
        DataCell(_buildCiterneCell(citerne.citerneNom, theme)),
        DataCell(_buildProduitCell(citerne.produitNom, theme)),
        DataCell(_buildVolumeCell(citerne.stockAmbiantTotal, theme)),
        DataCell(_buildVolumeCell(citerne.stock15cTotal, theme)),
        DataCell(_buildVolumeCell(citerne.capaciteTotale, theme)),
        DataCell(_buildVolumeCell(citerne.capaciteSecurite, theme)),
        DataCell(_buildRatioCell(ratio, theme)),
        DataCell(_buildAlertCell(isLowStock, theme)),
      ],
    );
  }

  /// Construit la ligne de total à partir des snapshots de citernes
  DataRow _buildTotalRowFromSnapshot(
    List<CiterneGlobalStockSnapshot> citernes,
    ThemeData theme,
  ) {
    final totalAmbiant = citernes.fold<double>(
      0.0,
      (sum, c) => sum + c.stockAmbiantTotal,
    );
    final total15c = citernes.fold<double>(
      0.0,
      (sum, c) => sum + c.stock15cTotal,
    );

    return DataRow(
      color: WidgetStateProperty.all(
        theme.colorScheme.primaryContainer.withOpacity(0.2),
      ),
      cells: [
        DataCell(
          Text(
            'TOTAL',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(
          Text(
            _formatVolume(totalAmbiant),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),
        DataCell(
          Text(
            _formatVolume(total15c),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
      ],
    );
  }

  DataRow _buildTotalRow(List<StockRowView> items, ThemeData theme) {
    final totalAmbiant = _calculateTotal(items, (s) => s.stockAmbiant);
    final total15c = _calculateTotal(items, (s) => s.stock15c);

    return DataRow(
      color: WidgetStateProperty.all(
        theme.colorScheme.primaryContainer.withOpacity(0.2),
      ),
      cells: [
        DataCell(
          Text(
            'TOTAL',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        DataCell(
          Text(
            _formatVolume(totalAmbiant),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),
        DataCell(
          Text(
            _formatVolume(total15c),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
        const DataCell(SizedBox.shrink()),
      ],
    );
  }

  /// Construit le header de stats à partir du snapshot KPI (données agrégées)
  Widget _buildStatsHeaderFromSnapshot(
    BuildContext context,
    DepotStocksSnapshot snapshot,
    ThemeData theme,
  ) {
    // Calculer les totaux depuis snapshot.citerneRows
    final totalAmbiant = snapshot.citerneRows.fold<double>(
      0.0,
      (sum, c) => sum + c.stockAmbiantTotal,
    );
    final total15c = snapshot.citerneRows.fold<double>(
      0.0,
      (sum, c) => sum + c.stock15cTotal,
    );
    // Calculer le nombre de citernes sous seuil de sécurité
    final lowStockCount = snapshot.citerneRows
        .where((c) => c.stockAmbiantTotal <= c.capaciteSecurite)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Statistique 1: Total des stocks
          Expanded(
            child: _buildStatCard(
              'Stock Total',
              _formatVolume(totalAmbiant),
              Icons.inventory_2,
              theme.colorScheme.primary,
              theme,
            ),
          ),
          const SizedBox(width: 16),

          // Statistique 2: Stock 15°C
          Expanded(
            child: _buildStatCard(
              'Stock 15°C',
              _formatVolume(total15c),
              Icons.thermostat,
              theme.colorScheme.secondary,
              theme,
            ),
          ),
          const SizedBox(width: 16),

          // Statistique 3: Alertes
          Expanded(
            child: _buildStatCard(
              'Alertes',
              '$lowStockCount',
              Icons.warning,
              lowStockCount > 0
                  ? theme.colorScheme.error
                  : theme.colorScheme.tertiary,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(
    BuildContext context,
    List<StockRowView> items,
    ThemeData theme,
  ) {
    final totalAmbiant = _calculateTotal(items, (s) => s.stockAmbiant);
    final total15c = _calculateTotal(items, (s) => s.stock15c);
    final lowStockCount = items
        .where((s) => s.stockAmbiant <= s.capaciteSecurite)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Statistique 1: Total des stocks
          Expanded(
            child: _buildStatCard(
              'Stock Total',
              _formatVolume(totalAmbiant),
              Icons.inventory_2,
              theme.colorScheme.primary,
              theme,
            ),
          ),
          const SizedBox(width: 16),

          // Statistique 2: Stock 15°C
          Expanded(
            child: _buildStatCard(
              'Stock 15°C',
              _formatVolume(total15c),
              Icons.thermostat,
              theme.colorScheme.secondary,
              theme,
            ),
          ),
          const SizedBox(width: 16),

          // Statistique 3: Alertes
          Expanded(
            child: _buildStatCard(
              'Alertes',
              '$lowStockCount',
              Icons.warning,
              lowStockCount > 0
                  ? theme.colorScheme.error
                  : theme.colorScheme.tertiary,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _csvEsc(String s) => '"${s.replaceAll('"', '""')}"';

  String _toCsv(List<StockRowView> data) {
    final b = StringBuffer(
      'date,citerne,produit,stock_ambiant,stock_15c,cap_totale,cap_securite\n',
    );
    for (final r in data) {
      b.writeln(
        [
          r.dateJour,
          _csvEsc(r.citerneNom),
          _csvEsc(r.produitNom),
          r.stockAmbiant.toString(),
          r.stock15c.toString(),
          r.capaciteTotale.toString(),
          r.capaciteSecurite.toString(),
        ].join(','),
      );
    }
    return b.toString();
  }

  String _formatVolume(double volume) {
    if (volume.isNaN || volume.isInfinite) return '0 L';

    // Format français avec espaces pour les milliers
    final formatted = volume.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    // Ajouter des espaces pour les milliers (format français)
    String spacedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        spacedInteger += ' ';
      }
      spacedInteger += integerPart[i];
    }

    return '${spacedInteger}${decimalPart} L';
  }

  double _calculateTotal(
    List<StockRowView> items,
    double Function(StockRowView) selector,
  ) {
    return items.fold<double>(0.0, (sum, item) => sum + selector(item));
  }
}

/// Delegate moderne pour la barre de filtres collante
class _ModernStickyFilters extends SliverPersistentHeaderDelegate {
  final Widget child;

  _ModernStickyFilters({required this.child});

  @override
  double get minExtent => 80;

  @override
  double get maxExtent => 80;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
