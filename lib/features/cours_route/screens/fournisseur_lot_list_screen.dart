// 📌 Module : Cours de Route — Liste des lots fournisseur (V1)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/cours_route/models/fournisseur_lot.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/fournisseur_lot_providers.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';

class FournisseurLotListScreen extends ConsumerStatefulWidget {
  const FournisseurLotListScreen({super.key});

  @override
  ConsumerState<FournisseurLotListScreen> createState() =>
      _FournisseurLotListScreenState();
}

class _FournisseurLotListScreenState
    extends ConsumerState<FournisseurLotListScreen> {
  final _searchController = TextEditingController();

  String? _fournisseurId;
  String? _produitId;
  StatutFournisseurLot? _statut;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _fournisseurId != null ||
      _produitId != null ||
      _statut != null;

  List<FournisseurLot> _filtered(List<FournisseurLot> all) {
    final q = _searchController.text.trim().toLowerCase();
    return all.where((lot) {
      if (q.isNotEmpty && !lot.reference.toLowerCase().contains(q)) {
        return false;
      }
      if (_fournisseurId != null && lot.fournisseurId != _fournisseurId) {
        return false;
      }
      if (_produitId != null && lot.produitId != _produitId) {
        return false;
      }
      if (_statut != null && lot.statut != _statut) {
        return false;
      }
      return true;
    }).toList();
  }

  String _dateLotStr(FournisseurLot lot) {
    final d = lot.dateLot;
    if (d == null) return '—';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _fournisseurId = null;
      _produitId = null;
      _statut = null;
    });
  }

  Widget _buildFilterBar(RefDataCache refData) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Référence',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _fournisseurId,
              decoration: const InputDecoration(
                labelText: 'Fournisseur',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Tous')),
                ...refData.fournisseurs.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: (v) => setState(() => _fournisseurId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _produitId,
              decoration: const InputDecoration(
                labelText: 'Produit',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Tous')),
                ...refData.produits.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: (v) => setState(() => _produitId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<StatutFournisseurLot?>(
              value: _statut,
              decoration: const InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem<StatutFournisseurLot?>(
                  value: null,
                  child: Text('Tous'),
                ),
                DropdownMenuItem(
                  value: StatutFournisseurLot.ouvert,
                  child: Text('Ouvert'),
                ),
                DropdownMenuItem(
                  value: StatutFournisseurLot.cloture,
                  child: Text('Clôturé'),
                ),
                DropdownMenuItem(
                  value: StatutFournisseurLot.facture,
                  child: Text('Facturé'),
                ),
              ],
              onChanged: (v) => setState(() => _statut = v),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Effacer'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () async {
              await context.push('/cours/lots/new');
              if (mounted) ref.invalidate(fournisseurLotsProvider);
            },
            icon: const Icon(Icons.add),
            label: const Text('Nouveau lot'),
          ),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(fournisseurLotsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Rafraîchir'),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(RefDataCache refData, List<FournisseurLot> filtered) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = filtered
            .map(
              (lot) => DataRow(
                cells: [
                  DataCell(Text(lot.reference)),
                  DataCell(
                    Text(
                      refData.fournisseurs[lot.fournisseurId] ??
                          lot.fournisseurId,
                    ),
                  ),
                  DataCell(
                    Text(
                      refData.produits[lot.produitId] ?? lot.produitId,
                    ),
                  ),
                  DataCell(Text(_dateLotStr(lot))),
                  DataCell(Text(lot.statut.label)),
                  DataCell(
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Lot ${lot.reference} (${lot.id.length >= 8 ? lot.id.substring(0, 8) : lot.id}…)',
                            ),
                          ),
                        );
                      },
                      child: const Text('Voir'),
                    ),
                  ),
                ],
              ),
            )
            .toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Référence')),
                DataColumn(label: Text('Fournisseur')),
                DataColumn(label: Text('Produit')),
                DataColumn(label: Text('Date lot')),
                DataColumn(label: Text('Statut')),
                DataColumn(label: Text('Actions')),
              ],
              rows: rows,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(RefDataCache refData, List<FournisseurLot> lots) {
    if (lots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Aucun lot fournisseur'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await context.push('/cours/lots/new');
                if (mounted) ref.invalidate(fournisseurLotsProvider);
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer un lot'),
            ),
          ],
        ),
      );
    }

    final filtered = _filtered(lots);

    return ListView(
      children: [
        _buildActionsBar(),
        _buildFilterBar(refData),
        if (filtered.isEmpty) ...[
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                const Text('Aucun résultat'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Effacer les filtres'),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTable(refData, filtered),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final refDataAsync = ref.watch(refDataProvider);
    final lotsAsync = ref.watch(fournisseurLotsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lots fournisseur'),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(fournisseurLotsProvider),
          ),
        ],
      ),
      body: refDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(refDataProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (refData) => lotsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(e.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(fournisseurLotsProvider),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
          data: (lots) => _buildBody(refData, lots),
        ),
      ),
    );
  }
}
