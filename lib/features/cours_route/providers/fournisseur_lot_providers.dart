// 📌 Module : Cours de Route - Providers
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2026-04-06
// 🧭 Description : Providers Riverpod pour la gestion des lots fournisseur

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/cours_route/data/fournisseur_lot_service.dart';
import 'package:ml_pp_mvp/features/cours_route/models/fournisseur_lot.dart';

/// Provider du service FournisseurLotService
final fournisseurLotServiceProvider = riverpod.Provider<FournisseurLotService>((
  ref,
) {
  return FournisseurLotService.withClient(Supabase.instance.client);
});

/// Provider : liste de tous les lots fournisseur
final fournisseurLotsProvider =
    riverpod.FutureProvider<List<FournisseurLot>>((ref) async {
      final service = ref.read(fournisseurLotServiceProvider);
      return await service.getAll();
    });

/// Provider : récupérer un lot fournisseur par ID
final fournisseurLotByIdProvider =
    riverpod.FutureProvider.family<FournisseurLot?, String>((ref, id) async {
      final service = ref.read(fournisseurLotServiceProvider);
      return await service.getById(id);
    });

/// Provider : récupérer les lots d’un fournisseur
final fournisseurLotsByFournisseurProvider =
    riverpod.FutureProvider.family<List<FournisseurLot>, String>((
      ref,
      fournisseurId,
    ) async {
      final service = ref.read(fournisseurLotServiceProvider);
      return await service.getByFournisseur(fournisseurId);
    });

/// Paramètres typés pour fournisseur + produit
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

/// Provider : récupérer les lots d’un fournisseur pour un produit donné
final fournisseurLotsByFournisseurAndProduitProvider = riverpod
    .FutureProvider.family<List<FournisseurLot>, FournisseurLotFilterParams>((
      ref,
      params,
    ) async {
      final service = ref.read(fournisseurLotServiceProvider);
      return await service.getByFournisseurAndProduit(
        fournisseurId: params.fournisseurId,
        produitId: params.produitId,
      );
    });

/// Provider : récupérer les lots ouverts d’un fournisseur
final fournisseurLotsOuvertsByFournisseurProvider =
    riverpod.FutureProvider.family<List<FournisseurLot>, String>((
      ref,
      fournisseurId,
    ) async {
      final service = ref.read(fournisseurLotServiceProvider);
      return await service.getOuvertsByFournisseur(fournisseurId);
    });

/// Provider : création d’un lot fournisseur
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

/// Provider : mise à jour d’un lot fournisseur
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

/// Provider : suppression d’un lot fournisseur
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

/// Provider : comptage simple par statut
final fournisseurLotCountsByStatutProvider =
    riverpod.FutureProvider<Map<String, int>>((ref) async {
      final service = ref.read(fournisseurLotServiceProvider);
      return await service.countByStatut();
    });