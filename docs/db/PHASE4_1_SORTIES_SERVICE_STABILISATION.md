# 🚀 Phase 4.1 – Stabiliser SortieService + sorties_submission_test.dart

**Date de démarrage** : 06/12/2025  
**Statut** : 🚧 **EN COURS**  
**Priorité** : 🔴 **HAUTE** (bloque les tests)

---

## 🎯 Objectif Phase 4.1

Corriger la signature de `SortieService.createValidated` et celle du `_SpySortieService` dans le test pour qu'elles soient parfaitement alignées.

S'assurer que le test ne casse rien niveau logique métier.

**Arriver à un état où** :
```bash
flutter test test/integration/sorties_submission_test.dart -r expanded
```
compile et exécute sans erreur de type/signature.

---

## 🐛 Erreurs actuelles (rappel)

### Erreur 1 : Paramètre `proprietaireType`
```
Error: The required named parameter 'proprietaireType' in method 
'_SpySortieService.createValidated' is not required in overridden method 
'SortieService.createValidated'.
```

**Problème** : Le spy déclare `proprietaireType` comme `required`, mais le service réel ne le fait pas (ou vice versa).

### Erreur 2 : Type `volumeCorrige15C`
```
Error: The parameter 'volumeCorrige15C' of the method 
'_SpySortieService.createValidated' has type 'double', which does not match 
the corresponding type, 'double?', in the overridden method, 
'SortieService.createValidated'.
```

**Problème** : Le spy déclare `volumeCorrige15C` comme `double`, mais le service réel attend `double?` (ou vice versa).

---

## 🔧 Plan d'action

### Étape 1 : Analyser le service réel

**Fichier** : `lib/features/sorties/data/sortie_service.dart`

**Actions** :
1. Localiser la méthode `createValidated`
2. Lister précisément tous les paramètres :
   - Nom exact
   - Type exact (`double` vs `double?`, `String` vs `String?`, etc.)
   - Caractère `required` ou optionnel
   - Ordre des paramètres

**Exemple de ce qu'on cherche** :
```dart
Future<void> createValidated({
  required String citerneId,
  required String produitId,
  required String proprietaireType,  // ← required ou non ?
  required double volumeAmbiant,
  double? volumeCorrige15C,          // ← double ou double? ?
  // ... autres paramètres
}) async {
  // ...
}
```

---

### Étape 2 : Analyser le spy dans le test

**Fichier** : `test/integration/sorties_submission_test.dart`

**Actions** :
1. Localiser la classe `_SpySortieService` (ou équivalent)
2. Localiser la méthode `createValidated` dans cette classe
3. Comparer signature par signature avec le service réel

**Exemple de ce qu'on cherche** :
```dart
class _SpySortieService extends Mock implements SortieService {
  @override
  Future<void> createValidated({
    required String citerneId,
    required String produitId,
    required String proprietaireType,  // ← doit matcher le service
    required double volumeAmbiant,
    double? volumeCorrige15C,          // ← doit matcher le service
    // ...
  }) async {
    // ...
  }
}
```

---

### Étape 3 : Décider de la "vérité métier"

#### Cas 1 : `proprietaireType`

**Question** : Ce champ est-il toujours obligatoire côté métier ?

- **Si OUI** → `required String proprietaireType` dans le service ET le spy
- **Si NON** → `String? proprietaireType` dans le service ET le spy

**Recommandation** : `required String proprietaireType` car :
- Une sortie doit toujours avoir un propriétaire (MONALUXE ou PARTENAIRE)
- C'est une règle métier fondamentale

#### Cas 2 : `volumeCorrige15C`

**Question** : Ce volume est-il calculé dans le service ou fourni en amont ?

