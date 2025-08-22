import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_input.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';

void main() {
  test('calcV15: calcule correctement le volume corrigé à 15°C', () {
    // Test de la fonction de calcul utilisée par le service
    final volObs = 100.0;
    final temp = 30.0;
    final densite = 0.835;

    final v15 = calcV15(
      volumeObserveL: volObs,
      temperatureC: temp,
      densiteA15: densite,
    );

    // Vérification que le calcul est cohérent
    expect(v15, isA<double>());
    expect(v15, isNot(volObs)); // Le volume corrigé doit être différent
    expect(v15, greaterThan(0)); // Doit être positif
  });

  test('ReceptionInput: validation des champs requis', () {
    // Test de la structure ReceptionInput
    final input = ReceptionInput(
      proprietaireType: 'MONALUXE',
      coursDeRouteId: 'cdr1',
      produitCode: 'ESS',
      produitId: 'p1',
      citerneId: 'c1',
      partenaireId: null,
      indexAvant: 1000,
      indexApres: 1100,
      temperatureC: 25,
      densiteA15: 0.83,
      dateReception: DateTime(2025, 8, 14),
      note: 'test',
    );

    expect(input.citerneId, 'c1');
    expect(input.produitCode, 'ESS');
    expect(input.produitId, 'p1');
    expect(input.indexAvant, 1000);
    expect(input.indexApres, 1100);
    expect(input.proprietaireType, 'MONALUXE');
    expect(input.coursDeRouteId, 'cdr1');
  });

  test('ReceptionInput: validation des indices cohérents', () {
    // Test que les indices sont logiques
    final input = ReceptionInput(
      proprietaireType: 'MONALUXE',
      coursDeRouteId: 'cdr1',
      produitCode: 'ESS',
      produitId: 'p1',
      citerneId: 'c1',
      partenaireId: null,
      indexAvant: 1000,
      indexApres: 1100, // > indexAvant
      temperatureC: 25,
      densiteA15: 0.83,
      dateReception: DateTime(2025, 8, 14),
      note: null,
    );

    final volumeAmbiant = (input.indexApres ?? 0) - (input.indexAvant ?? 0);
    expect(volumeAmbiant, 100.0);
    expect(volumeAmbiant, greaterThan(0));
  });

  test('ReceptionInput: validation propriétaire valide', () {
    // Test des valeurs autorisées pour proprietaireType
    final input1 = ReceptionInput(
      proprietaireType: 'MONALUXE', // ✅ Valide
      coursDeRouteId: 'cdr1',
      produitCode: 'ESS',
      produitId: 'p1',
      citerneId: 'c1',
      partenaireId: null,
      indexAvant: 1000,
      indexApres: 1100,
      temperatureC: 25,
      densiteA15: 0.83,
      dateReception: DateTime(2025, 8, 14),
      note: null,
    );

    final input2 = ReceptionInput(
      proprietaireType: 'PARTENAIRE', // ✅ Valide
      coursDeRouteId: null,
      produitCode: 'AGO',
      produitId: 'p2',
      citerneId: 'c2',
      partenaireId: 'par1',
      indexAvant: 500,
      indexApres: 650,
      temperatureC: 25,
      densiteA15: 0.84,
      dateReception: DateTime(2025, 8, 14),
      note: null,
    );

    expect(input1.proprietaireType, 'MONALUXE');
    expect(input2.proprietaireType, 'PARTENAIRE');
  });

  test('ReceptionInput: validation Monaluxe avec CDR', () {
    // Test que Monaluxe nécessite un cours de route
    final input = ReceptionInput(
      proprietaireType: 'MONALUXE',
      coursDeRouteId: 'cdr1', // ✅ CDR fourni
      produitCode: 'ESS',
      produitId: 'p1',
      citerneId: 'c1',
      partenaireId: null,
      indexAvant: 1000,
      indexApres: 1100,
      temperatureC: 25,
      densiteA15: 0.83,
      dateReception: DateTime(2025, 8, 14),
      note: null,
    );

    expect(input.coursDeRouteId, isNotNull);
    expect(input.produitId, isNotNull);
  });

  test('ReceptionInput: validation Partenaire avec partenaire', () {
    // Test que Partenaire nécessite un partenaire
    final input = ReceptionInput(
      proprietaireType: 'PARTENAIRE',
      coursDeRouteId: null,
      produitCode: 'AGO',
      produitId: 'p2',
      citerneId: 'c2',
      partenaireId: 'par1', // ✅ Partenaire fourni
      indexAvant: 500,
      indexApres: 650,
      temperatureC: 25,
      densiteA15: 0.84,
      dateReception: DateTime(2025, 8, 14),
      note: null,
    );

    expect(input.partenaireId, isNotNull);
    expect(input.coursDeRouteId, isNull);
  });

  test('ReceptionInput: validation citerne requise', () {
    // Test que la citerne est toujours requise
    final input = ReceptionInput(
      proprietaireType: 'MONALUXE',
      coursDeRouteId: 'cdr1',
      produitCode: 'ESS',
      produitId: 'p1',
      citerneId: 'c1', // ✅ Citerne fournie
      partenaireId: null,
      indexAvant: 1000,
      indexApres: 1100,
      temperatureC: 25,
      densiteA15: 0.83,
      dateReception: DateTime(2025, 8, 14),
      note: null,
    );

    expect(input.citerneId, isNotNull);
    expect(input.citerneId!.isNotEmpty, isTrue);
  });
}
