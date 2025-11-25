// ?? Module : Réceptions - Providers

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/reception_service.dart';
import '../data/reception_input.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;

final receptionServiceProvider = Provider<ReceptionService>((ref) {
  final refRepo = ref.read(refs.referentielsRepoProvider);
  return ReceptionService.withClient(
    Supabase.instance.client,
    refRepo: refRepo,
  );
});

final createReceptionProvider = FutureProvider.family<String, ReceptionInput>((
  ref,
  input,
) async {
  final service = ref.read(receptionServiceProvider);
  final id = await service.createDraft(input);
  return id;
});

/// Référentiels en ligne (MVP)
final produitsListProvider = FutureProvider<List<Map<String, String>>>((
  ref,
) async {
  final res = await Supabase.instance.client
      .from('produits')
      .select('id, nom')
      .order('nom');
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

/// Récupère le produit par id (nom/code) pour compatibilité schémas
final produitByIdProvider = FutureProvider.family<Map<String, String>?, String>(
  (ref, produitId) async {
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
  },
);

final citernesByProduitProvider =
    FutureProvider.family<List<Map<String, String>>, String>((
      ref,
      produitId,
    ) async {
      final produit = await ref.read(produitByIdProvider(produitId).future);
      final nom = produit?['nom'] ?? '';
      final code = produit?['code'] ?? '';

      // Stratégie compat: récupérer citernes actives et filtrer côté serveur au mieux
      // 1) citernes.produit_id = produitId
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

      // 2) citernes.type_produit = nom OR code (si colonne existe côté DB)
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

      // Fusion distincte par id
      final Map<String, String> byId = {};
      for (final e in [...res1, ...res2]) {
        final m = e as Map<String, dynamic>;
        final id = m['id'] as String?;
        if (id != null && !byId.containsKey(id)) {
          byId[id] = m['nom']?.toString() ?? 'Sans nom';
        }
      }
      return byId.entries.map((e) => {'id': e.key, 'nom': e.value}).toList();
    });

/// Partenaires (référentiel lecture seule)
final partenairesListProvider = FutureProvider<List<Map<String, String>>>((
  ref,
) async {
  final res = await Supabase.instance.client
      .from('partenaires')
      .select('id, nom')
      .order('nom');
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

