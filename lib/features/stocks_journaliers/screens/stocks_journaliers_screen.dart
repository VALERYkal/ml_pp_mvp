import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stocks_providers.dart';
import '../../../shared/utils/volume_formatter.dart';

class StocksJournaliersScreen extends ConsumerWidget {
  const StocksJournaliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocksAsync = ref.watch(stocksListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stocks journaliers'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(stocksListProvider);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: stocksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur lors du chargement',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(stocksListProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
          data: (dataWithMeta) {
            final rows = dataWithMeta.stocks;

            if (rows.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun stock journalier à afficher',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dataWithMeta.isFallback
                            ? 'Données de la date la plus récente disponible: ${dataWithMeta.actualDataDate}'
                            : 'Aucune donnée pour la date demandée: ${dataWithMeta.requestedDate}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Afficher un indicateur si on utilise des données de fallback
            final showFallbackWarning = dataWithMeta.isFallback &&
                dataWithMeta.actualDataDate != dataWithMeta.requestedDate;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showFallbackWarning)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.tertiary,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Données de la date la plus récente disponible: ${dataWithMeta.actualDataDate} (demandée: ${dataWithMeta.requestedDate})',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Citerne')),
                          DataColumn(label: Text('Produit')),
                          DataColumn(
                            label: Text('Stock ambiant'),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text('Stock 15°C'),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text('Capacité totale'),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text('Ratio'),
                            numeric: true,
                          ),
                        ],
                        rows: rows.map((row) {
                          final ratio = row.capaciteTotale > 0
                              ? (row.stockAmbiant / row.capaciteTotale * 100)
                              : 0.0;

                          return DataRow(
                            cells: [
                              DataCell(Text(
                                _formatDate(row.dateJour),
                              )),
                              DataCell(Text(row.citerneNom)),
                              DataCell(Text(row.produitNom)),
                              DataCell(Text(
                                VolumeFormatter.formatVolume(row.stockAmbiant),
                              )),
                              DataCell(Text(
                                VolumeFormatter.formatVolume(row.stock15c),
                              )),
                              DataCell(Text(
                                VolumeFormatter.formatVolume(row.capaciteTotale),
                              )),
                              DataCell(
                                Text(
                                  '${ratio.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: ratio > 80
                                        ? Theme.of(context).colorScheme.error
                                        : ratio > 60
                                            ? Theme.of(context).colorScheme.tertiary
                                            : null,
                                    fontWeight: ratio > 80
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    // dateStr est au format YYYY-MM-DD
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final month = parts[1];
        final day = parts[2];
        return '$day/$month/$year';
      }
    } catch (_) {
      // Ignore
    }
    return dateStr;
  }
}

