import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum UserRole { admin, operateur }

final roleProvider = StateProvider<UserRole>((_) => UserRole.operateur);

class _App extends ConsumerStatefulWidget {
  const _App();

  @override
  ConsumerState<_App> createState() => _AppState();
}

class _AppState extends ConsumerState<_App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}

class _Screen extends StatelessWidget {
  final String label;
  final String keyName;
  const _Screen(this.label, this.keyName);
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(key: Key(keyName), child: Text(label)),
  );
}

void main() {
  testWidgets('operateur ne peut pas accéder à /admin', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: _App()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen_forbidden')), findsOneWidget);
  });

  testWidgets('admin accède à /admin', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [roleProvider.overrideWith((_) => UserRole.admin)],
        child: const _App(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen_admin')), findsOneWidget);
  });
}
