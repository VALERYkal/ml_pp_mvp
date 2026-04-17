import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/lots_finance/data/fournisseur_finance_lot_service.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/providers/fournisseur_finance_lot_providers.dart';

/// Double de test : aucun [SupabaseClient].
class FakeFournisseurFinanceLotService implements FournisseurFinanceLotService {
  FakeFournisseurFinanceLotService({
    List<FournisseurFactureLot>? factures,
    List<FournisseurRapprochementLot>? rapprochements,
    FournisseurFactureLot? Function(CreateFournisseurFactureLotInput input)?
        onCreateFacture,
  })  : _factures = List<FournisseurFactureLot>.from(factures ?? const []),
        _rapprochements =
            List<FournisseurRapprochementLot>.from(rapprochements ?? const []),
        _onCreateFacture = onCreateFacture;

  final List<FournisseurFactureLot> _factures;
  final List<FournisseurRapprochementLot> _rapprochements;
  final FournisseurFactureLot? Function(CreateFournisseurFactureLotInput input)?
      _onCreateFacture;

  final List<CreateFournisseurPaiementLotInput> paiementCalls = [];
  final List<FournisseurPaiementLot> paiements = [];

  @override
  Future<List<FournisseurFactureLot>> fetchFacturesLot() async =>
      List<FournisseurFactureLot>.from(_factures);

  @override
  Future<FournisseurFactureLot?> fetchFactureLotById(String id) async {
    final t = id.trim();
    if (t.isEmpty) return null;
    for (final f in _factures) {
      if (f.factureId == t) return f;
    }
    return null;
  }

  @override
  Future<List<FournisseurRapprochementLot>> fetchRapprochementsLot() async =>
      List<FournisseurRapprochementLot>.from(_rapprochements);

  @override
  Future<FournisseurFactureLot> createFactureLot(
    CreateFournisseurFactureLotInput input,
  ) async {
    final built = _onCreateFacture?.call(input);
    if (built != null) {
      _factures.insert(0, built);
      return built;
    }
    throw StateError('Fake: configure onCreateFacture');
  }

  @override
  Future<void> createPaiementLot(CreateFournisseurPaiementLotInput input) async {
    paiementCalls.add(input);
  }

  @override
  Future<List<FournisseurPaiementLot>> fetchPaiementsLotByFactureId(
    String factureId,
  ) async {
    final trimmed = factureId.trim();
    return paiements
        .where((p) => p.fournisseurFactureId == trimmed)
        .toList(growable: false);
  }
}

FournisseurFactureLot _facture(String id, {String invoiceNo = 'INV'}) {
  return FournisseurFactureLot.fromMap({
    'facture_id': id,
    'invoice_no': invoiceNo,
    'deal_reference': null,
    'fournisseur_lot_id': 'lot-1',
    'nb_receptions': 0,
    'total_volume_15c': 0,
    'total_volume_20c': 0,
    'quantite_facturee_20c': 0,
    'ecart_volume_20c': 0,
    'statut_rapprochement': 'n/a',
    'prix_unitaire_usd': 0,
    'montant_total_usd': 0,
    'montant_regle_usd': 0,
    'solde_restant_usd': 0,
    'statut_paiement': 'n/a',
    'date_facture': null,
    'date_echeance': null,
    'created_at': null,
  });
}

FournisseurRapprochementLot _rapprochement(String id) {
  return FournisseurRapprochementLot.fromMap({
    'facture_id': id,
    'invoice_no': 'R-$id',
    'deal_reference': null,
    'fournisseur_lot_id': 'lot-1',
    'nb_receptions': 0,
    'total_volume_15c': 0,
    'total_volume_20c': 0,
    'quantite_facturee_20c': 0,
    'ecart_volume_20c': 0,
    'prix_unitaire_usd': 0,
    'montant_total_usd': 0,
    'statut_rapprochement': 'ok',
  });
}

