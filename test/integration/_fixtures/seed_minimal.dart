import 'package:supabase_flutter/supabase_flutter.dart';

import 'fixture_ids.dart';

/// Seed minimal : dépôt + produit + citerne (IDs fixes du seed staging)
Future<void> seedMinimal({
  required SupabaseClient client,
  required FixtureIds ids,
}) async {
  // Les IDs sont fixes et doivent déjà exister via seed_staging_minimal_v2.sql
  // On vérifie juste qu'ils existent, sinon on les crée (idempotent)
  
  // 1) Dépôt
  await client.from('depots').upsert({
    'id': ids.depotId,
    'nom': 'DEPOT STAGING',
  });

  // 2) Produit
  await client.from('produits').upsert({
    'id': ids.produitId,
    'nom': 'DIESEL STAGING',
  });

  // 3) Citerne
  await client.from('citernes').upsert({
    'id': ids.citerneId,
    'depot_id': ids.depotId,
    'produit_id': ids.produitId,
    'nom': 'TANK STAGING 1',
    'capacite_totale': 50000,
    'capacite_securite': 2000,
    'localisation': 'ZONE A',
    'statut': 'active',
  });
}

