// 📌 Module : Sorties - Providers

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/sortie_service.dart';
import '../data/sortie_draft_service.dart';
import '../models/sortie_produit.dart';
import '../models/citerne_with_stock.dart';

final sortieServiceProvider = Riverpod.Provider<SortieService>((ref) {
  return SortieService(); // Utilise le constructeur par défaut avec Supabase.instance.client
});

final sortieDraftServiceProvider = Riverpod.Provider<SortieDraftService>((ref) {
  return SortieDraftService(Supabase.instance.client);
});

/// Liste des sorties (lecture simple MVP)
final sortiesPageProvider = Riverpod.StateProvider<int>((ref) => 0);
final sortiesPageSizeProvider = Riverpod.StateProvider<int>((ref) => 25);

final sortiesListProvider = Riverpod.FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  try {
    final page = ref.watch(sortiesPageProvider);
    final size = ref.watch(sortiesPageSizeProvider);
    final startIdx = page * size;
    final endIdx = startIdx + size - 1;
    final res = await client
        .from('sorties_produit')
        .select(
          'id, created_at, date_sortie, proprietaire_type, volume_ambiant, volume_corrige_15c, '
          'produits:produit_id(code, nom), citernes:citerne_id(nom), '
          'client:client_id(nom), partenaire:partenaire_id(nom)',
        )
        .order('created_at', ascending: false)
        .range(startIdx, endIdx);

    return (res as List<dynamic>).map<Map<String, dynamic>>((e) {
      final m = e as Map<String, dynamic>;
      final produit = m['produits'] as Map<String, dynamic>?;
      final citerne = m['citernes'] as Map<String, dynamic>?;
      final client = m['client'] as Map<String, dynamic>?;
      final partenaire = m['partenaire'] as Map<String, dynamic>?;

      return {
        ...m,
        'produit_code': produit?['code'] ?? '',
        'produit_nom': produit?['nom'] ?? '',
        'citerne_nom': citerne?['nom'] ?? '',
        'client_nom': client?['nom'] ?? '',
        'partenaire_nom': partenaire?['nom'] ?? '',
      };
    }).toList();
  } on PostgrestException catch (e) {
    debugPrint('❌ sortiesListProvider: ${e.message}');
    rethrow;
  }
});

// Référentiels (réutilisation logique réceptions)
final produitsListProvider = Riverpod.FutureProvider<List<Map<String, String>>>((ref) async {
  final res = await Supabase.instance.client.from('produits').select('id, nom').order('nom');
  final list = (res as List<dynamic>)
      .map(
        (e) => {
          'id': (e as Map<String, dynamic>)['id'] as String,
          'nom': e['nom']?.toString() ?? 'Sans nom',
        },
      )
      .toList();
  return list;
});

final clientsListProvider = Riverpod.FutureProvider<List<Map<String, String>>>((ref) async {
  final res = await Supabase.instance.client.from('clients').select('id, nom').order('nom');
  final list = (res as List<dynamic>)
      .map(
        (e) => {
          'id': (e as Map<String, dynamic>)['id'] as String,
          'nom': e['nom']?.toString() ?? 'Sans nom',
        },
      )
      .toList();
  return list;
});

final partenairesListProvider = Riverpod.FutureProvider<List<Map<String, String>>>((ref) async {
  final res = await Supabase.instance.client.from('partenaires').select('id, nom').order('nom');
  final list = (res as List<dynamic>)
      .map(
        (e) => {
          'id': (e as Map<String, dynamic>)['id'] as String,
          'nom': e['nom']?.toString() ?? 'Sans nom',
        },
      )
      .toList();
  return list;
});

/// Produit par id (nom/code) – pour compatibilité de filtrage citernes
final produitByIdProvider = Riverpod.FutureProvider.family<Map<String, String>?, String>((
  ref,
  produitId,
) async {
  final res = await Supabase.instance.client
      .from('produits')
      .select('id, nom, code')
      .eq('id', produitId)
      .maybeSingle();
  if (res == null) return null;
  final m = res as Map<String, dynamic>;
  return {
    'id': m['id'] as String,
    'nom': (m['nom']?.toString() ?? '').trim(),
    'code': (m['code']?.toString() ?? '').trim(),
  };
});

/// Citernes actives filtrées par produit (stratégie identique à Réception)
final citernesByProduitProvider = Riverpod.FutureProvider.family<List<Map<String, String>>, String>(
  (ref, produitId) async {
    final produit = await ref.read(produitByIdProvider(produitId).future);
    final nom = produit?['nom'] ?? '';
    final code = produit?['code'] ?? '';

    List<dynamic> res1 = [];
    try {
      final q1 = await Supabase.instance.client
          .from('citernes')
          .select('id, nom')
          .eq('statut', 'active')
          .eq('produit_id', produitId)
          .order('nom');
      res1 = q1 as List<dynamic>;
    } catch (_) {}

    List<dynamic> res2 = [];
    if (nom.isNotEmpty || code.isNotEmpty) {
      try {
        final orClause = [
          if (nom.isNotEmpty) 'type_produit.eq.$nom',
          if (code.isNotEmpty) 'type_produit.eq.$code',
        ].join(',');
        if (orClause.isNotEmpty) {
          final q2 = await Supabase.instance.client
              .from('citernes')
              .select('id, nom')
              .eq('statut', 'active')
              .or(orClause)
              .order('nom');
          res2 = q2 as List<dynamic>;
        }
      } catch (_) {}
    }

    final Map<String, String> byId = {};
    for (final e in [...res1, ...res2]) {
      final m = e as Map<String, dynamic>;
      final id = m['id'] as String?;
      if (id != null && !byId.containsKey(id)) {
        byId[id] = m['nom']?.toString() ?? 'Sans nom';
      }
    }
    return byId.entries.map((e) => {'id': e.key, 'nom': e.value}).toList();
  },
);

// --- PROVIDER: CITERNE + DERNIER STOCK via vue stock_actuel ---
final citernesByProduitWithStockProvider =
    Riverpod.FutureProvider.family<List<CiterneWithStockForSortie>, String>((ref, produitId) async {
      if (produitId.isEmpty) return [];

      final supabase = Supabase.instance.client;

      // 1) Citernes du produit
      final citernes =
          await supabase
                  .from('citernes')
                  .select('id, nom, capacite_totale')
                  .eq('produit_id', produitId)
                  .order('nom', ascending: true)
              as List;

      if (citernes.isEmpty) return [];

      final citerneIds = citernes.map((e) => e['id'] as String).toList();

      // 2) Dernier stock par citerne depuis la vue stock_actuel
      final stocks =
          await supabase
                  .from('stock_actuel')
                  .select('citerne_id, stock_ambiant, stock_15c, date_jour')
                  .in_('citerne_id', citerneIds)
                  .eq('produit_id', produitId)
              as List;

      final byCiterne = {for (final s in stocks) (s['citerne_id'] as String): s};

      // 3) Assemblage UI
      DateTime? _parseDate(dynamic d) {
        if (d == null) return null;
        try {
          return DateTime.parse(d.toString());
        } catch (_) {
          return null;
        }
      }

      return citernes.map((c) {
        final cid = c['id'] as String;
        final s = byCiterne[cid];
        return CiterneWithStockForSortie(
          id: cid,
          nom: (c['nom'] as String?) ?? 'Citerne',
          capaciteTotale: (c['capacite_totale'] as num?)?.toDouble(),
          stockAmbiant: (s?['stock_ambiant'] as num?)?.toDouble(),
          stock15c: (s?['stock_15c'] as num?)?.toDouble(),
          date: _parseDate(s?['date_jour']),
        );
      }).toList();
    });
