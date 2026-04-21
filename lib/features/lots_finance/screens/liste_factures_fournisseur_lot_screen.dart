// 📌 Liste factures fournisseur lot — lecture `v_fournisseur_facture_lot` (provider existant).
// 🧭 Filtres / tri / libellés UI uniquement ; pas de recalcul métier ; mutations uniquement via feuilles modales dédiées.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/providers/fournisseur_finance_lot_providers.dart';
import 'package:ml_pp_mvp/features/lots_finance/utils/dashboard_finance_fournisseur_lot_status.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_currency_format.dart';
import 'package:ml_pp_mvp/features/lots_finance/screens/add_paiement_facture_screen.dart';

class ListeFacturesFournisseurLotScreen extends ConsumerStatefulWidget {
  const ListeFacturesFournisseurLotScreen({super.key});

  @override
  ConsumerState<ListeFacturesFournisseurLotScreen> createState() =>
      _ListeFacturesFournisseurLotScreenState();
}

class _ListeFacturesFournisseurLotScreenState
    extends ConsumerState<ListeFacturesFournisseurLotScreen> {
  final _invoiceSearch = TextEditingController();
  String? _statutGlobal;

  @override
  void initState() {
    super.initState();
    _invoiceSearch.addListener(_onSearchChanged);
  }

  void _onSearchChanged() => setState(() {});

  @override
  void dispose() {
    _invoiceSearch.removeListener(_onSearchChanged);
    _invoiceSearch.dispose();
    super.dispose();
  }

  String _fmtVol(double? v) {
    if (v == null) return '—';
    return v.toStringAsFixed(2);
  }

  List<FournisseurFactureLot> _filteredSorted(
    List<FournisseurFactureLot> raw,
    String? statutGlobalFiltre,
  ) {
    final q = _invoiceSearch.text.trim().toLowerCase();
    final out = raw.where((f) {
      if (q.isNotEmpty && !f.invoiceNo.toLowerCase().contains(q)) {
        return false;
      }
      if (statutGlobalFiltre != null) {
        final g = getStatutGlobal(
          statutRapprochement: f.statutRapprochement,
          statutPaiement: f.statutPaiement,
        );
        if (g != statutGlobalFiltre) return false;
      }
      return true;
    }).toList();

    out.sort((a, b) {
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
    return out;
  }

  Set<String> _statutsGlobauxPresents(List<FournisseurFactureLot> raw) {
    return raw
        .map(
          (f) => getStatutGlobal(
            statutRapprochement: f.statutRapprochement,
            statutPaiement: f.statutPaiement,
          ),
        )
        .toSet();
  }

  Future<void> _openPaiement(BuildContext context, String factureId) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddPaiementFactureScreen(factureId: factureId),
      ),
    );
    if (!mounted || ok != true) return;
    ref.invalidate(fournisseurFacturesLotProvider);
    ref.invalidate(fournisseurFactureLotByIdProvider(factureId));
    ref.invalidate(fournisseurPaiementsLotByFactureIdProvider(factureId));
  }

  void _openDetail(FournisseurFactureLot item) {
    context.push('/finance/factures-lot/${item.factureId}');
  }

  Widget _statutChip(BuildContext context, String code) {
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
      padding: const EdgeInsets.symmetric(horizontal: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(fournisseurFacturesLotProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factures fournisseur lot'),
        actions: [
          IconButton(
            tooltip: 'Synthèse',
            onPressed: () => context.push('/finance/factures-lot/dashboard'),
            icon: const Icon(Icons.dashboard_outlined),
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
          final statutsOrdonnes = _statutsGlobauxPresents(factures).toList()
            ..sort(
              (a, b) =>
                  statutGlobalSortKey(a).compareTo(statutGlobalSortKey(b)),
            );
          final filtreStatut = _statutGlobal != null &&
                  statutsOrdonnes.contains(_statutGlobal)
              ? _statutGlobal
              : null;
          final rows = _filteredSorted(factures, filtreStatut);
          final isWide = MediaQuery.sizeOf(context).width >= 960;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _invoiceSearch,
                        decoration: const InputDecoration(
                          labelText: 'Recherche (n° facture)',
                          hintText: 'invoice_no',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Statut global (UI)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: filtreStatut,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Tous'),
                              ),
                              ...statutsOrdonnes.map(
                                (s) => DropdownMenuItem<String?>(
                                  value: s,
                                  child: Text(s),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _statutGlobal = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (factures.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Aucune facture dans la vue.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              else if (rows.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucun résultat pour les filtres en cours.'),
                  ),
                )
              else if (isWide)
                Card(
                  margin: EdgeInsets.zero,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Statut global')),
                        DataColumn(label: Text('invoice_no')),
                        DataColumn(label: Text('fournisseur_lot_id')),
                        DataColumn(label: Text('total_volume_20c')),
                        DataColumn(label: Text('ecart_volume_20c')),
                        DataColumn(label: Text('montant_total_usd')),
                        DataColumn(label: Text('montant_regle_usd')),
                        DataColumn(label: Text('solde_restant_usd')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: rows.map((f) {
                        final g = getStatutGlobal(
                          statutRapprochement: f.statutRapprochement,
                          statutPaiement: f.statutPaiement,
                        );
                        return DataRow(
                          onSelectChanged: (_) => _openDetail(f),
                          cells: [
                            DataCell(_statutChip(context, g)),
                            DataCell(Text(f.invoiceNo)),
                            DataCell(Text(f.fournisseurLotId)),
                            DataCell(Text(_fmtVol(f.totalVolume20c))),
                            DataCell(Text(_fmtVol(f.ecartVolume20c))),
                            DataCell(Text(formatUsd(f.montantTotalUsd))),
                            DataCell(Text(formatUsd(f.montantRegleUsd))),
                            DataCell(Text(formatUsd(f.soldeRestantUsd))),
                            DataCell(
                              IconButton(
                                tooltip: 'Ajouter paiement',
                                icon: const Icon(Icons.add_card_outlined),
                                onPressed: () => _openPaiement(context, f.factureId),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                )
              else
                ...rows.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FactureMobileCard(
                      item: f,
                      statutBadge: _statutChip(
                        context,
                        getStatutGlobal(
                          statutRapprochement: f.statutRapprochement,
                          statutPaiement: f.statutPaiement,
                        ),
                      ),
                      fmtVol: _fmtVol,
                      onOpenDetail: () => _openDetail(f),
                      onAddPaiement: () => _openPaiement(context, f.factureId),
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

class _FactureMobileCard extends StatelessWidget {
  const _FactureMobileCard({
    required this.item,
    required this.statutBadge,
    required this.fmtVol,
    required this.onOpenDetail,
    required this.onAddPaiement,
  });

  final FournisseurFactureLot item;
  final Widget statutBadge;
  final String Function(double?) fmtVol;
  final VoidCallback onOpenDetail;
  final VoidCallback onAddPaiement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
            child: Row(
              children: [
                Expanded(child: statutBadge),
                IconButton(
                  tooltip: 'Ajouter paiement',
                  onPressed: onAddPaiement,
                  icon: const Icon(Icons.add_card_outlined),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onOpenDetail,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.invoiceNo, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Lot ${item.fournisseurLotId}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Divider(height: 20),
                  _kv('total_volume_20c', fmtVol(item.totalVolume20c)),
                  _kv('ecart_volume_20c', fmtVol(item.ecartVolume20c)),
                  _kv('montant_total_usd', formatUsd(item.montantTotalUsd)),
                  _kv('montant_regle_usd', formatUsd(item.montantRegleUsd)),
                  _kv('solde_restant_usd', formatUsd(item.soldeRestantUsd)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              k,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
