import 'package:supabase_flutter/supabase_flutter.dart';

import 'fixture_ids.dart';
import 'seed_minimal.dart';

class StockReady {
  final double stockAmb;
  final double stock15c;

  const StockReady({required this.stockAmb, required this.stock15c});
}

Future<StockReady> seedStockReady({
  required SupabaseClient client,
  required FixtureIds ids,
}) async {
  await seedMinimal(client: client, ids: ids);

  // Créer un client de test (obligatoire pour le check bénéficiaire des sorties)
  final clientRow = await client
      .from('clients')
      .insert({
        'nom': 'Client Test ${ids.tag}',
        // si ton schema impose d'autres champs NOT NULL, l'erreur nous dira quoi ajouter
      })
      .select('id')
      .single();

  ids.clientId = clientRow['id'] as String;

  // Inject stock via reception (DB triggers already proven in B2.1)
  const volumeAmb = 2000.0;
  const volume15c = 1990.0;

  await client.from('receptions').insert({
    'cours_de_route_id': null,
    'citerne_id': ids.citerneId,
    'produit_id': ids.produitId,
    'partenaire_id': null,
    'index_avant': 0,
    'index_apres': 2000,
    'volume_corrige_15c': volume15c,
    'temperature_ambiante_c': 20,
    'densite_a_15_kgm3': 830,
    'proprietaire_type': 'MONALUXE',
    'note': 'SEED STOCK ${ids.tag}',
    'volume_ambiant': volumeAmb,
    'statut': 'validee',
    'created_by': null,
    'validated_by': null,
    'date_reception': DateTime.now().toIso8601String(),
    'volume_observe': volumeAmb,
    'volume_15c': null,
  });

  return const StockReady(stockAmb: volumeAmb, stock15c: volume15c);
}