void main() {
  group('fournisseurFacturesLotProvider', () {
    test('retourne une liste de FournisseurFactureLot', () async {
      final fake = FakeFournisseurFinanceLotService(
        factures: [_facture('a'), _facture('b')],
      );
      final container = ProviderContainer(
        overrides: [
          fournisseurFinanceLotServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      final list = await container.read(fournisseurFacturesLotProvider.future);

      expect(list, isA<List<FournisseurFactureLot>>());
      expect(list, hasLength(2));
      expect(list.map((e) => e.factureId).toList(), ['a', 'b']);
    });
  });

  group('fournisseurFactureLotByIdProvider', () {
    test('retourne la facture attendue pour un factureId', () async {
      final f1 = _facture('fid-1', invoiceNo: 'I1');
      final fake = FakeFournisseurFinanceLotService(factures: [f1]);
      final container = ProviderContainer(
        overrides: [
          fournisseurFinanceLotServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      final got =
          await container.read(fournisseurFactureLotByIdProvider('fid-1').future);

      expect(got, isNotNull);
      expect(got!.factureId, 'fid-1');
      expect(got.invoiceNo, 'I1');
    });
  });

  group('fournisseurRapprochementsLotProvider', () {
    test('retourne une liste de FournisseurRapprochementLot', () async {
      final fake = FakeFournisseurFinanceLotService(
        rapprochements: [_rapprochement('r1')],
      );
      final container = ProviderContainer(
        overrides: [
          fournisseurFinanceLotServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      final list =
          await container.read(fournisseurRapprochementsLotProvider.future);

      expect(list, isA<List<FournisseurRapprochementLot>>());
      expect(list, hasLength(1));
      expect(list.single.factureId, 'r1');
    });
  });

  group('createFournisseurFactureLotProvider', () {
    test('création retourne FournisseurFactureLot ; lecture via .future', () async {
      final fake = FakeFournisseurFinanceLotService(
        onCreateFacture: (input) {
          return _facture('new-1', invoiceNo: input.invoiceNo);
        },
      );
      final container = ProviderContainer(
        overrides: [
          fournisseurFinanceLotServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      final input = CreateFournisseurFactureLotInput(
        fournisseurLotId: 'lot-1',
        invoiceNo: 'INV-X',
        dealReference: null,
        dateFacture: DateTime.utc(2025, 1, 1),
        dateEcheance: null,
        quantiteFacturee20c: 1,
        prixUnitaireUsd: 2,
      );

      final created = await container.read(
        createFournisseurFactureLotProvider(input).future,
      );

      expect(created, isA<FournisseurFactureLot>());
      expect(created.factureId, 'new-1');
      expect(created.invoiceNo, 'INV-X');
    });
  });

  group('createFournisseurPaiementLotProvider', () {
    test('appel sans erreur et passage par le fake service', () async {
      final fake = FakeFournisseurFinanceLotService();
      final container = ProviderContainer(
        overrides: [
          fournisseurFinanceLotServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      final input = CreateFournisseurPaiementLotInput(
        fournisseurFactureId: 'fac-99',
        datePaiement: null,
        montantPayeUsd: 10,
        modePaiement: null,
        referencePaiement: null,
        note: null,
      );

      await container.read(createFournisseurPaiementLotProvider(input).future);

      expect(fake.paiementCalls, hasLength(1));
      expect(fake.paiementCalls.single.fournisseurFactureId, 'fac-99');
      expect(fake.paiementCalls.single.montantPayeUsd, 10.0);
    });
  });

  group('fournisseurPaiementsLotByFactureIdProvider', () {
    test('retourne les paiements de la facture demandée', () async {
      final fake = FakeFournisseurFinanceLotService()
        ..paiements.addAll([
          FournisseurPaiementLot.fromMap({
            'id': 'p1',
            'fournisseur_facture_id': 'fac-1',
            'date_paiement': '2026-04-12T10:00:00Z',
            'montant_paye_usd': 50,
            'mode_paiement': 'VIREMENT',
            'reference_paiement': 'REF-A',
            'note': 'ok',
            'created_at': '2026-04-12T10:00:00Z',
          }),
          FournisseurPaiementLot.fromMap({
            'id': 'p2',
            'fournisseur_facture_id': 'fac-2',
            'date_paiement': '2026-04-11T10:00:00Z',
            'montant_paye_usd': 25,
            'mode_paiement': 'CASH',
            'reference_paiement': 'REF-B',
            'note': null,
            'created_at': '2026-04-11T10:00:00Z',
          }),
        ]);
      final container = ProviderContainer(
        overrides: [
          fournisseurFinanceLotServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        fournisseurPaiementsLotByFactureIdProvider('fac-1').future,
      );

      expect(result, hasLength(1));
      expect(result.single.paiementId, 'p1');
      expect(result.single.fournisseurFactureId, 'fac-1');
      expect(result.single.montantPayeUsd, 50.0);
    });
  });
}
