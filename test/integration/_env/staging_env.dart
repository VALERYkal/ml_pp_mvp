// test/integration/_env/staging_env.dart
import 'dart:io';

class StagingEnv {
  final String supabaseUrl;
  final String anonKey;
  final String? serviceRoleKey;
  final String? testUserEmail;
  final String? testUserPassword;
  final String? testUserRole;
  final String? nonAdminEmail;
  final String? nonAdminPassword;

  StagingEnv({
    required this.supabaseUrl,
    required this.anonKey,
    required this.serviceRoleKey,
    this.testUserEmail,
    this.testUserPassword,
    this.testUserRole,
    this.nonAdminEmail,
    this.nonAdminPassword,
  });

  static Future<StagingEnv> load({String path = 'env/.env.staging'}) async {
    final file = File(path);
    if (!await file.exists()) {
      throw StateError(
        '[DB-TEST] Missing $path. Create it locally (never commit).',
      );
    }

    final lines = await file.readAsLines();
    final map = <String, String>{};

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final idx = line.indexOf('=');
      if (idx <= 0) continue;

      final key = line.substring(0, idx).trim();
      final value = line.substring(idx + 1).trim();
      map[key] = value;
    }

    final env = map['SUPABASE_ENV']?.trim();
    if (env != 'STAGING') {
      throw StateError(
        '[DB-TEST] SUPABASE_ENV must be STAGING (got: ${env ?? "null"}). Refusing to run.',
      );
    }

    final url = map['SUPABASE_URL']?.trim();
    final anon = map['SUPABASE_ANON_KEY']?.trim();

    if (url == null || url.isEmpty) {
      throw StateError('[DB-TEST] SUPABASE_URL missing in $path.');
    }
    if (anon == null || anon.isEmpty) {
      throw StateError('[DB-TEST] SUPABASE_ANON_KEY missing in $path.');
    }

    _guardAgainstProd(url);

    return StagingEnv(
      supabaseUrl: url,
      anonKey: anon,
      serviceRoleKey: map['SUPABASE_SERVICE_ROLE_KEY']?.trim(),
      testUserEmail: map['TEST_USER_EMAIL']?.trim(),
      testUserPassword: map['TEST_USER_PASSWORD']?.trim(),
      testUserRole: map['TEST_USER_ROLE']?.trim(),
      nonAdminEmail: map['NON_ADMIN_EMAIL']?.trim(),
      nonAdminPassword: map['NON_ADMIN_PASSWORD']?.trim(),
    );
  }

  static void _guardAgainstProd(String url) {
    final u = url.toLowerCase();

    // Block obvious prod/production keywords
    const blocked = ['prod', 'production', 'live'];
    for (final b in blocked) {
      if (u.contains(b)) {
        throw StateError(
          '[DB-TEST] Refusing to run: SUPABASE_URL looks like PROD ($url).',
        );
      }
    }

    // Basic shape guard
    if (!u.startsWith('https://') || !u.contains('.supabase.co')) {
      throw StateError(
        '[DB-TEST] SUPABASE_URL malformed ($url). Expected https://xxxx.supabase.co',
      );
    }
  }
}

