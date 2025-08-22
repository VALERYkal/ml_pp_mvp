/* ===========================================================
   Tests d'intégration — Flux Réception (client-only, sans réseau)
   Pédagogie:
   - On isole le client via ReceptionServiceV2 + FakeDbPort
   - On simule les règles serveur pour valider l'UX & la gestion d'erreurs
   =========================================================== */
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_input.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_service_v3.dart';
import 'package:ml_pp_mvp/shared/db/db_port.dart';
import '../fixtures/fake_db_port.dart';

void main() {
  group('Reception flow (client-side with FakeDbPort)', () {
    late DbPort db;
    late ReceptionServiceV2 service;

    setUp(() {
      db = FakeDbPort(
        initialStockAmbiant: 1000.0,
        citerneCapaciteTotale: 100000.0,
        citerneCapaciteSecurite: 5000.0,
        citerneActive: true,
        coursArrive: true,
      );
      service = ReceptionServiceV2(db);
    });

    test('HAPPY PATH: createDraft -> validateReception OK', () async {
      final input = ReceptionInput(
        proprietaireType: 'MONALUXE',
        citerneId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        produitCode: 'ESS',
        indexAvant: 1000,
        indexApres: 1060,
        temperatureC: 25,
      );

      final id = await service.createDraft(input);
      expect(id, isNotEmpty);

      await service.validateReception(id); // ne jette pas
    });

    test('ERREUR: indices incohérents (apres <= avant)', () async {
      final input = ReceptionInput(
        proprietaireType: 'MONALUXE',
        citerneId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        produitCode: 'ESS',
        indexAvant: 1000,
        indexApres: 900, // KO
      );

      expect(
        () => service.createDraft(input),
        throwsA(isA<Exception>()),
      );
    });

    test('ERREUR: capacité insuffisante', () async {
      // Capacité dispo ~100000-5000-99000 =  -4000 -> clamp 0 => KO dès volAmb > 0
      db = FakeDbPort(
        initialStockAmbiant: 99000.0, // quasi plein
        citerneCapaciteTotale: 100000.0,
        citerneCapaciteSecurite: 5000.0,
        citerneActive: true,
        coursArrive: true,
      );
      service = ReceptionServiceV2(db);

      final input = ReceptionInput(
        proprietaireType: 'MONALUXE',
        citerneId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        produitCode: 'ESS',
        indexAvant: 1000,
        indexApres: 1010, // 10 L
        temperatureC: 25,
      );

      final id = await service.createDraft(input);
      expect(id, isNotEmpty);

      expect(
        () => service.validateReception(id),
        throwsA(isA<Exception>()),
      );
    });

    test('ERREUR: produit incompatible (citerne ESS, saisie AGO)', () async {
      final input = ReceptionInput(
        proprietaireType: 'MONALUXE',
        citerneId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        produitCode: 'AGO', // KO car citerne mappée sur ESS
        indexAvant: 1000,
        indexApres: 1060,
      );

      expect(
        () => service.createDraft(input),
        throwsA(isA<Exception>()),
      );
    });

    test('ERREUR: cours non "arrivé"', () async {
      db = FakeDbPort(
        initialStockAmbiant: 0,
        citerneCapaciteTotale: 100000.0,
        citerneCapaciteSecurite: 5000.0,
        citerneActive: true,
        coursArrive: false, // KO
      );
      service = ReceptionServiceV2(db);

      final input = ReceptionInput(
        proprietaireType: 'MONALUXE',
        citerneId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        produitCode: 'ESS',
        indexAvant: 1000,
        indexApres: 1060,
        coursDeRouteId: 'cdr-123',
      );

      final id = await service.createDraft(input);
      expect(id, isNotEmpty);

      expect(
        () => service.validateReception(id),
        throwsA(isA<Exception>()),
      );
    });

    test('ERREUR: PARTENAIRE sans partenaire_id', () async {
      final input = ReceptionInput(
        proprietaireType: 'PARTENAIRE',
        citerneId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        produitCode: 'ESS',
        indexAvant: 1000,
        indexApres: 1060,
        // partenaireId omis -> KO attendu en validation
      );

      final id = await service.createDraft(input);
      expect(id, isNotEmpty);

      expect(
        () => service.validateReception(id),
        throwsA(isA<Exception>()),
      );
    });
  });
}


