import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/shared/providers/supabase_client_provider.dart';

import '../data/repositories/supabase_fournisseur_repository.dart';
import '../domain/models/fournisseur.dart';
import '../domain/repositories/fournisseur_repository.dart';

/// Repository injecté (Supabase client via provider existant).
final fournisseurRepositoryProvider = Provider<FournisseurRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseFournisseurRepository(client);
});

/// Liste complète des fournisseurs (AsyncValue<List<Fournisseur>>).
final fournisseursListProvider =
    FutureProvider.autoDispose<List<Fournisseur>>((ref) async {
  final repo = ref.watch(fournisseurRepositoryProvider);
  return repo.fetchAllFournisseurs();
});

/// Détail d'un fournisseur par id.
final fournisseurDetailProvider =
    FutureProvider.autoDispose.family<Fournisseur?, String>((ref, id) async {
  final repo = ref.watch(fournisseurRepositoryProvider);
  return repo.getById(id);
});
