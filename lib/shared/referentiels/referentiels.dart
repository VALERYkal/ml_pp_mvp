/* ===========================================================
   ML_PP MVP — Référentiels (cache mémoire)
   Rôle: Charger 1x les produits (id, code, nom) & citernes
   actives (id, produit_id, capacités, statut) puis offrir
   des utilitaires de lookup sans requêtes répétées.
   =========================================================== */
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;

class ProduitRef {
  final String id;
  final String code;
  final String nom;
  ProduitRef({required this.id, required this.code, required this.nom});
}

class CiterneRef {
  final String id;
  final String nom;
  final String produitId;
  final double capaciteTotale;
  final double capaciteSecurite;
  final String statut; // 'active' | 'inactive' | 'maintenance'
  final String depotId;
  final String depotNom;
  CiterneRef({
    required this.id,
    required this.nom,
    required this.produitId,
    required this.capaciteTotale,
    required this.capaciteSecurite,
    required this.statut,
    required this.depotId,
    required this.depotNom,
  });
}

class ReferentielsRepo {
  ReferentielsRepo(this.client);
  final SupabaseClient client;

  List<ProduitRef>? _produits;
  List<CiterneRef>? _citernes;

  /// Charge les produits actifs (id, code, nom). Mémoïsé.
  Future<List<ProduitRef>> loadProduits() async {
    if (_produits != null) return _produits!;
    final rows = await client
        .from('produits')
        .select('id, code, nom, actif')
        .eq('actif', true);
    _produits = (rows as List)
        .map(
          (m) => ProduitRef(
            id: m['id'] as String,
            code: (m['code'] ?? '') as String,
            nom: (m['nom'] ?? '') as String,
          ),
        )
        .toList();
    return _produits!;
  }

  /// Charge les citernes actives (strict) avec produit_id. Mémoïsé.
  Future<List<CiterneRef>> loadCiternesActives() async {
    if (_citernes != null) return _citernes!;
    final rows = await client
        .from('citernes')
        .select(
          'id, nom, produit_id, capacite_totale, capacite_securite, statut, depot_id, depots(nom)',
        )
        .eq('statut', 'active');
    final list = (rows as List)
        .map(
          (m) => CiterneRef(
            id: m['id'] as String,
            nom: (m['nom'] ?? '') as String,
            produitId: m['produit_id'] as String,
            capaciteTotale: (m['capacite_totale'] as num).toDouble(),
            capaciteSecurite: (m['capacite_securite'] as num).toDouble(),
            statut: (m['statut'] ?? 'inactive') as String,
            depotId: (m['depot_id'] as String?) ?? '',
            depotNom:
                ((m['depots'] as Map<String, dynamic>?)?['nom'] as String?) ??
                    '',
          ),
        )
        .toList();
    // Trier les citernes par dépôt puis par ordre naturel des noms
    _citernes = sortCiternesHuman(list);
    return _citernes!;
  }

  /// Patch mineur — lookup produit par code
  /// Pédagogie: on évite l'usage null-aware sur String non-nullable
  /// et on compare en uppercase pour la robustesse.
  String? getProduitIdByCodeSync(String code) {
    final list = _produits;
    if (list == null) return null;
    final up = code.toUpperCase();
    for (final p in list) {
      if (p.code.toUpperCase() == up) return p.id;
    }
    return null;
  }

  /// Vérifie si une citerne 'id' est active (dans le cache courant).
  bool isCiterneActiveSync(String id) {
    final list = _citernes;
    if (list == null) return false;
    final match = list.where((c) => c.id == id);
    if (match.isEmpty) return false;
    return match.first.statut == 'active';
  }

  /// Compatibilité stricte: produit de la citerne == produit_id sélectionné.
  bool isProduitCompatible(String citerneId, String produitId) {
    final list = _citernes;
    if (list == null) return false;
    final match = list.where((c) => c.id == citerneId);
    if (match.isEmpty) return false;
    return match.first.produitId == produitId;
  }
}

// Providers Riverpod (additifs)
final referentielsRepoProvider = Riverpod.Provider<ReferentielsRepo>((ref) {
  return ReferentielsRepo(Supabase.instance.client);
});

final produitsRefProvider = Riverpod.FutureProvider<List<ProduitRef>>((
  ref,
) async {
  return ref.read(referentielsRepoProvider).loadProduits();
});

final citernesActivesProvider = Riverpod.FutureProvider<List<CiterneRef>>((
  ref,
) async {
  return ref.read(referentielsRepoProvider).loadCiternesActives();
});

// ════════════════════════════════════════════════════════════════════════════
// Helpers de tri naturel pour citernes (exportés pour tests)
// ════════════════════════════════════════════════════════════════════════════

/// Extrait le nombre en fin de chaîne (ex: "TANK10" → 10, "TANK" → null)
int? _extractTrailingInt(String s) {
  final match = RegExp(r'(\d+)\s*$').firstMatch(s.toUpperCase().trim());
  if (match == null) return null;
  return int.tryParse(match.group(1) ?? '');
}

/// Clé de tri naturelle pour nom de citerne
/// - Contient "STAGING" ou "TEST" → 1000000 (pousse à la fin)
/// - Chiffre trailing → retourne ce chiffre (TANK10 → 10)
/// - Sinon → 900000 (tri alphabétique après numérotées)
int _naturalTankKey(String nom) {
  final upper = nom.toUpperCase().trim();
  if (upper.contains('STAGING') || upper.contains('TEST')) {
    return 1000000;
  }
  final trailingInt = _extractTrailingInt(nom);
  if (trailingInt != null) {
    return trailingInt;
  }
  return 900000;
}

/// Tri humain pour les citernes :
/// 1. Par nom de dépôt (alphabétique, insensible à la casse)
/// 2. Par clé naturelle du nom (TANK1 < TANK2 < TANK10)
/// 3. Par nom alphabétique (tie-break)
int _compareCiternes(CiterneRef a, CiterneRef b) {
  // 1. Comparer par nom de dépôt
  final depotCompare =
      a.depotNom.toUpperCase().compareTo(b.depotNom.toUpperCase());
  if (depotCompare != 0) return depotCompare;

  // 2. Comparer par clé naturelle
  final keyA = _naturalTankKey(a.nom);
  final keyB = _naturalTankKey(b.nom);
  final keyCompare = keyA.compareTo(keyB);
  if (keyCompare != 0) return keyCompare;

  // 3. Tie-break : tri alphabétique sur nom
  return a.nom.toUpperCase().compareTo(b.nom.toUpperCase());
}

/// Fonction publique pour trier les citernes (exportée pour tests)
List<CiterneRef> sortCiternesHuman(List<CiterneRef> input) {
  final list = List<CiterneRef>.from(input);
  list.sort(_compareCiternes);
  return list;
}
