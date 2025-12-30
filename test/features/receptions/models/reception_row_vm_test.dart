// 📌 Module : Réceptions - Tests Modèle ReceptionRowVM
// 🧭 Description : Tests unitaires pour le modèle ReceptionRowVM, notamment le getter sourceLabel

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/receptions/models/reception_row_vm.dart';

void main() {
  group('ReceptionRowVM - sourceLabel', () {
    test('sourceLabel returns fournisseur from CDR when available', () {
      final r = ReceptionRowVM(
        id: 'rec-1',
        dateReception: DateTime.now(),
        propriete: 'MONALUXE',
        produitLabel: 'Essence',
        citerneNom: 'Citerne A',
        vol15: 1000.0,
        volAmb: 1000.0,
        fournisseurNom: 'moccho tst',
        partenaireNom: 'falcon test',
      );
      expect(r.sourceLabel, 'moccho tst');
    });

    test('sourceLabel falls back to partenaire when no CDR fournisseur', () {
      final r = ReceptionRowVM(
        id: 'rec-2',
        dateReception: DateTime.now(),
        propriete: 'PARTENAIRE',
        produitLabel: 'Gasoil',
        citerneNom: 'Citerne B',
        vol15: 2000.0,
        volAmb: 2000.0,
        fournisseurNom: null,
        partenaireNom: 'falcon test',
      );
      expect(r.sourceLabel, 'falcon test');
    });

    test(
      'sourceLabel returns dash when neither fournisseur nor partenaire',
      () {
        final r = ReceptionRowVM(
          id: 'rec-3',
          dateReception: DateTime.now(),
          propriete: 'MONALUXE',
          produitLabel: 'Essence',
          citerneNom: 'Citerne C',
          vol15: 3000.0,
          volAmb: 3000.0,
          fournisseurNom: null,
          partenaireNom: null,
        );
        expect(r.sourceLabel, '—');
      },
    );

    test(
      'sourceLabel prioritizes fournisseur even when partenaire is present',
      () {
        final r = ReceptionRowVM(
          id: 'rec-4',
          dateReception: DateTime.now(),
          propriete: 'MONALUXE',
          produitLabel: 'Essence',
          citerneNom: 'Citerne D',
          vol15: 4000.0,
          volAmb: 4000.0,
          fournisseurNom: 'kemexon',
          partenaireNom: 'falcon test',
        );
        expect(r.sourceLabel, 'kemexon');
      },
    );

    test('sourceLabel handles empty strings as null', () {
      final r = ReceptionRowVM(
        id: 'rec-5',
        dateReception: DateTime.now(),
        propriete: 'PARTENAIRE',
        produitLabel: 'Gasoil',
        citerneNom: 'Citerne E',
        vol15: 5000.0,
        volAmb: 5000.0,
        fournisseurNom: '',
        partenaireNom: 'falcon test',
      );
      expect(r.sourceLabel, 'falcon test');
    });

    test('sourceLabel returns dash when both are empty strings', () {
      final r = ReceptionRowVM(
        id: 'rec-6',
        dateReception: DateTime.now(),
        propriete: 'MONALUXE',
        produitLabel: 'Essence',
        citerneNom: 'Citerne F',
        vol15: 6000.0,
        volAmb: 6000.0,
        fournisseurNom: '',
        partenaireNom: '',
      );
      expect(r.sourceLabel, '—');
    });
  });
}
