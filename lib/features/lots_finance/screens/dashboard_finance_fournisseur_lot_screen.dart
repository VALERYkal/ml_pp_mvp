// 📌 Synthèse finance fournisseur lot — lecture `v_fournisseur_facture_lot` uniquement.
// 🧭 Aucun recalcul volumétrique ni agrégat métier : mapping UI + sommes simples sur la liste.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/providers/fournisseur_finance_lot_providers.dart';
import 'package:ml_pp_mvp/features/lots_finance/utils/dashboard_finance_fournisseur_lot_status.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_currency_format.dart';

class DashboardFinanceFournisseurLotScreen extends ConsumerWidget {
  const DashboardFinanceFournisseurLotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fournisseurFacturesLotProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance fournisseur lot — synthèse'),
        actions: [
          IconButton(
            tooltip: 'Liste factures',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.go('/finance/factures-lot'),
          ),
          IconButton(
            tooltip: 'Rafraîchir',
            onPressed: () => ref.invalidate(fournisseurFacturesLotProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: cs.error),
                const SizedBox(height: 12),
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(fournisseurFacturesLotProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (factures) {
          final sorted = [...factures]..sort((a, b) {
              final ga = getStatutGlobal(
                statutRapprochement: a.statutRapprochement,
                statutPaiement: a.statutPaiement,
              );
              final gb = getStatutGlobal(
                statutRapprochement: b.statutRapprochement,
                statutPaiement: b.statutPaiement,
              );
              final c = statutGlobalSortKey(ga).compareTo(statutGlobalSortKey(gb));
              if (c != 0) return c;
              return a.invoiceNo.compareTo(b.invoiceNo);
            });

          final n = sorted.length;
          final totalMontant =
              sorted.fold<double>(0, (s, f) => s + f.montantTotalUsd);
          final totalRegle =
              sorted.fold<double>(0, (s, f) => s + f.montantRegleUsd);
          final totalSolde =
              sorted.fold<double>(0, (s, f) => s + f.soldeRestantUsd);
          final pctPaye =
              totalMontant > 0 ? (100 * totalRegle / totalMontant) : 0.0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                'Indicateurs (agrégation UI sur la liste chargée)',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final cross = w >= 1100
                      ? 5
                      : w >= 720
                      ? 3
                      : 2;
                  return GridView.count(
                    crossAxisCount: cross,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: w >= 1100 ? 1.35 : 1.15,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _KpiCard(
                        label: 'Total factures',
                        value: '$n',
                        icon: Icons.receipt_long_outlined,
                      ),
                      _KpiCard(
                        label: 'Montant total',
                        value: formatUsd(totalMontant),
                        icon: Icons.attach_money,
                      ),
                      _KpiCard(
                        label: 'Montant payé',
                        value: formatUsd(totalRegle),
                        icon: Icons.payments_outlined,
                      ),
                      _KpiCard(
                        label: 'Solde total',
                        value: formatUsd(totalSolde),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      _KpiCard(
                        label: '% payé',
                        value: '${pctPaye.toStringAsFixed(1)} %',
                        icon: Icons.percent,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Factures (tri prioritaire)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (sorted.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Aucune facture dans la vue.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                ...sorted.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FactureDashboardCard(
                      item: f,
                      onTap: () =>
                          context.push('/finance/factures-lot/${f.factureId}'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: cs.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FactureDashboardCard extends StatelessWidget {
  const _FactureDashboardCard({
    required this.item,
    required this.onTap,
  });

  final FournisseurFactureLot item;
  final VoidCallback onTap;

  String _fmtVol(double? v) {
    if (v == null) return '—';
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final global = getStatutGlobal(
      statutRapprochement: item.statutRapprochement,
      statutPaiement: item.statutPaiement,
    );
    final couleur = couleurStatutGlobal(global);
    final pctLigne = item.montantTotalUsd > 0
        ? (100 * item.montantRegleUsd / item.montantTotalUsd)
        : 0.0;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.invoiceNo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lot ${item.fournisseurLotId}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message:
                        'Vue : ${item.statutRapprochement} / ${item.statutPaiement}',
                    child: Chip(
                      label: Text(
                        global,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: couleur.computeLuminance() > 0.45
                              ? Colors.black87
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: couleur.withValues(alpha: 0.92),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Volume reçu @20 °C : ${_fmtVol(item.totalVolume20c)}  ·  '
                'Facturé : ${_fmtVol(item.quantiteFacturee20c)}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Écart : ${_fmtVol(item.ecartVolume20c)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Divider(height: 20),
              Text(
                'Paiement : ${formatUsd(item.montantRegleUsd)} / '
                '${formatUsd(item.montantTotalUsd)} '
                '(${pctLigne.toStringAsFixed(1)} %)',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Solde : ${formatUsd(item.soldeRestantUsd)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
