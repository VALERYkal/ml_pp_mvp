@Tags(['e2e'])
// test/e2e/auth/login_flow_e2e_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Adapte ces imports à tes chemins réels :
import 'package:ml_pp_mvp/features/auth/screens/login_screen.dart';
import 'package:ml_pp_mvp/core/services/auth_service.dart';
import 'package:ml_pp_mvp/shared/providers/auth_service_provider.dart';

// Mock simple via Mockito (déjà généré dans test/features/auth/mocks.mocks.dart)
import '../../features/auth/mocks.mocks.dart';
import 'package:mockito/mockito.dart';

// On réutilise la même logique rôle que le test d'intégration
enum UserRole { admin, directeur, gerant, operateur, pca, lecture }

final isLoggedInProvider = StateProvider<bool>((_) => false);
final roleProvider = StateProvider<UserRole?>((_) => null);

class _TestApp extends ConsumerWidget {
  const _TestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(isLoggedInProvider);
    final role = ref.watch(roleProvider);

    String? redirectFn(BuildContext context, GoRouterState state) {
      if (!loggedIn) return state.matchedLocation == '/login' ? null : '/login';
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
          return '/login';
      }
    }

    final router = GoRouter(
      initialLocation: '/login',
      redirect: redirectFn,
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(
          path: '/admin',
          builder: (_, __) => const _Screen('ADMIN', 'screen_admin'),
        ),
        GoRoute(
          path: '/directeur',
          builder: (_, __) => const _Screen('DIRECTEUR', 'screen_directeur'),
        ),
        GoRoute(
          path: '/gerant',
          builder: (_, __) => const _Screen('GERANT', 'screen_gerant'),
        ),
        GoRoute(
          path: '/operateur',
          builder: (_, __) => const _Screen('OPERATEUR', 'screen_operateur'),
        ),
        GoRoute(
          path: '/pca',
          builder: (_, __) => const _Screen('PCA', 'screen_pca'),
        ),
        GoRoute(
          path: '/lecture',
          builder: (_, __) => const _Screen('LECTURE', 'screen_lecture'),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }
}

class _Screen extends StatelessWidget {
  final String label;
  final String keyName;
  const _Screen(this.label, this.keyName, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(key: Key(keyName), child: Text(label)),
  );
}

void main() {
  Future<void> _pumpLoginApp(
    WidgetTester tester, {
    required UserRole role,
    required void Function(ProviderContainer) onMounted,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override du service d'auth avec un mock
          authServiceProvider.overrideWith((ref) {
            final mock = MockAuthService();
            // Quand LoginScreen appelle signIn(...), on marque l'état connecté
            when(mock.signIn(any, any)).thenAnswer((_) async {
              ref.read(isLoggedInProvider.notifier).state = true;
              return MockUser();
            });
            // Si ton LoginScreen lit authStateChanges, renvoie un stream stable
            when(mock.authStateChanges).thenAnswer((_) => const Stream.empty());
            return mock;
          }),
          // Pré-configurer le rôle cible
          roleProvider.overrideWith((_) => role),
        ],
        child: const _TestApp(),
      ),
    );
    // Point d'accroche si tu veux lire/écrire des providers après montage
    onMounted(ProviderScope.containerOf(tester.element(find.byType(_TestApp))));
    await tester.pumpAndSettle();
  }

  Future<void> _performLogin(WidgetTester tester) async {
    final email = find.byKey(const Key('email'));
    final password = find.byKey(const Key('password'));
    final loginBtn = find.byKey(const Key('login_button'));

    expect(email, findsOneWidget);
    expect(password, findsOneWidget);
    expect(loginBtn, findsOneWidget);

    await tester.enterText(email, 'admin@example.com');
    await tester.enterText(password, 'P@ssw0rd!');
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();
  }

  testWidgets('E2E: login → admin dashboard', (tester) async {
    await _pumpLoginApp(tester, role: UserRole.admin, onMounted: (_) {});
    await _performLogin(tester);
    expect(find.byKey(const Key('screen_admin')), findsOneWidget);
  });

  testWidgets('E2E: login → opérateur dashboard', (tester) async {
    await _pumpLoginApp(tester, role: UserRole.operateur, onMounted: (_) {});
    await _performLogin(tester);
    expect(find.byKey(const Key('screen_operateur')), findsOneWidget);
  });
}
