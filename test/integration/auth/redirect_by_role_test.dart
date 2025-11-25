import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ml_pp_mvp/core/models/user_role.dart';

// --- Providers de test --- //

final isLoggedInProvider = StateProvider<bool>((ref) => false);
final roleProvider = StateProvider<UserRole?>((ref) => null);

// --- Widgets de test (dummy UI) --- //

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('LOGIN_SCREEN')),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('DASHBOARD_SCREEN')),
    );
  }
}

// --- Mini app de test --- //

class _TestApp extends ConsumerWidget {
  const _TestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final role = ref.watch(roleProvider);

    // Règle métier actuelle :
    // - Si pas connecté -> LoginScreen
    // - Si connecté -> DashboardScreen (quel que soit le rôle)
    final Widget home;
    if (!isLoggedIn) {
      home = const LoginScreen();
    } else {
      debugPrint('Redirecting to dashboard for role: $role');
      home = const DashboardScreen();
    }

    return MaterialApp(home: home);
  }
}

// --- TESTS --- //

void main() {
  group('Redirection par rôle vers le dashboard unique', () {
    testWidgets('affiche LoginScreen quand utilisateur non connecté',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: _TestApp()),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });

    testWidgets('affiche DashboardScreen quand connecté sans rôle défini',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isLoggedInProvider.overrideWith((ref) => true),
            roleProvider.overrideWith((ref) => null),
          ],
          child: const _TestApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets(
        'affiche DashboardScreen pour tous les rôles (admin, directeur, gérant, opérateur, pca, lecture)',
        (tester) async {
      final rolesToTest = [
        UserRole.admin,
        UserRole.directeur,
        UserRole.gerant,
        UserRole.operateur,
        UserRole.pca,
        UserRole.lecture,
      ];

      for (final role in rolesToTest) {
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

        expect(
          find.byType(DashboardScreen),
          findsOneWidget,
          reason: 'Le rôle $role devrait aller au Dashboard',
        );
        expect(find.byType(LoginScreen), findsNothing);
      }
    });
  });
}
