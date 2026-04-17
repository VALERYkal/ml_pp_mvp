import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_status_badges.dart';

String _fmtUsd(double value) => '${value.toStringAsFixed(2)} USD';

class FournisseurFactureLotAmountsCard extends StatelessWidget {
  const FournisseurFactureLotAmountsCard({super.key, required this.facture});

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
            Text('Montants', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Montant total: ${_fmtUsd(facture.montantTotalUsd)}'),
            const SizedBox(height: 6),
            Text('Montant réglé: ${_fmtUsd(facture.montantRegleUsd)}'),
            const SizedBox(height: 6),
            Text('Solde restant: ${_fmtUsd(facture.soldeRestantUsd)}'),
            const SizedBox(height: 10),
            StatutPaiementBadge(statut: facture.statutPaiement),
          ],
        ),
      ),
    );
  }
}
