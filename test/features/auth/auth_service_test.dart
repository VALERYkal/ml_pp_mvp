// 📌 Module : Auth Tests - AuthService Unit Tests
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Tests unitaires pour AuthService (≥95% coverage)

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/core/services/auth_service.dart';

import '../../_mocks.mocks.dart';

void main() {
  group('AuthService Unit Tests', () {
    late AuthService authService;
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late MockAuthResponse mockResponse;
    late MockUser mockUser;
    late MockSession mockSession;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockResponse = MockAuthResponse();
      mockUser = MockUser();
      mockSession = MockSession();

      // Configuration des mocks de base
      when(mockUser.id).thenReturn('test-user-id');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.createdAt).thenReturn(DateTime.now().toIso8601String());
      when(mockResponse.user).thenReturn(mockUser);
      when(mockResponse.session).thenReturn(mockSession);

      authService = AuthService.withSupabase(mockClient);
    });

    group('signIn', () {
      test('should successfully sign in with valid credentials', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        when(mockClient.auth).thenReturn(mockAuth);
        when(
          mockAuth.signInWithPassword(email: email, password: password),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await authService.signIn(email, password);

        // Assert
        expect(result, equals(mockUser));
        verify(mockAuth.signInWithPassword(email: email, password: password)).called(1);
        verify(mockClient.auth).called(1);
      });

      test('should throw AuthException when email is empty', () async {
        // Arrange
        const email = '';
        const password = 'password123';

        // Act & Assert
        expect(
          () => authService.signIn(email, password),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Email et mot de passe requis',
            ),
          ),
        );
        verifyNever(mockAuth.signInWithPassword(email: email, password: password));
      });

      test('should throw AuthException when password is empty', () async {
        // Arrange
        const email = 'test@example.com';
        const password = '';

        // Act & Assert
        expect(
          () => authService.signIn(email, password),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Email et mot de passe requis',
            ),
          ),
        );
        verifyNever(mockAuth.signInWithPassword(email: email, password: password));
      });

      test('should trim email before authentication', () async {
        // Arrange
        const email = '  test@example.com  ';
        const password = 'password123';
        when(mockClient.auth).thenReturn(mockAuth);
        when(
          mockAuth.signInWithPassword(email: 'test@example.com', password: password),
        ).thenAnswer((_) async => mockResponse);

        // Act
        await authService.signIn(email, password);

        // Assert
        verify(
          mockAuth.signInWithPassword(email: 'test@example.com', password: password),
        ).called(1);
      });

      test('should throw AuthException when user is null in response', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        when(mockClient.auth).thenReturn(mockAuth);
        when(mockResponse.user).thenReturn(null);
        when(
          mockAuth.signInWithPassword(email: email, password: password),
        ).thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => authService.signIn(email, password),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Aucun utilisateur retourné après connexion',
            ),
          ),
        );
      });

      test('should rethrow AuthException from Supabase', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'wrongpassword';
        when(mockClient.auth).thenReturn(mockAuth);
        final authException = AuthException('Invalid login credentials');
        when(
          mockAuth.signInWithPassword(email: email, password: password),
        ).thenThrow(authException);

        // Act & Assert
        expect(
          () => authService.signIn(email, password),
          throwsA(
            isA<AuthException>().having((e) => e.message, 'message', 'Invalid login credentials'),
          ),
        );
      });

      test('should rethrow PostgrestException from Supabase', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        when(mockClient.auth).thenReturn(mockAuth);
        final postgrestException = PostgrestException(
          message: 'Connection timeout',
          details: 'Network error',
          hint: 'Check your connection',
          code: 'CONNECTION_ERROR',
        );
        when(
          mockAuth.signInWithPassword(email: email, password: password),
        ).thenThrow(postgrestException);

        // Act & Assert
        expect(
          () => authService.signIn(email, password),
          throwsA(
            isA<PostgrestException>().having((e) => e.message, 'message', 'Connection timeout'),
          ),
        );
      });

      test('should rethrow generic exceptions', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        when(mockClient.auth).thenReturn(mockAuth);
        when(
          mockAuth.signInWithPassword(email: email, password: password),
        ).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => authService.signIn(email, password),
          throwsA(
            isA<Exception>().having((e) => e.toString(), 'toString', contains('Network error')),
          ),
        );
      });
    });

    group('signOut', () {
      test('should successfully sign out user', () async {
        // Arrange
        when(mockClient.auth).thenReturn(mockAuth);
        when(mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
        verify(mockClient.auth).called(1);
      });

      test('should rethrow AuthException from Supabase', () async {
        // Arrange
        when(mockClient.auth).thenReturn(mockAuth);
        final authException = AuthException('Sign out failed');
        when(mockAuth.signOut()).thenThrow(authException);

        // Act & Assert
        expect(
          () => authService.signOut(),
          throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Sign out failed')),
        );
      });

      test('should rethrow generic exceptions', () async {
        // Arrange
        when(mockClient.auth).thenReturn(mockAuth);
        when(mockAuth.signOut()).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => authService.signOut(),
          throwsA(
            isA<Exception>().having((e) => e.toString(), 'toString', contains('Network error')),
          ),
        );
      });
    });

    group('getCurrentUser', () {
      test('should return current user when authenticated', () {
        // Arrange
        when(mockClient.auth).thenReturn(mockAuth);
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        final result = authService.getCurrentUser();

        // Assert
        expect(result, equals(mockUser));
        verify(mockClient.auth).called(1);
      });

      test('should return null when not authenticated', () {
        // Arrange
        when(mockClient.auth).thenReturn(mockAuth);
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = authService.getCurrentUser();

        // Assert
        expect(result, isNull);
        verify(mockClient.auth).called(1);
      });
    });

    group('isAuthenticated', () {
      test('should return true when user is authenticated', () {
        // Arrange
        when(mockClient.auth).thenReturn(mockAuth);
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        final result = authService.isAuthenticated;

        // Assert
        expect(result, isTrue);
        verify(mockClient.auth).called(1);
      });

      test('should return false when user is not authenticated', () {
        // Arrange
        when(mockClient.auth).thenReturn(mockAuth);
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = authService.isAuthenticated;

        // Assert
        expect(result, isFalse);
        verify(mockClient.auth).called(1);
      });
    });

    group('authStateChanges', () {
      test('should return auth state changes stream', () {
        // Arrange
        final mockStream = Stream<AuthState>.empty();
        when(mockClient.auth).thenReturn(mockAuth);
        when(mockAuth.onAuthStateChange).thenAnswer((_) => mockStream);

        // Act
        final result = authService.authStateChanges;

        // Assert
        expect(result, equals(mockStream));
        verify(mockClient.auth).called(1);
      });
    });
  });
}
