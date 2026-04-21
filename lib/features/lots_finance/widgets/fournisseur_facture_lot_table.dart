import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_currency_format.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_status_badges.dart';

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
                DataColumn(label: Text('Facture')),
                DataColumn(label: Text('Référence lot')),
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
                        DataCell(Text(formatUsd(item.montantTotalUsd))),
                        DataCell(Text(formatUsd(item.montantRegleUsd))),
                        DataCell(Text(formatUsd(item.soldeRestantUsd))),
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
