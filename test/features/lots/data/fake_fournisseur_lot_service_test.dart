import 'package:flutter_test/flutter_test.dart';
import '../fake_fournisseur_lot_service.dart';

void main() {
  group('FakeFournisseurLotService (journal attach / detach)', () {
    test('attachCdrToLot enregistre la paire', () async {
      final fake = FakeFournisseurLotService();
      await fake.attachCdrToLot('cdr', 'lot');
      expect(fake.attachCalls, const [('cdr', 'lot')]);
    });

    test('detachCdrFromLot enregistre l’id CDR', () async {
      final fake = FakeFournisseurLotService();
      await fake.detachCdrFromLot('cdr-x');
      expect(fake.detachCalls, const ['cdr-x']);
    });

    test('plusieurs attach sont cumulés', () async {
      final fake = FakeFournisseurLotService();
      await fake.attachCdrToLot('a', 'l');
      await fake.attachCdrToLot('b', 'l');
      expect(fake.attachCalls, const [('a', 'l'), ('b', 'l')]);
    });
  });
}
