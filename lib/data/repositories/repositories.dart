import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cours_de_route_repository.dart';
import 'receptions_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final coursDeRouteRepoProvider = Provider<CoursDeRouteRepository>((ref) {
  final supa = ref.watch(supabaseClientProvider);
  return CoursDeRouteRepository(supa);
});

final receptionsRepoProvider = Provider<ReceptionsRepository>((ref) {
  final supa = ref.watch(supabaseClientProvider);
  return ReceptionsRepository(supa);
});




