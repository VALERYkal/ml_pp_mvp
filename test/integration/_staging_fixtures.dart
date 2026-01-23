// test/integration/_staging_fixtures.dart
//
// Fixtures centralisées pour les tests d'intégration DB-STRICT (STAGING).
//
// Ce fichier centralise :
// - Les IDs fixes du seed minimal (seed_staging_minimal_v2.sql)
// - Les helpers d'authentification STAGING
//
// ⚠️ IMPORTANT : Ne jamais hardcoder ces IDs ailleurs dans les tests.

import 'package:supabase_flutter/supabase_flutter.dart';

import '_env/staging_env.dart';

// ============================================================================
// IDs fixes du seed minimal (seed_staging_minimal_v2.sql)
// ============================================================================

/// ID du dépôt STAGING (fixe dans seed_staging_minimal_v2.sql)
const kStagingDepotId = '11111111-1111-1111-1111-111111111111';

/// ID du produit STAGING (fixe dans seed_staging_minimal_v2.sql)
const kStagingProduitId = '22222222-2222-2222-2222-222222222222';

/// ID de la citerne STAGING (fixe dans seed_staging_minimal_v2.sql)
///
/// ⚠️ NOTE : La citerne '33333333-3333-3333-3333-333333333333' (TANK STAGING 1)
/// a été supprimée pour aligner STAGING avec PROD. Cette constante utilise
/// une citerne existante (TANK1) qui doit être présente en STAGING.
///
/// Si vous devez utiliser une autre citerne, vérifiez qu'elle existe en STAGING
/// et qu'elle est associée au dépôt/produit corrects.
///
/// Pour trouver une citerne existante :
/// ```sql
/// SELECT id, nom, depot_id, produit_id FROM public.citernes
/// WHERE depot_id = '11111111-1111-1111-1111-111111111111'
///   AND produit_id = '22222222-2222-2222-2222-222222222222'
/// LIMIT 1;
/// ```
///
/// En attendant une vraie citerne TANK1..TANK6, on utilise une citerne générée
/// dynamiquement ou on crée une citerne de test avec un ID différent.
///
/// TODO: Remplacer par l'ID d'une vraie citerne TANK1..TANK6 une fois identifiée.
const kStagingCiterneId = '44444444-4444-4444-4444-444444444444';

/// ID du client STAGING (créé dynamiquement dans les tests si nécessaire)
///
/// Note : Les clients sont généralement créés dynamiquement dans les tests
/// car ils ne sont pas dans le seed minimal. Cette constante peut être utilisée
/// comme valeur par défaut si un client fixe est nécessaire.
const kStagingClientId = '55555555-5555-5555-5555-555555555555';

/// ID du partenaire STAGING (créé dynamiquement dans les tests si nécessaire)
///
/// Note : Les partenaires sont généralement créés dynamiquement dans les tests
/// car ils ne sont pas dans le seed minimal. Cette constante peut être utilisée
/// comme valeur par défaut si un partenaire fixe est nécessaire.
const kStagingPartenaireId = '66666666-6666-6666-6666-666666666666';

/// ID du fournisseur STAGING (créé dynamiquement dans les tests si nécessaire)
///
/// Note : Les fournisseurs sont généralement créés dynamiquement dans les tests
/// car ils ne sont pas dans le seed minimal. Cette constante peut être utilisée
/// comme valeur par défaut si un fournisseur fixe est nécessaire.
const kStagingFournisseurId = '77777777-7777-7777-7777-777777777777';

// ============================================================================
// Helper d'authentification STAGING
// ============================================================================

