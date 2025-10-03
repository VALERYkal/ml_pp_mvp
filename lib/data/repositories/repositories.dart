import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cours_de_route_repository.dart';
import 'receptions_repository.dart';

final supabaseClientProvider = riverpod.Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final coursDeRouteRepoProvider = riverpod.Provider<CoursDeRouteRepository>((
  ref,
) {
  final supa = ref.watch(supabaseClientProvider);
  return CoursDeRouteRepository(supa);
});

final receptionsRepoProvider = riverpod.Provider<ReceptionsRepository>((ref) {
  final supa = ref.watch(supabaseClientProvider);
  return ReceptionsRepository(supa);
});
