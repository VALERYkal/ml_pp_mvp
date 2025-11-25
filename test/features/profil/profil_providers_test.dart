import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ml_pp_mvp/core/models/profil.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';

/// Fake CurrentProfilNotifier qui renvoie une valeur contrôlée
class FakeCurrentProfilNotifier extends CurrentProfilNotifier {
  FakeCurrentProfilNotifier(this._profil);

  final Profil? _profil;

  @override
  Future<Profil?> build() async {
    // On ignore toute la logique réelle (reactiveUserProvider, Supabase, etc.)
    // et on renvoie simplement la valeur injectée.
    return _profil;
  }
}

void main() {
  group('userRoleProvider', () {
    test('retourne null quand aucun profil n’est chargé', () async {
      final container = ProviderContainer(overrides: [
        currentProfilProvider.overrideWith(
          () => FakeCurrentProfilNotifier(null),
        ),
      ]);

      // 🔹 On force l’exécution de build() du notifier
      await container.read(currentProfilProvider.future);

      final role = container.read(userRoleProvider);

      expect(role, isNull);
    });

    test('retourne UserRole.admin quand role="admin"', () async {
      final profil = Profil(
        id: 'test-id',
        userId: 'user-123',
        role: 'admin', // String dans TON modèle
        nomComplet: 'Test Admin',
        email: 'admin@test.com',
        depotId: 'depot-1',
      );

      final container = ProviderContainer(overrides: [
        currentProfilProvider.overrideWith(
          () => FakeCurrentProfilNotifier(profil),
        ),
      ]);

      // 🔹 On attend que currentProfilProvider ait fini son build
      await container.read(currentProfilProvider.future);

      final role = container.read(userRoleProvider);

      expect(role, equals(UserRole.admin));
    });

    test('fallback en UserRole.lecture pour role inconnu', () async {
      final profil = Profil(
        id: 'test-id',
        userId: 'user-123',
        role: 'unknown_role',
        nomComplet: 'Test User',
        email: 'test@example.com',
        depotId: 'depot-1',
      );

      final container = ProviderContainer(overrides: [
        currentProfilProvider.overrideWith(
          () => FakeCurrentProfilNotifier(profil),
        ),
      ]);

      // 🔹 Pareil : on attend la résolution de build()
      await container.read(currentProfilProvider.future);

      final role = container.read(userRoleProvider);

      expect(role, equals(UserRole.lecture));
    });
  });
}
