import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/lots/data/fournisseur_lot_service.dart';
import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';

/// Double de test pour [FournisseurLotService] (méthodes utilisées par les tests + journal FK).
class FakeFournisseurLotService implements FournisseurLotService {
  FakeFournisseurLotService({
    this.lotOverride,
    this.cdrsForLot = const [],
    this.available = const [],
  });

  FournisseurLot? lotOverride;
  List<CoursDeRoute> cdrsForLot;
  List<CoursDeRoute> available;

  final List<(String cdrId, String lotId)> attachCalls = [];
  final List<String> detachCalls = [];
  final List<String> closeLotCalls = [];
  final List<String> markLotAsFacturedCalls = [];

  @override
  Future<List<FournisseurLot>> getAll() async => throw UnimplementedError();

  @override
  Future<FournisseurLot?> getById(String id) async {
    final l = lotOverride;
    if (l == null) return null;
    return l.id == id ? l : null;
  }

  @override
  Future<List<FournisseurLot>> getByFournisseur(String fournisseurId) async =>
      throw UnimplementedError();

  @override
  Future<List<FournisseurLot>> getByFournisseurAndProduit({
    required String fournisseurId,
    required String produitId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<FournisseurLot>> getOuvertsByFournisseur(
    String fournisseurId,
  ) async =>
      throw UnimplementedError();

  @override
  Future<FournisseurLot> create(FournisseurLot lot) async =>
      throw UnimplementedError();

  @override
  Future<FournisseurLot> update(FournisseurLot lot) async =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) async => throw UnimplementedError();

  @override
  Future<Map<String, int>> countByStatut() async => throw UnimplementedError();

  @override
  Future<List<CoursDeRoute>> getCdrByLot(String lotId) async {
    if (lotOverride != null && lotOverride!.id == lotId) {
      return cdrsForLot;
    }
    return cdrsForLot;
  }

  @override
  Future<List<CoursDeRoute>> listCdrAvailableForLot({
    required String fournisseurId,
    required String produitId,
  }) async {
    return available
        .where(
          (c) =>
              c.fournisseurId == fournisseurId && c.produitId == produitId,
        )
        .toList();
  }

  @override
  Future<void> attachCdrToLot(String cdrId, String lotId) async {
    attachCalls.add((cdrId, lotId));
  }

  @override
  Future<void> detachCdrFromLot(String cdrId) async {
    detachCalls.add(cdrId);
  }

  @override
  Future<FournisseurLot> closeLot(String lotId) async {
    closeLotCalls.add(lotId);
    final l = lotOverride;
    if (l == null || l.id != lotId) {
      throw StateError('closeLot: lot introuvable');
    }
    lotOverride = l.copyWith(statut: StatutFournisseurLot.cloture);
    return lotOverride!;
  }

  @override
  Future<FournisseurLot> markLotAsFactured(String lotId) async {
    markLotAsFacturedCalls.add(lotId);
    final l = lotOverride;
    if (l == null || l.id != lotId) {
      throw StateError('markLotAsFactured: lot introuvable');
    }
    lotOverride = l.copyWith(statut: StatutFournisseurLot.facture);
    return lotOverride!;
  }
}
