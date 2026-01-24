import '../_staging_fixtures.dart';

/// IDs fixes du seed staging minimal (seed_staging_minimal_v2.sql)
///
/// ⚠️ IMPORTANT : Cette classe utilise les IDs centralisés dans `_staging_fixtures.dart`.
/// Ne pas hardcoder les IDs ici, utiliser les constantes `kStaging*`.
class FixtureIds {
  final String depotId;
  final String produitId;
  final String citerneId;
  final String tag;
  String? clientId;
  String? sortieId;
  String? sortieRejectId;

  FixtureIds({
    required this.depotId,
    required this.produitId,
    required this.citerneId,
    required this.tag,
    this.clientId,
    this.sortieId,
    this.sortieRejectId,
  });

  /// Crée un FixtureIds avec les IDs centralisés du seed staging minimal.
  ///
  /// Utilise les constantes `kStagingDepotId`, `kStagingProduitId`, `kStagingCiterneId`
  /// définies dans `_staging_fixtures.dart`.
  ///
  /// ⚠️ NOTE : La citerne '33333333-3333-3333-3333-333333333333' (TANK STAGING 1)
  /// a été supprimée. Cette factory utilise maintenant `kStagingCiterneId`.
  factory FixtureIds.makeRunTag() {
    return FixtureIds(
      depotId: kStagingDepotId,
      produitId: kStagingProduitId,
      citerneId: kStagingCiterneId,
      tag: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}

