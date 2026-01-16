/* ===========================================================
   ML_PP MVP — PartenaireAutocomplete
   Rôle: Autocomplete simple pour sélectionner un partenaire
   (id, nom). Remonte l'item sélectionné via callback.
   =========================================================== */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/partenaires_provider.dart';

typedef OnPartenaireSelected = void Function(PartenaireItem item);

class PartenaireAutocomplete extends ConsumerWidget {
  const PartenaireAutocomplete({super.key, required this.onSelected});
  final OnPartenaireSelected onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(partenairesProvider);
    return async.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Erreur partenaires: $e'),
      data: (list) {
        return Autocomplete<PartenaireItem>(
          displayStringForOption: (o) => o.nom,
          optionsBuilder: (text) {
            final q = text.text.toLowerCase();
            if (q.isEmpty) return list;
            return list.where((o) => o.nom.toLowerCase().contains(q));
          },
          onSelected: onSelected,
          fieldViewBuilder: (ctx, ctrl, focus, onSubmit) => TextFormField(
            key: const Key('reception_partenaire_field'),
            controller: ctrl,
            focusNode: focus,
            onFieldSubmitted: (value) => onSubmit(),
            decoration: const InputDecoration(
              labelText: 'Partenaire',
              hintText: 'Rechercher partenaire…',
            ),
          ),
          optionsViewBuilder: (ctx, onSelect, opts) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: SizedBox(
                width: MediaQuery.of(ctx).size.width - 96,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final o in opts)
                      ListTile(title: Text(o.nom), onTap: () => onSelect(o)),
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
