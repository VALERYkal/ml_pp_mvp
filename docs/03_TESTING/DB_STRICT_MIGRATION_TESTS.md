# Guide Migration Tests — DB-STRICT

**Phase** : Phase 3  
**Statut** : ⚪ À faire  
**Objectif** : Aligner les tests avec le paradigme DB-STRICT

---

## Vue d'ensemble

Cette phase consiste à **migrer tous les tests** pour qu'ils utilisent uniquement `createValidated()` et testent les invariants DB-STRICT.

**Principe** : Les tests doivent refléter la réalité de production (pas de brouillon, pas de validation différée).

---

## Tests à migrer

### 1. `test/integration/reception_flow_test.dart`

**Statut actuel** : Utilise `createDraft()` + `validateReception()` (legacy)

**Actions** :
- [ ] Remplacer tous les appels `createDraft()` par `createValidated()`
- [ ] Supprimer tous les appels `validateReception()`
- [ ] Ajouter des tests d'immutabilité
- [ ] Ajouter des tests de compensation

**Exemple de migration** :

**Avant** :
```dart
test('HAPPY PATH: createDraft -> validateReception OK', () async {
  final id = await service.createDraft(input);
  await service.validateReception(id); // ❌ Legacy
});
```

**Après** :
```dart
test('HAPPY PATH: createValidated OK', () async {
  final id = await service.createValidated(
    citerneId: 'citerne-id',
    produitId: 'produit-id',
    indexAvant: 1000,
    indexApres: 1060,
    temperatureCAmb: 25,
    densiteA15: 0.835,
    proprietaireType: 'MONALUXE',
  );
  
  expect(id, isNotEmpty);
  // Vérifier que le stock a été crédité (via trigger)
});
```

---

### 2. `test/sorties/sortie_draft_service_test.dart`

**Statut actuel** : Teste `SortieDraftService` (legacy)

**Actions** :
- [ ] Supprimer ce fichier (si `SortieDraftService` est supprimé)
- [ ] Ou créer `test/sorties/sortie_service_test.dart` avec des tests DB-STRICT

**Nouveau test** :
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/sorties/data/sortie_service.dart';
import 'package:ml_pp_mvp/core/errors/sortie_service_exception.dart';

