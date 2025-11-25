@Tags(['e2e'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Auth & UI
import 'package:ml_pp_mvp/core/services/auth_service.dart';
import 'package:ml_pp_mvp/features/auth/screens/login_screen.dart';
import 'package:ml_pp_mvp/shared/providers/auth_service_provider.dart';

// Modèle User Supabase (gotrue)
import 'package:gotrue/src/types/user.dart';
import 'package:mockito/mockito.dart' as mockito;

/// Fake contrôlable pour le flux de login.
/// On n’utilise PAS when/verify ici, on override directement signIn.
class MockAuthService extends mockito.Mock implements AuthService {
  String? lastEmail;
  String? lastPassword;
  int signInCallCount = 0;
  late User fakeUser;

  @override
  Future<User> signIn(String email, String password) async {
    lastEmail = email;
    lastPassword = password;
    signInCallCount++;
    return fakeUser;
  }
}

Future<void> _pumpLoginApp(
  WidgetTester tester,
  MockAuthService mock,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(mock),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _performLogin(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  // ⚠️ Ces Keys doivent correspondre à ton LoginScreen
  await tester.enterText(find.byKey(const Key('email')), email);
  await tester.enterText(find.byKey(const Key('password')), password);
  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'login flow calls signIn with correct email and password',
    (WidgetTester tester) async {
      const email = 'test@example.com';
      const password = 'P@ssw0rd!';

      final mock = MockAuthService();

      // Faux utilisateur Supabase minimal
      mock.fakeUser = User(
        id: 'test-user-id',
        appMetadata: const <String, dynamic>{},
        userMetadata: const <String, dynamic>{},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      await _pumpLoginApp(tester, mock);

      await _performLogin(
        tester,
        email: email,
        password: password,
      );

      // Vérifications sans API Mockito avancée
      expect(mock.signInCallCount, 1);
      expect(mock.lastEmail, email);
      expect(mock.lastPassword, password);
    },
  );
}
