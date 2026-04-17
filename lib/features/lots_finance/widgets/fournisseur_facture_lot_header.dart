import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_status_badges.dart';
import 'package:ml_pp_mvp/shared/ui/format.dart';

class FournisseurFactureLotHeader extends StatelessWidget {
  const FournisseurFactureLotHeader({
    super.key,
    required this.facture,
    this.lotReference,
    this.fournisseurLabel,
  });

  final FournisseurFactureLot facture;
  final String? lotReference;
  final String? fournisseurLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(facture.invoiceNo, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Deal reference: ${facture.dealReference ?? '—'}'),
            const SizedBox(height: 6),
            Text('Référence lot: ${lotReference ?? facture.fournisseurLotId}'),
            const SizedBox(height: 6),
            Text('Fournisseur: ${fournisseurLabel ?? '—'}'),
            const SizedBox(height: 6),
            Text('Date facture: ${fmtDate(facture.dateFacture)}'),
            const SizedBox(height: 6),
            Text('Échéance: ${fmtDate(facture.dateEcheance)}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatutPaiementBadge(statut: facture.statutPaiement),
                StatutRapprochementBadge(statut: facture.statutRapprochement),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
