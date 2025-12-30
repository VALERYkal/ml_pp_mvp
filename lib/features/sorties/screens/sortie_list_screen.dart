import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/sorties/providers/sorties_table_provider.dart';
import 'package:ml_pp_mvp/features/sorties/kpi/sorties_kpi_provider.dart';
import 'package:ml_pp_mvp/shared/utils/date_formatter.dart';
import 'package:ml_pp_mvp/shared/utils/volume_formatter.dart';

class SortieListScreen extends ConsumerStatefulWidget {
  const SortieListScreen({super.key});
  @override
  ConsumerState<SortieListScreen> createState() => _SortieListScreenState();
}

class _SortieListScreenState extends ConsumerState<SortieListScreen> {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  bool _sortAsc = false;
  int _sortColumnIndex = 0; // 0: date, 4: vol15

  @override
  Widget build(BuildContext context) {
    final asyncRows = ref.watch(sortiesTableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sorties'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(sortiesTableProvider);
              ref.invalidate(sortiesKpiTodayProvider);
            },
          ),
          IconButton(
            tooltip: 'Nouvelle sortie',
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              context.go('/sorties/new');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/sorties/new'),
        child: const Icon(Icons.add),
      ),
      body: asyncRows.when(
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
                  'Erreur lors du chargement des sorties',
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
                  onPressed: () => ref.invalidate(sortiesTableProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (rows) {
          // État vide
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
                      'Aucune sortie enregistrée',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Commencez par créer une nouvelle sortie',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/sorties/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Créer une sortie'),
                    ),
                  ],
                ),
              ),
            );
          }

          final sorted = [...rows];
          if (_sortColumnIndex == 0) {
            sorted.sort(
              (a, b) =>
                  a.dateSortie.compareTo(b.dateSortie) * (_sortAsc ? 1 : -1),
            );
          } else if (_sortColumnIndex == 4) {
            double v(x) => x.vol15 ?? -1;
            sorted.sort((a, b) => v(a).compareTo(v(b)) * (_sortAsc ? 1 : -1));
          }

          final source = _SortieDataSource(
            context: context,
            rows: sorted,
            onTap: (id) {
              context.go('/sorties/$id');
            },
          );

          // 🚨 PROD-LOCK: Configuration PaginatedDataTable - DO NOT MODIFY
          // Structure UX: PaginatedDataTable avec tri par date et volume 15°C.
          // Colonnes: Date, Propriété, Produit, Citerne, Vol @15°C, Vol ambiant, Bénéficiaire, Actions.
          // Si cette configuration est modifiée, mettre à jour:
          // - Tests UI (sortie_list_screen_test.dart si applicable)
          // - Documentation UX
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PaginatedDataTable(
              header: const Text('Sorties'),
              showCheckboxColumn: false,
              rowsPerPage: _rowsPerPage,
              onRowsPerPageChanged: (v) {
                if (v != null) setState(() => _rowsPerPage = v);
              },
              sortAscending: _sortAsc,
              sortColumnIndex: _sortColumnIndex,
              columns: [
                DataColumn(
                  label: const Text('Date'),
                  onSort: (_, asc) => setState(() {
                    _sortColumnIndex = 0;
                    _sortAsc = asc;
                  }),
                ),
                const DataColumn(label: Text('Propriété')),
                const DataColumn(label: Text('Produit')),
                const DataColumn(label: Text('Citerne')),
                DataColumn(
                  label: const Text('Vol @15°C'),
                  numeric: true,
                  onSort: (_, asc) => setState(() {
                    _sortColumnIndex = 4;
                    _sortAsc = asc;
                  }),
                ),
                const DataColumn(label: Text('Vol ambiant'), numeric: true),
                const DataColumn(label: Text('Bénéficiaire')),
                const DataColumn(label: Text('Actions')),
              ],
              source: source,
            ),
          );
        },
      ),
    );
  }
}

class _SortieDataSource extends DataTableSource {
  final BuildContext context;
  final List<dynamic> rows; // SortieRowVM
  final void Function(String id) onTap;
  _SortieDataSource({
    required this.context,
    required this.rows,
    required this.onTap,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) return null;
    final r = rows[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(_fmtDate(r.dateSortie))),
        DataCell(_MiniChip(r.propriete)),
        DataCell(Text(r.produitLabel)),
        DataCell(Text(r.citerneNom)),
        DataCell(Text(_fmtVol(r.vol15))),
        DataCell(Text(_fmtVol(r.volAmb))),
        DataCell(
          r.beneficiaireNom != null && r.beneficiaireNom!.isNotEmpty
              ? _ModernChip(
                  text: r.beneficiaireNom!,
                  color: r.propriete == 'MONALUXE'
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  icon: r.propriete == 'MONALUXE'
                      ? Icons.person
                      : Icons.business,
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Bénéficiaire inconnu',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                tooltip: 'Voir',
                icon: const Icon(Icons.open_in_new),
                onPressed: () => onTap(r.id),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => rows.length;
  @override
  int get selectedRowCount => 0;
}

String _fmtDate(DateTime d) => DateFormatter.formatDate(d);
String _fmtVol(double? v) => VolumeFormatter.formatVolume(v);

class _MiniChip extends StatelessWidget {
  final String text;
  const _MiniChip(this.text);
  @override
  Widget build(BuildContext context) {
    final isMonaluxe = text == 'MONALUXE';
    final color = isMonaluxe
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMonaluxe ? Icons.person : Icons.business,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _ModernChip({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
