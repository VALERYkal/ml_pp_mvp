import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum UserRole { admin, operateur }

final roleProvider = StateProvider<UserRole>((_) => UserRole.operateur);

class _App extends ConsumerWidget {
  const _App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Créer le router dans build() pour avoir accès à ref
    final router = GoRouter(
      initialLocation: '/admin',
      redirect: (_, s) {
        final role = ref.read(roleProvider);
        if (s.matchedLocation == '/admin' && role != UserRole.admin) {
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
    await tester.pumpWidget(const ProviderScope(child: _App()));
    
    // Attendre que la navigation et le redirect soient complétés
    await tester.pump();
    await pumpUntilSettled(tester);
    
    // Obtenir le router depuis le contexte
    final context = tester.element(find.byType(Scaffold));
    final router = GoRouter.of(context);
    
    // Vérifier que l'écran forbidden est affiché
    expect(find.byKey(const Key('screen_forbidden')), findsOneWidget);
    
    // Vérifier que la location n'est PAS /admin (assertion robuste)
    final loc = currentLocation(router);
    expect(loc.contains('/admin'), isFalse, reason: 'Operateur ne doit pas pouvoir accéder à /admin');
  });

  testWidgets('admin accède à /admin', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [roleProvider.overrideWith((_) => UserRole.admin)],
        child: const _App(),
      ),
    );
    
    // Attendre que la navigation soit complète
    await tester.pump();
    await pumpUntilSettled(tester);
    
    // Obtenir le router depuis le contexte
    final context = tester.element(find.byType(Scaffold));
    final router = GoRouter.of(context);
    
    // Vérifier que l'écran admin est affiché
    expect(find.byKey(const Key('screen_admin')), findsOneWidget);
    
    // Vérifier que la location contient /admin (assertion robuste)
    final loc = currentLocation(router);
    expect(loc.contains('/admin'), isTrue, reason: 'Admin doit pouvoir accéder à /admin');
  });

  testWidgets('operateur redirigé après router.go(/admin)', (tester) async {
    GoRouter? testRouter;
    
    // Widget qui expose le router
    final app = ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          testRouter = GoRouter(
            initialLocation: '/forbidden',
            redirect: (_, s) {
              final role = ref.read(roleProvider);
              if (s.matchedLocation == '/admin' && role != UserRole.admin) {
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
          return MaterialApp.router(routerConfig: testRouter!);
        },
      ),
    );
    
    await tester.pumpWidget(app);
    await tester.pump();
    await pumpUntilSettled(tester);
    
    // Naviguer vers /admin
    testRouter!.go('/admin');
    await tester.pump();
    await pumpUntilSettled(tester);
    
    // Vérifier la redirection
    final loc = currentLocation(testRouter!);
    expect(loc.contains('/admin'), isFalse, reason: 'Operateur doit être redirigé depuis /admin');
    expect(find.byKey(const Key('screen_forbidden')), findsOneWidget);
  });

  testWidgets('admin peut naviguer vers /admin via router.go', (tester) async {
    GoRouter? testRouter;
    
    // Widget qui expose le router
    final app = ProviderScope(
      overrides: [roleProvider.overrideWith((_) => UserRole.admin)],
      child: Consumer(
        builder: (context, ref, _) {
          testRouter = GoRouter(
            initialLocation: '/forbidden',
            redirect: (_, s) {
              final role = ref.read(roleProvider);
              if (s.matchedLocation == '/admin' && role != UserRole.admin) {
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
          return MaterialApp.router(routerConfig: testRouter!);
        },
      ),
    );
    
    await tester.pumpWidget(app);
    await tester.pump();
    await pumpUntilSettled(tester);
    
    // Naviguer vers /admin
    testRouter!.go('/admin');
    await tester.pump();
    await pumpUntilSettled(tester);
    
    // Vérifier que l'admin peut accéder
    final loc = currentLocation(testRouter!);
    expect(loc.contains('/admin'), isTrue, reason: 'Admin doit pouvoir accéder à /admin');
    expect(find.byKey(const Key('screen_admin')), findsOneWidget);
  });
}