- **Si calculé dans le service** → `double? volumeCorrige15C` (optionnel, le service le calcule)
- **Si fourni en amont** → `required double volumeCorrige15C` (obligatoire, calculé avant l'appel)

**Recommandation** : `double? volumeCorrige15C` car :
- Le service peut calculer ce volume à partir de `volumeAmbiant`, `temperature`, `densite`
- Permet plus de flexibilité (calcul côté service ou côté formulaire)

---

### Étape 4 : Aligner les signatures

**Principe** : Le spy doit être **exactement identique** au service réel.

**Checklist** :
- [ ] Même nom pour chaque paramètre
- [ ] Même type pour chaque paramètre (`double` vs `double?`, `String` vs `String?`, etc.)
- [ ] Même caractère `required` ou optionnel
- [ ] Même ordre des paramètres (bonne pratique)
- [ ] Même type de retour (`Future<void>`)

**Exemple de correction** :
```dart
// Service réel
Future<void> createValidated({
  required String citerneId,
  required String produitId,
  required String proprietaireType,
  required double volumeAmbiant,
  double? volumeCorrige15C,
  // ...
}) async { ... }

// Spy corrigé (identique)
@override
Future<void> createValidated({
  required String citerneId,
  required String produitId,
  required String proprietaireType,  // ← aligné
  required double volumeAmbiant,
  double? volumeCorrige15C,          // ← aligné
  // ...
}) async { ... }
```

---

### Étape 5 : Vérifier la logique métier

**Actions** :
1. S'assurer que les choix de signature sont cohérents avec la logique métier
2. Vérifier que le service appelle bien la bonne fonction SQL / RPC
3. Vérifier que le trigger SQL est bien déclenché

**Points de contrôle** :
- Le service doit appeler la fonction/trigger unifié (pas d'appels multiples)
- Les paramètres envoyés doivent correspondre à ce que la DB attend
- Les validations métier doivent être cohérentes (citerne active, volume disponible, etc.)

---

### Étape 6 : Re-run le test

**Commande** :
```bash
flutter test test/integration/sorties_submission_test.dart -r expanded
```

**Résultat attendu** :
- ✅ Compilation OK (plus d'erreur de signature)
- ✅ Tests qui s'exécutent (même s'ils échouent pour d'autres raisons fonctionnelles)

**Si erreurs fonctionnelles restent** :
- Ce sera la suite de la Phase 4.1 (correction de la logique métier)
- Mais au moins, on aura résolu le problème de signature

---

## 📋 Checklist de validation

- [ ] Signature `SortieService.createValidated` analysée et documentée
- [ ] Signature `_SpySortieService.createValidated` alignée 1:1 avec le service
- [ ] Décisions métier prises pour `proprietaireType` et `volumeCorrige15C`
- [ ] Test compile sans erreur de signature
- [ ] Test s'exécute (même s'il échoue pour d'autres raisons)
- [ ] Logique métier vérifiée (appels DB corrects)

---

## 🔗 Fichiers concernés

### Fichiers à modifier
- `lib/features/sorties/data/sortie_service.dart` (si besoin d'ajustement)
- `test/integration/sorties_submission_test.dart` (correction du spy)

### Fichiers à analyser
- `lib/features/sorties/data/sortie_service.dart` (signature actuelle)
- `test/integration/sorties_submission_test.dart` (spy actuel)
- Documentation SQL des triggers/fonctions (si disponible)

---

## 📝 Notes importantes

- **Principe** : Le spy doit être un miroir exact du service réel
- **Ordre** : Analyser d'abord le service réel, puis aligner le spy
- **Métier d'abord** : Les décisions de signature doivent être cohérentes avec la logique métier
- **Tests ensuite** : Une fois la signature alignée, on peut s'attaquer aux erreurs fonctionnelles

---

## 🎯 Résultat attendu

À la fin de la Phase 4.1 :

- ✅ `sorties_submission_test.dart` compile sans erreur
- ✅ Signature service/spy parfaitement alignée
- ✅ Logique métier cohérente
- ✅ Base solide pour la suite (Phase 4.2+)

