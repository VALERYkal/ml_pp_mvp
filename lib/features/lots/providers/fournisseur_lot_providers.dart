// 📌 Module : Lots — Providers
// 🧭 Lots fournisseur + détail / liaison CDR (FK `fournisseur_lot_id`).

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/lots/data/fournisseur_lot_service.dart';
import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';
import 'package:ml_pp_mvp/features/lots/models/lot_detail_view.dart';
import 'package:ml_pp_mvp/shared/providers/supabase_client_provider.dart';

final fournisseurLotServiceProvider =
    riverpod.Provider<FournisseurLotService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FournisseurLotService.withClient(client);
});

final fournisseurLotsProvider =
    riverpod.FutureProvider<List<FournisseurLot>>((ref) async {
  final service = ref.read(fournisseurLotServiceProvider);
  return service.getAll();
});

final fournisseurLotByIdProvider =
    riverpod.FutureProvider.family<FournisseurLot?, String>((ref, id) async {
  final service = ref.read(fournisseurLotServiceProvider);
  return service.getById(id);
});

final fournisseurLotsByFournisseurProvider =
    riverpod.FutureProvider.family<List<FournisseurLot>, String>((
  ref,
  fournisseurId,
) async {
  final service = ref.read(fournisseurLotServiceProvider);
  return service.getByFournisseur(fournisseurId);
});

class FournisseurLotFilterParams {
  final String fournisseurId;
  final String produitId;

  const FournisseurLotFilterParams({
    required this.fournisseurId,
    required this.produitId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FournisseurLotFilterParams &&
        other.fournisseurId == fournisseurId &&
        other.produitId == produitId;
  }

  @override
  int get hashCode => fournisseurId.hashCode ^ produitId.hashCode;
}

final fournisseurLotsByFournisseurAndProduitProvider = riverpod
    .FutureProvider.family<List<FournisseurLot>, FournisseurLotFilterParams>((
  ref,
  params,
) async {
  final service = ref.read(fournisseurLotServiceProvider);
  return service.getByFournisseurAndProduit(
    fournisseurId: params.fournisseurId,
    produitId: params.produitId,
  );
});

final fournisseurLotsOuvertsByFournisseurProvider =
    riverpod.FutureProvider.family<List<FournisseurLot>, String>((
  ref,
  fournisseurId,
) async {
  final service = ref.read(fournisseurLotServiceProvider);
  return service.getOuvertsByFournisseur(fournisseurId);
});

final createFournisseurLotProvider =
    riverpod.FutureProvider.family<FournisseurLot, FournisseurLot>((
  ref,
  lot,
) async {
  final service = ref.read(fournisseurLotServiceProvider);
  final created = await service.create(lot);

  ref.invalidate(fournisseurLotsProvider);
  ref.invalidate(fournisseurLotsByFournisseurProvider(lot.fournisseurId));
  ref.invalidate(
    fournisseurLotsByFournisseurAndProduitProvider(
      FournisseurLotFilterParams(
        fournisseurId: lot.fournisseurId,
        produitId: lot.produitId,
      ),
    ),
  );
  ref.invalidate(
    fournisseurLotsOuvertsByFournisseurProvider(lot.fournisseurId),
  );

  return created;
});

final updateFournisseurLotProvider =
    riverpod.FutureProvider.family<FournisseurLot, FournisseurLot>((
  ref,
  lot,
) async {
  final service = ref.read(fournisseurLotServiceProvider);
  final updated = await service.update(lot);

  ref.invalidate(fournisseurLotsProvider);
  ref.invalidate(fournisseurLotByIdProvider(lot.id));
  ref.invalidate(fournisseurLotsByFournisseurProvider(lot.fournisseurId));
  ref.invalidate(
    fournisseurLotsByFournisseurAndProduitProvider(
      FournisseurLotFilterParams(
        fournisseurId: lot.fournisseurId,
        produitId: lot.produitId,
      ),
    ),
  );
  ref.invalidate(
    fournisseurLotsOuvertsByFournisseurProvider(lot.fournisseurId),
  );

  return updated;
});

final deleteFournisseurLotProvider =
    riverpod.FutureProvider.family<void, Map<String, String>>((
  ref,
  params,
) async {
  final service = ref.read(fournisseurLotServiceProvider);
  final id = params['id']!;
  final fournisseurId = params['fournisseurId']!;

  await service.delete(id);

  ref.invalidate(fournisseurLotsProvider);
  ref.invalidate(fournisseurLotByIdProvider(id));
  ref.invalidate(fournisseurLotsByFournisseurProvider(fournisseurId));
  ref.invalidate(fournisseurLotsOuvertsByFournisseurProvider(fournisseurId));
});

final fournisseurLotCountsByStatutProvider =
    riverpod.FutureProvider<Map<String, int>>((ref) async {
  final service = ref.read(fournisseurLotServiceProvider);
  return service.countByStatut();
});

/// Lot + CDR liés (écran détail).
final lotDetailProvider =
    riverpod.FutureProvider.autoDispose.family<LotDetailView?, String>((
  ref,
  lotId,
) async {
  final service = ref.read(fournisseurLotServiceProvider);
  final lot = await service.getById(lotId);
  if (lot == null) return null;
  final cdrs = await service.getCdrByLot(lotId);
  return LotDetailView(lot: lot, cdrs: cdrs);
});

/// CDR éligibles pour rattachement (requête filtrée).
final cdrAvailableForLotProvider =
    riverpod.FutureProvider.autoDispose.family<List<CoursDeRoute>,
        FournisseurLot>((ref, lot) async {
  final service = ref.read(fournisseurLotServiceProvider);
  return service.listCdrAvailableForLot(
    fournisseurId: lot.fournisseurId,
    produitId: lot.produitId,
  );
});

void invalidateAfterLotCdrLinkChange(
    riverpod.WidgetRef ref, FournisseurLot lot) {
  ref.invalidate(lotDetailProvider(lot.id));
  ref.invalidate(cdrAvailableForLotProvider(lot));
  ref.invalidate(coursDeRouteListProvider);
  ref.invalidate(fournisseurLotsProvider);
  ref.invalidate(fournisseurLotByIdProvider(lot.id));
}

void _invalidateLotAfterStatutChange(
    riverpod.WidgetRef ref, FournisseurLot lot) {
  ref.invalidate(fournisseurLotsProvider);
  ref.invalidate(lotDetailProvider(lot.id));
  ref.invalidate(fournisseurLotByIdProvider(lot.id));
  ref.invalidate(fournisseurLotsByFournisseurProvider(lot.fournisseurId));
  ref.invalidate(
    fournisseurLotsByFournisseurAndProduitProvider(
      FournisseurLotFilterParams(
        fournisseurId: lot.fournisseurId,
        produitId: lot.produitId,
      ),
    ),
  );
  ref.invalidate(
    fournisseurLotsOuvertsByFournisseurProvider(lot.fournisseurId),
  );
  ref.invalidate(fournisseurLotCountsByStatutProvider);
}

/// Après clôture (statut uniquement) : listes, détail, compteurs.
void invalidateAfterLotClose(riverpod.WidgetRef ref, FournisseurLot lot) {
  _invalidateLotAfterStatutChange(ref, lot);
}

/// Après facturation (statut uniquement) : mêmes invalidations que la clôture.
void invalidateAfterLotFactured(riverpod.WidgetRef ref, FournisseurLot lot) {
  _invalidateLotAfterStatutChange(ref, lot);
}
