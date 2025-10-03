import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/data/repositories/depots_repository.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';

final depotsRepoProvider = riverpod.Provider<DepotsRepository>((ref) {
  return DepotsRepository(Supabase.instance.client);
});

final depotNameProvider = riverpod.FutureProvider.family<String?, String>((
  ref,
  depotId,
) async {
  if (depotId.isEmpty) return null;
  final repo = ref.watch(depotsRepoProvider);
  return repo.getDepotNameById(depotId);
});

/// Nom du dépôt courant (profil) — pratique pour l'AppBar
final currentDepotNameProvider = riverpod.FutureProvider<String?>((ref) async {
  final profil = ref.watch(currentProfilProvider).valueOrNull;
  final depotId = profil?.depotId;
  if (depotId == null || depotId.isEmpty) return null;
  return ref.watch(depotNameProvider(depotId).future);
});
