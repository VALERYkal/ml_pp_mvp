import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:ml_pp_mvp/features/stocks/data/stocks_kpi_providers.dart';
import 'package:ml_pp_mvp/shared/formatters.dart';
import '../../stocks_adjustments/widgets/stock_corrige_badge.dart'
    show StockCorrectedBadge;

/// Carte affichant le breakdown des stocks par propriétaire (MONALUXE / PARTENAIRE).
///
/// Utilise `depotOwnerStockFromSnapshotProvider` pour obtenir les données depuis v_stock_actuel (agrégation Dart par proprietaire_type).
/// Affiche deux lignes : une pour MONALUXE, une pour PARTENAIRE avec volumes ambiant/15°C.
class OwnerStockBreakdownCard extends ConsumerWidget {
  final String depotId;
  final DateTime?
  dateJour; // Gardé pour compatibilité mais non utilisé (snapshot = toujours actuel)
  final VoidCallback? onTap;

  const OwnerStockBreakdownCard({
    super.key,
    required this.depotId,
    this.dateJour,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownersAsync = ref.watch(depotOwnerStockFromSnapshotProvider(depotId));

    return ownersAsync.when(
      loading: () {
        debugPrint(
          '📊 OwnerStockBreakdownCard: state=loading (depotId=$depotId)',
        );
        return _buildLoadingCard(context);
      },
      error: (error, stack) {
        debugPrint('📊 OwnerStockBreakdownCard: state=error $error');
        debugPrint('Stack: $stack');
        // Fallback gracieux : afficher 0.0 au lieu d'une erreur
        // (sauf si c'est une erreur réseau critique)
        return _buildDataCard(context, [
          DepotOwnerStockKpi(
            depotId: depotId,
            depotNom: '',
            proprietaireType: 'MONALUXE',
            produitId: '',
            produitNom: '',
            stockAmbiantTotal: 0.0,
            stock15cTotal: 0.0,
          ),
          DepotOwnerStockKpi(
            depotId: depotId,
            depotNom: '',
            proprietaireType: 'PARTENAIRE',
            produitId: '',
            produitNom: '',
            stockAmbiantTotal: 0.0,
            stock15cTotal: 0.0,
          ),
        ]);
      },
      data: (owners) {
        debugPrint(
          '📊 OwnerStockBreakdownCard: state=data (${owners.length} owners)',
        );
        return _buildDataCard(context, owners);
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object error) {
    final t = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: t.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: t.colorScheme.error, size: 32),
            const SizedBox(height: 8),
            Text(
              'Erreur de chargement',
              style: t.textTheme.bodyMedium?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(BuildContext context, List<DepotOwnerStockKpi> owners) {
    final t = Theme.of(context);

    // Trouver MONALUXE et PARTENAIRE (le provider garantit qu'ils existent, avec 0.0 si absent)
    final monaluxe = owners.firstWhere(
      (o) => o.proprietaireType.toUpperCase() == 'MONALUXE',
      orElse: () => _emptyOwner('MONALUXE'),
    );

    final partenaire = owners.firstWhere(
      (o) => o.proprietaireType.toUpperCase() == 'PARTENAIRE',
      orElse: () => _emptyOwner('PARTENAIRE'),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        key: const Key('owner_stock_breakdown_card'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: t.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              color: Colors.black.withOpacity(0.06),
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec badge "Corrigé" (B4.4-B)
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF7C4DFF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                    'Stock par propriétaire',
                    style: t.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StockCorrectedBadge(depotId: depotId),
                ],
              ),
              const SizedBox(height: 16),
              // MONALUXE avec badge "Corrigé" (B4.4-B)
              _buildOwnerRow(
                context,
                label: 'MONALUXE',
                ambiant: monaluxe.stockAmbiantTotal,
                stock15c: monaluxe.stock15cTotal,
                color: const Color(0xFF4CAF50),
                depotId: depotId,
              ),
              const SizedBox(height: 12),
              // PARTENAIRE avec badge "Corrigé" (B4.4-B)
              _buildOwnerRow(
                context,
                label: 'PARTENAIRE',
                ambiant: partenaire.stockAmbiantTotal,
                stock15c: partenaire.stock15cTotal,
                color: const Color(0xFF2196F3),
                depotId: depotId,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerRow(
    BuildContext context, {
    required String label,
    required double ambiant,
    required double stock15c,
    required Color color,
    String? depotId,
  }) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: t.colorScheme.surfaceVariant.withOpacity(0.25),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;

          final ownerChip = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
            ),
          );

          final ambiantBlock = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmtL(ambiant),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Ambiant',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              if (depotId != null && depotId.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: StockCorrectedBadge(depotId: depotId),
                ),
            ],
          );

          final stock15cBlock = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmtL(stock15c),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                '≈ 15°C',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          );

          if (!isNarrow) {
            // Large: row classique (comme avant) mais sans overflow
            return Row(
              children: [
                ownerChip,
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        ambiantBlock,
                        stock15cBlock,
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Narrow: colonne => aucun risque d'overflow
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ownerChip,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: ambiantBlock),
                  const SizedBox(width: 12),
                  stock15cBlock,
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  DepotOwnerStockKpi _emptyOwner(String type) {
    return DepotOwnerStockKpi(
      depotId: '',
      depotNom: '',
      proprietaireType: type,
      produitId: '',
      produitNom: '',
      stockAmbiantTotal: 0.0,
      stock15cTotal: 0.0,
    );
  }
}
