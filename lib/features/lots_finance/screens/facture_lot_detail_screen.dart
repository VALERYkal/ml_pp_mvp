// 📌 Détail facture lot — lecture `v_fournisseur_facture_lot` + `fournisseur_paiement_lot_min` (providers existants).
// 🧭 Aucune logique métier : affichage, `getStatutGlobal` / progression UI uniquement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/lots_finance/providers/fournisseur_finance_lot_providers.dart';
import 'package:ml_pp_mvp/features/lots_finance/utils/dashboard_finance_fournisseur_lot_status.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_currency_format.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_status_badges.dart';
import 'package:ml_pp_mvp/features/lots_finance/screens/add_paiement_facture_screen.dart';
import 'package:ml_pp_mvp/shared/ui/format.dart';

class FactureLotDetailScreen extends ConsumerWidget {
  const FactureLotDetailScreen({
    super.key,
    required this.factureId,
  });

  final String factureId;

  Future<void> _openPaiementForm(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddPaiementFactureScreen(factureId: factureId),
      ),
    );
    if (created == true) {
      ref.invalidate(fournisseurFactureLotByIdProvider(factureId));
      ref.invalidate(fournisseurFacturesLotProvider);
      ref.invalidate(fournisseurPaiementsLotByFactureIdProvider(factureId));
    }
  }

  Widget _chipStatutGlobal(BuildContext context, String code) {
    final theme = Theme.of(context);
    final c = couleurStatutGlobal(code);
    return Chip(
      label: Text(
        code,
        style: theme.textTheme.labelMedium?.copyWith(
          color: c.computeLuminance() > 0.45 ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: c.withValues(alpha: 0.92),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _fmtVol(double? v) {
    if (v == null) return '—';
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factureAsync = ref.watch(fournisseurFactureLotByIdProvider(factureId));
    final paiementsAsync = ref.watch(
      fournisseurPaiementsLotByFactureIdProvider(factureId),
    );
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail facture lot'),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            onPressed: () {
              ref.invalidate(fournisseurFactureLotByIdProvider(factureId));
              ref.invalidate(fournisseurPaiementsLotByFactureIdProvider(factureId));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPaiementForm(context, ref),
        icon: const Icon(Icons.add_card_outlined),
        label: const Text('Ajouter paiement'),
      ),
      body: factureAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: cs.error),
                const SizedBox(height: 12),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(fournisseurFactureLotByIdProvider(factureId)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (facture) {
          if (facture == null) {
            return const Center(
              child: Text('Facture lot introuvable ou non disponible.'),
            );
          }

          final global = getStatutGlobal(
            statutRapprochement: facture.statutRapprochement,
            statutPaiement: facture.statutPaiement,
          );
          final percent = facture.montantTotalUsd > 0
              ? (facture.montantRegleUsd / facture.montantTotalUsd).clamp(0.0, 1.0)
              : 0.0;

          Widget paiementsSection() {
            return paiementsAsync.when(
              loading: () => Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Chargement des paiements…',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              error: (e, _) => Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Erreur paiements: $e',
                    style: TextStyle(color: cs.error),
                  ),
                ),
              ),
              data: (paiements) {
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paiements',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (paiements.isEmpty)
                          Text(
                            'Aucun paiement enregistré.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: paiements.length,
                            itemBuilder: (context, index) {
                              final p = paiements[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (index > 0)
                                    Divider(
                                      height: 16,
                                      thickness: 1,
                                      color: cs.outlineVariant,
                                    ),
                                  _kvRow(
                                    theme,
                                    'date_paiement',
                                    fmtDate(p.datePaiement ?? p.createdAt),
                                  ),
                                  _kvRow(
                                    theme,
                                    'montant_paye_usd',
                                    formatUsd(p.montantPayeUsd),
                                  ),
                                  _kvRow(
                                    theme,
                                    'mode_paiement',
                                    (p.modePaiement ?? '—').trim().isEmpty
                                        ? '—'
                                        : p.modePaiement!.trim(),
                                  ),
                                  _kvRow(
                                    theme,
                                    'reference_paiement',
                                    (p.referencePaiement ?? '—').trim().isEmpty
                                        ? '—'
                                        : p.referencePaiement!.trim(),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _chipStatutGlobal(context, global),
                          const SizedBox(height: 12),
                          Text(
                            facture.invoiceNo,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'fournisseur_lot_id : ${facture.fournisseurLotId}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'date_facture : ${fmtDate(facture.dateFacture)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'date_echeance : ${fmtDate(facture.dateEcheance)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rapport volume',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _kvRow(
                            theme,
                            'total_volume_20c',
                            _fmtVol(facture.totalVolume20c),
                          ),
                          _kvRow(
                            theme,
                            'quantite_facturee_20c',
                            _fmtVol(facture.quantiteFacturee20c),
                          ),
                          _kvRow(
                            theme,
                            'ecart_volume_20c',
                            _fmtVol(facture.ecartVolume20c),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'statut_rapprochement',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          StatutRapprochementBadge(
                            statut: facture.statutRapprochement,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Finance',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _kvRow(
                            theme,
                            'montant_total_usd',
                            formatUsd(facture.montantTotalUsd),
                          ),
                          _kvRow(
                            theme,
                            'montant_regle_usd',
                            formatUsd(facture.montantRegleUsd),
                          ),
                          _kvRow(
                            theme,
                            'solde_restant_usd',
                            formatUsd(facture.soldeRestantUsd),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'statut_paiement',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          StatutPaiementBadge(statut: facture.statutPaiement),
                          const SizedBox(height: 16),
                          Text(
                            '${(percent * 100).toStringAsFixed(1)} % réglé',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  paiementsSection(),
                ],
              );
        },
      ),
    );
  }

  static Widget _kvRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
