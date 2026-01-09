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
    // 1) Prefer dart-define (works on macOS sandbox integration tests)
    const env = String.fromEnvironment('SUPABASE_ENV');
    const url = String.fromEnvironment('SUPABASE_URL');
    const anon = String.fromEnvironment('SUPABASE_ANON_KEY');
    const service = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
    const email = String.fromEnvironment('TEST_USER_EMAIL');
    const pass = String.fromEnvironment('TEST_USER_PASSWORD');
    const role = String.fromEnvironment('TEST_USER_ROLE');
    const nonAdminEmail = String.fromEnvironment('NON_ADMIN_EMAIL');
    const nonAdminPass = String.fromEnvironment('NON_ADMIN_PASSWORD');

    final hasDefines = url.isNotEmpty && anon.isNotEmpty && env.isNotEmpty;

    if (hasDefines) {
      if (env != 'STAGING') {
        throw StateError('[DB-TEST] SUPABASE_ENV must be STAGING (got: $env). Refusing to run.');
      }
      _guardAgainstProd(url);

      return StagingEnv(
        supabaseUrl: url,
        anonKey: anon,
        serviceRoleKey: service.isEmpty ? null : service,
        testUserEmail: email.isEmpty ? null : email,
        testUserPassword: pass.isEmpty ? null : pass,
        testUserRole: role.isEmpty ? null : role,
        nonAdminEmail: nonAdminEmail.isEmpty ? null : nonAdminEmail,
        nonAdminPassword: nonAdminPass.isEmpty ? null : nonAdminPass,
      );
    }

    // 2) Fallback: file loading (kept for old flutter test runs)
    File resolveEnvFile() {
      // 1) Try as-is relative to current working directory
      final direct = File(path);
      if (direct.existsSync()) return direct;

      // 2) Try relative to the test script location (integration_test/...)
      final scriptDir = File.fromUri(Platform.script).parent;
      final fromScript = File('${scriptDir.path}/../$path');
      if (fromScript.existsSync()) return fromScript;

      // 3) Try one more level up (in case of nested runner dirs)
      final fromScript2 = File('${scriptDir.path}/../../$path');
      if (fromScript2.existsSync()) return fromScript2;

      // 4) Last fallback: project root guessed from current dir
      final fromCwd1 = File('${Directory.current.path}/../$path');
      if (fromCwd1.existsSync()) return fromCwd1;

      return direct; // will fail below with the same error message
    }

    final file = resolveEnvFile();

    if (!file.existsSync()) {
      throw StateError('[DB-TEST] Missing $path. Create it locally (never commit). '
          'Tried cwd=${Directory.current.path} script=${File.fromUri(Platform.script).path}');
    }

    final lines = file.readAsLinesSync();
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

    final envFromFile = map['SUPABASE_ENV']?.trim();
    if (envFromFile != 'STAGING') {
      throw StateError(
        '[DB-TEST] SUPABASE_ENV must be STAGING (got: ${envFromFile ?? "null"}). Refusing to run.',
      );
    }

    final urlFromFile = map['SUPABASE_URL']?.trim();
    final anonFromFile = map['SUPABASE_ANON_KEY']?.trim();

    if (urlFromFile == null || urlFromFile.isEmpty) {
      throw StateError('[DB-TEST] SUPABASE_URL missing in $path.');
    }
    if (anonFromFile == null || anonFromFile.isEmpty) {
      throw StateError('[DB-TEST] SUPABASE_ANON_KEY missing in $path.');
    }

    _guardAgainstProd(urlFromFile);

    return StagingEnv(
      supabaseUrl: urlFromFile,
      anonKey: anonFromFile,
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

