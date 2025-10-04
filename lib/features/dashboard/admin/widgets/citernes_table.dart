import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/citernes_sous_seuil_provider.dart';
import '../../../../shared/ui/async_view.dart';

class CiternesSousSeuilTable extends ConsumerWidget {
  const CiternesSousSeuilTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(citernesSousSeuilProvider);
    return AsyncView(
      state: state,
      builder: (rows) => DataTable(
        columns: const [
          DataColumn(label: Text('Citerne')),
          DataColumn(label: Text('Stock')),
          DataColumn(label: Text('Seuil')),
          DataColumn(label: Text('Ratio')),
          DataColumn(label: Text('Action')),
        ],
        rows: rows.map((r) {
          final ratio = r.seuil > 0 ? (r.stock / r.seuil) : 1.0;
          final color = ratio < 0.6 ? Colors.red : (ratio < 1.0 ? Colors.orange : Colors.green);
          return DataRow(
            cells: [
              DataCell(Text(r.nom)),
              DataCell(Text(r.stock.toStringAsFixed(0))),
              DataCell(Text(r.seuil.toStringAsFixed(0))),
              DataCell(
                Text('${(ratio * 100).toStringAsFixed(0)} %', style: TextStyle(color: color)),
              ),
              DataCell(
                TextButton(
                  onPressed: () {
                    // TODO: context.go('/citernes/${r.id}');
                  },
                  child: const Text('Voir'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
