import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/receptions/providers/receptions_table_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reception.dart';
import 'package:ml_pp_mvp/shared/utils/date_formatter.dart';
import 'package:ml_pp_mvp/shared/utils/volume_formatter.dart';

// Providers extraits vers features/receptions/providers/receptions_list_provider.dart

class ReceptionListScreen extends ConsumerStatefulWidget {
  const ReceptionListScreen({super.key});
  @override
  ConsumerState<ReceptionListScreen> createState() =>
      _ReceptionListScreenState();
}

class _ReceptionListScreenState extends ConsumerState<ReceptionListScreen> {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  bool _sortAsc = false;
  int _sortColumnIndex = 0; // 0: date, 4: vol15

  @override
  Widget build(BuildContext context) {
    final asyncRows = ref.watch(receptionsTableProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Réceptions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/receptions/new'),
        child: const Icon(Icons.add),
      ),
      body: asyncRows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Erreur chargement: $e'),
        ),
        data: (rows) {
          final sorted = [...rows];
          if (_sortColumnIndex == 0) {
            sorted.sort(
              (a, b) =>
                  a.dateReception.compareTo(b.dateReception) *
                  (_sortAsc ? 1 : -1),
            );
          } else if (_sortColumnIndex == 4) {
            double v(x) => x.vol15 ?? -1;
            sorted.sort((a, b) => v(a).compareTo(v(b)) * (_sortAsc ? 1 : -1));
          }

          final source = _ReceptionDataSource(
            context: context,
            rows: sorted,
            onTap: (id) => context.go('/receptions/$id'),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PaginatedDataTable(
              header: const Text('Réceptions'),
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
                const DataColumn(label: Text('CDR')),
                const DataColumn(label: Text('Fournisseur')),
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

class _ReceptionDataSource extends DataTableSource {
  final BuildContext context;
  final List<dynamic> rows; // ReceptionRowVM
  final void Function(String id) onTap;
  _ReceptionDataSource({
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
        DataCell(Text(_fmtDate(r.dateReception))),
        DataCell(_MiniChip(r.propriete)),
        DataCell(Text(r.produitLabel)),
        DataCell(Text(r.citerneNom)),
        DataCell(Text(_fmtVol(r.vol15))),
        DataCell(Text(_fmtVol(r.volAmb))),
        DataCell(Text(_cdrCell(r))),
        DataCell(
          r.fournisseurNom != null && r.fournisseurNom!.isNotEmpty
              ? _ModernChip(
                  text: r.fournisseurNom!,
                  color: Theme.of(context).colorScheme.tertiary,
                  icon: Icons.business,
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Fournisseur inconnu',
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

  String _cdrCell(dynamic r) {
    if (r.cdrShort == null) return '—';
    final plaque = (r.cdrPlaques ?? '').isNotEmpty ? ' · ${r.cdrPlaques}' : '';
    return '${r.cdrShort}$plaque';
  }
}

String _fmtDate(DateTime d) => DateFormatter.formatDate(d);
String _fmtVol(double? v) => VolumeFormatter.formatVolume(v);

class _MiniChip extends StatelessWidget {
  final String text;
  const _MiniChip(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ModernChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _ModernChip({
    required this.text,
    required this.color,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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