/// S'assure que le client Supabase est authentifié avec un utilisateur STAGING.
///
/// Si le client est déjà authentifié, cette fonction ne fait rien.
/// Sinon, elle effectue un `signInWithPassword` avec les credentials STAGING.
///
/// Les credentials sont lus depuis :
/// - Variables d'environnement (`--dart-define=TEST_USER_EMAIL=...`)
/// - Fichier `env/.env.staging` (fallback)
///
/// [client] : Le client Supabase à authentifier (généralement `anonClient`)
///
/// Exemple d'utilisation :
/// ```dart
/// final staging = await StagingSupabase.create(envPath: 'env/.env.staging');
/// await ensureStagingAuth(staging.anonClient);
/// // Maintenant le client est authentifié et peut faire des opérations nécessitant auth.uid()
/// ```
///
/// ⚠️ IMPORTANT : Cette fonction doit être appelée AVANT toute opération DB
/// nécessitant une authentification (INSERT, UPDATE, DELETE, RPC).
///
/// Throws [StateError] si les variables d'environnement sont manquantes.
Future<void> ensureStagingAuth(SupabaseClient client) async {
  // 1) Vérifier si déjà authentifié
  final currentUser = client.auth.currentUser;
  if (currentUser != null) {
    // ignore: avoid_print
    print('[DB-TEST] Already authenticated: userId=${currentUser.id}');
    return;
  }

  // 2) Charger les credentials STAGING
  final env = await StagingEnv.load(path: 'env/.env.staging');

  if (env.testUserEmail == null || env.testUserEmail!.isEmpty) {
    throw StateError(
      '[DB-TEST] TEST_USER_EMAIL must be set in env/.env.staging or via --dart-define=TEST_USER_EMAIL=...\n'
      'Create this user in Supabase Auth STAGING or update TEST_USER_EMAIL/PASSWORD',
    );
  }

  if (env.testUserPassword == null || env.testUserPassword!.isEmpty) {
    throw StateError(
      '[DB-TEST] TEST_USER_PASSWORD must be set in env/.env.staging or via --dart-define=TEST_USER_PASSWORD=...\n'
      'Create this user in Supabase Auth STAGING or update TEST_USER_EMAIL/PASSWORD',
    );
  }

  // 3) Authentifier
  try {
    final authResponse = await client.auth.signInWithPassword(
      email: env.testUserEmail!,
      password: env.testUserPassword!,
    );

    final userId = authResponse.user?.id;
    if (userId == null) {
      throw StateError('[DB-TEST] Failed to get userId after login');
    }

    // ignore: avoid_print
    print('[DB-TEST] Authenticated: userId=$userId, email=${env.testUserEmail}');
  } catch (e) {
    throw StateError(
      '[DB-TEST] Failed to authenticate with STAGING: $e\n'
      'Verify that TEST_USER_EMAIL and TEST_USER_PASSWORD are correct in env/.env.staging',
    );
  }
}

/// S'assure qu'un profil existe pour l'utilisateur authentifié avec le rôle spécifié.
///
/// Cette fonction est optionnelle et n'est nécessaire que si le test a besoin
/// d'un profil avec un rôle spécifique (ex: 'admin', 'gerant', 'directeur').
///
/// Si le profil existe déjà, il est mis à jour avec le rôle spécifié.
/// Sinon, un nouveau profil est créé.
///
/// [serviceClient] : Le client Supabase avec service_role_key (pour bypass RLS)
/// [userId] : L'ID de l'utilisateur (généralement `client.auth.currentUser?.id`)
/// [role] : Le rôle à assigner ('admin', 'gerant', 'directeur', 'pca', 'lecture', 'operateur')
/// [email] : L'email de l'utilisateur (pour création du profil)
///
/// ⚠️ NOTE : Cette fonction utilise le serviceClient pour bypasser RLS.
/// Elle ne doit être utilisée que dans les tests d'intégration DB.
Future<void> ensureStagingProfilExists({
  required SupabaseClient serviceClient,
  required String userId,
  required String role,
  required String email,
}) async {
  // Normaliser le rôle
  const allowed = {'admin', 'directeur', 'gerant', 'lecture', 'pca', 'operateur'};
  final r = role.toLowerCase();
  if (!allowed.contains(r)) {
    throw StateError('[DB-TEST] Invalid role="$role". Allowed: $allowed');
  }

  // 1) Chercher un profil existant
  Map<String, dynamic>? existing;

  try {
    final rows = await serviceClient
        .from('profils')
        .select('id, user_id, role')
        .eq('user_id', userId)
        .limit(1);
    if (rows is List && rows.isNotEmpty) {
      existing = (rows.first as Map<String, dynamic>);
    }
  } catch (_) {
    // Ignore: certains schémas peuvent ne pas avoir user_id
  }

  // 2) Update si trouvé
  if (existing != null) {
    final id = existing['id']?.toString();
    if (id == null) {
      throw StateError('[DB-TEST] profils row found but has no id');
    }
    await serviceClient.from('profils').update({
      'role': r,
    }).eq('id', id);
    // ignore: avoid_print
    print('[DB-TEST] Updated profil: id=$id, role=$r');
    return;
  }

  // 3) Sinon créer un nouveau profil
  try {
    await serviceClient.from('profils').insert({
      'id': userId,
      'user_id': userId,
      'role': r,
      'email': email,
    });
    // ignore: avoid_print
    print('[DB-TEST] Created profil: id=$userId, role=$r');
  } catch (e) {
    // Fallback: essayer sans email si la colonne n'existe pas
    try {
      await serviceClient.from('profils').insert({
        'id': userId,
        'user_id': userId,
        'role': r,
      });
      // ignore: avoid_print
      print('[DB-TEST] Created profil (no email): id=$userId, role=$r');
    } catch (e2) {
      throw StateError('[DB-TEST] Failed to create profil: $e2');
    }
  }
}
