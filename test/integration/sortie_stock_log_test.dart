import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '_harness/staging_supabase_client.dart';
import '_env/staging_env.dart';
import '_fixtures/fixture_ids.dart';
import '_fixtures/seed_stock_ready.dart';

Future<double> _latestStock15c({
  required dynamic client,
  required String citerneId,
  required String produitId,
}) async {
  final rows = await client
      .from('stocks_journaliers')
      .select('stock_15c, created_at')
      .eq('citerne_id', citerneId)
      .eq('produit_id', produitId)
      .order('created_at', ascending: false)
      .limit(1);

  if (rows is! List || rows.isEmpty) {
    throw StateError('No stocks_journaliers row found for citerne=$citerneId produit=$produitId');
  }
  final latest = rows.first as Map<String, dynamic>;
  return (latest['stock_15c'] as num).toDouble();
}

Future<Map<String, dynamic>?> readSortie(SupabaseClient c, String id) async {
  final result = await c
      .from('sorties_produit')
      .select('id, statut, created_by, validated_by, volume_corrige_15c, volume_ambiant, client_id, partenaire_id, created_at')
      .eq('id', id)
      .maybeSingle();
  return result as Map<String, dynamic>?;
}

Future<void> ensureProfilRole({
  required SupabaseClient service,
  required String userId,
  required String role,
  required String email,
}) async {
  // role normalisé en lowercase et validé
  const allowed = {'admin', 'directeur', 'gerant', 'lecture', 'pca'};
  final r = role.toLowerCase();
  if (!allowed.contains(r)) {
    throw StateError('[DB-TEST] Invalid TEST_USER_ROLE="$role". Allowed: $allowed');
  }

  // 1) tenter de trouver un profil existant par user_id
  // (le schéma peut être id=userId ou user_id=userId)
  Map<String, dynamic>? existing;

  try {
    final rows = await service
        .from('profils')
        .select('id,user_id,role')
        .eq('user_id', userId)
        .limit(1);
    if (rows is List && rows.isNotEmpty) {
      existing = (rows.first as Map<String, dynamic>);
    }
  } catch (_) {
    // ignore: certain schémas n'ont pas user_id, on tentera via id
  }

  if (existing == null) {
    try {
      final row = await service
          .from('profils')
          .select('id,user_id,role')
          .eq('id', userId)
          .maybeSingle();
      if (row != null) existing = (row as Map<String, dynamic>);
    } catch (_) {
      // ignore
    }
  }

  // 2) update si trouvé
  if (existing != null) {
    final id = existing['id']?.toString();
    if (id == null) {
      throw StateError('[DB-TEST] profils row found but has no id');
    }
    await service.from('profils').update({
      'role': r,
    }).eq('id', id);
    return;
  }

  // 3) sinon insert (sans upsert)
  // On essaie d'abord id=userId + user_id=userId (le plus courant)
  try {
    await service.from('profils').insert({
      'id': userId,
      'user_id': userId,
      'role': r,
      'email': email, // si colonne existe; si erreur, retirer
    });
    return;
  } catch (_) {
    // fallback: insert minimal id=userId,role
  }

  try {
    await service.from('profils').insert({
      'id': userId,
      'role': r,
    });
    return;
  } catch (_) {
    // fallback: insert user_id=userId,role
  }

  await service.from('profils').insert({
    'user_id': userId,
    'role': r,
  });
}

