import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

class RefDataCache {
  final Map<String, String> fournisseurs; // id -> nom
  final Map<String, String> produits; // id -> nom
  final Map<String, String> produitCodes; // id -> code
  final Map<String, String> depots; // id -> nom
  final DateTime loadedAt;
  const RefDataCache({
    required this.fournisseurs,
    required this.produits,
    required this.produitCodes,
    required this.depots,
    required this.loadedAt,
  });
}

final refDataProvider = Riverpod.FutureProvider<RefDataCache>((ref) async {
  final client = Supabase.instance.client;
  try {
    final now = DateTime.now();
    final fournisseursRes = await client
        .from('fournisseurs')
        .select('id, nom')
        .order('nom');
    final produitsRes = await client
        .from('produits')
        .select('id, nom, code')
        .order('nom');
    final depotsRes = await client
        .from('depots')
        .select('id, nom')
        .order('nom');
    final fournisseurs = <String, String>{
      for (final e in fournisseursRes)
        (e['id'] as String): _bestLabel([
          e['nom']?.toString(),
        ], fallback: 'Fournisseur'),
    };
    final produits = <String, String>{
      for (final e in produitsRes)
        (e['id'] as String): _bestLabel([
          e['nom']?.toString(),
        ], fallback: 'Produit'),
    };
    final produitCodes = <String, String>{
      for (final e in produitsRes)
        (e['id'] as String): (e['code']?.toString() ?? '').trim(),
    };
    final depots = <String, String>{
      for (final e in depotsRes)
        (e['id'] as String): _bestLabel([
          e['nom']?.toString(),
        ], fallback: 'Dépôt'),
    };
    return RefDataCache(
      fournisseurs: fournisseurs,
      produits: produits,
      produitCodes: produitCodes,
      depots: depots,
      loadedAt: now,
    );
  } catch (e) {
    debugPrint('❌ refDataProvider load error: $e');
    rethrow;
  }
});

String resolveName(RefDataCache cache, String id, String type) {
  if (id.isEmpty) {
    return '—';
  }
  final key = id.trim();
  switch (type) {
    case 'fournisseur':
      return cache.fournisseurs[key] ??
          _findByPrefix(cache.fournisseurs, key) ??
          _shortId(key);
    case 'produit':
      final byId = cache.produits[key] ?? _findByPrefix(cache.produits, key);
      if (byId != null) {
        return byId;
      }
      // Fallback via code connu si l'id existe dans le mapping des codes
      final code =
          cache.produitCodes[key] ?? _findCodeByPrefix(cache.produitCodes, key);
      if (code != null && code.isNotEmpty) {
        switch (code.toUpperCase()) {
          case 'ESS':
            return 'Essence';
          case 'G.O':
          case 'GO':
            return 'Gasoil / AGO';
          default:
            return code; // comme dernier recours, afficher le code
        }
      }
      // Fallback ultime: deux produits connus par UUID/prefixe
      if (_matchesIdOrPrefix(key, '640cf7ec-1616-4503-a484-0a61afb20005')) {
        return 'Essence';
      }
      if (_matchesIdOrPrefix(key, '452b557c-e974-4315-b6c2-cda8487db428')) {
        return 'Gasoil / AGO';
      }
      return _shortId(key);
    default:
      return '—';
  }
}

/// Extension pour accès map des produits par ID (non cassant)
extension RefDataLookups on RefDataCache {
  Map<String, String> get produitsById => produits;

  Map<String, String> get produitsByCode => produitCodes;
}

Iterable<MapEntry<String, String>> searchFournisseurs(
  RefDataCache cache,
  String query,
) {
  final q = _normalize(query);
  return cache.fournisseurs.entries.where(
    (e) => _normalize(e.value).contains(q),
  );
}

String _normalize(String s) => s.toLowerCase();

String _shortId(String id) => id.length > 6 ? id.substring(0, 6) : id;

String _bestLabel(List<String?> candidates, {required String fallback}) {
  for (final c in candidates) {
    final v = (c ?? '').trim();
    if (v.isNotEmpty) {
      return v;
    }
  }
  return fallback;
}

String? _findByPrefix(Map<String, String> map, String key) {
  final k = key.toLowerCase();
  // Match if incoming key is a short prefix of UUID or vice versa
  for (final entry in map.entries) {
    final mk = entry.key.toLowerCase();
    if (mk.startsWith(k) || k.startsWith(mk)) {
      return entry.value;
    }
    // Match on first 6 chars
    final mks = mk.length >= 6 ? mk.substring(0, 6) : mk;
    final ks = k.length >= 6 ? k.substring(0, 6) : k;
    if (mks == ks) {
      return entry.value;
    }
  }
  return null;
}

/// Trouve un code produit (id -> code) par préfixe d'UUID
String? _findCodeByPrefix(Map<String, String> idToCode, String key) {
  final k = key.toLowerCase();
  for (final entry in idToCode.entries) {
    final mk = entry.key.toLowerCase();
    if (mk.startsWith(k) || k.startsWith(mk)) {
      return entry.value;
    }
    final mks = mk.length >= 6 ? mk.substring(0, 6) : mk;
    final ks = k.length >= 6 ? k.substring(0, 6) : k;
    if (mks == ks) {
      return entry.value;
    }
  }
  return null;
}

bool _matchesIdOrPrefix(String key, String fullId) {
  final k = key.toLowerCase();
  final fid = fullId.toLowerCase();
  if (k == fid) {
    return true;
  }
  if (fid.startsWith(k) || k.startsWith(fid)) {
    return true;
  }
  final ks = k.length >= 6 ? k.substring(0, 6) : k;
  final fids = fid.length >= 6 ? fid.substring(0, 6) : fid;
  return ks == fids;
}
