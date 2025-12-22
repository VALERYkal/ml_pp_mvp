/* ===========================================================
   Tests d'intégration — Flux Réception (DB-STRICT compatible)
   NOTE: Legacy flow (createDraft + validate) supprimé.
   Le flow actuel utilise ReceptionService.createValidated() directement.
   =========================================================== */
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_input.dart';

void main() {
  group('Reception flow (DB-STRICT)', () {
    test('ReceptionInput peut être créé avec les champs requis', () {
      final input = ReceptionInput(
        proprietaireType: 'MONALUXE',
        citerneId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        produitCode: 'ESS',
        indexAvant: 1000,
        indexApres: 1060,
        temperatureC: 25,
      );

      expect(input.proprietaireType, 'MONALUXE');
      expect(input.citerneId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
      expect(input.produitCode, 'ESS');
      expect(input.indexAvant, 1000);
      expect(input.indexApres, 1060);
      expect(input.temperatureC, 25);
    });

    test('ReceptionInput PARTENAIRE avec partenaireId', () {
      final input = ReceptionInput(
        proprietaireType: 'PARTENAIRE',
        citerneId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        produitCode: 'ESS',
        indexAvant: 1000,
        indexApres: 1060,
        partenaireId: 'partner-123',
      );

      expect(input.proprietaireType, 'PARTENAIRE');
      expect(input.partenaireId, 'partner-123');
    });

    // NOTE: Les tests legacy (createDraft/validate) sont supprimés car :
    // - ReceptionServiceV2 / reception_service_v3.dart n'existent plus
    // - Le flow DB-STRICT utilise createValidated() directement (INSERT = validation)
    // - Les tests d'intégration complets nécessiteraient un SupabaseClient réel
    //   et doivent être réécrits dans un contexte E2E approprié
  });
}


