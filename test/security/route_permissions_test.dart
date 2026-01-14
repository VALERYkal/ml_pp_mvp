import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum UserRole { admin, operateur }

class _TestApp extends StatelessWidget {
  final GoRouter router;

  const _TestApp({required this.router});

  @override
  Widget build(BuildContext context) {
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

String currentLocation(GoRouter router) {
  try {
    final loc = router.routeInformationProvider.value.location ?? '';
    if (loc.isNotEmpty) return loc;
  } catch (e) {
    // Fallback
  }
  try {
    return router.routerDelegate.currentConfiguration.uri.toString();
  } catch (e) {
    return '';
  }
}

GoRouter _createRouter(UserRole role, {String initialLocation = '/admin'}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (_, s) {
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
}

void main() {
  testWidgets('operateur ne peut pas accéder à /admin', (tester) async {
    final container = ProviderContainer();
    final router = _createRouter(UserRole.operateur, initialLocation: '/admin');

    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _TestApp(router: router),
        ),
      );

      await tester.pump();
      await pumpUntilSettled(tester);
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final contextRouter = GoRouter.of(context);

      expect(find.byKey(const Key('screen_forbidden')), findsOneWidget);
      final loc = currentLocation(contextRouter);
      expect(loc.contains('/admin'), isFalse);
    } finally {
      container.dispose();
    }
  });

  testWidgets('admin accède à /admin', (tester) async {
    final container = ProviderContainer();
    final router = _createRouter(UserRole.admin, initialLocation: '/admin');

    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _TestApp(router: router),
        ),
      );

      await tester.pump();
      await pumpUntilSettled(tester);
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final contextRouter = GoRouter.of(context);

      expect(find.byKey(const Key('screen_admin')), findsOneWidget);
      final loc = currentLocation(contextRouter);
      expect(loc.contains('/admin'), isTrue);
    } finally {
      container.dispose();
    }
  });

  testWidgets('operateur redirigé après router.go(/admin)', (tester) async {
    final container = ProviderContainer();
    final router = _createRouter(UserRole.operateur, initialLocation: '/forbidden');

    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _TestApp(router: router),
        ),
      );

      await tester.pump();
      await pumpUntilSettled(tester);
      await tester.pumpAndSettle();

      router.go('/admin');
      await tester.pump();
      await pumpUntilSettled(tester);
      await tester.pumpAndSettle();

      final loc = currentLocation(router);
      expect(loc.contains('/admin'), isFalse);
      expect(find.byKey(const Key('screen_forbidden')), findsOneWidget);
    } finally {
      container.dispose();
    }
  });

  testWidgets('admin peut naviguer vers /admin via router.go', (tester) async {
    final container = ProviderContainer();
    final router = _createRouter(UserRole.admin, initialLocation: '/forbidden');

    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _TestApp(router: router),
        ),
      );

      await tester.pump();
      await pumpUntilSettled(tester);
      await tester.pumpAndSettle();

      router.go('/admin');
      await tester.pump();
      await pumpUntilSettled(tester);
      await tester.pumpAndSettle();

      final loc = currentLocation(router);
      expect(loc.contains('/admin'), isTrue);
      expect(find.byKey(const Key('screen_admin')), findsOneWidget);
    } finally {
      container.dispose();
    }
  });
}
