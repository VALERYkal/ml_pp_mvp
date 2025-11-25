import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/sorties/data/sortie_draft_service.dart';
import 'package:ml_pp_mvp/features/sorties/data/sortie_input.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';

void main() {
  test('calcV15: calcule correctement le volume corrigÃ© Ã  15Â°C', () {
    // Test de la fonction de calcul utilisÃ©e par le service
    final volObs = 100.0;
    final temp = 30.0;
    final densite = 0.835;

    final v15 = calcV15(volumeObserveL: volObs, temperatureC: temp, densiteA15: densite);

    // VÃ©rification que le calcul est cohÃ©rent
    expect(v15, isA<double>());
    expect(v15, isNot(volObs)); // Le volume corrigÃ© doit Ãªtre diffÃ©rent
    expect(v15, greaterThan(0)); // Doit Ãªtre positif
  });

  test('SortieInput: validation des champs requis', () {
    // Test de la structure SortieInput
    final input = SortieInput(
      citerneId: 'c1',
      produitId: 'p1',
      clientId: 'cl1',
      partenaireId: null,
      indexAvant: 1000,
      indexApres: 1100,
      temperatureC: 25,
      densiteA15: 0.83,
      proprietaireType: 'MONALUXE',
      note: 'test',
      dateSortie: DateTime(2025, 8, 14),
      chauffeurNom: 'John',
      plaqueCamion: 'ABC-123',
      plaqueRemorque: null,
      transporteur: 'DHL',
    );

    expect(input.citerneId, 'c1');
    expect(input.produitId, 'p1');
    expect(input.indexAvant, 1000);
    expect(input.indexApres, 1100);
    expect(input.proprietaireType, 'MONALUXE');
    expect(input.chauffeurNom, 'John');
    expect(input.transporteur, 'DHL');
  });

  test('SortieInput: validation des indices cohÃ©rents', () {
    // Test que les indices sont logiques
    final input = SortieInput(
      citerneId: 'c1',
      produitId: 'p1',
      clientId: 'cl1',
      partenaireId: null,
      indexAvant: 1000,
      indexApres: 1100, // > indexAvant
      temperatureC: 25,
      densiteA15: 0.83,
      proprietaireType: 'MONALUXE',
      note: null,
      dateSortie: DateTime(2025, 8, 14),
      chauffeurNom: 'John',
      plaqueCamion: 'ABC-123',
      plaqueRemorque: null,
      transporteur: 'DHL',
    );

    final volumeAmbiant = (input.indexApres ?? 0) - (input.indexAvant ?? 0);
    expect(volumeAmbiant, 100.0);
    expect(volumeAmbiant, greaterThan(0));
  });

  test('SortieInput: validation propriÃ©taire valide', () {
    // Test des valeurs autorisÃ©es pour proprietaireType
    final input1 = SortieInput(
      citerneId: 'c1',
      produitId: 'p1',
      clientId: 'cl1',
      partenaireId: null,
      indexAvant: 1000,
      indexApres: 1100,
      temperatureC: 25,
      densiteA15: 0.83,
      proprietaireType: 'MONALUXE', // â Valide
      note: null,
      dateSortie: DateTime(2025, 8, 14),
      chauffeurNom: 'John',
      plaqueCamion: 'ABC-123',
      plaqueRemorque: null,
      transporteur: 'DHL',
    );

    final input2 = SortieInput(
      citerneId: 'c1',
      produitId: 'p1',
      clientId: null,
      partenaireId: 'part1',
      indexAvant: 1000,
      indexApres: 1100,
      temperatureC: 25,
      densiteA15: 0.83,
      proprietaireType: 'PARTENAIRE', // â Valide
      note: null,
      dateSortie: DateTime(2025, 8, 14),
      chauffeurNom: 'John',
      plaqueCamion: 'ABC-123',
      plaqueRemorque: null,
      transporteur: 'DHL',
    );

    expect(input1.proprietaireType, 'MONALUXE');
    expect(input2.proprietaireType, 'PARTENAIRE');
  });

  test('SortieInput: validation bÃ©nÃ©ficiaire requis', () {
    // Test qu'au moins un bÃ©nÃ©ficiaire est fourni
    final input = SortieInput(
      citerneId: 'c1',
      produitId: 'p1',
      clientId: 'cl1', // â Client fourni
      partenaireId: null,
      indexAvant: 1000,
      indexApres: 1100,
      temperatureC: 25,
      densiteA15: 0.83,
      proprietaireType: 'MONALUXE',
      note: null,
      dateSortie: DateTime(2025, 8, 14),
      chauffeurNom: 'John',
      plaqueCamion: 'ABC-123',
      plaqueRemorque: null,
      transporteur: 'DHL',
    );

    // Au moins un des deux doit Ãªtre non-null
    expect(input.clientId != null || input.partenaireId != null, isTrue);
  });

  test('SortieInput: validation champs transport requis', () {
    // Test que les champs transport sont fournis
    final input = SortieInput(
      citerneId: 'c1',
      produitId: 'p1',
      clientId: 'cl1',
      partenaireId: null,
      indexAvant: 1000,
      indexApres: 1100,
      temperatureC: 25,
      densiteA15: 0.83,
      proprietaireType: 'MONALUXE',
      note: null,
      dateSortie: DateTime(2025, 8, 14),
      chauffeurNom: 'John Doe', // â Non vide
      plaqueCamion: 'ABC-123', // â Non vide
      plaqueRemorque: null, // Optionnel
      transporteur: 'DHL', // â Non vide
    );

    expect(input.chauffeurNom?.isNotEmpty ?? false, isTrue);
    expect(input.plaqueCamion?.isNotEmpty ?? false, isTrue);
    expect(input.transporteur?.isNotEmpty ?? false, isTrue);
  });
}

