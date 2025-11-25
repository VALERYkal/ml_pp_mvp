/* ===========================================================
   ML_PP MVP  Référentiels (cache mémoire)
   Rôle: Charger 1x les produits (id, code, nom) & citernes
   actives (id, produit_id, capacités, statut) puis offrir
   des utilitaires de lookup sans requêtes répétées.
   =========================================================== */
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  CiterneRef({
    required this.id,
    required this.nom,
    required this.produitId,
    required this.capaciteTotale,
    required this.capaciteSecurite,
    required this.statut,
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
    final rows = await client.from('produits').select('id, code, nom, actif').eq('actif', true);
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
        .select('id, nom, produit_id, capacite_totale, capacite_securite, statut')
        .eq('statut', 'active');
    _citernes = (rows as List)
        .map(
          (m) => CiterneRef(
            id: m['id'] as String,
            nom: (m['nom'] ?? '') as String,
            produitId: m['produit_id'] as String,
            capaciteTotale: (m['capacite_totale'] as num).toDouble(),
            capaciteSecurite: (m['capacite_securite'] as num).toDouble(),
            statut: (m['statut'] ?? 'inactive') as String,
          ),
        )
        .toList();
    return _citernes!;
  }

  /// Patch mineur  lookup produit par code
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
final referentielsRepoProvider = Provider<ReferentielsRepo>((ref) {
  return ReferentielsRepo(Supabase.instance.client);
});

final produitsRefProvider = FutureProvider<List<ProduitRef>>((ref) async {
  return ref.read(referentielsRepoProvider).loadProduits();
});

final citernesActivesProvider = FutureProvider<List<CiterneRef>>((ref) async {
  return ref.read(referentielsRepoProvider).loadCiternesActives();
});




