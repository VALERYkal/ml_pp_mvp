// 📌 Module : Finance fournisseur lot — Providers
// 🧭 Riverpod read/write sur vues/tables finance lot.

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';
import 'package:ml_pp_mvp/features/lots/providers/fournisseur_lot_providers.dart';
import 'package:ml_pp_mvp/features/lots_finance/data/fournisseur_finance_lot_service.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/shared/providers/supabase_client_provider.dart';

final fournisseurFinanceLotServiceProvider =
    riverpod.Provider<FournisseurFinanceLotService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FournisseurFinanceLotService.withClient(client);
});

final fournisseurFacturesLotProvider =
    riverpod.FutureProvider<List<FournisseurFactureLot>>((ref) async {
  final service = ref.read(fournisseurFinanceLotServiceProvider);
  return service.fetchFacturesLot();
});

final fournisseurFactureLotByIdProvider =
    riverpod.FutureProvider.family<FournisseurFactureLot?, String>((
  ref,
  factureId,
) async {
  final service = ref.read(fournisseurFinanceLotServiceProvider);
  return service.fetchFactureLotById(factureId);
});

final fournisseurRapprochementsLotProvider =
    riverpod.FutureProvider<List<FournisseurRapprochementLot>>((ref) async {
  final service = ref.read(fournisseurFinanceLotServiceProvider);
  return service.fetchRapprochementsLot();
});

/// Lots pouvant recevoir une première facture (aucune ligne `fournisseur_facture_lot_min` pour ce lot).
final fournisseurLotsFacturablesProvider =
    riverpod.FutureProvider<List<FournisseurLot>>((ref) async {
  final lots = await ref.watch(fournisseurLotsProvider.future);
  final finance = ref.read(fournisseurFinanceLotServiceProvider);
  final avecFacture = await finance.fetchFournisseurLotIdsAvecFacture();
  return lots.where((l) => !avecFacture.contains(l.id)).toList();
});

/// Action d'écriture : création d'une facture lot.
final createFournisseurFactureLotProvider = riverpod
    .FutureProvider.family<FournisseurFactureLot, CreateFournisseurFactureLotInput>((
  ref,
  input,
) async {
  final service = ref.read(fournisseurFinanceLotServiceProvider);
  final created = await service.createFactureLot(input);

  ref.invalidate(fournisseurFacturesLotProvider);
  ref.invalidate(fournisseurRapprochementsLotProvider);
  ref.invalidate(fournisseurFactureLotByIdProvider(created.factureId));
  ref.invalidate(fournisseurLotsFacturablesProvider);

  return created;
});

/// Action d'écriture : création d'un paiement lot.
final createFournisseurPaiementLotProvider = riverpod
    .FutureProvider.family<void, CreateFournisseurPaiementLotInput>((
  ref,
  input,
) async {
  final service = ref.read(fournisseurFinanceLotServiceProvider);
  await service.createPaiementLot(input);

  // Après paiement, les projections de lecture doivent être rafraîchies.
  ref.invalidate(fournisseurFacturesLotProvider);
  ref.invalidate(fournisseurRapprochementsLotProvider);
  ref.invalidate(fournisseurFactureLotByIdProvider(input.fournisseurFactureId));
  ref.invalidate(fournisseurPaiementsLotByFactureIdProvider(input.fournisseurFactureId));
});

final fournisseurPaiementsLotByFactureIdProvider =
    riverpod.FutureProvider.family<List<FournisseurPaiementLot>, String>((
  ref,
  factureId,
) async {
  final service = ref.read(fournisseurFinanceLotServiceProvider);
  return service.fetchPaiementsLotByFactureId(factureId);
});
