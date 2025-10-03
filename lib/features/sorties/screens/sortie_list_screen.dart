import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';
import 'package:ml_pp_mvp/features/sorties/providers/sortie_providers.dart';
import 'package:ml_pp_mvp/shared/utils/date_formatter.dart';
import 'package:ml_pp_mvp/shared/utils/volume_formatter.dart';

class SortieListScreen extends ConsumerWidget {
  const SortieListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sortiesAsync = ref.watch(sortiesListProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Sorties'),
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/sorties/new'),
        child: const Icon(Icons.add),
      ),
      body: sortiesAsync.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('Aucune sortie'));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Propriété')),
                DataColumn(label: Text('Produit')),
                DataColumn(label: Text('Citerne')),
                DataColumn(label: Text('Vol @15°C')),
                DataColumn(label: Text('Vol ambiant')),
                DataColumn(label: Text('Bénéficiaire')),
                DataColumn(label: Text('Actions')),
              ],
              rows: rows.map<DataRow>((r) {
                final date = DateFormatter.formatDate(
                  r['date_sortie'] ?? r['created_at'],
                );
                final prop = (r['proprietaire_type'] ?? 'MONALUXE').toString();
                final prod =
                    '${r['produit_code'] ?? ''} ${r['produit_nom'] ?? ''}'
                        .trim();
                final cit = (r['citerne_nom'] ?? '').toString();
                final v15 = VolumeFormatter.formatVolume(
                  r['volume_corrige_15c'],
                );
                final vAmb = VolumeFormatter.formatVolume(r['volume_ambiant']);
                final benef = r['client_nom'] ?? r['partenaire_nom'] ?? '';

                return DataRow(
                  cells: [
                    DataCell(Text(date)),
                    DataCell(
                      Chip(
                        label: Text(prop),
                        backgroundColor: prop == 'MONALUXE'
                            ? colorScheme.primaryContainer.withOpacity(0.3)
                            : colorScheme.secondaryContainer.withOpacity(0.3),
                      ),
                    ),
                    DataCell(Text(prod)),
                    DataCell(Text(cit)),
                    DataCell(Text(v15)),
                    DataCell(Text(vAmb)),
                    DataCell(
                      benef.isNotEmpty
                          ? Chip(
                              label: Text(benef),
                              avatar: Icon(
                                Icons.person,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              backgroundColor: colorScheme.surfaceVariant
                                  .withOpacity(0.5),
                            )
                          : const Text('—'),
                    ),
                    DataCell(
                      IconButton(
                        onPressed: () {
                          // TODO: Navigation vers détail
                        },
                        icon: Icon(
                          Icons.open_in_new,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
