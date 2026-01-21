import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/core/errors/stocks_adjustments_exception.dart';
import 'package:ml_pp_mvp/data/repositories/repositories.dart';
import 'package:ml_pp_mvp/features/stocks_adjustments/providers/stocks_adjustments_providers.dart';

/// Fake qui capture les payloads insérés
class _FakeSupabaseInsertCapture {
  final List<Map<String, dynamic>> insertedPayloads = [];
  int insertCallCount = 0;
  String? capturedTableName;
  Exception? throwOnInsert;

  void captureInsert(String tableName, Map<String, dynamic> payload) {
    insertCallCount++;
    capturedTableName = tableName;
    insertedPayloads.add(Map<String, dynamic>.from(payload));
    if (throwOnInsert != null) {
      throw throwOnInsert!;
    }
  }
}

/// Fake GoTrueClient pour simuler auth.currentUser
class _FakeGoTrueClient implements GoTrueClient {
  final User? fakeUser;

  _FakeGoTrueClient(this.fakeUser);

  @override
  User? get currentUser => fakeUser;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  Stream<AuthState> get onAuthStateChangeSync => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake SupabaseClient qui capture les appels insert
class _FakeSupabaseClient extends SupabaseClient {
  final _FakeSupabaseInsertCapture capture = _FakeSupabaseInsertCapture();
  final _FakeGoTrueClient fakeAuth;

  _FakeSupabaseClient({User? fakeUser})
      : fakeAuth = _FakeGoTrueClient(fakeUser),
        super('http://localhost:54321', 'test-anon-key');

  @override
  GoTrueClient get auth => fakeAuth;

  @override
  SupabaseQueryBuilder from(String table) {
    return _FakeSupabaseQueryBuilder(table, capture);
  }
}

/// Fake SupabaseQueryBuilder qui intercepte les appels insert
class _FakeSupabaseQueryBuilder implements SupabaseQueryBuilder {
  final String tableName;
  final _FakeSupabaseInsertCapture capture;

  _FakeSupabaseQueryBuilder(this.tableName, this.capture);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // insert() est une méthode qui retourne directement un PostgrestFilterBuilder
    if (invocation.isMethod && invocation.memberName == #insert) {
      final values = invocation.positionalArguments.first;
      if (values is Map<String, dynamic>) {
        capture.captureInsert(tableName, values);
      } else if (values is List) {
        for (final item in values) {
          if (item is Map<String, dynamic>) {
            capture.captureInsert(tableName, item);
          }
        }
      }
      // Retourner un fake filter builder qui implémente then() pour await
      return _FakePostgrestFilterBuilder();
    }
    // Pour toutes les autres méthodes/getters, retourner this
    if (invocation.isGetter || invocation.isMethod) {
      return this;
    }
    throw UnimplementedError(
      'Méthode non implémentée: ${invocation.memberName}',
    );
  }
}

/// Fake PostgrestFilterBuilder qui implémente then() pour await
class _FakePostgrestFilterBuilder implements PostgrestFilterBuilder {
  final Future<void> _future = Future.value();

