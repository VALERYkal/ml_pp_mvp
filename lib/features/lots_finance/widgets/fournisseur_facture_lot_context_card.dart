import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';

class FournisseurFactureLotContextCard extends StatelessWidget {
  const FournisseurFactureLotContextCard({
    super.key,
    required this.facture,
    this.lotReference,
    this.produitLabel,
    this.fournisseurLabel,
  });

  final FournisseurFactureLot facture;
  final String? lotReference;
  final String? produitLabel;
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
            Text('Contexte lot', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Référence lot: ${lotReference ?? facture.fournisseurLotId}'),
            if (produitLabel != null) ...[
              const SizedBox(height: 6),
              Text('Produit: $produitLabel'),
            ],
            if (fournisseurLabel != null) ...[
              const SizedBox(height: 6),
              Text('Fournisseur: $fournisseurLabel'),
            ],
            const SizedBox(height: 6),
            Text(
              'Nombre de réceptions: ${facture.nbReceptions?.toString() ?? '—'}',
            ),
          ],
        ),
      ),
    );
  }
}
