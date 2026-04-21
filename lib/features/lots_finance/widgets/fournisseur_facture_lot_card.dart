import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_currency_format.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_status_badges.dart';

class FournisseurFactureLotCard extends StatelessWidget {
  const FournisseurFactureLotCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final FournisseurFactureLot item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.invoiceNo, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(item.dealReference ?? '—'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatutRapprochementBadge(statut: item.statutRapprochement),
                  StatutPaiementBadge(statut: item.statutPaiement),
                ],
              ),
              const SizedBox(height: 12),
              Text('Montant total: ${formatUsd(item.montantTotalUsd)}'),
              const SizedBox(height: 4),
              Text('Montant réglé: ${formatUsd(item.montantRegleUsd)}'),
              const SizedBox(height: 4),
              Text('Solde: ${formatUsd(item.soldeRestantUsd)}'),
            ],
          ),
        ),
      ),
    );
  }
}
