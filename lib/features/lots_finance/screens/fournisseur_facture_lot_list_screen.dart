import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/providers/fournisseur_finance_lot_providers.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_filter_bar.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/fournisseur_facture_lot_card.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/fournisseur_facture_lot_table.dart';

class FournisseurFactureLotListScreen extends ConsumerStatefulWidget {
  const FournisseurFactureLotListScreen({super.key});

  @override
  ConsumerState<FournisseurFactureLotListScreen> createState() =>
      _FournisseurFactureLotListScreenState();
}

class _FournisseurFactureLotListScreenState
    extends ConsumerState<FournisseurFactureLotListScreen> {
  final _searchController = TextEditingController();
  String? _statutRapprochement;
  String? _statutPaiement;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FournisseurFactureLot> _applyFilters(List<FournisseurFactureLot> source) {
    final q = _searchController.text.trim().toLowerCase();
    return source.where((item) {
      final matchesQuery =
          q.isEmpty ||
          item.invoiceNo.toLowerCase().contains(q) ||
          (item.dealReference ?? '').toLowerCase().contains(q);
      final matchesRapprochement =
          _statutRapprochement == null ||
          item.statutRapprochement == _statutRapprochement;
      final matchesPaiement =
          _statutPaiement == null || item.statutPaiement == _statutPaiement;
      return matchesQuery && matchesRapprochement && matchesPaiement;
    }).toList();
  }

  void _openDetail(FournisseurFactureLot item) {
    context.push('/finance/factures-lot/${item.factureId}');
  }

  @override
  Widget build(BuildContext context) {
    final facturesAsync = ref.watch(fournisseurFacturesLotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factures fournisseur lot'),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            onPressed: () => ref.invalidate(fournisseurFacturesLotProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: facturesAsync.when(
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
                  onPressed: () => ref.invalidate(fournisseurFacturesLotProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (factures) {
          if (factures.isEmpty) {
            return const Center(
              child: Text('Aucune facture lot disponible.'),
            );
          }

          final statutRapprochementOptions = factures
              .map((e) => e.statutRapprochement)
              .where((e) => e.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          final statutPaiementOptions = factures
              .map((e) => e.statutPaiement)
              .where((e) => e.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          final filtered = _applyFilters(factures);
          final isMobile = MediaQuery.of(context).size.width < 900;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FinanceLotFilterBar(
                searchController: _searchController,
                statutRapprochement: _statutRapprochement,
                statutPaiement: _statutPaiement,
                statutRapprochementOptions: statutRapprochementOptions,
                statutPaiementOptions: statutPaiementOptions,
                onChanged: (value) {
                  setState(() {
                    _statutRapprochement = value.statutRapprochement;
                    _statutPaiement = value.statutPaiement;
                  });
                },
                onClear: () {
                  setState(() {
                    _searchController.clear();
                    _statutRapprochement = null;
                    _statutPaiement = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucun résultat pour les filtres en cours.'),
                  ),
                )
              else if (isMobile)
                ...filtered.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FournisseurFactureLotCard(
                      item: item,
                      onTap: () => _openDetail(item),
                    ),
                  ),
                )
              else
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: FournisseurFactureLotTable(
                      items: filtered,
                      onTap: _openDetail,
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
