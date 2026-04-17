import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_status_badges.dart';

String _fmtUsd(double value) => '${value.toStringAsFixed(2)} USD';

class FournisseurFactureLotTable extends StatelessWidget {
  const FournisseurFactureLotTable({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<FournisseurFactureLot> items;
  final ValueChanged<FournisseurFactureLot> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Invoice')),
                DataColumn(label: Text('Deal reference')),
                DataColumn(label: Text('Rapprochement')),
                DataColumn(label: Text('Montant total')),
                DataColumn(label: Text('Montant réglé')),
                DataColumn(label: Text('Solde')),
                DataColumn(label: Text('Paiement')),
              ],
              rows: items
                  .map(
                    (item) => DataRow(
                      onSelectChanged: (_) => onTap(item),
                      cells: [
                        DataCell(Text(item.invoiceNo)),
                        DataCell(Text(item.dealReference ?? '—')),
                        DataCell(
                          StatutRapprochementBadge(
                            statut: item.statutRapprochement,
                          ),
                        ),
                        DataCell(Text(_fmtUsd(item.montantTotalUsd))),
                        DataCell(Text(_fmtUsd(item.montantRegleUsd))),
                        DataCell(Text(_fmtUsd(item.soldeRestantUsd))),
                        DataCell(
                          StatutPaiementBadge(statut: item.statutPaiement),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
