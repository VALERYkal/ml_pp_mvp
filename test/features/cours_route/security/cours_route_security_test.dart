@Tags(['integration'])
// 📌 Module : Cours de Route - Tests de Sécurité
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Tests de sécurité et RLS pour le module CDR
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/auth/models/user_role.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/shared/providers/auth_provider.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('Cours de Route Security Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Role-Based Access Control', () {
      testWidgets('should restrict CDR creation to authorized roles', (
        WidgetTester tester,
      ) async {
        // Arrange - Utilisateur avec rôle LECTURE
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            overrides: [
              authProvider.overrideWith(
                (ref) => AuthState(
                  user: MockUser(role: UserRole.lecture),
                  isAuthenticated: true,
                ),
              ),
            ],
            child: const MaterialApp(home: CoursRouteListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Assert - Pas de bouton "Nouveau cours" pour les utilisateurs LECTURE
        expect(find.text('Nouveau cours'), findsNothing);
      });

      testWidgets('should allow CDR creation for authorized roles', (
        WidgetTester tester,
      ) async {
        // Arrange - Utilisateur avec rôle ADMIN
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            overrides: [
              authProvider.overrideWith(
                (ref) => AuthState(
                  user: MockUser(role: UserRole.admin),
                  isAuthenticated: true,
                ),
              ),
            ],
            child: const MaterialApp(home: CoursRouteListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Assert - Bouton "Nouveau cours" disponible pour les ADMIN
        expect(find.text('Nouveau cours'), findsOneWidget);
      });

      testWidgets('should restrict CDR modification to authorized roles', (
        WidgetTester tester,
      ) async {
        // Arrange - Utilisateur avec rôle LECTURE
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            overrides: [
              authProvider.overrideWith(
                (ref) => AuthState(
                  user: MockUser(role: UserRole.lecture),
                  isAuthenticated: true,
                ),
              ),
            ],
            child: const MaterialApp(
              home: CoursRouteDetailScreen(coursId: 'test-id'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert - Pas de boutons de modification pour les utilisateurs LECTURE
        expect(find.text('Modifier'), findsNothing);
        expect(find.text('Supprimer'), findsNothing);
        expect(find.text('Avancer statut'), findsNothing);
      });

      testWidgets('should allow CDR modification for authorized roles', (
        WidgetTester tester,
      ) async {
        // Arrange - Utilisateur avec rôle ADMIN
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            overrides: [
              authProvider.overrideWith(
                (ref) => AuthState(
                  user: MockUser(role: UserRole.admin),
                  isAuthenticated: true,
                ),
              ),
            ],
            child: const MaterialApp(
              home: CoursRouteDetailScreen(coursId: 'test-id'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert - Boutons de modification disponibles pour les ADMIN
        expect(find.text('Modifier'), findsOneWidget);
        expect(find.text('Supprimer'), findsOneWidget);
        expect(find.text('Avancer statut'), findsOneWidget);
      });
    });

    group('Data Filtering by Depot', () {
      testWidgets('should filter CDR by user depot for non-admin users', (
        WidgetTester tester,
      ) async {
        // Arrange - Utilisateur avec rôle OPERATEUR et dépôt spécifique
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            overrides: [
              authProvider.overrideWith(
                (ref) => AuthState(
                  user: MockUser(role: UserRole.operateur, depotId: 'depot-1'),
                  isAuthenticated: true,
                ),
              ),
            ],
            child: const MaterialApp(home: CoursRouteListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Charger la liste des cours
        final coursList = await container.read(coursDeRouteListProvider.future);

        // Assert - Seuls les cours du dépôt de l'utilisateur devraient être visibles
        for (final cours in coursList) {
          expect(cours.depotDestinationId, 'depot-1');
        }
      });

      testWidgets('should show all CDR for admin users', (
        WidgetTester tester,
      ) async {
        // Arrange - Utilisateur avec rôle ADMIN
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            overrides: [
              authProvider.overrideWith(
                (ref) => AuthState(
                  user: MockUser(role: UserRole.admin),
                  isAuthenticated: true,
                ),
              ),
            ],
            child: const MaterialApp(home: CoursRouteListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Charger la liste des cours
        final coursList = await container.read(coursDeRouteListProvider.future);

        // Assert - Tous les cours devraient être visibles pour les ADMIN
        expect(coursList, isA<List<CoursDeRoute>>());
        // Pas de restriction par dépôt pour les ADMIN
      });
    });

    group('RLS Policy Enforcement', () {
      test('should enforce RLS policies on cours_de_route table', () async {
        // Arrange
        final service = CoursDeRouteService.withClient(mockSupabaseClient);

        // Act & Assert - Tenter d'accéder aux données sans authentification
        expect(() => service.getAll(), throwsA(isA<PostgrestException>()));
      });

      test('should enforce depot-based RLS for non-admin users', () async {
        // Arrange - Utilisateur avec dépôt spécifique
        final service = CoursDeRouteService.withClient(mockSupabaseClient);

        // Act - Tenter d'accéder aux cours d'un autre dépôt
        final cours = await service.getByDepot('other-depot-id');

        // Assert - Seuls les cours du dépôt de l'utilisateur devraient être retournés
        for (final c in cours) {
          expect(c.depotDestinationId, 'user-depot-id');
        }
      });

      test('should prevent unauthorized statut updates', () async {
        // Arrange
        final service = CoursDeRouteService.withClient(mockSupabaseClient);

        // Act & Assert - Tenter de mettre à jour le statut sans autorisation
        expect(
          () => service.updateStatut(
            id: 'test-id',
            to: StatutCours.decharge,
            fromReception: false,
          ),
          throwsA(isA<PostgrestException>()),
        );
      });
    });

    group('Input Validation and Sanitization', () {
      test('should sanitize user inputs', () async {
        // Arrange
        final maliciousInput = '<script>alert("XSS")</script>';

        // Act
        final cours = CoursDeRoute(
          id: 'test-id',
          fournisseurId: 'f1',
          produitId: 'p1',
          depotDestinationId: 'd1',
          chauffeur: maliciousInput,
          note: maliciousInput,
        );

        // Assert - Les entrées malveillantes devraient être échappées
        expect(cours.chauffeur, isNot(contains('<script>')));
        expect(cours.note, isNot(contains('<script>')));
      });

      test('should validate volume constraints', () async {
        // Arrange
        final invalidVolumes = [-100, 0, 1000000]; // Volumes invalides

        // Act & Assert
        for (final volume in invalidVolumes) {
          expect(
            () => CoursDeRoute(
              id: 'test-id',
              fournisseurId: 'f1',
              produitId: 'p1',
              depotDestinationId: 'd1',
              volume: volume,
            ),
            throwsArgumentError,
          );
        }
      });

      test('should validate plaque camion format', () async {
        // Arrange
        final invalidPlaques = ['', 'INVALID', '123', 'ABC-123-456'];

        // Act & Assert
        for (final plaque in invalidPlaques) {
          expect(
            () => CoursDeRoute(
              id: 'test-id',
              fournisseurId: 'f1',
              produitId: 'p1',
              depotDestinationId: 'd1',
              plaqueCamion: plaque,
            ),
            throwsArgumentError,
          );
        }
      });
    });

    group('Business Rule Enforcement', () {
      test('should enforce unique plaque camion constraint', () async {
        // Arrange
        final service = CoursDeRouteService.withClient(mockSupabaseClient);
        final cours1 = CoursDeRoute(
          id: 'id1',
          fournisseurId: 'f1',
          produitId: 'p1',
          depotDestinationId: 'd1',
          plaqueCamion: 'ABC123',
          statut: StatutCours.chargement,
        );

        final cours2 = CoursDeRoute(
          id: 'id2',
          fournisseurId: 'f1',
          produitId: 'p1',
          depotDestinationId: 'd1',
          plaqueCamion: 'ABC123', // Même plaque
          statut: StatutCours.transit,
        );

        // Act
        await service.create(cours1);

        // Assert - Créer un deuxième cours avec la même plaque devrait échouer
        expect(
          () => service.create(cours2),
          throwsA(isA<PostgrestException>()),
        );
      });

      test('should enforce statut transition rules', () async {
        // Arrange
        final service = CoursDeRouteService.withClient(mockSupabaseClient);

        // Act & Assert - Transitions invalides
        expect(
          () => service.updateStatut(
            id: 'test-id',
            to: StatutCours.decharge,
            fromReception: false, // Invalide - pas depuis réception
          ),
          throwsArgumentError,
        );

        expect(
          () => service.updateStatut(
            id: 'test-id',
            to: StatutCours.transit,
            fromReception: false, // Invalide - déjà au statut TRANSIT
          ),
          throwsArgumentError,
        );
      });

      test('should enforce date constraints', () async {
        // Arrange
        final futureDate = DateTime.now().add(const Duration(days: 1));

        // Act & Assert
        expect(
          () => CoursDeRoute(
            id: 'test-id',
            fournisseurId: 'f1',
            produitId: 'p1',
            depotDestinationId: 'd1',
            dateChargement: futureDate,
          ),
          throwsArgumentError,
        );
      });
    });

    group('Audit Trail and Logging', () {
      test('should log all CDR operations', () async {
        // Arrange
        final service = CoursDeRouteService.withClient(mockSupabaseClient);
        final cours = CoursDeRoute(
          id: '',
          fournisseurId: 'f1',
          produitId: 'p1',
          depotDestinationId: 'd1',
        );

        // Act
        await service.create(cours);

        // Assert - Vérifier que l'opération est loggée
        verify(
          mockAuditLogger.logOperation(
            operation: 'CREATE',
            table: 'cours_de_route',
            userId: 'test-user-id',
            data: any,
          ),
        ).called(1);
      });

      test('should log statut changes with timestamps', () async {
        // Arrange
        final service = CoursDeRouteService.withClient(mockSupabaseClient);

        // Act
        await service.updateStatut(
          id: 'test-id',
          to: StatutCours.transit,
          fromReception: false,
        );

        // Assert - Vérifier que le changement de statut est loggé
        verify(
          mockAuditLogger.logStatutChange(
            coursId: 'test-id',
            fromStatut: 'CHARGEMENT',
            toStatut: 'TRANSIT',
            userId: 'test-user-id',
            timestamp: any,
          ),
        ).called(1);
      });
    });
  });
}

// Mock classes for testing
class MockUser {
  final UserRole role;
  final String? depotId;

  MockUser({required this.role, this.depotId});
}

class AuthState {
  final MockUser user;
  final bool isAuthenticated;

  AuthState({required this.user, required this.isAuthenticated});
}

class MockSupabaseClient {
  // Mock implementation
}

class MockAuditLogger {
  void logOperation({
    required String operation,
    required String table,
    required String userId,
    required dynamic data,
  }) {}

  void logStatutChange({
    required String coursId,
    required String fromStatut,
    required String toStatut,
    required String userId,
    required DateTime timestamp,
  }) {}
}

// Mock instances
final mockSupabaseClient = MockSupabaseClient();
final mockAuditLogger = MockAuditLogger();
