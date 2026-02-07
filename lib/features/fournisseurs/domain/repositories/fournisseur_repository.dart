import '../models/fournisseur.dart';

/// Repository lecture seule pour le référentiel fournisseurs.
/// Sprint 1 : aucune mutation (create/update/delete).
abstract class FournisseurRepository {
  /// Récupère tous les fournisseurs (tri côté DB par nom).
  /// Extensible pour pagination future (profil M).
  Future<List<Fournisseur>> fetchAllFournisseurs();

  /// Récupère un fournisseur par id, ou null si absent.
  Future<Fournisseur?> getById(String id);
}
