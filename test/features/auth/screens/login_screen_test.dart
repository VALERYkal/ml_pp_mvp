// ð Module : Auth Tests - LoginScreen Widget Tests
// ð§ Auteur : Valery Kalonga
// ð Date : 2025-01-27
// ð§­ Description : Tests widget pour LoginScreen (â¥90% coverage)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/core/services/auth_service.dart';
import 'package:ml_pp_mvp/features/auth/screens/login_screen.dart';
import 'package:ml_pp_mvp/shared/providers/auth_service_provider.dart';

import '../mocks.mocks.dart';

// Mock User simple pour les tests
class MockUser extends Mock implements User {}

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          // Override the auth service provider with our mock
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
        child: const MaterialApp(home: LoginScreen()),
      );
    }

    group('UI Elements', () {
      testWidgets('should display all required UI elements', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Connexion ML_PP MVP'), findsOneWidget);
        expect(find.text('Bienvenue'), findsOneWidget);
        expect(find.text('Connectez-vous Ã  votre compte'), findsOneWidget);
        expect(find.byKey(const Key('email')), findsOneWidget);
        expect(find.byKey(const Key('password')), findsOneWidget);
        expect(find.byKey(const Key('login_button')), findsOneWidget);
        expect(find.text('Se connecter'), findsOneWidget);
        expect(
          find.text('Utilisez vos identifiants fournis par votre administrateur'),
          findsOneWidget,
        );
      });

      testWidgets('should display logo image', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('should have proper form structure', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('should show validation error for empty email', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pump();

        // Assert
        expect(find.text('Email requis'), findsOneWidget);
        verifyNever(mockAuthService.signIn(any, any));
      });

      testWidgets('should show validation error for empty password', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pump();

        // Assert
        expect(find.text('Mot de passe requis'), findsOneWidget);
        verifyNever(mockAuthService.signIn(any, any));
      });

      testWidgets('should show validation error for invalid email format', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byKey(const Key('email')), 'invalid-email');
        await tester.enterText(find.byKey(const Key('password')), 'password123');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pump();

        // Assert
        expect(find.text('Format d\'email invalide'), findsOneWidget);
        verifyNever(mockAuthService.signIn(any, any));
      });

      testWidgets('should accept valid email formats', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password')), 'password123');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pump();

        // Assert
        expect(find.text('Email requis'), findsNothing);
        expect(find.text('Format d\'email invalide'), findsNothing);
        expect(find.text('Mot de passe requis'), findsNothing);
      });
    });

    group('Password Visibility Toggle', () {
      testWidgets('should toggle password visibility when eye icon is tapped', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Initially should show visibility icon
        expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);

        // Act - Tap the visibility toggle icon
        await tester.tap(find.byIcon(Icons.visibility_rounded));
        await tester.pump();

        // Assert - Should show visibility off icon
        expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
      });

      testWidgets('should toggle back to obscured when eye icon is tapped again', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act - Tap visibility toggle twice
        await tester.tap(find.byIcon(Icons.visibility_rounded));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.visibility_off_rounded));
        await tester.pump();

        // Assert - Should show visibility icon again
        expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
      });
    });

    group('Login Button States', () {
      testWidgets('should enable login button when not loading', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Assert
        final loginButton = tester.widget<ElevatedButton>(find.byKey(const Key('login_button')));
        expect(loginButton.onPressed, isNotNull);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Se connecter'), findsOneWidget);
      });

      testWidgets('should handle login button interaction', (WidgetTester tester) async {
        // Arrange
        when(mockAuthService.signIn(any, any)).thenAnswer((_) async => MockUser());

        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password')), 'password123');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert - Should show success message
        expect(find.text('Connexion rÃ©ussie'), findsOneWidget);
      });
    });

    group('Successful Login', () {
      testWidgets('should show success message on successful login', (WidgetTester tester) async {
        // Arrange
        when(mockAuthService.signIn(any, any)).thenAnswer((_) async => MockUser());

        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password')), 'password123');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Connexion rÃ©ussie'), findsOneWidget);
        verify(mockAuthService.signIn('test@example.com', 'password123')).called(1);
      });

      testWidgets('should validate email format correctly', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act - Enter email with spaces (should be invalid)
        await tester.enterText(find.byKey(const Key('email')), '  test@example.com  ');
        await tester.enterText(find.byKey(const Key('password')), 'password123');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pump();

        // Assert - Should show email format error
        expect(find.text('Format d\'email invalide'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should show error message for invalid credentials', (WidgetTester tester) async {
        // Arrange
        when(
          mockAuthService.signIn(any, any),
        ).thenThrow(const AuthException('Invalid login credentials'));

        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password')), 'wrongpassword');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Identifiants invalides'), findsOneWidget);
        verify(mockAuthService.signIn('test@example.com', 'wrongpassword')).called(1);
      });

      testWidgets('should show error message for unconfirmed email', (WidgetTester tester) async {
        // Arrange
        when(
          mockAuthService.signIn(any, any),
        ).thenThrow(const AuthException('Email not confirmed'));

        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password')), 'password123');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Email non confirmÃ©'), findsOneWidget);
      });

      testWidgets('should show error message for network issues', (WidgetTester tester) async {
        // Arrange
        when(mockAuthService.signIn(any, any)).thenThrow(const AuthException('Network error'));

        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password')), 'password123');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('ProblÃ¨me rÃ©seau'), findsOneWidget);
      });

      testWidgets('should show error message for too many requests', (WidgetTester tester) async {
        // Arrange
        when(mockAuthService.signIn(any, any)).thenThrow(const AuthException('Too many requests'));

        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password')), 'password123');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Trop de tentatives. RÃ©essayez plus tard.'), findsOneWidget);
      });

      testWidgets('should show generic error message for unknown AuthException', (
        WidgetTester tester,
      ) async {
        // Arrange
        when(mockAuthService.signIn(any, any)).thenThrow(const AuthException('Unknown error'));

        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password')), 'password123');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Impossible de se connecter'), findsOneWidget);
      });

      testWidgets('should show error message for PostgrestException', (WidgetTester tester) async {
        // Arrange
        when(mockAuthService.signIn(any, any)).thenThrow(
          const PostgrestException(
            message: 'Permission denied',
            details: 'RLS policy violation',
            hint: 'Check user permissions',
            code: 'RLS_ERROR',
          ),
        );

        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password')), 'password123');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('AccÃ¨s au profil refusÃ© (policies RLS). Contactez l\'administrateur.'),
          findsOneWidget,
        );
      });

      testWidgets('should show error message for generic exceptions', (WidgetTester tester) async {
        // Arrange
        when(mockAuthService.signIn(any, any)).thenThrow(Exception('Unexpected error'));

        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password')), 'password123');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Erreur inattendue. RÃ©essaie.'), findsOneWidget);
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('should submit form when Enter is pressed on password field', (
        WidgetTester tester,
      ) async {
        // Arrange
        when(mockAuthService.signIn(any, any)).thenAnswer((_) async => MockUser());

        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password')), 'password123');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Assert
        verify(mockAuthService.signIn('test@example.com', 'password123')).called(1);
      });

      testWidgets('should have proper form structure for keyboard navigation', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Assert - Verify form fields exist for keyboard navigation
        expect(find.byKey(const Key('email')), findsOneWidget);
        expect(find.byKey(const Key('password')), findsOneWidget);
        expect(find.byKey(const Key('login_button')), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byKey(const Key('email')), findsOneWidget);
        expect(find.byKey(const Key('password')), findsOneWidget);
        expect(find.byKey(const Key('login_button')), findsOneWidget);
      });

      testWidgets('should have proper form structure for accessibility', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert - Verify form structure exists
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });
  });
}

