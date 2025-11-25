import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/sorties/data/sortie_service.dart';

// Fake StocksService pour compter les appels
class FakeStocksService {
  double ambientToday = 1000;
  double v15Today = 1000;
  int decrements = 0;
  Map<String, dynamic>? lastArgs;

  Future<double> getAmbientForToday({required String citerneId, required String produitId}) async =>
      ambientToday;
  Future<double> getV15ForToday({required String citerneId, required String produitId}) async =>
      v15Today;

  Future<void> decrement({
    required String citerneId,
    required String produitId,
    required double volumeAmbiant,
    required double volume15c,
  }) async {
    decrements++;
    lastArgs = {
      'citerneId': citerneId,
      'produitId': produitId,
      'volAmb': volumeAmbiant,
      'vol15': volume15c,
    };
  }
}

void main() {
  test('FakeStocksService: test des mÃ©thodes de base', () async {
    final fakeStocks = FakeStocksService();

    // Test getAmbientForToday
    final ambient = await fakeStocks.getAmbientForToday(citerneId: 'c1', produitId: 'p1');
    expect(ambient, 1000.0);

    // Test getV15ForToday
    final v15 = await fakeStocks.getV15ForToday(citerneId: 'c1', produitId: 'p1');
    expect(v15, 1000.0);

    // Test decrement
    expect(fakeStocks.decrements, 0);
    await fakeStocks.decrement(
      citerneId: 'c1',
      produitId: 'p1',
      volumeAmbiant: 100.0,
      volume15c: 98.0,
    );
    expect(fakeStocks.decrements, 1);
    expect(fakeStocks.lastArgs!['volAmb'], 100.0);
    expect(fakeStocks.lastArgs!['vol15'], 98.0);
  });

  test('FakeStocksService: test stock insuffisant', () async {
    final fakeStocks = FakeStocksService();
    fakeStocks.ambientToday = 50; // Stock faible
    fakeStocks.v15Today = 48;

    final ambient = await fakeStocks.getAmbientForToday(citerneId: 'c1', produitId: 'p1');
    final v15 = await fakeStocks.getV15ForToday(citerneId: 'c1', produitId: 'p1');

    expect(ambient, 50.0);
    expect(v15, 48.0);

    // Test que le stock est insuffisant pour une sortie de 100L
    expect(ambient < 100.0, isTrue);
    expect(v15 < 100.0, isTrue);
  });

  test('FakeStocksService: test multiple decrements', () async {
    final fakeStocks = FakeStocksService();

    // Premier decrement
    await fakeStocks.decrement(
      citerneId: 'c1',
      produitId: 'p1',
      volumeAmbiant: 50.0,
      volume15c: 49.0,
    );

    // DeuxiÃ¨me decrement
    await fakeStocks.decrement(
      citerneId: 'c1',
      produitId: 'p1',
      volumeAmbiant: 30.0,
      volume15c: 29.5,
    );

    expect(fakeStocks.decrements, 2);
    expect(fakeStocks.lastArgs!['volAmb'], 30.0);
    expect(fakeStocks.lastArgs!['vol15'], 29.5);
  });

  test('FakeStocksService: test diffÃ©rents citernes/produits', () async {
    final fakeStocks = FakeStocksService();

    // Test avec diffÃ©rents paramÃ¨tres
    await fakeStocks.decrement(
      citerneId: 'citerne-essence',
      produitId: 'produit-essence',
      volumeAmbiant: 200.0,
      volume15c: 198.0,
    );

    expect(fakeStocks.lastArgs!['citerneId'], 'citerne-essence');
    expect(fakeStocks.lastArgs!['produitId'], 'produit-essence');
    expect(fakeStocks.lastArgs!['volAmb'], 200.0);
    expect(fakeStocks.lastArgs!['vol15'], 198.0);
  });
}

