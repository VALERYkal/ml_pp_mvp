import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/citerne_providers.dart';
import '../../../shared/ui/typography.dart';
import '../../../shared/formatters.dart';
import '../../stocks/domain/depot_stocks_snapshot.dart';
import '../../../data/repositories/stocks_kpi_repository.dart';

// Fonctions de formatage modernisées avec chiffres tabulaires
final _n0 = NumberFormat.decimalPattern();
final _n1 = NumberFormat.decimalPattern()..minimumFractionDigits = 1..maximumFractionDigits = 1;

String _fmtL(double? v, {int fixed = 1}) {
  final x = (v == null || v.isNaN || v.isInfinite) ? 0.0 : v;
  return '${(fixed == 0 ? _n0.format(x) : _n1.format(x))} L';
}

String _formatVolume(double? volume) {
  if (volume == null || volume.isNaN || volume.isInfinite) return '0 L';
  
  // Format français avec espaces pour les milliers
  final formatted = volume.toStringAsFixed(1);
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
  
  return '$spacedInteger$decimalPart L';
}

String _formatDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat('dd/MM/yyyy').format(date);
}

String _formatPercentage(double ratio) {
  return '${(ratio * 100).toStringAsFixed(1)}%';
}

// Couleurs modernes pour les niveaux de remplissage
class _TankColors {
  static const Color empty = Color(0xFF94A3B8);      // Gris slate
  static const Color low = Color(0xFF10B981);        // Vert emerald
  static const Color medium = Color(0xFF3B82F6);     // Bleu
  static const Color high = Color(0xFFF59E0B);       // Orange amber
  static const Color critical = Color(0xFFEF4444);   // Rouge
  
  static Color getColorForLevel(double pct) {
    if (pct <= 0) return empty;
    if (pct < 25) return low;
    if (pct < 70) return medium;
    if (pct < 90) return high;
    return critical;
  }
  
  static Color getBackgroundTint(double pct) {
    return getColorForLevel(pct).withOpacity(0.04);
  }
}

