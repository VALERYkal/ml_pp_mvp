// test/features/sorties/sortie_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/sorties/data/sortie_service.dart';
import 'package:ml_pp_mvp/core/errors/sortie_service_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake qui capture les payloads insérés
class _FakeSupabaseInsertCapture {
  final List<Map<String, dynamic>> insertedPayloads = [];
  int insertCallCount = 0;

  void captureInsert(Map<String, dynamic> payload) {
    insertCallCount++;
    insertedPayloads.add(Map<String, dynamic>.from(payload));
  }
}

/// Fake SupabaseClient qui capture les appels insert
class _FakeSupabaseClient extends SupabaseClient {
  final _FakeSupabaseInsertCapture capture = _FakeSupabaseInsertCapture();
  final _FakeSupabaseQueryBuilder queryBuilder = _FakeSupabaseQueryBuilder();

  _FakeSupabaseClient() : super('http://localhost:54321', 'test-anon-key');

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == 'sorties_produit') {
      queryBuilder.capture = capture;
      return queryBuilder;
    }
    throw UnimplementedError('Table $table non mockée');
  }
}

/// Fake SupabaseQueryBuilder qui intercepte les appels insert
class _FakeSupabaseQueryBuilder implements SupabaseQueryBuilder {
  _FakeSupabaseInsertCapture? capture;
  final _FakeFilterBuilder filterBuilder = _FakeFilterBuilder();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // insert() est une méthode qui retourne directement un PostgrestFilterBuilder
    if (invocation.isMethod && invocation.memberName == #insert) {
      final values = invocation.positionalArguments.first;
      if (capture != null) {
        if (values is Map<String, dynamic>) {
          capture!.captureInsert(values);
        } else if (values is List) {
          for (final item in values) {
            if (item is Map<String, dynamic>) {
              capture!.captureInsert(item);
            }
          }
        }
      }
      return filterBuilder;
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

/// Fake filter builder qui retourne un transform builder sur select()
class _FakeFilterBuilder implements PostgrestFilterBuilder {
  final _FakeTransformBuilder transformBuilder = _FakeTransformBuilder();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // select() doit retourner un objet qui a une méthode single()
    if (invocation.isMethod && invocation.memberName == #select) {
      return transformBuilder;
    }
    // Pour toutes les autres méthodes, retourner this
    if (invocation.isGetter || invocation.isMethod) {
      return this;
    }
    throw UnimplementedError(
      'Méthode non implémentée: ${invocation.memberName}',
    );
  }
}

/// Fake transform builder qui retourne un Future sur single()
/// Note: PostgrestTransformBuilder est un Future, donc single() retourne this
class _FakeTransformBuilder implements PostgrestTransformBuilder {
  final Future<Map<String, dynamic>> _future = Future.value({
    'id': 'fake-sortie-id',
  });

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // single() doit retourner this (qui est un PostgrestTransformBuilder et un Future)
    if (invocation.isMethod && invocation.memberName == #single) {
      return this;
    }
    // Déléguer les méthodes de Future à _future
    if (invocation.isMethod && invocation.memberName == #then) {
      return _future.then(
        invocation.positionalArguments[0] as dynamic,
        onError: invocation.positionalArguments.length > 1
            ? invocation.positionalArguments[1] as dynamic
            : null,
      );
    }
    if (invocation.isMethod && invocation.memberName == #catchError) {
      return _future.catchError(
        invocation.positionalArguments[0] as dynamic,
        test: invocation.positionalArguments.length > 1
            ? invocation.positionalArguments[1] as dynamic
            : null,
      );
    }
    if (invocation.isMethod && invocation.memberName == #whenComplete) {
      return _future.whenComplete(invocation.positionalArguments[0] as dynamic);
    }
    if (invocation.isMethod && invocation.memberName == #timeout) {
      return _future.timeout(
        invocation.positionalArguments[0] as Duration,
        onTimeout: invocation.positionalArguments.length > 1
            ? invocation.positionalArguments[1] as dynamic
            : null,
      );
    }
    // Pour toutes les autres méthodes, retourner this
    if (invocation.isGetter || invocation.isMethod) {
      return this;
    }
    throw UnimplementedError(
      'Méthode non implémentée: ${invocation.memberName}',
    );
  }
}

