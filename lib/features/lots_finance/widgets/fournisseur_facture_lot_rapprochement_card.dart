import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_status_badges.dart';
import 'package:ml_pp_mvp/shared/ui/format.dart';

class FournisseurFactureLotRapprochementCard extends StatelessWidget {
  const FournisseurFactureLotRapprochementCard({super.key, required this.facture});

  final FournisseurFactureLot facture;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rapprochement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text('Total volume 15°C: ${fmtVolume(facture.totalVolume15c)}'),
            const SizedBox(height: 6),
            Text('Total volume 20°C: ${fmtVolume(facture.totalVolume20c)}'),
            const SizedBox(height: 6),
            Text(
              'Quantité facturée 20°C: ${fmtVolume(facture.quantiteFacturee20c)}',
            ),
            const SizedBox(height: 6),
            Text('Écart volume 20°C: ${fmtVolume(facture.ecartVolume20c)}'),
            const SizedBox(height: 10),
            StatutRapprochementBadge(statut: facture.statutRapprochement),
          ],
        ),
      ),
    );
  }
}
