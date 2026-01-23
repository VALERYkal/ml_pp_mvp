import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '_harness/staging_supabase_client.dart';
import '_env/staging_env.dart';
import '_fixtures/fixture_ids.dart';
import '_fixtures/seed_stock_ready.dart';
import '_staging_fixtures.dart';

/// Lit le stock_15c depuis stocks_journaliers (owner-aware, anti-flaky).
///
/// Filtre strictement par proprietaire_type et date_jour.
/// Tri robuste : updated_at DESC puis created_at DESC (updated_at plus fiable si trigger fait UPDATE).
Future<double> latestStock15c({
  required dynamic client,
  required String citerneId,
  required String produitId,
  required String proprietaireType, // 'MONALUXE' | 'PARTENAIRE'
  required String dateJourIso, // 'YYYY-MM-DD'
}) async {
  final rows = await client
      .from('stocks_journaliers')
      .select('stock_15c, date_jour, created_at, updated_at, proprietaire_type')
      .eq('citerne_id', citerneId)
      .eq('produit_id', produitId)
      .eq('proprietaire_type', proprietaireType)
      .eq('date_jour', dateJourIso)
      // Important: si le trigger fait UPDATE (pas INSERT), updated_at est plus fiable
      .order('updated_at', ascending: false)
      .order('created_at', ascending: false)
      .limit(1);

  if (rows is! List || rows.isEmpty) {
    throw StateError('No stocks_journaliers row for $citerneId/$produitId owner=$proprietaireType date=$dateJourIso');
  }
  return (rows.first['stock_15c'] as num).toDouble();
}

