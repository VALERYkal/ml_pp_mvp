// test/integration/auth/redirect_by_role_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Enum locale pour le test (évite tout couplage fragile).
enum UserRole { admin, directeur, gerant, operateur, pca, lecture }

// Providers "état auth" simulés pour le test d'intégration.
final isLoggedInProvider = StateProvider<bool>((_) => false);
final roleProvider = StateProvider<UserRole?>((_) => null);

// App de test avec un GoRouter basé sur les providers ci-dessus.
// On lit les providers au build (les overrides sont déjà appliqués dans ProviderScope).
class _TestApp extends ConsumerWidget {
  const _TestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(isLoggedInProvider);
    final role = ref.watch(roleProvider);

    String? redirectFn(BuildContext context, GoRouterState state) {
      // Si pas loggué → rester sur /login
      if (!loggedIn) {
        return state.matchedLocation == '/login' ? null : '/login';
      }
      // Loggué → router selon rôle
      switch (role) {
        case UserRole.admin:
          return state.matchedLocation == '/admin' ? null : '/admin';
        case UserRole.directeur:
          return state.matchedLocation == '/directeur' ? null : '/directeur';
        case UserRole.gerant:
          return state.matchedLocation == '/gerant' ? null : '/gerant';
        case UserRole.operateur:
          return state.matchedLocation == '/operateur' ? null : '/operateur';
        case UserRole.pca:
          return state.matchedLocation == '/pca' ? null : '/pca';
        case UserRole.lecture:
          return state.matchedLocation == '/lecture' ? null : '/lecture';
        default:
          // Cas inattendu → renvoyer login
          return '/login';
      }
    }

    final router = GoRouter(
      initialLocation: '/login',
      redirect: redirectFn,
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const _Screen(label: 'LOGIN', keyName: 'screen_login'),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, __) => const _Screen(label: 'ADMIN', keyName: 'screen_admin'),
        ),
        GoRoute(
          path: '/directeur',
          builder: (_, __) => const _Screen(label: 'DIRECTEUR', keyName: 'screen_directeur'),
        ),
        GoRoute(
          path: '/gerant',
          builder: (_, __) => const _Screen(label: 'GERANT', keyName: 'screen_gerant'),
        ),
        GoRoute(
          path: '/operateur',
          builder: (_, __) => const _Screen(label: 'OPERATEUR', keyName: 'screen_operateur'),
        ),
        GoRoute(
          path: '/pca',
          builder: (_, __) => const _Screen(label: 'PCA', keyName: 'screen_pca'),
        ),
        GoRoute(
          path: '/lecture',
          builder: (_, __) => const _Screen(label: 'LECTURE', keyName: 'screen_lecture'),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }
}

class _Screen extends StatelessWidget {
  final String label;
  final String keyName;
  const _Screen({required this.label, required this.keyName, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        key: Key(keyName),
        child: Text(label),
      ),
    );
  }
}

void main() {
  Future<void> _pumpWithRole(
    WidgetTester tester, {
    required UserRole role,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isLoggedInProvider.overrideWith((ref) => true),
          roleProvider.overrideWith((ref) => role),
        ],
        child: const _TestApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('redirects to admin dashboard', (tester) async {
    await _pumpWithRole(tester, role: UserRole.admin);
    expect(find.byKey(const Key('screen_admin')), findsOneWidget);
  });

  testWidgets('redirects to directeur dashboard', (tester) async {
    await _pumpWithRole(tester, role: UserRole.directeur);
    expect(find.byKey(const Key('screen_directeur')), findsOneWidget);
  });

  testWidgets('redirects to gerant dashboard', (tester) async {
    await _pumpWithRole(tester, role: UserRole.gerant);
    expect(find.byKey(const Key('screen_gerant')), findsOneWidget);
  });

  testWidgets('redirects to operateur dashboard', (tester) async {
    await _pumpWithRole(tester, role: UserRole.operateur);
    expect(find.byKey(const Key('screen_operateur')), findsOneWidget);
  });

  testWidgets('redirects to pca dashboard', (tester) async {
    await _pumpWithRole(tester, role: UserRole.pca);
    expect(find.byKey(const Key('screen_pca')), findsOneWidget);
  });

  testWidgets('redirects to lecture dashboard', (tester) async {
    await _pumpWithRole(tester, role: UserRole.lecture);
    expect(find.byKey(const Key('screen_lecture')), findsOneWidget);
  });

  testWidgets('stays on login when not authenticated', (tester) async {
    // loggedIn=false par défaut
    await tester.pumpWidget(const ProviderScope(child: _TestApp()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen_login')), findsOneWidget);
  });
}
