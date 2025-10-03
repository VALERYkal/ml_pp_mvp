import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/citerne_providers.dart';
import '../../../shared/ui/typography.dart';
import '../../../shared/formatters.dart';

// Fonctions de formatage modernisées avec chiffres tabulaires
final _n0 = NumberFormat.decimalPattern();
final _n1 = NumberFormat.decimalPattern()
  ..minimumFractionDigits = 1
  ..maximumFractionDigits = 1;

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

class CiterneListScreen extends ConsumerWidget {
  const CiterneListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citernesAsync = ref.watch(citernesWithStockProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildModernAppBar(context, ref),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(citernesWithStockProvider),
        child: citernesAsync.when(
          loading: () => _buildLoadingState(context, theme),
          error: (error, stack) => _buildErrorState(context, error, theme, ref),
          data: (citernes) => citernes.isEmpty
              ? _buildEmptyState(context, theme)
              : _buildCiterneGrid(context, citernes, theme),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context, WidgetRef ref) {
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
              Icons.storage_outlined,
              color: theme.colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Citernes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'Gestion des réservoirs',
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
          onPressed: () => ref.invalidate(citernesWithStockProvider),
          icon: Icon(Icons.refresh, color: theme.colorScheme.onSurfaceVariant),
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
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Chargement des citernes...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    Object error,
    ThemeData theme,
    WidgetRef ref,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger les données des citernes',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(citernesWithStockProvider),
              icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
              label: Text(
                'Réessayer',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.storage_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune citerne active',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune citerne n\'est actuellement configurée ou active',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCiterneGrid(
    BuildContext context,
    List<CiterneRow> citernes,
    ThemeData theme,
  ) {
    // Calculer les statistiques
    final totalCiternes = citernes.length;
    final alertesCiternes = citernes.where((c) => c.belowSecurity).length;
    final capaciteTotale = citernes.fold<double>(
      0,
      (sum, c) => sum + (c.capaciteTotale ?? 0),
    );
    final stockTotal = citernes.fold<double>(
      0,
      (sum, c) => sum + (c.stock15c ?? c.stockAmbiant ?? 0),
    );

    return CustomScrollView(
      slivers: [
        // En-tête avec statistiques
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cartes de statistiques
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildStatCard(
                      context,
                      'Total Citernes',
                      totalCiternes.toString(),
                      Icons.storage,
                      theme.colorScheme.primary,
                      theme,
                    ),
                    _buildStatCard(
                      context,
                      'Alertes',
                      alertesCiternes.toString(),
                      Icons.warning,
                      alertesCiternes > 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.outline,
                      theme,
                    ),
                    _buildStatCard(
                      context,
                      'Capacité Totale',
                      _formatVolume(capaciteTotale),
                      Icons.straighten,
                      theme.colorScheme.secondary,
                      theme,
                    ),
                    _buildStatCard(
                      context,
                      'Stock Total',
                      _formatVolume(stockTotal),
                      Icons.inventory,
                      theme.colorScheme.tertiary,
                      theme,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio:
                  1.6, // Plus de hauteur pour la nouvelle typographie
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildCiterneCard(context, citernes[index], theme),
              childCount: citernes.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCiterneCard(
    BuildContext context,
    CiterneRow citerne,
    ThemeData theme,
  ) {
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 11, color: theme.colorScheme.onSurfaceVariant),
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
    final warn = utilPct >= 90
        ? Colors.red
        : (utilPct >= 70 ? Colors.orange : t.colorScheme.primary);
    return Container(
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: t.colorScheme.outlineVariant.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                Text(
                  '${utilPct.toStringAsFixed(1)}%',
                  style: t.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: warn,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _metricLine(
                        context,
                        icon: Icons.opacity_rounded,
                        label: '15°C',
                        value: fmtL(stock15c),
                      ),
                      const SizedBox(height: 6),
                      _metricLine(
                        context,
                        icon: Icons.water_drop_outlined,
                        label: 'Amb',
                        value: fmtL(stockAmb),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _metricLine(
                        context,
                        icon: Icons.memory_rounded,
                        label: 'Cap',
                        value: fmtL(capacity, fixed: 0),
                        alignEnd: true,
                      ),
                      if (lastUpdated != null) ...[
                        const SizedBox(height: 6),
                        _metricLine(
                          context,
                          icon: Icons.update_rounded,
                          label: 'MAJ',
                          value: DateFormat('dd/MM/yyyy').format(lastUpdated!),
                          alignEnd: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _metricLine(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String value,
  bool alignEnd = false,
}) {
  final t = Theme.of(context);
  final ic = Icon(
    icon,
    size: 14,
    color: t.colorScheme.onSurfaceVariant.withOpacity(0.8),
  );
  final lab = Text(
    label,
    style: t.textTheme.bodySmall?.copyWith(
      color: t.colorScheme.onSurfaceVariant,
    ),
  );
  final val = Text(
    value,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
  );
  if (alignEnd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        lab,
        const SizedBox(width: 6),
        Flexible(child: val),
        const SizedBox(width: 4),
        ic,
      ],
    );
  }
  return Row(
    children: [
      ic,
      const SizedBox(width: 6),
      lab,
      const SizedBox(width: 8),
      Flexible(child: val),
    ],
  );
}
