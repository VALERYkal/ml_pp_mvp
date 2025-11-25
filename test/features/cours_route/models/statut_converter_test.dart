import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

void main() {
  group('StatutCoursConverter', () {
    test('fromDb accepte variantes accentuÃ©es et non accentuÃ©es', () {
      expect(StatutCoursConverter.fromDb('frontiere'), StatutCours.frontiere);
      expect(StatutCoursConverter.fromDb('frontiÃ¨re'), StatutCours.frontiere);
      expect(StatutCoursConverter.fromDb('arrive'), StatutCours.arrive);
      expect(StatutCoursConverter.fromDb('arrivÃ©'), StatutCours.arrive);
      expect(StatutCoursConverter.fromDb('decharge'), StatutCours.decharge);
      expect(StatutCoursConverter.fromDb('dÃ©chargÃ©'), StatutCours.decharge);
    });

    test('toDb retourne les formes majuscules sans accents', () {
      expect(StatutCoursConverter.toDb(StatutCours.frontiere), 'FRONTIERE');
      expect(StatutCoursConverter.toDb(StatutCours.arrive), 'ARRIVE');
      expect(StatutCoursConverter.toDb(StatutCours.decharge), 'DECHARGE');
      expect(StatutCoursConverter.toDb(StatutCours.transit), 'TRANSIT');
      expect(StatutCoursConverter.toDb(StatutCours.chargement), 'CHARGEMENT');
    });
  });
}

