/// IDs fixes du seed staging minimal (seed_staging_minimal_v2.sql)
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

  factory FixtureIds.makeRunTag() {
    return FixtureIds(
      depotId: '11111111-1111-1111-1111-111111111111',
      produitId: '22222222-2222-2222-2222-222222222222',
      citerneId: '33333333-3333-3333-3333-333333333333',
      tag: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}

