import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:ml_pp_mvp/shared/providers/supabase_client_provider.dart';
import 'cours_de_route_repository.dart';
import 'receptions_repository.dart';

// Réexport pour compatibilité avec les imports existants
export 'package:ml_pp_mvp/shared/providers/supabase_client_provider.dart'
    show supabaseClientProvider;

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