void main() {
  group('SortieService.createValidated', () {
    late _FakeSupabaseClient fakeClient;
    late SortieService service;

    setUp(() {
      fakeClient = _FakeSupabaseClient();
      service = SortieService(fakeClient);
    });

    test('insère une sortie MONALUXE avec client et indices valides', () async {
      // Arrange
      const citerneId = 'citerne-1';
      const produitId = 'produit-go';
      const indexAvant = 0.0;
      const indexApres = 100.0;
      const temperatureCAmb = 20.0;
      const densiteA15 = 0.83;
      const clientId = 'client-1';
      const proprietaireType = 'MONALUXE';
      final dateSortie = DateTime.now();

      // Act
      await service.createValidated(
        citerneId: citerneId,
        produitId: produitId,
        indexAvant: indexAvant,
        indexApres: indexApres,
        temperatureCAmb: temperatureCAmb,
        densiteA15: densiteA15,
        volumeCorrige15C: null, // Laisser le service calculer
        proprietaireType: proprietaireType,
        clientId: clientId,
        partenaireId: null,
        chauffeurNom: 'Jean Chauffeur',
        plaqueCamion: 'ABC-123',
        transporteur: 'Transports TEST',
        note: 'Note de test',
        dateSortie: dateSortie,
      );

      // Assert
      expect(
        fakeClient.capture.insertCallCount,
        equals(1),
        reason: 'insert doit être appelé exactement une fois',
      );

      final payload = fakeClient.capture.insertedPayloads.first;

      // Vérifier les champs obligatoires
      expect(payload['citerne_id'], equals(citerneId));
      expect(payload['produit_id'], equals(produitId));
      expect(payload['proprietaire_type'], equals('MONALUXE'));
      expect(payload['client_id'], equals(clientId));
      expect(
        payload['partenaire_id'],
        isNull,
        reason: 'partenaire_id doit être null pour MONALUXE',
      );

      // Vérifier les indices
      expect(payload['index_avant'], equals(indexAvant));
      expect(payload['index_apres'], equals(indexApres));

      // Vérifier les mesures
      expect(payload['temperature_ambiante_c'], equals(temperatureCAmb));
      expect(payload['densite_a_15_kgm3'], equals(densiteA15));

      // Vérifier les volumes
      expect(
        payload['volume_ambiant'],
        equals(100.0),
        reason: 'volume_ambiant = indexApres - indexAvant = 100 - 0',
      );
      expect(
        payload['volume_corrige_15c'],
        equals(100.0),
        reason: 'volumeCorrige15C null → utilise volumeAmbiant',
      );
      expect(payload['volume_corrige_15c'], greaterThan(0));

      // Vérifier le statut
      expect(payload['statut'], equals('validee'));

      // Vérifier les champs optionnels
      expect(payload['chauffeur_nom'], equals('Jean Chauffeur'));
      expect(payload['plaque_camion'], equals('ABC-123'));
      expect(payload['transporteur'], equals('Transports TEST'));
      expect(payload['note'], equals('Note de test'));
      expect(
        payload['date_sortie'],
        equals(dateSortie.toUtc().toIso8601String()),
      );
    });

    test(
      'insère une sortie PARTENAIRE avec partenaireId et sans clientId',
      () async {
        // Arrange
        const citerneId = 'citerne-2';
        const produitId = 'produit-ess';
        const indexAvant = 50.0;
        const indexApres = 150.0;
        const temperatureCAmb = 25.0;
        const densiteA15 = 0.75;
        const partenaireId = 'partenaire-42';
        const proprietaireType = 'PARTENAIRE';

        // Act
        await service.createValidated(
          citerneId: citerneId,
          produitId: produitId,
          indexAvant: indexAvant,
          indexApres: indexApres,
          temperatureCAmb: temperatureCAmb,
          densiteA15: densiteA15,
          volumeCorrige15C: null,
          proprietaireType: proprietaireType,
          clientId: null,
          partenaireId: partenaireId,
          note: 'Sortie partenaire',
        );

        // Assert
        expect(fakeClient.capture.insertCallCount, equals(1));

        final payload = fakeClient.capture.insertedPayloads.first;

        // Vérifier le propriétaire
        expect(payload['proprietaire_type'], equals('PARTENAIRE'));
        expect(payload['partenaire_id'], equals(partenaireId));
        expect(
          payload['client_id'],
          isNull,
          reason: 'client_id doit être null pour PARTENAIRE',
        );

        // Vérifier les autres champs
        expect(payload['citerne_id'], equals(citerneId));
        expect(payload['produit_id'], equals(produitId));
        expect(payload['index_avant'], equals(indexAvant));
        expect(payload['index_apres'], equals(indexApres));
        expect(payload['temperature_ambiante_c'], equals(temperatureCAmb));
        expect(payload['densite_a_15_kgm3'], equals(densiteA15));
        expect(payload['volume_ambiant'], equals(100.0)); // 150 - 50
        expect(payload['volume_corrige_15c'], equals(100.0));
        expect(payload['statut'], equals('validee'));
        expect(payload['note'], equals('Sortie partenaire'));
      },
    );

    test('utilise directement volumeCorrige15C si fourni', () async {
      // Arrange
      const citerneId = 'citerne-1';
      const produitId = 'produit-go';
      const indexAvant = 0.0;
      const indexApres = 100.0;
      const temperatureCAmb = 20.0;
      const densiteA15 = 0.83;
      const volumeCorrige15C = 123.45; // Valeur fournie explicitement
      const clientId = 'client-1';

      // Act
      await service.createValidated(
        citerneId: citerneId,
        produitId: produitId,
        indexAvant: indexAvant,
        indexApres: indexApres,
        temperatureCAmb: temperatureCAmb,
        densiteA15: densiteA15,
        volumeCorrige15C: volumeCorrige15C, // Fourni explicitement
        proprietaireType: 'MONALUXE',
        clientId: clientId,
      );

      // Assert
      final payload = fakeClient.capture.insertedPayloads.first;

      // Vérifier que le volume fourni est utilisé tel quel
      expect(
        payload['volume_corrige_15c'],
        equals(volumeCorrige15C),
        reason:
            'Le volumeCorrige15C fourni doit être utilisé tel quel, sans recalcul',
      );

      // Vérifier que volume_ambiant est toujours calculé depuis les indices
      expect(payload['volume_ambiant'], equals(100.0));
    });

    test('lance une exception si clientId manquant pour MONALUXE', () async {
      // Arrange
      const citerneId = 'citerne-1';
      const produitId = 'produit-go';

      // Act & Assert
      expect(
        () => service.createValidated(
          citerneId: citerneId,
          produitId: produitId,
          indexAvant: 0.0,
          indexApres: 100.0,
          temperatureCAmb: 20.0,
          densiteA15: 0.83,
          proprietaireType: 'MONALUXE',
          clientId: null, // ❌ Manquant
          partenaireId: null,
        ),
        throwsA(
          isA<SortieServiceException>()
              .having(
                (e) => e.message,
                'message',
                contains('client est obligatoire'),
              )
              .having((e) => e.code, 'code', equals('CLIENT_REQUIRED')),
        ),
      );
    });

    test(
      'lance une exception si partenaireId manquant pour PARTENAIRE',
      () async {
        // Arrange
        const citerneId = 'citerne-1';
        const produitId = 'produit-go';

        // Act & Assert
        expect(
          () => service.createValidated(
            citerneId: citerneId,
            produitId: produitId,
            indexAvant: 0.0,
            indexApres: 100.0,
            temperatureCAmb: 20.0,
            densiteA15: 0.83,
            proprietaireType: 'PARTENAIRE',
            clientId: null,
            partenaireId: null, // ❌ Manquant
          ),
          throwsA(
            isA<SortieServiceException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('partenaire est obligatoire'),
                )
                .having((e) => e.code, 'code', equals('PARTENAIRE_REQUIRED')),
          ),
        );
      },
    );

    test('normalise proprietaireType (monaluxe → MONALUXE)', () async {
      // Arrange
      const citerneId = 'citerne-1';
      const produitId = 'produit-go';
      const clientId = 'client-1';

      // Act
      await service.createValidated(
        citerneId: citerneId,
        produitId: produitId,
        indexAvant: 0.0,
        indexApres: 100.0,
        temperatureCAmb: 20.0,
        densiteA15: 0.83,
        proprietaireType: 'monaluxe', // Minuscules
        clientId: clientId,
      );

      // Assert
      final payload = fakeClient.capture.insertedPayloads.first;
      expect(
        payload['proprietaire_type'],
        equals('MONALUXE'),
        reason: 'proprietaireType doit être normalisé en majuscules',
      );
    });

    test('trim les champs texte optionnels', () async {
      // Arrange
      const citerneId = 'citerne-1';
      const produitId = 'produit-go';
      const clientId = 'client-1';

      // Act
      await service.createValidated(
        citerneId: citerneId,
        produitId: produitId,
        indexAvant: 0.0,
        indexApres: 100.0,
        temperatureCAmb: 20.0,
        densiteA15: 0.83,
        proprietaireType: 'MONALUXE',
        clientId: clientId,
        chauffeurNom: '  Jean Chauffeur  ', // Avec espaces
        note: '  Note avec espaces  ',
      );

      // Assert
      final payload = fakeClient.capture.insertedPayloads.first;
      expect(
        payload['chauffeur_nom'],
        equals('Jean Chauffeur'),
        reason: 'chauffeurNom doit être trimé',
      );
      expect(
        payload['note'],
        equals('Note avec espaces'),
        reason: 'note doit être trimée',
      );
    });

    test('n\'inclut pas les champs optionnels vides dans le payload', () async {
      // Arrange
      const citerneId = 'citerne-1';
      const produitId = 'produit-go';
      const clientId = 'client-1';

      // Act
      await service.createValidated(
        citerneId: citerneId,
        produitId: produitId,
        indexAvant: 0.0,
        indexApres: 100.0,
        temperatureCAmb: 20.0,
        densiteA15: 0.83,
        proprietaireType: 'MONALUXE',
        clientId: clientId,
        chauffeurNom: '', // Vide
        note: '', // Vide
        plaqueCamion: null, // Null
      );

      // Assert
      final payload = fakeClient.capture.insertedPayloads.first;

      // Les champs vides/null ne doivent pas être présents
      expect(
        payload.containsKey('chauffeur_nom'),
        isFalse,
        reason: 'chauffeurNom vide ne doit pas être dans le payload',
      );
      expect(
        payload.containsKey('note'),
        isFalse,
        reason: 'note vide ne doit pas être dans le payload',
      );
      expect(
        payload.containsKey('plaque_camion'),
        isFalse,
        reason: 'plaqueCamion null ne doit pas être dans le payload',
      );
    });
  });
}
