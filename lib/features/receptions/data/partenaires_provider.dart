/* ===========================================================
   ML_PP MVP — partenaires_provider.dart
   Rôle: Exposer une liste de partenaires (id, nom) pour
   l'autocomplete côté UI. Lecture seule.
   =========================================================== */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartenaireItem {
  final String id;
  final String nom;
  const PartenaireItem({required this.id, required this.nom});
  @override
  String toString() => nom;
}

final partenairesProvider = FutureProvider<List<PartenaireItem>>((ref) async {
  final client = Supabase.instance.client;
  final rows = await client.from('partenaires').select('id, nom').order('nom');
  return (rows as List)
      .map(
        (m) => PartenaireItem(
          id: m['id'] as String,
          nom: (m['nom']?.toString() ?? '').trim(),
        ),
      )
      .toList();
});