class CiterneListScreen extends ConsumerWidget {
  const CiterneListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(citerneStocksSnapshotProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fond légèrement bleuté
      appBar: _buildModernAppBar(context, ref),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(citerneStocksSnapshotProvider),
        color: theme.colorScheme.primary,
        child: snapshotAsync.when(
          loading: () => _buildLoadingState(context, theme),
          error: (error, stack) => _buildErrorState(context, error, theme, ref),
          data: (snapshot) => snapshot.citerneRows.isEmpty
              ? _buildEmptyState(context, theme)
              : _buildCiterneGridFromSnapshot(context, snapshot, theme),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => ref.invalidate(citerneStocksSnapshotProvider),
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.refresh_rounded,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      foregroundColor: theme.colorScheme.onSurface,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.storage_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Citernes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Gestion des réservoirs',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => ref.invalidate(citerneStocksSnapshotProvider),
          icon: const Icon(
            Icons.refresh_rounded,
            color: Color(0xFF64748B),
          ),
          tooltip: 'Actualiser',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chargement des citernes...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, ThemeData theme, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Erreur de chargement',
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger les données des citernes',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(citerneStocksSnapshotProvider),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.storage_outlined,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune citerne active',
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune citerne n\'est actuellement configurée ou active',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCiterneGrid(BuildContext context, List<CiterneRow> citernes, ThemeData theme) {
    // Calculer les statistiques
    final totalCiternes = citernes.length;
    final alertesCiternes = citernes.where((c) => c.belowSecurity).length;
    final capaciteTotale = citernes.fold<double>(0, (sum, c) => sum + (c.capaciteTotale ?? 0));
    // RÈGLE MÉTIER : Stock ambiant = source de vérité opérationnelle
    final stockTotalAmbiant = citernes.fold<double>(0, (sum, c) => sum + (c.stockAmbiant ?? 0));
    final stockTotal15c = citernes.fold<double>(0, (sum, c) => sum + (c.stock15c ?? 0));

    return CustomScrollView(
      slivers: [
        // En-tête avec statistiques
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cartes de statistiques modernisées
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildStatCard(
                      context,
                      'Total Citernes',
                      totalCiternes.toString(),
                      Icons.storage_rounded,
                      const Color(0xFF3B82F6),
                      theme,
                    ),
                    _buildStatCard(
                      context,
                      'Alertes',
                      alertesCiternes.toString(),
                      Icons.warning_amber_rounded,
                      alertesCiternes > 0 ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                      theme,
                    ),
                    _buildStatCard(
                      context,
                      'Capacité Totale',
                      _formatVolume(capaciteTotale),
                      Icons.straighten_rounded,
                      const Color(0xFF8B5CF6),
                      theme,
                    ),
                    // RÈGLE MÉTIER : Stock ambiant = source de vérité opérationnelle
                    _buildStockTotalCard(
                      context,
                      stockTotalAmbiant,
                      stockTotal15c,
                      theme,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Titre de section
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Réservoirs',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalCiternes',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        
        // Grille des citernes
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.35,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildCiterneCard(context, citernes[index], theme),
              childCount: citernes.length,
            ),
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  /// Construit la grille de citernes à partir du snapshot KPI
  /// Utilise la même source de données que le dashboard et le module Stocks
  Widget _buildCiterneGridFromSnapshot(
    BuildContext context,
    DepotStocksSnapshot snapshot,
    ThemeData theme,
  ) {
    final citerneRows = snapshot.citerneRows;
    
    // Calculer les statistiques depuis le snapshot
    final totalCiternes = citerneRows.length;
    final alertesCiternes = citerneRows
        .where((c) => c.stockAmbiantTotal <= c.capaciteSecurite)
        .length;
    final capaciteTotale = citerneRows.fold<double>(
      0.0,
      (sum, c) => sum + c.capaciteTotale,
    );
    // RÈGLE MÉTIER : Stock ambiant = source de vérité opérationnelle
    // Calculer les totaux séparément pour affichage conforme
    final stockTotalAmbiant = citerneRows.fold<double>(
      0.0,
      (sum, c) => sum + c.stockAmbiantTotal,
    );
    final stockTotal15c = citerneRows.fold<double>(
      0.0,
      (sum, c) => sum + c.stock15cTotal,
    );

    return CustomScrollView(
      slivers: [
        // En-tête avec statistiques
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cartes de statistiques modernisées
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildStatCard(
                      context,
                      'Total Citernes',
                      totalCiternes.toString(),
                      Icons.storage_rounded,
                      const Color(0xFF3B82F6),
                      theme,
                    ),
                    _buildStatCard(
                      context,
                      'Alertes',
                      alertesCiternes.toString(),
                      Icons.warning_amber_rounded,
                      alertesCiternes > 0 ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                      theme,
                    ),
                    _buildStatCard(
                      context,
                      'Capacité Totale',
                      _formatVolume(capaciteTotale),
                      Icons.straighten_rounded,
                      const Color(0xFF8B5CF6),
                      theme,
                    ),
                    // RÈGLE MÉTIER : Stock ambiant = source de vérité opérationnelle
                    _buildStockTotalCard(
                      context,
                      stockTotalAmbiant,
                      stockTotal15c,
                      theme,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Titre de section
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Réservoirs',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalCiternes',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        
        // Grille des citernes
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.35,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildCiterneCardFromSnapshot(
                context,
                citerneRows[index],
                theme,
              ),
              childCount: citerneRows.length,
            ),
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  /// Construit une carte de statistique pour "Stock Total" avec ambiant en principal et 15°C en secondaire
  /// RÈGLE MÉTIER : Stock ambiant = source de vérité opérationnelle
  Widget _buildStockTotalCard(
    BuildContext context,
    double stockAmbiant,
    double stock15c,
    ThemeData theme,
  ) {
    final color = const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 18,
              color: color,
            ),
          ),
          const Spacer(),
          // Valeur principale : Stock ambiant
          Text(
            _formatVolume(stockAmbiant),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
              fontSize: 15,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Valeur secondaire : Stock 15°C
          Text(
            '≈ ${_formatVolume(stock15c)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Stock Total',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
              fontSize: 15,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCiterneCard(BuildContext context, CiterneRow citerne, ThemeData theme) {
    final stock15c = citerne.stock15c ?? citerne.stockAmbiant ?? 0;
    final stockAmbiant = citerne.stockAmbiant ?? 0;
    final capacite = citerne.capaciteTotale ?? 0;
    final utilPct = capacite > 0 ? (100 * stockAmbiant / capacite) : 0.0;
    
    return TankCard(
      name: citerne.nom,
      stock15c: stock15c,
      stockAmb: stockAmbiant,
      capacity: capacite,
      utilPct: utilPct.toDouble(),
      lastUpdated: citerne.dateStock,
    );
  }

  /// Construit une carte de citerne à partir d'un snapshot KPI
  /// Utilise CiterneGlobalStockSnapshot (données agrégées de v_stocks_citerne_global)
  Widget _buildCiterneCardFromSnapshot(
    BuildContext context,
    CiterneGlobalStockSnapshot citerne,
    ThemeData theme,
  ) {
    final stock15c = citerne.stock15cTotal;
    final stockAmbiant = citerne.stockAmbiantTotal;
    final capacite = citerne.capaciteTotale;
    final utilPct = capacite > 0 ? (100 * stockAmbiant / capacite) : 0.0;
    
    return TankCard(
      name: citerne.citerneNom,
      stock15c: stock15c,
      stockAmb: stockAmbiant,
      capacity: capacite,
      utilPct: utilPct.toDouble(),
      lastUpdated: citerne.dateJour,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 11,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class TankCard extends StatelessWidget {
  final String name;
  final double stock15c;
  final double stockAmb;
  final double capacity;
  final DateTime? lastUpdated;
  final double utilPct; // 0..100
  
  const TankCard({
    super.key,
    required this.name,
    required this.stock15c,
    required this.stockAmb,
    required this.capacity,
    required this.utilPct,
    this.lastUpdated,
  });
  
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final levelColor = _TankColors.getColorForLevel(utilPct);
    final isEmpty = utilPct <= 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEmpty 
              ? const Color(0xFFE2E8F0) 
              : levelColor.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isEmpty 
                ? Colors.black.withOpacity(0.03)
                : levelColor.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Fond dégradé subtil
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    isEmpty 
                        ? const Color(0xFFF8FAFC)
                        : levelColor.withOpacity(0.03),
                  ],
                ),
              ),
            ),
          ),
          
          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête : Nom + Badge pourcentage
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Indicateur LED
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      decoration: BoxDecoration(
                        color: isEmpty ? const Color(0xFFCBD5E1) : levelColor,
                        shape: BoxShape.circle,
                        boxShadow: isEmpty ? null : [
                          BoxShadow(
                            color: levelColor.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: const Color(0xFF1E293B),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Badge pourcentage
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEmpty 
                            ? const Color(0xFFF1F5F9)
                            : levelColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${utilPct.toStringAsFixed(1)}%',
                        style: t.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isEmpty ? const Color(0xFF94A3B8) : levelColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Barre de progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (utilPct / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isEmpty ? const Color(0xFFCBD5E1) : levelColor,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Métriques
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Colonne gauche : Stocks
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // RÈGLE MÉTIER : Stock ambiant = source de vérité opérationnelle (affiché en premier)
                            _buildMetricRow(
                              context,
                              icon: Icons.water_drop_outlined,
                              label: 'Amb',
                              value: fmtL(stockAmb),
                              color: const Color(0xFF3B82F6),
                            ),
                            const SizedBox(height: 6),
                            // Stock 15°C = valeur dérivée, analytique (affiché en secondaire)
                            _buildMetricRow(
                              context,
                              icon: Icons.thermostat_rounded,
                              label: '≈ 15°C',
                              value: fmtL(stock15c),
                              color: const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Colonne droite : Capacité + MAJ
                      SizedBox(
                        width: 115,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildMetricRow(
                              context,
                              icon: Icons.straighten_rounded,
                              label: 'Cap',
                              value: fmtL(capacity, fixed: 0),
                              alignEnd: true,
                              color: const Color(0xFF8B5CF6),
                            ),
                            if (lastUpdated != null) ...[
                              const SizedBox(height: 6),
                              _buildMetricRow(
                                context,
                                icon: Icons.schedule_rounded,
                                label: 'MAJ',
                                value: DateFormat('dd/MM/yy').format(lastUpdated!),
                                alignEnd: true,
                                color: const Color(0xFF64748B),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool alignEnd = false,
  }) {
    final t = Theme.of(context);
    
    final iconWidget = Icon(
      icon,
      size: 13,
      color: color.withOpacity(0.7),
    );
    
    final labelWidget = Text(
      label,
      style: t.textTheme.bodySmall?.copyWith(
        color: const Color(0xFF94A3B8),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
    
    final valueWidget = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: t.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF334155),
        fontSize: 11,
      ),
    );
    
    if (alignEnd) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          labelWidget,
          const SizedBox(width: 6),
          Flexible(child: valueWidget),
          const SizedBox(width: 4),
          iconWidget,
        ],
      );
    }
    
    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 5),
        labelWidget,
        const SizedBox(width: 6),
        Flexible(child: valueWidget),
      ],
    );
  }
}

// Fonction helper globale pour le formatage (conservée pour compatibilité)
Widget _metricLine(BuildContext context, {required IconData icon, required String label, required String value, bool alignEnd = false}) {
  final t = Theme.of(context);
  final ic = Icon(icon, size: 14, color: t.colorScheme.onSurfaceVariant.withOpacity(0.8));
  final lab = Text(label, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant));
  final val = Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700));
  if (alignEnd) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [lab, const SizedBox(width: 6), Flexible(child: val), const SizedBox(width: 4), ic]);
  }
  return Row(children: [ic, const SizedBox(width: 6), lab, const SizedBox(width: 8), Flexible(child: val)]);
}
