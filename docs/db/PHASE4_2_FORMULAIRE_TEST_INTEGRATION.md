# 🎯 Phase 4.2 – Formulaire & Test d'intégration réel

**Date de démarrage** : 06/12/2025  
**Statut** : 🚧 **EN PLANIFICATION**  
**Priorité** : 🟡 **MOYENNE**  
**Dépendances** : Phase 4.1 (signatures stabilisées) ✅

---

## 🎯 Objectif Phase 4.2

Rendre le test d'intégration `sorties_submission_test.dart` réellement utile et fiabiliser le formulaire `sortie_form_screen.dart` pour qu'il soit aligné avec la logique métier et les validations SQL.

**Résultat attendu** :
- ✅ Test d'intégration dé-skippé et fonctionnel
- ✅ Formulaire avec validations métier complètes
- ✅ Gestion d'erreurs robuste
- ✅ Mapping Form → Service testé et validé

---

## 📋 Découpage des tâches

### 4.2.1 – Dé-skipper et stabiliser le test d'intégration

**Objectifs** :
- Retirer `skip: true` du test `sorties_submission_test.dart`
- Vérifier que le test compile et s'exécute
- Corriger les erreurs fonctionnelles (si présentes)
- S'assurer que le test vérifie bien l'appel à `SortieService.createValidated`

**Actions** :
1. Retirer `skip: true` du test
2. Exécuter le test et identifier les erreurs
3. Corriger les problèmes d'interaction UI (finders, widgets, etc.)
4. Vérifier que `spy.lastCall` capture bien tous les paramètres attendus
5. Valider que les assertions du test sont cohérentes avec la logique métier

**Livrables** :
- Test `sorties_submission_test.dart` qui passe (vert)
- Toutes les assertions validées

---

### 4.2.2 – Renforcer les validations du formulaire

**Objectifs** :
- Aligner les validations UI avec la logique métier SQL
- S'assurer que tous les champs obligatoires sont validés
- Ajouter des pré-checks côté UI (volume disponible, citerne active, etc.)

**Champs obligatoires à valider** :

#### Champs toujours obligatoires
- ✅ **Citerne** : doit être sélectionnée et active
- ✅ **Produit** : doit être sélectionné et compatible avec la citerne
- ✅ **Propriétaire** : MONALUXE ou PARTENAIRE (déjà géré par ChoiceChip)
- ✅ **Index avant** : nombre positif
- ✅ **Index après** : nombre positif, > index avant
- ✅ **Température** : nombre valide (généralement entre -50°C et 100°C)
- ✅ **Densité @15°C** : nombre positif (généralement entre 0.7 et 1.0)

#### Champs conditionnels selon propriétaire
- ✅ **Client** : obligatoire si `proprietaireType == 'MONALUXE'`
- ✅ **Partenaire** : obligatoire si `proprietaireType == 'PARTENAIRE'`

#### Champs optionnels
- Chauffeur
- Plaque camion
- Plaque remorque
- Transporteur
- Note
- Date de sortie

**Actions** :
1. Vérifier que `_submitSortie()` valide tous les champs obligatoires
2. Ajouter des messages d'erreur clairs pour chaque validation
3. Implémenter des pré-checks UI (ex: volume disponible, citerne active)
4. S'assurer que le formulaire ne peut pas être soumis si les validations échouent

**Livrables** :
- Formulaire avec toutes les validations métier
- Messages d'erreur clairs et contextuels
- Pré-checks UI fonctionnels

---

### 4.2.3 – Gestion des erreurs du service

**Objectifs** :
- Afficher des messages d'erreur utilisateur-friendly
- Gérer les différents types d'erreurs (validation métier, erreurs réseau, etc.)
- Fournir un feedback visuel clair (snackbar, dialogs, etc.)

**Types d'erreurs à gérer** :

#### Erreurs de validation métier (SortieServiceException)
- Citerne inactive ou introuvable
- Produit incompatible
- Stock insuffisant
- Client/Partenaire manquant
- Autres erreurs du trigger SQL

#### Erreurs réseau/techniques
- Timeout
- Erreur de connexion
- Erreur serveur

**Actions** :
1. Vérifier que `_submitSortie()` catch bien les `SortieServiceException`
2. Mapper les codes d'erreur vers des messages utilisateur lisibles
3. Afficher les erreurs via `ScaffoldMessenger` (snackbar)
4. Gérer les erreurs génériques (réseau, serveur, etc.)

**Livrables** :
- Gestion d'erreurs complète et robuste
- Messages d'erreur utilisateur-friendly
- Feedback visuel approprié

---

### 4.2.4 – Mapping Form → Service

**Objectifs** :
- S'assurer que tous les champs du formulaire sont correctement mappés vers `SortieService.createValidated`
- Vérifier que les calculs (volume, etc.) sont corrects
- Tester le mapping avec différents scénarios

**Points de contrôle** :
- ✅ `proprietaireType` : correctement dérivé de `_owner`
- ✅ `volumeAmbiant` : calculé depuis `indexApres - indexAvant`
- ✅ `volumeCorrige15C` : calculé ou fourni par l'UI
- ✅ `clientId` / `partenaireId` : correctement conditionnés selon `proprietaireType`
- ✅ Tous les champs optionnels : correctement passés (null si vides)