/// Lit le stock_15c depuis la vue snapshot (source de vérité alternative).
///
/// Utilise v_stock_actuel pour une lecture cohérente du stock actuel par citerne.
/// Utile pour comparer avec stocks_journaliers et détecter les drifts.
Future<double> latestOwnerSnapshot15c({
  required dynamic client,
  required String citerneId,
  required String produitId,
  required String proprietaireType,
}) async {
  final rows = await client
      .from('v_stock_actuel')
      .select('stock_15c')
      .eq('citerne_id', citerneId)
      .eq('produit_id', produitId)
      .eq('proprietaire_type', proprietaireType)
      .limit(1);

  if (rows is! List || rows.isEmpty) {
    throw StateError('No snapshot row found in v_stock_actuel for $citerneId/$produitId owner=$proprietaireType');
  }
  return (rows.first['stock_15c'] as num).toDouble();
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
    
    // ✅ Séparation claire des clients :
    // - anon : utilisé pour TOUTES les écritures/RPC/ensure profil (avec JWT)
    // - serviceOrAnon : optionnel, pour SELECT uniquement
    final anon = staging.anonClient;
    final serviceOrAnon = staging.serviceClient ?? anon;

    final ids = FixtureIds.makeRunTag();

    // ignore: avoid_print
    print('[DB-TEST] Connected: service=${serviceOrAnon != staging.anonClient}, anon=true');

    // 0) Authentifier le client anon AVANT toute opération DB nécessitant auth.uid()
    // ⚠️ IMPORTANT : RLS nécessite auth.uid() pour les INSERT/UPDATE/DELETE
    await ensureStagingAuth(anon);

    // Vérifier que l'authentification est bien active
    final session = anon.auth.currentSession;
    if (session == null) {
      throw StateError('[DB-TEST] Authentication failed: no session after ensureStagingAuth');
    }
    // ignore: avoid_print
    print('[DB-TEST] Authenticated: userId=${session.user.id}, email=${session.user.email}');

    // 1) Seed: depot+produit+citerne + stock via reception (via anon pour que les triggers aient auth.uid())
    // ⚠️ IMPORTANT : seedStockReady fait des INSERT (clients, receptions) qui nécessitent auth.uid()
    await seedStockReady(client: anon, ids: ids);

    // SELECT peut utiliser serviceOrAnon (optionnel, pour bypass RLS si nécessaire)
    // Calculer dateJourIso pour filtrer par date (YYYY-MM-DD)
    final dateJourIso = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    
    // Lecture depuis stocks_journaliers (source transactionnelle)
    final before15cSj = await latestStock15c(
      client: serviceOrAnon,
      citerneId: ids.citerneId,
      produitId: ids.produitId,
      proprietaireType: 'MONALUXE',
      dateJourIso: dateJourIso,
    );
    
    // Lecture depuis vue snapshot (source de vérité alternative, anti-flaky)
    final before15cSnap = await latestOwnerSnapshot15c(
      client: serviceOrAnon,
      citerneId: ids.citerneId,
      produitId: ids.produitId,
      proprietaireType: 'MONALUXE',
    );
    
    // ignore: avoid_print
    print('[DB-TEST] Before stock_15c SJ=$before15cSj / SNAP=$before15cSnap (tag=${ids.tag})');
    
    // Utiliser la valeur depuis stocks_journaliers pour l'assertion principale
    final before15c = before15cSj;

    // 2) S'assurer que le profil existe avec le bon rôle
    // (ensureStagingAuth a déjà été appelé à l'étape 0)
    final userId = anon.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('[DB-TEST] userId is null after ensureStagingAuth');
    }

    // ignore: avoid_print
    print('[DB-TEST] Authenticated userId: $userId');

    // 3) Ensure profil avec rôle normalisé (utilise anon avec JWT, pas service)
    // ⚠️ IMPORTANT : Même si le param s'appelle serviceClient, on passe anon pour avoir auth.uid()
    await ensureStagingProfilExists(
      serviceClient: anon, // ✅ Utiliser anon authentifié, pas service (sans JWT)
      userId: userId,
      role: env.testUserRole ?? 'admin',
      email: env.testUserEmail ?? 'test@staging.test',
    );

    final roleRaw = (env.testUserRole ?? 'admin').toLowerCase();
    // ignore: avoid_print
    print('[DB-TEST] Ensured profil: userId=$userId, role=$roleRaw');

    // 4) Insert sortie avec statut='brouillon' (via anon pour que created_by soit rempli par triggers)
    // ⚠️ CRITICAL : Vérifier que le JWT est présent avant toute écriture
    final sessionBeforeInsert = anon.auth.currentSession;
    expect(
      sessionBeforeInsert,
      isNotNull,
      reason: 'DB-TEST requires JWT; do not use service client for writes',
    );
    // ignore: avoid_print
    print('[DB-TEST] Writing with ANON JWT userId=${sessionBeforeInsert!.user.id}');

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

    // 5) Validate via anon RPC (authentifié avec JWT)
    // ⚠️ IMPORTANT : RPC validate_sortie nécessite auth.uid() pour les triggers
    await anon.rpc('validate_sortie', params: {'p_id': sortieId});

    // Relire la sortie après validation (SELECT peut utiliser service ou anon)
    final s1 = await anon
        .from('sorties_produit')
        .select('id, statut, created_by, validated_by')
        .eq('id', sortieId)
        .single();
    // ignore: avoid_print
    print('[DB-TEST] Sortie validated: statut=${s1['statut']} validated_by=${s1['validated_by']}');

    await Future.delayed(const Duration(milliseconds: 500));

    // SELECT peut utiliser serviceOrAnon (optionnel, pour bypass RLS si nécessaire)
    // Utiliser la même dateJourIso que pour before15c
    // Lecture depuis stocks_journaliers (source transactionnelle)
    final after15cSj = await latestStock15c(
      client: serviceOrAnon,
      citerneId: ids.citerneId,
      produitId: ids.produitId,
      proprietaireType: 'MONALUXE',
      dateJourIso: dateJourIso,
    );
    
    // Lecture depuis vue snapshot (source de vérité alternative, anti-flaky)
    final after15cSnap = await latestOwnerSnapshot15c(
      client: serviceOrAnon,
      citerneId: ids.citerneId,
      produitId: ids.produitId,
      proprietaireType: 'MONALUXE',
    );
    
    // ignore: avoid_print
    print('[DB-TEST] After stock_15c SJ=$after15cSj / SNAP=$after15cSnap (tag=${ids.tag}, userId=$userId, role=$roleRaw)');
    // ignore: avoid_print
    print('[DB-TEST] Before stock_15c: $before15c, After stock_15c: $after15cSj (tag=${ids.tag})');
    
    // Utiliser la valeur depuis stocks_journaliers pour l'assertion principale
    final after15c = after15cSj;

    expect(after15c, lessThan(before15c),
        reason: 'Stock should decrease after validate_sortie.');

    // 6) Reject case: ask more than remaining stock
    // ⚠️ IMPORTANT : Vérifier que le JWT est toujours présent avant la deuxième insertion
    final sessionBeforeInsert2 = anon.auth.currentSession;
    expect(
      sessionBeforeInsert2,
      isNotNull,
      reason: 'DB-TEST requires JWT for all writes',
    );

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

