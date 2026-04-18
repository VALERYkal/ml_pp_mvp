import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/finance_lot_currency_format.dart';
import 'package:ml_pp_mvp/shared/ui/format.dart';

class FournisseurPaiementListItem {
  const FournisseurPaiementListItem({
    required this.datePaiement,
    required this.montantUsd,
    required this.modePaiement,
    required this.reference,
    required this.note,
  });

  final DateTime? datePaiement;
  final double montantUsd;
  final String? modePaiement;
  final String? reference;
  final String? note;
}

class FournisseurPaiementsList extends StatelessWidget {
  const FournisseurPaiementsList({
    super.key,
    required this.paiements,
    this.totalPayeUsd,
  });

  final List<FournisseurPaiementListItem> paiements;
  final double? totalPayeUsd;

  String get _title {
    if (totalPayeUsd == null) return 'Paiements';
    return 'Paiements (Total: ${formatUsd(totalPayeUsd!)})';
  }

  @override
  Widget build(BuildContext context) {
    if (paiements.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              const Text('Aucun paiement enregistré pour cette facture.'),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...paiements.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(formatUsd(item.montantUsd)),
                subtitle: Text(
                  'Date: ${fmtDate(item.datePaiement)}'
                  ' · Mode: ${(item.modePaiement ?? '—').trim().isEmpty ? '—' : item.modePaiement}'
                  ' · Réf: ${(item.reference ?? '—').trim().isEmpty ? '—' : item.reference}',
                ),
                trailing: item.note == null || item.note!.trim().isEmpty
                    ? null
                    : Tooltip(
                        message: item.note!.trim(),
                        child: const Icon(Icons.notes_outlined),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
