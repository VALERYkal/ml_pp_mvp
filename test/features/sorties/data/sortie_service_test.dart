import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/sorties/data/sortie_service.dart';
import '../../../helpers/no_network_helper.dart';

void main() {
  group('SortieService - Tests avec injection de dépendance', () {
    late SortieService service;
    late Map<String, dynamic>? lastRpcCall;
    late String? lastRpcFunction;

    setUpAll(() {
      // Bloquer tout accès réseau
      NoNetworkHelper.blockNetwork();
    });

    tearDownAll(() {
      // Restaurer l'accès réseau
      NoNetworkHelper.restoreNetwork();
    });

    setUp(() {
      // Mock de la fonction RPC
      lastRpcCall = null;
      lastRpcFunction = null;
      
      final rpcMock = (String fn, {Map<String, dynamic>? params}) async {
        lastRpcFunction = fn;
        lastRpcCall = params;
        
        if (fn == 'create_sortie') {
          return {'id': 'sortie-123'};
        }
        
        return null;
      };
      
      service = SortieService(rpc: rpcMock);
    });

    test('createValidated appelle la bonne fonction RPC avec les bons paramètres', () async {
      // Arrange
      const citerneId = 'cit-1';
      const produitId = 'prod-1';
      const clientId = 'client-1';
      const indexAvant = 100.0;
      const indexApres = 120.0;
      const chauffeurNom = 'Chauffeur Test';
      const plaqueCamion = 'ABC-123';
      const transporteur = 'Transport Test';
      const note = 'Note de test';

      // Act
      final result = await service.createValidated(
        citerneId: citerneId,
        produitId: produitId,
        clientId: clientId,
        indexAvant: indexAvant,
        indexApres: indexApres,
        chauffeurNom: chauffeurNom,
        plaqueCamion: plaqueCamion,
        transporteur: transporteur,
        note: note,
      );

      // Assert
      expect(result, equals('sortie-123'));
      expect(lastRpcFunction, equals('create_sortie'));
      expect(lastRpcCall, isNotNull);
      expect(lastRpcCall!['citerne_id'], equals(citerneId));
      expect(lastRpcCall!['produit_id'], equals(produitId));
      expect(lastRpcCall!['client_id'], equals(clientId));
      expect(lastRpcCall!['index_avant'], equals(indexAvant));
      expect(lastRpcCall!['index_apres'], equals(indexApres));
      expect(lastRpcCall!['chauffeur_nom'], equals(chauffeurNom));
      expect(lastRpcCall!['plaque_camion'], equals(plaqueCamion));
      expect(lastRpcCall!['transporteur'], equals(transporteur));
      expect(lastRpcCall!['note'], equals(note));
      expect(lastRpcCall!['proprietaire_type'], equals('MONALUXE'));
    });

    test('createValidated avec partenaire utilise le bon proprietaire_type', () async {
      // Arrange
      const partenaireId = 'part-1';

      // Act
      await service.createValidated(
        citerneId: 'cit-1',
        produitId: 'prod-1',
        partenaireId: partenaireId,
        proprietaireType: 'PARTENAIRE',
        indexAvant: 100.0,
        indexApres: 120.0,
        chauffeurNom: 'Chauffeur',
        plaqueCamion: 'ABC-123',
        transporteur: 'Transport',
      );

      // Assert
      expect(lastRpcCall!['proprietaire_type'], equals('PARTENAIRE'));
      expect(lastRpcCall!['partenaire_id'], equals(partenaireId));
      expect(lastRpcCall!['client_id'], isNull);
    });

    test('createValidated avec température et densité', () async {
      // Act
      await service.createValidated(
        citerneId: 'cit-1',
        produitId: 'prod-1',
        clientId: 'client-1',
        indexAvant: 100.0,
        indexApres: 120.0,
        temperatureCAmb: 25.0,
        densiteA15: 0.75,
        chauffeurNom: 'Chauffeur',
        plaqueCamion: 'ABC-123',
        transporteur: 'Transport',
      );

      // Assert
      expect(lastRpcCall!['temperature_ambiante_c'], equals(25.0));
      expect(lastRpcCall!['densite_a_15'], equals(0.75));
    });

    test('createValidated avec date de sortie', () async {
      // Arrange
      final dateSortie = DateTime(2025, 1, 15, 14, 30);

      // Act
      await service.createValidated(
        citerneId: 'cit-1',
        produitId: 'prod-1',
        clientId: 'client-1',
        indexAvant: 100.0,
        indexApres: 120.0,
        chauffeurNom: 'Chauffeur',
        plaqueCamion: 'ABC-123',
        transporteur: 'Transport',
        dateSortie: dateSortie,
      );

      // Assert
      expect(lastRpcCall!['date_sortie'], equals(dateSortie.toIso8601String()));
    });

    test('createValidated rejette les indices incohérents', () async {
      // Act & Assert
      expect(
        () => service.createValidated(
          citerneId: 'cit-1',
          produitId: 'prod-1',
          clientId: 'client-1',
          indexAvant: 120.0, // Plus grand que indexApres
          indexApres: 100.0,
          chauffeurNom: 'Chauffeur',
          plaqueCamion: 'ABC-123',
          transporteur: 'Transport',
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('INDEX_INCOHERENTS'),
        )),
      );
    });

    test('createValidated gère les erreurs RPC', () async {
      // Arrange
      final errorRpc = (String fn, {Map<String, dynamic>? params}) async {
        throw Exception('Erreur RPC simulée');
      };
      
      final errorService = SortieService(rpc: errorRpc);

      // Act & Assert
      expect(
        () => errorService.createValidated(
          citerneId: 'cit-1',
          produitId: 'prod-1',
          clientId: 'client-1',
          indexAvant: 100.0,
          indexApres: 120.0,
          chauffeurNom: 'Chauffeur',
          plaqueCamion: 'ABC-123',
          transporteur: 'Transport',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Erreur RPC simulée'),
        )),
      );
    });

    test('createValidated gère les réponses invalides', () async {
      // Arrange
      final invalidRpc = (String fn, {Map<String, dynamic>? params}) async {
        return null; // Réponse null
      };
      
      final invalidService = SortieService(rpc: invalidRpc);

      // Act & Assert
      expect(
        () => invalidService.createValidated(
          citerneId: 'cit-1',
          produitId: 'prod-1',
          clientId: 'client-1',
          indexAvant: 100.0,
          indexApres: 120.0,
          chauffeurNom: 'Chauffeur',
          plaqueCamion: 'ABC-123',
          transporteur: 'Transport',
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Réponse invalide du serveur'),
        )),
      );
    });
  });
}