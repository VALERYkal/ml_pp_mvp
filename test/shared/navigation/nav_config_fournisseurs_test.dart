import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/shared/navigation/nav_config.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';

void main() {
  group('NavConfig - Fournisseurs menu visibility', () {
    test('admin sees Fournisseurs item', () {
      final items = NavConfig.getItemsForRole(UserRole.admin);

      final hasFournisseurs = items.any((i) => i.id == 'fournisseurs' && i.path == '/fournisseurs');
      expect(hasFournisseurs, isTrue);
    });

    test('operateur does NOT see Fournisseurs item', () {
      final items = NavConfig.getItemsForRole(UserRole.operateur);

      final hasFournisseurs = items.any((i) => i.id == 'fournisseurs' || i.path == '/fournisseurs');
      expect(hasFournisseurs, isFalse);
    });

    test('lecture does NOT see Fournisseurs item', () {
      final items = NavConfig.getItemsForRole(UserRole.lecture);

      final hasFournisseurs = items.any((i) => i.id == 'fournisseurs' || i.path == '/fournisseurs');
      expect(hasFournisseurs, isFalse);
    });
  });
}
