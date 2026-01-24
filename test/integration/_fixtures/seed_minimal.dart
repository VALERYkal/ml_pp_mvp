import 'package:supabase_flutter/supabase_flutter.dart';

import 'fixture_ids.dart';

/// Seed minimal : dépôt + produit + citerne (IDs fixes du seed staging)
///
/// ⚠️ NOTE : Cette fonction utilise les IDs centralisés dans `_staging_fixtures.dart`.
/// Elle crée idempotemment les entités référentielles nécessaires pour les tests.
Future<void> seedMinimal({
  required SupabaseClient client,
  required FixtureIds ids,
}) async {
  // Les IDs sont fixes et doivent déjà exister via seed_staging_minimal_v2.sql
  // On vérifie juste qu'ils existent, sinon on les crée (idempotent)
  
  // 1) Dépôt (utilise l'ID centralisé)
  await client.from('depots').upsert({
    'id': ids.depotId,
    'nom': 'DEPOT STAGING',
  });

  // 2) Produit (utilise l'ID centralisé)
  await client.from('produits').upsert({
    'id': ids.produitId,
    'nom': 'DIESEL STAGING',
  });

  // 3) Citerne (utilise l'ID centralisé, pas la citerne supprimée 3333...)
  // ⚠️ IMPORTANT : Ne pas utiliser '33333333-3333-3333-3333-333333333333' (supprimée)
  await client.from('citernes').upsert({
    'id': ids.citerneId,
    'depot_id': ids.depotId,
    'produit_id': ids.produitId,
    'nom': 'TANK TEST',
    'capacite_totale': 50000,
    'capacite_securite': 2000,
    'localisation': 'ZONE TEST',
    'statut': 'active',
  });
}