  @override
  Future<S> then<S>(
    FutureOr<S> Function(void value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('StocksAdjustmentsService', () {
    late ProviderContainer container;
    late _FakeSupabaseClient fakeClient;

    setUp(() {
      // Créer un fake user pour les tests
      final fakeUser = User(
        id: 'test-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      fakeClient = _FakeSupabaseClient(fakeUser: fakeUser);

      // Créer un container avec override du client Supabase
      container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(fakeClient),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('createAdjustment - Happy path', () {
      test('inserts correct payload to stocks_adjustments table', () async {
        final service = container.read(stocksAdjustmentsServiceProvider);

        await service.createAdjustment(
          mouvementType: 'RECEPTION',
          mouvementId: 'test-mouvement-id',
          deltaAmbiant: 50.0,
          delta15c: 48.5,
          reason: 'Correction manuelle du volume',
        );

        // Vérifier que l'insert a été appelé
        expect(fakeClient.capture.insertCallCount, 1);
        expect(fakeClient.capture.capturedTableName, 'stocks_adjustments');

        // Vérifier le payload
        final payload = fakeClient.capture.insertedPayloads.first;
        expect(payload['mouvement_type'], 'RECEPTION');
        expect(payload['mouvement_id'], 'test-mouvement-id');
        expect(payload['delta_ambiant'], 50.0);
        expect(payload['delta_15c'], 48.5);
        expect(payload['reason'], 'Correction manuelle du volume');
        expect(payload['created_by'], 'test-user-id');
      });

      test('normalizes mouvement_type to uppercase', () async {
        final service = container.read(stocksAdjustmentsServiceProvider);

        await service.createAdjustment(
          mouvementType: 'reception',
          mouvementId: 'test-id',
          deltaAmbiant: 10.0,
          reason: 'Test reason with enough characters',
        );

        final payload = fakeClient.capture.insertedPayloads.first;
        expect(payload['mouvement_type'], 'RECEPTION');
      });

      test('trims mouvement_id and reason', () async {
        final service = container.read(stocksAdjustmentsServiceProvider);

        await service.createAdjustment(
          mouvementType: 'SORTIE',
          mouvementId: '  test-id  ',
          deltaAmbiant: 10.0,
          reason: '  Test reason with enough characters  ',
        );

        final payload = fakeClient.capture.insertedPayloads.first;
        expect(payload['mouvement_id'], 'test-id');
        expect(payload['reason'], 'Test reason with enough characters');
      });

      test('handles SORTIE mouvement type', () async {
        final service = container.read(stocksAdjustmentsServiceProvider);

        await service.createAdjustment(
          mouvementType: 'SORTIE',
          mouvementId: 'test-sortie-id',
          deltaAmbiant: -30.0,
          delta15c: -29.0,
          reason: 'Correction sortie avec assez de caractères',
        );

        final payload = fakeClient.capture.insertedPayloads.first;
        expect(payload['mouvement_type'], 'SORTIE');
        expect(payload['delta_ambiant'], -30.0);
      });
    });

    group('createAdjustment - Validations', () {
      test('throws StocksAdjustmentsException when deltaAmbiant is 0', () async {
        final service = container.read(stocksAdjustmentsServiceProvider);

        expect(
          () => service.createAdjustment(
            mouvementType: 'RECEPTION',
            mouvementId: 'test-id',
            deltaAmbiant: 0.0,
            reason: 'Test reason with enough characters',
          ),
          throwsA(
            isA<StocksAdjustmentsException>().having(
              (e) => e.message,
              'message',
              contains('Delta ambiant invalide'),
            ),
          ),
        );

        expect(fakeClient.capture.insertCallCount, 0);
      });

      test('throws StocksAdjustmentsException when reason is too short', () async {
        final service = container.read(stocksAdjustmentsServiceProvider);

        expect(
          () => service.createAdjustment(
            mouvementType: 'RECEPTION',
            mouvementId: 'test-id',
            deltaAmbiant: 10.0,
            reason: 'Short',
          ),
          throwsA(
            isA<StocksAdjustmentsException>().having(
              (e) => e.message,
              'message',
              contains('Raison trop courte'),
            ),
          ),
        );

        expect(fakeClient.capture.insertCallCount, 0);
      });

      test('throws StocksAdjustmentsException when mouvement_type is invalid', () async {
        final service = container.read(stocksAdjustmentsServiceProvider);

        expect(
          () => service.createAdjustment(
            mouvementType: 'INVALID',
            mouvementId: 'test-id',
            deltaAmbiant: 10.0,
            reason: 'Test reason with enough characters',
          ),
          throwsA(
            isA<StocksAdjustmentsException>().having(
              (e) => e.message,
              'message',
              contains('Type de mouvement invalide'),
            ),
          ),
        );

        expect(fakeClient.capture.insertCallCount, 0);
      });

      test('throws StocksAdjustmentsException when mouvement_id is empty', () async {
        final service = container.read(stocksAdjustmentsServiceProvider);

        expect(
          () => service.createAdjustment(
            mouvementType: 'RECEPTION',
            mouvementId: '   ',
            deltaAmbiant: 10.0,
            reason: 'Test reason with enough characters',
          ),
          throwsA(
            isA<StocksAdjustmentsException>().having(
              (e) => e.message,
              'message',
              contains('Identifiant du mouvement invalide'),
            ),
          ),
        );

        expect(fakeClient.capture.insertCallCount, 0);
      });

      test('throws StocksAdjustmentsException when user is not authenticated', () async {
        // Créer un client sans user
        final clientWithoutUser = _FakeSupabaseClient(fakeUser: null);
        final containerNoUser = ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWithValue(clientWithoutUser),
          ],
        );

        final service = containerNoUser.read(stocksAdjustmentsServiceProvider);

        expect(
          () => service.createAdjustment(
            mouvementType: 'RECEPTION',
            mouvementId: 'test-id',
            deltaAmbiant: 10.0,
            reason: 'Test reason with enough characters',
          ),
          throwsA(
            isA<StocksAdjustmentsException>().having(
              (e) => e.message,
              'message',
              contains('Utilisateur non authentifié'),
            ),
          ),
        );

        containerNoUser.dispose();
      });
    });

    group('createAdjustment - Supabase errors', () {
      test('maps RLS errors to user-friendly message', () async {
        final service = container.read(stocksAdjustmentsServiceProvider);

        // Configurer le fake pour lancer une PostgrestException avec message RLS
        fakeClient.capture.throwOnInsert = PostgrestException(
          message: 'Row level security policy violation',
          details: 'RLS check failed',
          hint: 'Check permissions',
          code: '42501',
        );

        expect(
          () => service.createAdjustment(
            mouvementType: 'RECEPTION',
            mouvementId: 'test-id',
            deltaAmbiant: 10.0,
            reason: 'Test reason with enough characters',
          ),
          throwsA(
            isA<StocksAdjustmentsException>().having(
              (e) => e.message,
              'message',
              contains('Droits insuffisants'),
            ),
          ),
        );
      });

      test('maps generic PostgrestException to user-friendly message', () async {
        final service = container.read(stocksAdjustmentsServiceProvider);

        // Configurer le fake pour lancer une PostgrestException générique
        fakeClient.capture.throwOnInsert = PostgrestException(
          message: 'Connection timeout',
          details: 'Network error',
          hint: 'Check connection',
          code: 'CONNECTION_ERROR',
        );

        expect(
          () => service.createAdjustment(
            mouvementType: 'RECEPTION',
            mouvementId: 'test-id',
            deltaAmbiant: 10.0,
            reason: 'Test reason with enough characters',
          ),
          throwsA(
            isA<StocksAdjustmentsException>().having(
              (e) => e.message,
              'message',
              contains('Erreur lors de la création'),
            ),
          ),
        );
      });
    });
  });
}

