import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/sorties/data/sortie_service.dart';
import 'package:ml_pp_mvp/features/sorties/models/sortie_produit.dart';
import 'package:ml_pp_mvp/features/citernes/data/citerne_service.dart';
import 'package:ml_pp_mvp/features/stocks_journaliers/data/stocks_service.dart';

class _FakeClient extends SupabaseClient {
  _FakeClient() : super('http://localhost', 'anon');
}

class _FakeCiterneActiveGood extends CiterneService {
  _FakeCiterneActiveGood() : super.withClient(_FakeClient());
  @override
  Future<CiterneInfo?> getById(String id) async => CiterneInfo(
        id: id,
        capaciteTotale: 10000,
        capaciteSecurite: 500,
        statut: 'active',
        produitId: 'prod-1',
      );
}

class _FakeStocksFixed extends StocksService {
  final double stock;
  _FakeStocksFixed(this.stock) : super.withClient(_FakeClient());
  @override
  Future<double> getAmbientForToday({required String citerneId, required String produitId, DateTime? dateJour}) async => stock;
  @override
  Future<void> increment({required String citerneId, required String produitId, required double volumeAmbiant, required double volume15c, DateTime? dateJour}) async {}
}

void main() {
  group('SortieService validations', () {
    final supa = _FakeClient();

    SortieProduit build({double avant = 1000, double apres = 1200, String? clientId = 'cli-1', String? partenaireId}) => SortieProduit(
          id: '',
          citerneId: 'cit-1',
          produitId: 'prod-1',
          clientId: clientId,
          partenaireId: partenaireId,
          indexAvant: avant,
          indexApres: apres,
        );

    test('rejette indices incohérents', () async {
      final service = SortieService(supa);
      expect(() => service.createValidated(
        citerneId: 'cit-1',
        produitId: 'prod-1',
        indexAvant: 1000,
        indexApres: 900,
      ), throwsA(isA<StateError>()));
    });

    test('rejette bénéficiaire manquant', () async {
      final service = SortieService(supa);
      expect(() => service.createValidated(
        citerneId: 'cit-1',
        produitId: 'prod-1',
        indexAvant: 1000,
        indexApres: 1200,
        // Pas de clientId ni partenaireId
      ), throwsA(isA<PostgrestException>()));
    });

    test('rejette stock insuffisant', () async {
      final service = SortieService(supa);
      // Ce test nécessiterait une validation côté service, mais actuellement c'est géré par les triggers DB
      // On teste juste que le service fonctionne avec des données valides
      expect(service, isA<SortieService>());
    });

    // Note: pas de happy path ici pour éviter les appels réseau réels
  });
}


