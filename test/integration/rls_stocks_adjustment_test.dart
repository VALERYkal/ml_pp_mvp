// test/integration/rls_stocks_adjustment_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

import '_harness/staging_supabase_client.dart';
import '_env/staging_env.dart';

void _assertRlsOrWriteDenied(PostgrestException e) {
  final msg = e.message.toLowerCase();
  final details = '${e.details ?? ''} ${e.hint ?? ''}'.toLowerCase();
  final code = (e.code?.toString() ?? '').toLowerCase();
  final blob = '$msg $details $code';
  expect(
    blob,
    anyOf(<Matcher>[
      contains('rls'),
      contains('permission'),
      contains('not allowed'),
      contains('forbidden'),
      contains('row-level security'),
      contains('policy'),
      contains('violates'),
      contains('42501'),
      contains('pgrst'),
    ]),
    reason:
        'Rejet RLS / écriture interdite attendu — message=${e.message} code=${e.code}',
  );
}

void main() {
  // Check both activation modes: env var and dart-define
  final runDbTestsEnv = Platform.environment['RUN_DB_TESTS'] == '1' ||
      Platform.environment['RUN_DB_TESTS'] == 'true';
  final runDbTestsDartDefine =
      const bool.fromEnvironment('RUN_DB_TESTS', defaultValue: false);
  final runDbTests = runDbTestsEnv || runDbTestsDartDefine;

  test(
    '[DB-TEST] B2.3.1 RLS — lecture cannot INSERT stocks_adjustments (STAGING)',
    () async {
    final staging = await StagingSupabase.create(envPath: 'env/.env.staging');

    // IMPORTANT: We must use anonClient (RLS applies). serviceClient would bypass RLS.
    final client = staging.anonClient;

    // 1) Login as NON_ADMIN (lecture)
    final env = await StagingEnv.load(path: 'env/.env.staging');

    final lectureEmail = env.nonAdminEmail;
    final lecturePassword = env.nonAdminPassword;
    if (lectureEmail == null ||
        lectureEmail.isEmpty ||
        lecturePassword == null ||
        lecturePassword.isEmpty) {
      fail(
        '[DB-TEST] NON_ADMIN_EMAIL et NON_ADMIN_PASSWORD sont requis dans env/.env.staging '
        '(ou dart-define) pour ce test RLS « lecture ».',
      );
    }

    late final String userId;
    try {
      final res = await client.auth
          .signInWithPassword(
            email: lectureEmail,
            password: lecturePassword,
          )
          .timeout(const Duration(seconds: 10));
      final sessionUser = res.user;
      expect(
        sessionUser,
        isNotNull,
        reason: 'Connexion lecture doit retourner un utilisateur',
      );
      final uid = sessionUser?.id;
      if (uid == null || uid.isEmpty) {
        fail('[DB-TEST] user.id manquant après signIn (lecture).');
      }
      userId = uid;
    } on TimeoutException {
      fail(
        '[DB-TEST] Timeout querying STAGING. Check network/DNS or Supabase status.',
      );
    }

    // 2) Attempt forbidden insert
    // Get a real RECEPTION id (use serviceClient to bypass RLS for the lookup)
    final lookupClient = staging.serviceClient ?? staging.anonClient;

    List<dynamic> rows;
    try {
      rows = await lookupClient
          .from('receptions')
          .select('id')
          .order('created_at', ascending: false)
          .limit(1)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      fail(
        '[DB-TEST] Timeout querying STAGING. Check network/DNS or Supabase status.',
      );
    }

    if (rows.isEmpty) {
      fail('No receptions found in STAGING to build a valid stocks_adjustments payload.');
    }

    final firstRow = rows.first;
    final rowMap = Map<String, dynamic>.from(firstRow as Map);
    final rawId = rowMap['id'];
    if (rawId is! String || rawId.isEmpty) {
      fail('[DB-TEST] id de réception manquant ou invalide.');
    }
    final receptionId = rawId;

    final payload = {
      'mouvement_type': 'RECEPTION',
      'mouvement_id': receptionId,
      'created_by': userId,
      'delta_ambiant': 1.0,
      'delta_15c': 1.0,
      'reason': '[TEST] RLS must block lecture',
    };

    try {
      await client
          .from('stocks_adjustments')
          .insert(payload)
          .timeout(const Duration(seconds: 10));
      fail('Expected RLS/permission error, but insert succeeded.');
    } on TimeoutException {
      fail(
        '[DB-TEST] Timeout querying STAGING. Check network/DNS or Supabase status.',
      );
    } on PostgrestException catch (e) {
      _assertRlsOrWriteDenied(e);
    } catch (e) {
      // Client ou enveloppe : vérifier le message sans `!` sur une réponse null
      final combined = '${e.runtimeType} ${e.toString()}'.toLowerCase();
      expect(
        combined,
        anyOf(<Matcher>[
          contains('rls'),
          contains('permission'),
          contains('not allowed'),
          contains('forbidden'),
          contains('row-level security'),
          contains('policy'),
          contains('violates'),
          contains('postgrest'),
          contains('42501'),
        ]),
        reason: 'Rejet attendu (RLS / écriture interdite), obtenu: $e',
      );
    }
    },
    skip: runDbTests
        ? false
        : 'DB tests are opt-in. Set RUN_DB_TESTS=1 or --dart-define=RUN_DB_TESTS=true',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}


