import 'package:flutter/material.dart';

class FinanceLotFilterValue {
  const FinanceLotFilterValue({
    required this.searchText,
    required this.statutRapprochement,
    required this.statutPaiement,
  });

  final String searchText;
  final String? statutRapprochement;
  final String? statutPaiement;
}

class FinanceLotFilterBar extends StatelessWidget {
  const FinanceLotFilterBar({
    super.key,
    required this.searchController,
    required this.statutRapprochement,
    required this.statutPaiement,
    required this.statutRapprochementOptions,
    required this.statutPaiementOptions,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String? statutRapprochement;
  final String? statutPaiement;
  final List<String> statutRapprochementOptions;
  final List<String> statutPaiementOptions;
  final ValueChanged<FinanceLotFilterValue> onChanged;
  final VoidCallback onClear;

  void _notify() {
    onChanged(
      FinanceLotFilterValue(
        searchText: searchController.text.trim(),
        statutRapprochement: statutRapprochement,
        statutPaiement: statutPaiement,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: (_) => _notify(),
              decoration: const InputDecoration(
                labelText: 'Recherche',
                hintText: 'Facture, référence lot...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: statutRapprochement,
              decoration: const InputDecoration(
                labelText: 'Statut rapprochement',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tous'),
                ),
                ...statutRapprochementOptions.map(
                  (value) => DropdownMenuItem<String?>(value: value, child: Text(value)),
                ),
              ],
              onChanged: (value) {
                onChanged(
                  FinanceLotFilterValue(
                    searchText: searchController.text.trim(),
                    statutRapprochement: value,
                    statutPaiement: statutPaiement,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: statutPaiement,
              decoration: const InputDecoration(
                labelText: 'Statut paiement',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tous'),
                ),
                ...statutPaiementOptions.map(
                  (value) => DropdownMenuItem<String?>(value: value, child: Text(value)),
                ),
              ],
              onChanged: (value) {
                onChanged(
                  FinanceLotFilterValue(
                    searchText: searchController.text.trim(),
                    statutRapprochement: statutRapprochement,
                    statutPaiement: value,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Effacer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