**Actions** :
1. Vérifier le mapping dans `_submitSortie()`
2. Ajouter des logs de debug pour tracer les valeurs passées
3. Tester avec différents scénarios (MONALUXE, PARTENAIRE, avec/sans champs optionnels)
4. Valider que les calculs sont corrects

**Livrables** :
- Mapping Form → Service testé et validé
- Logs de debug pour faciliter le troubleshooting
- Documentation du mapping

---

## 🔍 Analyse du formulaire actuel

### Fichier : `lib/features/sorties/screens/sortie_form_screen.dart`

**Points à vérifier** :
- [ ] Validation de tous les champs obligatoires avant soumission
- [ ] Messages d'erreur clairs pour chaque validation
- [ ] Gestion des erreurs `SortieServiceException`
- [ ] Calcul correct de `volumeAmbiant` et `volumeCorrige15C`
- [ ] Mapping correct de `proprietaireType` depuis `_owner`
- [ ] Conditionnement correct de `clientId` / `partenaireId`

---

## 🧪 Scénarios de test à couvrir

### Scénario 1 : Sortie MONALUXE complète
- Propriétaire : MONALUXE
- Client : sélectionné
- Tous les champs obligatoires remplis
- Champs optionnels remplis
- **Attendu** : Appel à `createValidated` avec tous les paramètres

### Scénario 2 : Sortie PARTENAIRE complète
- Propriétaire : PARTENAIRE
- Partenaire : sélectionné
- Tous les champs obligatoires remplis
- **Attendu** : Appel à `createValidated` avec `partenaireId` et `clientId = null`

### Scénario 3 : Sortie avec champs optionnels vides
- Tous les champs obligatoires remplis
- Champs optionnels laissés vides
- **Attendu** : Appel à `createValidated` avec champs optionnels à `null`

### Scénario 4 : Validation échoue (champ manquant)
- Un champ obligatoire manquant
- **Attendu** : Message d'erreur affiché, pas d'appel au service

### Scénario 5 : Erreur service (stock insuffisant)
- Tous les champs valides
- Service retourne une erreur (ex: stock insuffisant)
- **Attendu** : Message d'erreur utilisateur-friendly affiché

---

## 📝 Checklist de validation

### Test d'intégration
- [ ] Test dé-skippé et fonctionnel
- [ ] Toutes les interactions UI fonctionnent (tap, enterText, etc.)
- [ ] `spy.lastCall` capture tous les paramètres attendus
- [ ] Toutes les assertions passent

### Formulaire
- [ ] Tous les champs obligatoires validés
- [ ] Messages d'erreur clairs pour chaque validation
- [ ] Pré-checks UI fonctionnels (si implémentés)
- [ ] Formulaire ne peut pas être soumis si validations échouent

### Gestion d'erreurs
- [ ] `SortieServiceException` catchées et affichées
- [ ] Messages d'erreur utilisateur-friendly
- [ ] Erreurs réseau/techniques gérées
- [ ] Feedback visuel approprié (snackbar, etc.)

### Mapping Form → Service
- [ ] Tous les champs correctement mappés
- [ ] Calculs corrects (volume, etc.)
- [ ] Conditionnement correct selon `proprietaireType`
- [ ] Logs de debug pour troubleshooting

---

## 🔗 Fichiers concernés

### Fichiers à modifier
- `test/integration/sorties_submission_test.dart` (dé-skipper et corriger)
- `lib/features/sorties/screens/sortie_form_screen.dart` (validations, gestion d'erreurs)

### Fichiers à analyser
- `lib/features/sorties/data/sortie_service.dart` (pour comprendre les erreurs possibles)
- `lib/core/errors/sortie_service_exception.dart` (pour les types d'erreurs)

---

## 📊 Critères de succès

### Phase 4.2.1 (Test)
- ✅ `sorties_submission_test.dart` passe (vert)
- ✅ Toutes les assertions validées
- ✅ Test vérifie bien l'appel au service avec les bons paramètres

### Phase 4.2.2 (Validations)
- ✅ Tous les champs obligatoires validés
- ✅ Messages d'erreur clairs
- ✅ Pré-checks UI fonctionnels (si implémentés)

### Phase 4.2.3 (Gestion d'erreurs)
- ✅ Toutes les erreurs gérées et affichées
- ✅ Messages utilisateur-friendly
- ✅ Feedback visuel approprié

### Phase 4.2.4 (Mapping)
- ✅ Mapping Form → Service testé et validé
- ✅ Calculs corrects
- ✅ Documentation du mapping

---

## 🎯 Résultat attendu

À la fin de la Phase 4.2 :

- ✅ Test d'intégration fonctionnel et utile
- ✅ Formulaire robuste avec validations complètes
- ✅ Gestion d'erreurs professionnelle
- ✅ Mapping Form → Service validé
- ✅ Base solide pour la Phase 4.3 (flux de validation & rôles)

---

## 📚 Références

- **Phase 4.1** : `docs/db/PHASE4_1_SORTIES_SERVICE_STABILISATION.md`
- **Plan global Phase 4** : `docs/db/PHASE4_SORTIES_PRODUIT_PLAN.md`
- **Service** : `lib/features/sorties/data/sortie_service.dart`
- **Formulaire** : `lib/features/sorties/screens/sortie_form_screen.dart`
- **Test** : `test/integration/sorties_submission_test.dart`

