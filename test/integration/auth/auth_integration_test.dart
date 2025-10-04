@Tags(['integration'])
// 📌 Module : Auth Tests - Integration Tests
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Tests d'intégration pour la redirection par rôle (≥85% coverage)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/core/services/auth_service.dart';
import 'package:ml_pp_mvp/features/profil/data/profil_service.dart';
import 'package:ml_pp_mvp/core/models/profil.dart';
import 'package:ml_pp_mvp/shared/navigation/app_router.dart';
import 'package:ml_pp_mvp/features/auth/screens/login_screen.dart';

import '../mocks.mocks.dart';

@GenerateMocks([AuthService, ProfilService, User])
void main() {
  group('Auth Integration Tests', () {
    late MockAuthService mockAuthService;
    late MockProfilService mockProfilService;
    late MockUser mockUser;

    setUp(() {
      mockAuthService = MockAuthService();
      mockProfilService = MockProfilService();
      mockUser = MockUser();
      when(mockUser.id).thenReturn('test-user-id');
      when(mockUser.email).thenReturn('test@example.com');
    });

    Widget createTestApp({required Profil? profil}) {
      return ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          profilServiceProvider.overrideWithValue(mockProfilService),
          // Mock the current profil provider
          currentProfilProvider.overrideWith((ref) => AsyncValue.data(profil)),
        ],
        child: MaterialApp.router(routerConfig: AppRouter.router),
      );
    }

    group('Role-based Redirection', () {
      testWidgets('should redirect admin to admin dashboard', (
        WidgetTester tester,
      ) async {
        // Arrange
        final adminProfil = Profil(
          id: 'profil-id',
          userId: 'test-user-id',
          role: 'admin',
          nomComplet: 'Admin User',
          email: 'admin@example.com',
          depotId: 'depot-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(createTestApp(profil: adminProfil));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Dashboard Admin'), findsOneWidget);
        expect(find.text('Administration'), findsOneWidget);
        expect(find.text('Gestion des utilisateurs'), findsOneWidget);
      });

      testWidgets('should redirect directeur to directeur dashboard', (
        WidgetTester tester,
      ) async {
        // Arrange
        final directeurProfil = Profil(
          id: 'profil-id',
          userId: 'test-user-id',
          role: 'directeur',
          nomComplet: 'Directeur User',
          email: 'directeur@example.com',
          depotId: 'depot-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(createTestApp(profil: directeurProfil));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Dashboard Directeur'), findsOneWidget);
        expect(find.text('Direction'), findsOneWidget);
        expect(find.text('Validation des mouvements'), findsOneWidget);
      });

      testWidgets('should redirect gerant to gerant dashboard', (
        WidgetTester tester,
      ) async {
        // Arrange
        final gerantProfil = Profil(
          id: 'profil-id',
          userId: 'test-user-id',
          role: 'gerant',
          nomComplet: 'Gerant User',
          email: 'gerant@example.com',
          depotId: 'depot-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(createTestApp(profil: gerantProfil));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Dashboard Gérant'), findsOneWidget);
        expect(find.text('Gestion'), findsOneWidget);
        expect(find.text('Gestion des stocks'), findsOneWidget);
      });

      testWidgets('should redirect operateur to operateur dashboard', (
        WidgetTester tester,
      ) async {
        // Arrange
        final operateurProfil = Profil(
          id: 'profil-id',
          userId: 'test-user-id',
          role: 'operateur',
          nomComplet: 'Operateur User',
          email: 'operateur@example.com',
          depotId: 'depot-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(createTestApp(profil: operateurProfil));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Dashboard Opérateur'), findsOneWidget);
        expect(find.text('Opérations'), findsOneWidget);
        expect(find.text('Cours de route'), findsOneWidget);
        expect(find.text('Réceptions'), findsOneWidget);
      });

      testWidgets('should redirect pca to pca dashboard', (
        WidgetTester tester,
      ) async {
        // Arrange
        final pcaProfil = Profil(
          id: 'profil-id',
          userId: 'test-user-id',
          role: 'pca',
          nomComplet: 'PCA User',
          email: 'pca@example.com',
          depotId: 'depot-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(createTestApp(profil: pcaProfil));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Dashboard PCA'), findsOneWidget);
        expect(find.text('Consultation'), findsOneWidget);
        expect(find.text('Rapports'), findsOneWidget);
      });

      testWidgets('should redirect lecture to lecture dashboard', (
        WidgetTester tester,
      ) async {
        // Arrange
        final lectureProfil = Profil(
          id: 'profil-id',
          userId: 'test-user-id',
          role: 'lecture',
          nomComplet: 'Lecture User',
          email: 'lecture@example.com',
          depotId: 'depot-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(createTestApp(profil: lectureProfil));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Dashboard Lecture'), findsOneWidget);
        expect(find.text('Consultation'), findsOneWidget);
        expect(find.text('Lecture seule'), findsOneWidget);
      });
    });

    group('Menu Conformity by Role', () {
      testWidgets('admin should see all menu items', (
        WidgetTester tester,
      ) async {
        // Arrange
        final adminProfil = Profil(
          id: 'profil-id',
          userId: 'test-user-id',
          role: 'admin',
          nomComplet: 'Admin User',
          email: 'admin@example.com',
          depotId: 'depot-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(createTestApp(profil: adminProfil));
        await tester.pumpAndSettle();

        // Assert - Admin should see all menu items
        expect(find.text('Cours de route'), findsOneWidget);
        expect(find.text('Réceptions'), findsOneWidget);
        expect(find.text('Sorties'), findsOneWidget);
        expect(find.text('Stocks'), findsOneWidget);
        expect(find.text('Administration'), findsOneWidget);
        expect(find.text('Utilisateurs'), findsOneWidget);
        expect(find.text('Paramètres'), findsOneWidget);
      });

      testWidgets('directeur should see management menu items', (
        WidgetTester tester,
      ) async {
        // Arrange
        final directeurProfil = Profil(
          id: 'profil-id',
          userId: 'test-user-id',
          role: 'directeur',
          nomComplet: 'Directeur User',
          email: 'directeur@example.com',
          depotId: 'depot-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(createTestApp(profil: directeurProfil));
        await tester.pumpAndSettle();

        // Assert - Directeur should see management items but not admin items
        expect(find.text('Cours de route'), findsOneWidget);
        expect(find.text('Réceptions'), findsOneWidget);
        expect(find.text('Sorties'), findsOneWidget);
        expect(find.text('Stocks'), findsOneWidget);
        expect(find.text('Rapports'), findsOneWidget);
        expect(find.text('Administration'), findsNothing);
        expect(find.text('Utilisateurs'), findsNothing);
      });

      testWidgets('operateur should see operational menu items only', (
        WidgetTester tester,
      ) async {
        // Arrange
        final operateurProfil = Profil(
          id: 'profil-id',
          userId: 'test-user-id',
          role: 'operateur',
          nomComplet: 'Operateur User',
          email: 'operateur@example.com',
          depotId: 'depot-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(createTestApp(profil: operateurProfil));
        await tester.pumpAndSettle();

        // Assert - Operateur should see operational items only
        expect(find.text('Cours de route'), findsOneWidget);
        expect(find.text('Réceptions'), findsOneWidget);
        expect(find.text('Sorties'), findsOneWidget);
        expect(find.text('Stocks'), findsOneWidget);
        expect(find.text('Administration'), findsNothing);
        expect(find.text('Rapports'), findsNothing);
      });

      testWidgets('lecture should see read-only menu items', (
        WidgetTester tester,
      ) async {
        // Arrange
        final lectureProfil = Profil(
          id: 'profil-id',
          userId: 'test-user-id',
          role: 'lecture',
          nomComplet: 'Lecture User',
          email: 'lecture@example.com',
          depotId: 'depot-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(createTestApp(profil: lectureProfil));
        await tester.pumpAndSettle();

        // Assert - Lecture should see read-only items only
        expect(find.text('Cours de route'), findsOneWidget);
        expect(find.text('Réceptions'), findsOneWidget);
        expect(find.text('Sorties'), findsOneWidget);
        expect(find.text('Stocks'), findsOneWidget);
        expect(find.text('Rapports'), findsOneWidget);
        expect(find.text('Administration'), findsNothing);
        expect(find.text('Créer'), findsNothing);
        expect(find.text('Modifier'), findsNothing);
      });
    });

    group('Authentication Flow', () {
      testWidgets('should redirect to login when not authenticated', (
        WidgetTester tester,
      ) async {
        // Arrange
        when(mockAuthService.isAuthenticated).thenReturn(false);
        when(mockAuthService.getCurrentUser()).thenReturn(null);

        await tester.pumpWidget(createTestApp(profil: null));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Connexion ML_PP MVP'), findsOneWidget);
      });

      testWidgets('should redirect to login when profil is null', (
        WidgetTester tester,
      ) async {
        // Arrange
        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(createTestApp(profil: null));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('should handle profil loading state', (
        WidgetTester tester,
      ) async {
        // Arrange
        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authServiceProvider.overrideWithValue(mockAuthService),
              profilServiceProvider.overrideWithValue(mockProfilService),
              currentProfilProvider.overrideWith(
                (ref) => const AsyncValue.loading(),
              ),
            ],
            child: MaterialApp.router(routerConfig: AppRouter.router),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle profil error state', (
        WidgetTester tester,
      ) async {
        // Arrange
        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authServiceProvider.overrideWithValue(mockAuthService),
              profilServiceProvider.overrideWithValue(mockProfilService),
              currentProfilProvider.overrideWith(
                (ref) => AsyncValue.error('Profil error', StackTrace.current),
              ),
            ],
            child: MaterialApp.router(routerConfig: AppRouter.router),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Erreur de chargement du profil'), findsOneWidget);
      });
    });

    group('Navigation Guards', () {
      testWidgets('should prevent access to admin routes for non-admin users', (
        WidgetTester tester,
      ) async {
        // Arrange
        final operateurProfil = Profil(
          id: 'profil-id',
          userId: 'test-user-id',
          role: 'operateur',
          nomComplet: 'Operateur User',
          email: 'operateur@example.com',
          depotId: 'depot-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(createTestApp(profil: operateurProfil));
        await tester.pumpAndSettle();

        // Act - Try to navigate to admin route
        final context = tester.element(find.byType(MaterialApp));
        context.go('/admin/users');

        await tester.pumpAndSettle();

        // Assert - Should be redirected or show access denied
        expect(find.text('Accès refusé'), findsOneWidget);
      });

      testWidgets('should allow access to admin routes for admin users', (
        WidgetTester tester,
      ) async {
        // Arrange
        final adminProfil = Profil(
          id: 'profil-id',
          userId: 'test-user-id',
          role: 'admin',
          nomComplet: 'Admin User',
          email: 'admin@example.com',
          depotId: 'depot-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);

        await tester.pumpWidget(createTestApp(profil: adminProfil));
        await tester.pumpAndSettle();

        // Act - Navigate to admin route
        final context = tester.element(find.byType(MaterialApp));
        context.go('/admin/users');

        await tester.pumpAndSettle();

        // Assert - Should have access
        expect(find.text('Gestion des utilisateurs'), findsOneWidget);
      });
    });

    group('Logout Flow', () {
      testWidgets('should redirect to login after logout', (
        WidgetTester tester,
      ) async {
        // Arrange
        final adminProfil = Profil(
          id: 'profil-id',
          userId: 'test-user-id',
          role: 'admin',
          nomComplet: 'Admin User',
          email: 'admin@example.com',
          depotId: 'depot-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentUser()).thenReturn(mockUser);
        when(mockAuthService.signOut()).thenAnswer((_) async {});

        await tester.pumpWidget(createTestApp(profil: adminProfil));
        await tester.pumpAndSettle();

        // Act - Click logout button
        await tester.tap(find.text('Déconnexion'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(LoginScreen), findsOneWidget);
        verify(mockAuthService.signOut()).called(1);
      });
    });
  });
}
