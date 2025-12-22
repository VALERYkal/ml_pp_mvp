import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:ml_pp_mvp/features/stocks/data/stocks_kpi_providers.dart';
import 'package:ml_pp_mvp/features/stocks/domain/depot_stocks_snapshot.dart';
import 'package:ml_pp_mvp/features/stocks_journaliers/providers/stocks_providers.dart';
import 'package:ml_pp_mvp/shared/formatters.dart';

/// Carte affichant le breakdown des stocks par propriétaire (MONALUXE / PARTENAIRE).
///
/// Utilise `depotStocksSnapshotProvider` pour obtenir les données agrégées.
/// Affiche deux lignes : une pour MONALUXE, une pour PARTENAIRE avec volumes ambiant/15°C.
class OwnerStockBreakdownCard extends ConsumerWidget {
  final String depotId;
  final DateTime? dateJour;
  final VoidCallback? onTap;

  const OwnerStockBreakdownCard({
    super.key,
    required this.depotId,
    this.dateJour,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1) Récupérer la date sélectionnée ou la date fournie
    final rawDate = dateJour ?? ref.watch(stocksSelectedDateProvider) ?? DateTime.now();

    // 2) Normaliser la date à minuit pour stabiliser la clé du provider
    final dateJourValue = DateTime(rawDate.year, rawDate.month, rawDate.day);

    final snapshotAsync = ref.watch(
      depotStocksSnapshotProvider(
        DepotStocksSnapshotParams(depotId: depotId, dateJour: dateJourValue),
      ),
    );

    return snapshotAsync.when(
      loading: () {
        debugPrint(
          '📊 OwnerStockBreakdownCard: state=loading (depotId=$depotId, dateJour=$dateJourValue)',
        );
        return _buildLoadingCard(context);
      },
      error: (error, stack) {
        debugPrint('📊 OwnerStockBreakdownCard: state=error $error');
        debugPrint('Stack: $stack');
        return _buildErrorCard(context, error);
      },
      data: (snapshot) {
        debugPrint(
          '📊 OwnerStockBreakdownCard: state=data isFallback=${snapshot.isFallback}',
        );
        return _buildDataCard(context, snapshot);
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

  Widget _buildDataCard(BuildContext context, DepotStocksSnapshot snapshot) {
    final t = Theme.of(context);
    final owners = snapshot.owners;
    final totals = snapshot.totals;

    DepotOwnerStockKpi monaluxe;
    DepotOwnerStockKpi partenaire;

    if (owners.isEmpty) {
      // 🔁 Fallback : les vues KPI ne renvoient rien, mais on a un stock global
      // Si le total est nul, on garde le comportement historique (0/0 pour tous)
      if (totals.stockAmbiantTotal == 0.0 && totals.stock15cTotal == 0.0) {
        monaluxe = _emptyOwner('MONALUXE');
        partenaire = _emptyOwner('PARTENAIRE');
      } else {
        // Cas actuel de la base : tout le stock est MONALUXE, PARTENAIRE = 0
        monaluxe = DepotOwnerStockKpi(
          depotId: totals.depotId,
          depotNom: totals.depotNom,
          proprietaireType: 'MONALUXE',
          produitId: totals.produitId,
          produitNom: totals.produitNom,
          stockAmbiantTotal: totals.stockAmbiantTotal,
          stock15cTotal: totals.stock15cTotal,
        );
        partenaire = _emptyOwner('PARTENAIRE');
      }
    } else {
      // 🔍 Cas nominal : on s'appuie sur v_kpi_stock_owner
      monaluxe = owners.firstWhere(
        (o) => o.proprietaireType.toUpperCase() == 'MONALUXE',
        orElse: () => _emptyOwner('MONALUXE'),
      );
      partenaire = owners.firstWhere(
        (o) => o.proprietaireType.toUpperCase() == 'PARTENAIRE',
        orElse: () => _emptyOwner('PARTENAIRE'),
      );
    }

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
              // Header
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
                  Text(
                    'Stock par propriétaire',
                    style: t.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // MONALUXE
              _buildOwnerRow(
                context,
                label: 'MONALUXE',
                ambiant: monaluxe.stockAmbiantTotal,
                stock15c: monaluxe.stock15cTotal,
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 12),
              // PARTENAIRE
              _buildOwnerRow(
                context,
                label: 'PARTENAIRE',
                ambiant: partenaire.stockAmbiantTotal,
                stock15c: partenaire.stock15cTotal,
                color: const Color(0xFF2196F3),
              ),
              if (snapshot.isFallback) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    "⚠︎ Données de stock indisponibles. Affichage d'une vue de secours (0 L).",
                    style: t.textTheme.bodySmall?.copyWith(
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
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
          // Volume ambiant (source de vérité opérationnelle)
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
