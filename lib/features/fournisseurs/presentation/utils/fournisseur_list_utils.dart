// Filtre et tri client-side (fonctions pures, testables sans Supabase).

import '../../domain/models/fournisseur.dart';

/// Filtre client-side multi-champs (nom, pays, contact_personne).
/// Case-insensitive, ignore nulls.
List<Fournisseur> filterFournisseurs(
  List<Fournisseur> list,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return List.from(list);
  }
  return list.where((f) {
    if ((f.nom).toLowerCase().contains(q)) {
      return true;
    }
    if (f.pays != null && (f.pays!).toLowerCase().contains(q)) {
      return true;
    }
    if (f.contactPersonne != null &&
        (f.contactPersonne!).toLowerCase().contains(q)) {
      return true;
    }
    return false;
  }).toList();
}

/// Tri client-side par nom uniquement. [asc] true = A→Z, false = Z→A.
List<Fournisseur> sortFournisseursByNom(
  List<Fournisseur> list,
  bool asc,
) {
  final copy = List<Fournisseur>.from(list);
  copy.sort((a, b) {
    final cmp = (a.nom).compareTo(b.nom);
    return asc ? cmp : -cmp;
  });
  return copy;
}
