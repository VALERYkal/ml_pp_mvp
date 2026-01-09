import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/formatters.dart';
import '../../profil/providers/profil_provider.dart';
import '../widgets/stocks_kpi_cards.dart';
import '../data/stocks_kpi_providers.dart';
import '../../stocks_adjustments/widgets/stock_corrige_badge.dart'
    show StockCorrectedBadge;

/// Écran affichant les stocks du dépôt (KPI stocks par propriétaire).
class StocksScreen extends ConsumerWidget {
  const StocksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilProvider).valueOrNull;
    final depotId = profil?.depotId;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Stocks'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: depotId == null || depotId.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun dépôt associé',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous devez être associé à un dépôt pour voir les stocks',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                // Invalider les providers pour rafraîchir les données
                ref.invalidate(depotGlobalStockFromSnapshotProvider);
                ref.invalidate(depotOwnerStockFromSnapshotProvider);
                await Future.delayed(const Duration(milliseconds: 300));
              },
              color: theme.colorScheme.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Titre de section avec badge "STOCK CORRIGÉ" (B4.2)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Stock par propriétaire',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        StockCorrectedBadge(depotId: depotId),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Carte breakdown par propriétaire
                    OwnerStockBreakdownCard(
                      depotId: depotId,
                      // Pas de navigation imbriquée
                      onTap: null,
                    ),
                    const SizedBox(height: 32),
                    // Stock total dépôt avec badge "STOCK CORRIGÉ" (B4.2)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Stock total dépôt',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        StockCorrectedBadge(depotId: depotId),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // KPI Stock total (réutilise le widget du dashboard)
                    Builder(
                      builder: (context) {
                        final stockAsync = ref.watch(
                          depotGlobalStockFromSnapshotProvider(depotId),
                        );
                        return stockAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, stack) {
                            // Fallback gracieux : afficher 0.0
                            return _buildTotalStockCard(
                              context,
                              depotId: depotId,
                              amb: 0.0,
                              v15: 0.0,
                              nbTanks: 0,
                            );
                          },
                          data: (stock) => _buildTotalStockCard(
                            context,
                            depotId: depotId,
                            amb: stock.amb,
                            v15: stock.v15,
                            nbTanks: stock.nbTanks,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTotalStockCard(
    BuildContext context, {
    String? depotId,
    required double amb,
    required double v15,
    required int nbTanks,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // B4.4-B : Header avec badge "Corrigé"
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Stock total',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          // B4.4-B : Badge "Corrigé" pour stock total dépôt
                          if (depotId != null && depotId.isNotEmpty)
                            StockCorrectedBadge(depotId: depotId),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$nbTanks citernes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volume ambiant',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmtL(amb, fixed: 2),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volume @15°C',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmtL(v15, fixed: 2),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
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