void main() {
  group('SortieService (DB-STRICT)', () {
    late SortieService service;

    setUp(() {
      service = SortieService(Supabase.instance.client); // Ou mock
    });

    test('HAPPY PATH: createValidated MONALUXE OK', () async {
      await service.createValidated(
        citerneId: 'citerne-id',
        produitId: 'produit-id',
        indexAvant: 1000,
        indexApres: 1100,
        temperatureCAmb: 25,
        densiteA15: 0.83,
        proprietaireType: 'MONALUXE',
        clientId: 'client-id',
      );
      // Vérifier que le stock a été débité (via trigger)
    });

    test('ERREUR: stock insuffisant', () async {
      expect(
        () => service.createValidated(
          citerneId: 'citerne-vide',
          produitId: 'produit-id',
          indexAvant: 0,
          indexApres: 10000, // Volume trop important
          temperatureCAmb: 25,
          densiteA15: 0.83,
          proprietaireType: 'MONALUXE',
          clientId: 'client-id',
        ),
        throwsA(isA<SortieServiceException>()),
      );
    });
  });
}
```

---

## Nouveaux tests à ajouter

### 3. Tests d'immutabilité

**Fichier** : `test/integration/immutability_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Immutabilité DB-STRICT', () {
    test('UPDATE réception validée → rejet', () async {
      // Créer une réception
      final receptionId = await createReception();
      
      // Tenter UPDATE
      expect(
        () => Supabase.instance.client
            .from('receptions')
            .update({'note': 'test'})
            .eq('id', receptionId),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('DELETE sortie validée → rejet', () async {
      // Créer une sortie
      final sortieId = await createSortie();
      
      // Tenter DELETE
      expect(
        () => Supabase.instance.client
            .from('sorties_produit')
            .delete()
            .eq('id', sortieId),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
```

---

### 4. Tests de compensation

**Fichier** : `test/integration/compensation_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Compensation admin', () {
    test('admin_compensate_reception → stock corrigé + log CRITICAL', () async {
      // Créer une réception
      final receptionId = await createReception();
      
      // Récupérer le stock avant
      final stockAvant = await getStock();
      
      // Compenser
      final adjustmentId = await Supabase.instance.client
          .rpc('admin_compensate_reception', params: {
        'p_reception_id': receptionId,
        'p_reason': 'Test de compensation - réception en double',
      });
      
      expect(adjustmentId, isNotEmpty);
      
      // Vérifier que le stock a été corrigé
      final stockApres = await getStock();
      expect(stockApres, lessThan(stockAvant));
      
      // Vérifier le log CRITICAL
      final logs = await Supabase.instance.client
          .from('log_actions')
          .select()
          .eq('action', 'STOCK_ADJUSTMENT')
          .eq('niveau', 'CRITICAL')
          .order('created_at', ascending: false)
          .limit(1);
      
      expect(logs, isNotEmpty);
      expect(logs[0]['details']['source_id'], equals(receptionId));
    });

    test('Non-admin compensation → rejet', () async {
      // En tant que non-admin
      expect(
        () => Supabase.instance.client
            .rpc('admin_compensate_reception', params: {
          'p_reception_id': 'uuid',
          'p_reason': 'Test',
        }),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
```

---

## Tests d'intégration complets

### 5. Test du flux complet DB-STRICT

**Fichier** : `test/integration/db_strict_flow_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_service.dart';
import 'package:ml_pp_mvp/features/sorties/data/sortie_service.dart';

void main() {
  group('Flux DB-STRICT complet', () {
    test('Réception → Stock crédité automatiquement', () async {
      final receptionService = ReceptionService.withClient(...);
      
      final receptionId = await receptionService.createValidated(
        citerneId: 'citerne-id',
        produitId: 'produit-id',
        indexAvant: 1000,
        indexApres: 1060,
        temperatureCAmb: 25,
        densiteA15: 0.835,
      );
      
      // Vérifier que le stock a été crédité
      final stock = await getStock();
      expect(stock.stock_ambiant, greaterThan(0));
      expect(stock.stock_15c, greaterThan(0));
    });

    test('Sortie → Stock débité automatiquement', () async {
      final sortieService = SortieService(...);
      
      final sortieId = await sortieService.createValidated(
        citerneId: 'citerne-id',
        produitId: 'produit-id',
        indexAvant: 1000,
        indexApres: 1100,
        temperatureCAmb: 25,
        densiteA15: 0.83,
        proprietaireType: 'MONALUXE',
        clientId: 'client-id',
      );
      
      // Vérifier que le stock a été débité
      final stock = await getStock();
      expect(stock.stock_ambiant, lessThan(stockInitial));
    });

    test('Compensation → Stock corrigé', () async {
      // Créer une réception
      final receptionId = await createReception();
      
      // Compenser
      await compensateReception(receptionId);
      
      // Vérifier que le stock est revenu à l'état initial
      final stock = await getStock();
      expect(stock.stock_ambiant, equals(stockInitial));
    });
  });
}
```

---

## Checklist de validation

- [ ] `test/integration/reception_flow_test.dart` migré vers `createValidated()`
- [ ] `test/sorties/sortie_draft_service_test.dart` supprimé ou migré
- [ ] Tests d'immutabilité ajoutés
- [ ] Tests de compensation ajoutés
- [ ] Tests d'intégration complets ajoutés
- [ ] Suite tests verte sur CI/local
- [ ] Tous les tests utilisent uniquement `createValidated()`
- [ ] Aucun test n'utilise `createDraft()` ou `validate()`

---

## Commandes de test

```bash
# Exécuter tous les tests
flutter test

# Exécuter uniquement les tests d'intégration
flutter test test/integration/

# Exécuter avec coverage
flutter test --coverage
```

---

## Notes importantes

- **Ordre** : Faire cette migration **après** la Phase 2 (nettoyage code) pour éviter de tester du code legacy.
- **Cohérence** : Les tests doivent refléter exactement le comportement de production.
- **Couverture** : S'assurer que tous les cas d'erreur sont testés.

---

**Dernière mise à jour** : 2025-12-21

