import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/lots_finance/providers/fournisseur_finance_lot_providers.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/fournisseur_facture_lot_amounts_card.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/fournisseur_facture_lot_context_card.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/fournisseur_facture_lot_header.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/fournisseur_facture_lot_rapprochement_card.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/fournisseur_paiement_form_sheet.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/fournisseur_paiements_list.dart';

class FournisseurFactureLotDetailScreen extends ConsumerWidget {
  const FournisseurFactureLotDetailScreen({
    super.key,
    required this.factureId,
  });

  final String factureId;

  Future<void> _openPaiementForm(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FournisseurPaiementFormSheet(factureId: factureId),
    );
    if (created == true) {
      ref.invalidate(fournisseurFactureLotByIdProvider(factureId));
      ref.invalidate(fournisseurFacturesLotProvider);
      ref.invalidate(fournisseurPaiementsLotByFactureIdProvider(factureId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factureAsync = ref.watch(fournisseurFactureLotByIdProvider(factureId));
    final paiementsAsync = ref.watch(
      fournisseurPaiementsLotByFactureIdProvider(factureId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail facture lot'),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            onPressed: () => ref.invalidate(fournisseurFactureLotByIdProvider(factureId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPaiementForm(context, ref),
        icon: const Icon(Icons.add_card_outlined),
        label: const Text('Enregistrer un paiement'),
      ),
      body: factureAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
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

          final paiementsWidget = paiementsAsync.when(
            loading: () => const Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Erreur de chargement des paiements: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
            data: (paiements) {
              final items = paiements
                  .map(
                    (p) => FournisseurPaiementListItem(
                      datePaiement: p.datePaiement ?? p.createdAt,
                      montantUsd: p.montantPayeUsd,
                      modePaiement: p.modePaiement,
                      reference: p.referencePaiement,
                      note: p.note,
                    ),
                  )
                  .toList();
              return FournisseurPaiementsList(paiements: items);
            },
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FournisseurFactureLotHeader(facture: facture),
              const SizedBox(height: 12),
              FournisseurFactureLotRapprochementCard(facture: facture),
              const SizedBox(height: 12),
              FournisseurFactureLotAmountsCard(facture: facture),
              const SizedBox(height: 12),
              FournisseurFactureLotContextCard(facture: facture),
              const SizedBox(height: 12),
              paiementsWidget,
              const SizedBox(height: 90),
            ],
          );
        },
      ),
    );
  }
}
