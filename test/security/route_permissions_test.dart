import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum UserRole { admin, operateur }

/// Provider local isolé (pas de variable globale partagée)
final _roleProvider = StateProvider<UserRole>((_) => UserRole.operateur);

/// Widget de test qui crée son propre router isolé dans build()
class _TestApp extends ConsumerWidget {
  final UserRole role;
  final String initialLocation;
  final GoRouter? externalRouter; // Pour les tests avec router.go()

  const _TestApp({
    required this.role,
    this.initialLocation = '/admin',
    this.externalRouter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si un router externe est fourni, l'utiliser directement
    if (externalRouter != null) {
      return MaterialApp.router(routerConfig: externalRouter!);
    }

    // Sinon, créer un nouveau router isolé pour ce test
    // Le router lit le rôle depuis ref (contexte du widget)
    final router = GoRouter(
      initialLocation: initialLocation,
      redirect: (_, s) {
        // Lire le rôle depuis le contexte du widget (ref)
        final currentRole = ref.read(_roleProvider);
        if (s.matchedLocation == '/admin' && currentRole != UserRole.admin) {
          return '/forbidden';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/admin',
          builder: (_, __) => const _Screen('ADMIN', 'screen_admin'),
        ),
        GoRoute(
          path: '/forbidden',
          builder: (_, __) => const _Screen('FORBIDDEN', 'screen_forbidden'),
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

/// Helper pour attendre que les animations et navigations soient complètes
Future<void> pumpUntilSettled(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 50),
  Duration timeout = const Duration(seconds: 3),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (!tester.hasRunningAnimations) return;
  }
  await tester.pumpAndSettle();
}

/// Helper pour obtenir la location actuelle du router de manière fiable
String currentLocation(GoRouter router) {
  // Essayer routeInformationProvider en premier (go_router récent)
  try {
    final loc = router.routeInformationProvider.value.location ?? '';
    if (loc.isNotEmpty) return loc;
  } catch (e) {
    // Fallback si routeInformationProvider n'est pas disponible
  }
  
  // Fallback: utiliser routerDelegate.currentConfiguration
  try {
    return router.routerDelegate.currentConfiguration.uri.toString();
  } catch (e) {
    return '';
  }
}

void main() {
  testWidgets('operateur ne peut pas accéder à /admin', (tester) async {
    // Créer un ProviderContainer isolé pour ce test
    final container = ProviderContainer(
      overrides: [
        _roleProvider.overrideWith((_) => UserRole.operateur),
      ],
    );

    // Créer le widget avec le container isolé
    // Le widget créera son propre router dans build()
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          role: UserRole.operateur,
          initialLocation: '/admin',
        ),
      ),
    );

    // Attendre que la navigation et le redirect soient complétés
    await tester.pump();
    await pumpUntilSettled(tester);
    await tester.pumpAndSettle();

    // Obtenir le router depuis le contexte
    final context = tester.element(find.byType(Scaffold));
    final contextRouter = GoRouter.of(context);

    // Vérifier que l'écran forbidden est affiché
    expect(find.byKey(const Key('screen_forbidden')), findsOneWidget);

    // Vérifier que la location n'est PAS /admin (assertion robuste)
    final loc = currentLocation(contextRouter);
    expect(loc.contains('/admin'), isFalse, reason: 'Operateur ne doit pas pouvoir accéder à /admin');

    // Nettoyer le container isolé
    container.dispose();
  });

  testWidgets('admin accède à /admin', (tester) async {
    // Créer un ProviderContainer isolé pour ce test
    final container = ProviderContainer(
      overrides: [
        _roleProvider.overrideWith((_) => UserRole.admin),
      ],
    );

    // Créer le widget avec le container isolé
    // Le widget créera son propre router dans build()
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          role: UserRole.admin,
          initialLocation: '/admin',
        ),
      ),
    );

    // Attendre que la navigation soit complète
    await tester.pump();
    await pumpUntilSettled(tester);
    await tester.pumpAndSettle();

    // Obtenir le router depuis le contexte
    final context = tester.element(find.byType(Scaffold));
    final contextRouter = GoRouter.of(context);

