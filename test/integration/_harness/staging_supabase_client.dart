// test/integration/_harness/staging_supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../_env/staging_env.dart';

class StagingSupabase {
  final SupabaseClient anonClient;
  final SupabaseClient? serviceClient;

  StagingSupabase({
    required this.anonClient,
    required this.serviceClient,
  });

  static Future<StagingSupabase> create({String envPath = 'env/.env.staging'}) async {
    final env = await StagingEnv.load(path: envPath);

    final anonClient = SupabaseClient(env.supabaseUrl, env.anonKey);

    final serviceClient = (env.serviceRoleKey != null && env.serviceRoleKey!.isNotEmpty)
        ? SupabaseClient(env.supabaseUrl, env.serviceRoleKey!)
        : null;

    return StagingSupabase(
      anonClient: anonClient,
      serviceClient: serviceClient,
    );
  }
}

