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
      child: Row(
        children: [
          // Label avec badge coloré
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: t.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const Spacer(),
          // Volume ambiant (source de vérité opérationnelle) avec badge "Corrigé" (B4.4-B)
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmtL(ambiant),
                    style: t.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Ambiant',
                    style: t.textTheme.bodySmall?.copyWith(
                      color: t.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              // B4.4-B : Badge "Corrigé" pour stock par propriétaire
              if (depotId != null && depotId.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: StockCorrectedBadge(depotId: depotId),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Volume 15°C (valeur dérivée, analytique)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmtL(stock15c),
                style: t.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: t.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '≈ 15°C',
                style: t.textTheme.bodySmall?.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
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