    // Vérifier que l'écran admin est affiché
    expect(find.byKey(const Key('screen_admin')), findsOneWidget);

    // Vérifier que la location contient /admin (assertion robuste)
    final loc = currentLocation(contextRouter);
    expect(loc.contains('/admin'), isTrue, reason: 'Admin doit pouvoir accéder à /admin');

    // Nettoyer le container isolé
    container.dispose();
  });

  testWidgets('operateur redirigé après router.go(/admin)', (tester) async {
    // Créer un ProviderContainer isolé pour ce test
    final container = ProviderContainer(
      overrides: [
        _roleProvider.overrideWith((_) => UserRole.operateur),
      ],
    );

    // Créer un router isolé pour ce test (commence sur /forbidden)
    // Ce router doit pouvoir lire le rôle depuis le container
    final router = GoRouter(
      initialLocation: '/forbidden',
      redirect: (context, s) {
        // Lire le rôle depuis le container via le contexte
        final container = ProviderScope.containerOf(context);
        final currentRole = container.read(_roleProvider);
        if (s.matchedLocation == '/admin' && currentRole != UserRole.admin) {
          return '/forbidden';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/admin',
          builder: (_, __) => const _Screen('ADMIN', 'screen_admin'),
        ),
        GoRoute(
          path: '/forbidden',
          builder: (_, __) => const _Screen('FORBIDDEN', 'screen_forbidden'),
        ),
      ],
    );

    // Créer le widget avec le container et le router isolés
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _TestApp(
          role: UserRole.operateur,
          initialLocation: '/forbidden',
          externalRouter: router,
        ),
      ),
    );

    await tester.pump();
    await pumpUntilSettled(tester);
    await tester.pumpAndSettle();

    // Naviguer vers /admin (après pumpWidget)
    router.go('/admin');
    await tester.pump();
    await pumpUntilSettled(tester);
    await tester.pumpAndSettle();

    // Vérifier la redirection
    final loc = currentLocation(router);
    expect(loc.contains('/admin'), isFalse, reason: 'Operateur doit être redirigé depuis /admin');
    expect(find.byKey(const Key('screen_forbidden')), findsOneWidget);

    // Nettoyer le container isolé
    container.dispose();
  });

  testWidgets('admin peut naviguer vers /admin via router.go', (tester) async {
    // Créer un ProviderContainer isolé pour ce test
    final container = ProviderContainer(
      overrides: [
        _roleProvider.overrideWith((_) => UserRole.admin),
      ],
    );

    // Créer un router isolé pour ce test (commence sur /forbidden)
    // Ce router doit pouvoir lire le rôle depuis le container
    final router = GoRouter(
      initialLocation: '/forbidden',
      redirect: (context, s) {
        // Lire le rôle depuis le container via le contexte
        final container = ProviderScope.containerOf(context);
        final currentRole = container.read(_roleProvider);
        if (s.matchedLocation == '/admin' && currentRole != UserRole.admin) {
          return '/forbidden';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/admin',
          builder: (_, __) => const _Screen('ADMIN', 'screen_admin'),
        ),
        GoRoute(
          path: '/forbidden',
          builder: (_, __) => const _Screen('FORBIDDEN', 'screen_forbidden'),
        ),
      ],
    );

    // Créer le widget avec le container et le router isolés
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _TestApp(
          role: UserRole.admin,
          initialLocation: '/forbidden',
          externalRouter: router,
        ),
      ),
    );

    await tester.pump();
    await pumpUntilSettled(tester);
    await tester.pumpAndSettle();

    // Naviguer vers /admin (après pumpWidget)
    router.go('/admin');
    await tester.pump();
    await pumpUntilSettled(tester);
    await tester.pumpAndSettle();

    // Vérifier que l'admin peut accéder
    final loc = currentLocation(router);
    expect(loc.contains('/admin'), isTrue, reason: 'Admin doit pouvoir accéder à /admin');
    expect(find.byKey(const Key('screen_admin')), findsOneWidget);

    // Nettoyer le container isolé
    container.dispose();
  });
}
