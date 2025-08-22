import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart'; // unused
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ml_pp_mvp/features/receptions/data/reception_service.dart';
import 'package:ml_pp_mvp/features/receptions/models/reception.dart';
import 'package:ml_pp_mvp/features/receptions/models/owner_type.dart';
import 'package:ml_pp_mvp/features/citernes/data/citerne_service.dart';
import 'package:ml_pp_mvp/features/stocks_journaliers/data/stocks_service.dart';

import 'reception_service_test.mocks.dart';

// Fakes top-level pour simplifier les tests
class _TestSupabaseClient extends SupabaseClient {
  _TestSupabaseClient() : super('http://localhost', 'anon');
}

class FakeCiterneServiceInactive extends CiterneService {
  FakeCiterneServiceInactive() : super.withClient(_TestSupabaseClient());
  @override
  Future<CiterneInfo?> getById(String id) async => CiterneInfo(
        id: id,
        capaciteTotale: 5000,
        capaciteSecurite: 500,
        statut: 'inactive',
        produitId: 'prod-1',
      );
}

class FakeCiterneServiceIncompatible extends CiterneService {
  FakeCiterneServiceIncompatible() : super.withClient(_TestSupabaseClient());
  @override
  Future<CiterneInfo?> getById(String id) async => CiterneInfo(
        id: id,
        capaciteTotale: 5000,
        capaciteSecurite: 500,
        statut: 'active',
        produitId: 'autre-prod',
      );
}

class FakeCiterneServiceCapacity extends CiterneService {
  FakeCiterneServiceCapacity() : super.withClient(_TestSupabaseClient());
  @override
  Future<CiterneInfo?> getById(String id) async => CiterneInfo(
        id: id,
        capaciteTotale: 2000,
        capaciteSecurite: 500,
        statut: 'active',
        produitId: 'prod-1',
      );
}

class FakeStocksServiceHigh extends StocksService {
  FakeStocksServiceHigh() : super.withClient(_TestSupabaseClient());
  @override
  Future<double> getAmbientForToday({required String citerneId, required String produitId, DateTime? dateJour}) async => 600.0;
}

@GenerateMocks([SupabaseClient])
void main() {
  group('ReceptionService validations', () {
    late MockSupabaseClient mockClient;

    Reception buildReception({double indexAvant = 0, double indexApres = 1000}) => Reception(
          id: '',
          coursDeRouteId: 'cours-1',
          citerneId: 'cit-1',
          produitId: 'prod-1',
          indexAvant: indexAvant,
          indexApres: indexApres,
          proprietaireType: OwnerType.monaluxe,
        );

    setUp(() {
      mockClient = MockSupabaseClient();
    });

    test('rejette indices incohérents (volume <= 0)', () async {
      final service = ReceptionService.withClient(mockClient);
      final r = buildReception(indexApres: 0);
      expect(() => service.createReception(r), throwsA(isA<ArgumentError>()));
    });

    test('rejette citerne inactive', () async {
      final service = ReceptionService.withClient(
        mockClient,
        citerneServiceFactory: (_) => FakeCiterneServiceInactive(),
        stocksServiceFactory: (_) => StocksService.withClient(mockClient),
      );

      expect(
        () => service.createReception(buildReception()),
        throwsA(isA<ArgumentError>().having((e) => e.toString(), 'message', contains('Citerne inactive'))),
      );
    });

    test('rejette produit incompatible', () async {
      final service = ReceptionService.withClient(
        mockClient,
        citerneServiceFactory: (_) => FakeCiterneServiceIncompatible(),
        stocksServiceFactory: (_) => StocksService.withClient(mockClient),
      );

      expect(
        () => service.createReception(buildReception()),
        throwsA(isA<ArgumentError>().having((e) => e.toString(), 'message', contains('Produit incompatible'))),
      );
    });

    test('rejette capacité insuffisante (volume > capacitéDisponible)', () async {
      final service = ReceptionService.withClient(
        mockClient,
        citerneServiceFactory: (_) => FakeCiterneServiceCapacity(),
        stocksServiceFactory: (_) => FakeStocksServiceHigh(),
      );

      // vObs = 1000, capacityDisponible = 2000 - 500 - 600 = 900 → 1000 > 900
      expect(
        () => service.createReception(buildReception()),
        throwsA(isA<ArgumentError>().having((e) => e.toString(), 'message', contains('capacité disponible'))),
      );
    });
  });
}