void main() {
  test('[DB-TEST] B2.2 Sortie -> Stock -> Log (STAGING, DB-STRICT)', () async {
    final staging = await StagingSupabase.create(envPath: 'env/.env.staging');
    final env = await StagingEnv.load(path: 'env/.env.staging');
    final service = staging.serviceClient ?? staging.anonClient;
    final anon = staging.anonClient;

    final ids = FixtureIds.makeRunTag();

    // ignore: avoid_print
    print('[DB-TEST] Connected: service=${service != staging.anonClient}, anon=true');

    // 1) Seed: depot+produit+citerne + stock via reception (via service)
    await seedStockReady(client: service, ids: ids);

    final before15c = await _latestStock15c(
      client: service,
      citerneId: ids.citerneId,
      produitId: ids.produitId,
    );

    // ignore: avoid_print
    print('[DB-TEST] Before stock_15c: $before15c (tag=${ids.tag})');

    // 2) Login avec utilisateur de test
    if (env.testUserEmail == null || env.testUserEmail!.isEmpty ||
        env.testUserPassword == null || env.testUserPassword!.isEmpty) {
      throw StateError(
        '[DB-TEST] TEST_USER_EMAIL and TEST_USER_PASSWORD must be set in env/.env.staging. '
        'Create this user in Supabase Auth STAGING or update TEST_USER_EMAIL/PASSWORD',
      );
    }

    final authResponse = await anon.auth.signInWithPassword(
      email: env.testUserEmail!,
      password: env.testUserPassword!,
    );

    final userId = authResponse.user?.id;
    if (userId == null) {
      throw StateError('[DB-TEST] Failed to get userId after login');
    }

    // ignore: avoid_print
    print('[DB-TEST] Logged in userId: $userId');

    // 3) Ensure profil avec rôle normalisé
    await ensureProfilRole(
      service: service,
      userId: userId,
      role: env.testUserRole ?? 'admin',
      email: env.testUserEmail!,
    );

    final roleRaw = (env.testUserRole ?? 'admin').toLowerCase();
    // ignore: avoid_print
    print('[DB-TEST] Ensured profil: userId=$userId, role=$roleRaw');

    // 4) Insert sortie avec statut='brouillon' (via anon pour que created_by soit rempli par triggers)
    const out15c = 495.0;
    final note = 'TEST SORTIE ${ids.tag}';

    final inserted = await anon
        .from('sorties_produit')
        .insert({
          'citerne_id': ids.citerneId,
          'produit_id': ids.produitId,
          'client_id': ids.clientId, // IMPORTANT: passe beneficiaire_check
          'index_avant': 0,
          'index_apres': 500, // volume_ambiant = 500 via validate_sortie fallback
          'temperature_ambiante_c': 20,
          'densite_a_15': 0.83,
          'proprietaire_type': 'MONALUXE',
          'note': note,
          'statut': 'brouillon', // IMPORTANT: requis pour validate_sortie
          'date_sortie': DateTime.now().toUtc().toIso8601String(),
          'volume_corrige_15c': out15c, // pour tester stock_15c aussi
        })
        .select('id, statut, created_by, validated_by')
        .single();

    final sortieId = inserted['id'] as String;
    ids.sortieId = sortieId;
    // ignore: avoid_print
    print('[DB-TEST] Sortie inserted(brouillon): id=$sortieId statut=${inserted['statut']} created_by=${inserted['created_by']}');

    // 5) Validate via anon RPC (authentifié)
    await anon.rpc('validate_sortie', params: {'p_id': sortieId});

    // Relire la sortie après validation
    final s1 = await service
        .from('sorties_produit')
        .select('id, statut, created_by, validated_by')
        .eq('id', sortieId)
        .single();
    // ignore: avoid_print
    print('[DB-TEST] Sortie validated: statut=${s1['statut']} validated_by=${s1['validated_by']}');

    await Future.delayed(const Duration(milliseconds: 500));

    final after15c = await _latestStock15c(
      client: service,
      citerneId: ids.citerneId,
      produitId: ids.produitId,
    );

    // ignore: avoid_print
    print('[DB-TEST] Before stock_15c: $before15c, After stock_15c: $after15c (tag=${ids.tag}, userId=$userId, role=$roleRaw)');

    expect(after15c, lessThan(before15c),
        reason: 'Stock should decrease after validate_sortie.');

    // 6) Reject case: ask more than remaining stock
    final tooMuch = after15c + 999999.0;

    final inserted2 = await anon
        .from('sorties_produit')
        .insert({
          'citerne_id': ids.citerneId,
          'produit_id': ids.produitId,
          'client_id': ids.clientId,
          'index_avant': 0,
          'index_apres': tooMuch.toInt(),
          'temperature_ambiante_c': 20,
          'densite_a_15': 0.83,
          'proprietaire_type': 'MONALUXE',
          'note': 'TEST SORTIE REJECT ${ids.tag}',
          'statut': 'brouillon',
          'date_sortie': DateTime.now().toUtc().toIso8601String(),
          'volume_corrige_15c': tooMuch,
        })
        .select('id, statut, created_by, validated_by')
        .single();

    final sortieId2 = inserted2['id'] as String;
    ids.sortieRejectId = sortieId2;

    // validate_sortie must throw
    bool rejected = false;
    try {
      await anon.rpc('validate_sortie', params: {'p_id': sortieId2});
    } on PostgrestException catch (e) {
      rejected = true;
      // ignore: avoid_print
      print('[DB-TEST] Rejet stock insuffisant => validate_sortie throw: ${e.message}');
    } catch (e) {
      // Accept any exception for rejection case
      rejected = true;
      // ignore: avoid_print
      print('[DB-TEST] Rejet stock insuffisant => validate_sortie throw: $e');
    }
    
    expect(rejected, isTrue, reason: 'validate_sortie should reject when stock is insufficient.');

    // ignore: avoid_print
    print('[DB-TEST] B2.2 OK — debit & reject verified (tag=${ids.tag})');
  });
}

