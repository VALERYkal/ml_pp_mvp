/* ===========================================================
   ML_PP MVP — CoursArriveSelector
   Rôle: Autocomplete lisible pour choisir un cours_de_route
   au statut "arrivé". Une fois choisi, on remonte (id, produitCode).
   =========================================================== */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/cours_arrives_provider.dart';

typedef OnCoursSelected = void Function(CoursArriveItem item);

class CoursArriveSelector extends ConsumerStatefulWidget {
  const CoursArriveSelector({super.key, required this.onSelected});
  final OnCoursSelected onSelected;

  @override
  ConsumerState<CoursArriveSelector> createState() =>
      _CoursArriveSelectorState();
}

class _CoursArriveSelectorState extends ConsumerState<CoursArriveSelector> {
  CoursArriveItem? selected;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coursArrivesProvider);

    return async.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Erreur chargement cours: $e'),
      data: (list) {
        return Autocomplete<CoursArriveItem>(
          displayStringForOption: (o) => '${o.title} — ${o.subtitle}',
          optionsBuilder: (text) {
            final q = text.text.toLowerCase();
            if (q.isEmpty) return list;
            return list.where((o) {
              final hay = [
                o.title,
                o.subtitle,
                o.fournisseurNom ?? '',
                o.transporteur ?? '',
                o.chauffeur ?? '',
                o.plaqueCamion ?? '',
                o.produitCode,
                o.produitNom,
                o.departPays ?? '',
              ].join(' ').toLowerCase();
              return hay.contains(q);
            });
          },
          onSelected: (item) {
            setState(() => selected = item);
            widget.onSelected(item);
          },
          fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
            return TextField(
              controller: ctrl,
              focusNode: focus,
              decoration: const InputDecoration(
                labelText: 'Cours de route (statut "arrivé")',
                hintText:
                    'Rechercher par date, fournisseur, transporteur, plaque…',
              ),
            );
          },
          optionsViewBuilder: (ctx, onSelect, opts) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: SizedBox(
                width: MediaQuery.of(ctx).size.width - 96,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row
                    Container(
                      color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: const [
                          Expanded(flex: 14, child: Text('Date chargement')),
                          Expanded(flex: 24, child: Text('Fournisseur')),
                          Expanded(flex: 14, child: Text('Volume')),
                          Expanded(flex: 18, child: Text('Produit')),
                          Expanded(flex: 10, child: Text('Origine')),
                          Expanded(flex: 18, child: Text('Transporteur')),
                          Expanded(flex: 14, child: Text('Chauffeur')),
                          Expanded(flex: 12, child: Text('Plaque')),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: opts.map((o) {
                          final dateStr = o.dateChargement
                              .toIso8601String()
                              .split('T')
                              .first;
                          final prod =
                              '${o.produitNom.isNotEmpty ? o.produitNom : ''}${o.produitNom.isNotEmpty ? ' / ' : ''}${o.produitCode}';
                          final volStr = o.volume == null
                              ? '-'
                              : '${o.volume} L';
                          return InkWell(
                            onTap: () => onSelect(o),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(flex: 14, child: Text(dateStr)),
                                  Expanded(
                                    flex: 24,
                                    child: Text(o.fournisseurNom ?? '-'),
                                  ),
                                  Expanded(flex: 14, child: Text(volStr)),
                                  Expanded(flex: 18, child: Text(prod)),
                                  Expanded(
                                    flex: 10,
                                    child: Text(o.departPays ?? '-'),
                                  ),
                                  Expanded(
                                    flex: 18,
                                    child: Text(o.transporteur ?? '-'),
                                  ),
                                  Expanded(
                                    flex: 14,
                                    child: Text(o.chauffeur ?? '-'),
                                  ),
                                  Expanded(
                                    flex: 12,
                                    child: Text(o.plaqueCamion ?? '-'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
