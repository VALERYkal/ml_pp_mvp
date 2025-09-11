import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stocks_providers.dart';
import '../../dashboard/widgets/placeholders.dart';

class StocksListScreen extends ConsumerWidget {
  const StocksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocks = ref.watch(stocksListProvider);
    final date = ref.watch(stocksSelectedDateProvider);
    final produitsRef = ref.watch(stocksProduitsRefProvider);
    final citernesRef = ref.watch(stocksCiternesRefProvider);
    final sortKey = ref.watch(stocksSortKeyProvider);
    final asc = ref.watch(stocksSortAscendingProvider);

    // Barre de filtres collante
    final filters = SliverPersistentHeader(
      pinned: true,
      delegate: _StickyFilters(
        child: Material(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Sélecteur de date
                TextButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(_fmtDate(date)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      ref.read(stocksSelectedDateProvider.notifier).state = picked;
                    }
                  },
                ),
                // Filtre produit
                SizedBox(
                  width: 220,
                  child: produitsRef.when(
                    data: (items) => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Produit',
                        border: OutlineInputBorder(),
                      ),
                      value: ref.watch(stocksSelectedProduitIdProvider),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tous')),
                        ...items.map((e) => DropdownMenuItem(
                          value: e['id'],
                          child: Text(e['nom'] ?? ''),
                        )),
                      ],
                      onChanged: (v) => ref.read(stocksSelectedProduitIdProvider.notifier).state = v,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => const Text('Erreur produits'),
                  ),
                ),
                // Filtre citerne
                SizedBox(
                  width: 220,
                  child: citernesRef.when(
                    data: (items) {
                      final selectedProduitId = ref.watch(stocksSelectedProduitIdProvider);
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Citerne',
                          border: OutlineInputBorder(),
                        ),
                        value: ref.watch(stocksSelectedCiterneIdProvider),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Toutes')),
                          ...items
                              .where((e) => selectedProduitId == null || (e['produit_id'] ?? '') == selectedProduitId)
                              .map((e) => DropdownMenuItem(
                                value: e['id'],
                                child: Text(e['nom'] ?? ''),
                              )),
                        ],
                        onChanged: (v) => ref.read(stocksSelectedCiterneIdProvider.notifier).state = v,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => const Text('Erreur citernes'),
                  ),
                ),
                // Bouton export CSV
                OutlinedButton.icon(
                  onPressed: () async {
                    final data = await ref.read(stocksListProvider.future);
                    final csv = _toCsv(data);
                    await Clipboard.setData(ClipboardData(text: csv));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV copié dans le presse-papiers')),
                      );
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Exporter CSV'),
                ),
                // Bouton réinitialiser
                TextButton.icon(
                  onPressed: () {
                    ref.read(stocksSelectedDateProvider.notifier).state = DateTime.now();
                    ref.read(stocksSelectedProduitIdProvider.notifier).state = null;
                    ref.read(stocksSelectedCiterneIdProvider.notifier).state = null;
                    ref.read(stocksSortKeyProvider.notifier).state = StockSortKey.ratio;
                    ref.read(stocksSortAscendingProvider.notifier).state = false;
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Réinitialiser'),
                ),
                // Tri
                DropdownButton<StockSortKey>(
                  value: sortKey,
                  items: const [
                    DropdownMenuItem(value: StockSortKey.ratio, child: Text('Ratio')),
                    DropdownMenuItem(value: StockSortKey.stockAmbiant, child: Text('Stock ambiant')),
                    DropdownMenuItem(value: StockSortKey.stock15c, child: Text('Stock 15°C')),
                    DropdownMenuItem(value: StockSortKey.capaciteTotale, child: Text('Capacité totale')),
                  ],
                  onChanged: (v) {
                    if (v != null) ref.read(stocksSortKeyProvider.notifier).state = v;
                  },
                ),
                IconButton(
                  tooltip: asc ? 'Ordre croissant' : 'Ordre décroissant',
                  icon: Icon(asc ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () => ref.read(stocksSortAscendingProvider.notifier).state = !asc,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Liste avec états améliorés
    final listSliver = stocks.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(
              6,
              (_) => Container(
                height: 44,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorTile(
            'Erreur de chargement des stocks',
            onRetry: () => ref.invalidate(stocksListProvider),
          ),
        ),
      ),
      data: (items) => items.isEmpty
          ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun stock pour cette date',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Citerne')),
                      DataColumn(label: Text('Produit')),
                      DataColumn(label: Text('Ambiant (L)')),
                      DataColumn(label: Text('15°C (L)')),
                      DataColumn(label: Text('Capacité (L)')),
                      DataColumn(label: Text('Sécurité (L)')),
                      DataColumn(label: Text('Ratio')),
                      DataColumn(label: Text('Alerte')),
                    ],
                    rows: [
                      // Lignes de données
                      ...items.map((s) => DataRow(cells: [
                        DataCell(Text(s.dateJour)),
                        DataCell(Text(s.citerneNom)),
                        DataCell(Text(s.produitNom)),
                        DataCell(Text(s.stockAmbiant.toStringAsFixed(0))),
                        DataCell(Text(s.stock15c.toStringAsFixed(0))),
                        DataCell(Text(s.capaciteTotale.toStringAsFixed(0))),
                        DataCell(Text(s.capaciteSecurite.toStringAsFixed(0))),
                        DataCell(Text(_fmtRatio(s))),
                        DataCell(s.stockAmbiant <= s.capaciteSecurite
                            ? const Icon(Icons.warning, color: Colors.red)
                            : const SizedBox.shrink()),
                      ])),
                      // Ligne de total
                      DataRow(
                        color: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
                        cells: [
                          const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          DataCell(Text(_calculateTotal(items, (s) => s.stockAmbiant).toStringAsFixed(0), 
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(_calculateTotal(items, (s) => s.stock15c).toStringAsFixed(0), 
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stocks journaliers'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(stocksListProvider),
        child: CustomScrollView(
          slivers: [
            filters,
            listSliver,
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _csvEsc(String s) => '"${s.replaceAll('"', '""')}"';

  String _toCsv(List<StockRowView> data) {
    final b = StringBuffer('date,citerne,produit,stock_ambiant,stock_15c,cap_totale,cap_securite\n');
    for (final r in data) {
      b.writeln([
        r.dateJour,
        _csvEsc(r.citerneNom),
        _csvEsc(r.produitNom),
        r.stockAmbiant.toString(),
        r.stock15c.toString(),
        r.capaciteTotale.toString(),
        r.capaciteSecurite.toString(),
      ].join(','));
    }
    return b.toString();
  }

  String _fmtRatio(StockRowView s) {
    final r = s.capaciteTotale > 0 ? s.stockAmbiant / s.capaciteTotale : 0.0;
    return '${(r * 100).toStringAsFixed(1)}%';
  }

  double _calculateTotal(List<StockRowView> items, double Function(StockRowView) selector) {
    return items.fold<double>(0.0, (sum, item) => sum + selector(item));
  }
}

/// Delegate pour la barre de filtres collante
class _StickyFilters extends SliverPersistentHeaderDelegate {
  final Widget child;
  
  _StickyFilters({required this.child});
  
  @override
  double get minExtent => 72;
  
  @override
  double get maxExtent => 96;
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

