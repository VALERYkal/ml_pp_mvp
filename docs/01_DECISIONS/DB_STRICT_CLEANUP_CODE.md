# Guide Nettoyage Code — DB-STRICT

**Phase** : Phase 2  
**Statut** : ⚪ À faire  
**Objectif** : Empêcher l'app d'appeler des chemins interdits

---

## Vue d'ensemble

Cette phase consiste à **supprimer tout le code legacy** qui permet de créer des brouillons ou de valider différemment.

**Principe** : Une fois le code legacy supprimé, il devient **impossible** pour un développeur d'utiliser le mauvais paradigme.

---

## Fichiers à supprimer

### 1. Services legacy

- [ ] `lib/features/receptions/data/reception_service_v2.dart`
- [ ] `lib/features/receptions/data/reception_service_v3.dart`
- [ ] `lib/features/sorties/data/sortie_draft_service.dart`

**Action** : Supprimer ces fichiers complètement.

---

## Fichiers à modifier

### 2. `lib/features/receptions/data/reception_service.dart`

**Actions** :
- [ ] Supprimer la méthode `createDraft()` (lignes ~244-314)
- [ ] Supprimer la méthode `validate()` (lignes ~316-377)
- [ ] Supprimer la méthode `_validateInput()` (lignes ~379-428)

**Résultat** : Le service ne contient plus que `createValidated()`.

---

### 3. `lib/features/receptions/providers/reception_providers.dart`

**Actions** :
- [ ] Supprimer ou modifier `createReceptionProvider` (lignes 17-21)

**Avant** :
```dart
final createReceptionProvider = Riverpod.FutureProvider.family<String, ReceptionInput>((ref, input) async {
  final service = ref.read(receptionServiceProvider);
  final id = await service.createDraft(input); // ❌ Legacy
  return id;
});
```

**Après** : Supprimer ce provider (ou le migrer vers `createValidated` si nécessaire).

---

### 4. `lib/features/sorties/providers/sortie_providers.dart`

**Actions** :
- [ ] Supprimer `sortieDraftServiceProvider` (lignes 34-36)

**Avant** :
```dart
final sortieDraftServiceProvider = Riverpod.Provider<SortieDraftService>((ref) {
  return SortieDraftService(Supabase.instance.client);
});
```

**Après** : Supprimer complètement.

---

### 5. `lib/features/receptions/screens/reception_screen.dart`

**Options** :

**Option A** : Supprimer complètement si non utilisé
- [ ] Vérifier si cette route est utilisée dans `app_router.dart`
- [ ] Si non utilisée, supprimer le fichier

**Option B** : Migrer vers `createValidated()`
- [ ] Remplacer `_enregistrerBrouillon()` par une méthode utilisant `createValidated()`
- [ ] Supprimer le bouton "Valider (RPC)"
- [ ] Modifier le bouton "Enregistrer (brouillon)" → "Enregistrer"

**Code de migration** :
```dart
// ❌ AVANT
Future<void> _enregistrerBrouillon() async {
  // ...
  final id = await service.createDraft(input); // ❌
  // ...
}

// ✅ APRÈS
Future<void> _enregistrerReception() async {
  setState(() => loading = true);
  try {
    final repo = ref.read(refs.referentielsRepoProvider);
    final service = ReceptionService.withClient(
      Supabase.instance.client,
      refRepo: repo,
    );

    // Résoudre produitId depuis produitCode
    final produits = await repo.loadProduits();
    final produit = produits.firstWhere(
      (p) => p.code == produitCode,
      orElse: () => throw ArgumentError('Produit introuvable: $produitCode'),
    );

    final id = await service.createValidated(
      coursDeRouteId: (proprietaireType == 'MONALUXE') ? coursDeRouteId : null,
      citerneId: citerneId!,
      produitId: produit.id,
      indexAvant: _num(ctrlAvant.text) ?? 0,
      indexApres: _num(ctrlApres.text) ?? 0,
      temperatureCAmb: _num(ctrlTemp.text),
      densiteA15: _num(ctrlDens.text),
      proprietaireType: proprietaireType,
      partenaireId: (proprietaireType == 'PARTENAIRE') ? partenaireId : null,
      dateReception: dateReception ?? DateTime.now(),
      note: ctrlNote.text.isEmpty ? null : ctrlNote.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réception enregistrée (#$id)')),
      );
      context.go('/receptions');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  } finally {
    if (mounted) setState(() => loading = false);
  }
}
```

---

### 6. `lib/shared/db/db_port.dart`

**Actions** :
- [ ] Supprimer `rpcValidateReception()` de l'interface `DbPort`
- [ ] Supprimer l'implémentation dans `SupabaseDbPort`

**Avant** :
```dart
abstract class DbPort {
  Future<void> rpcValidateReception(String receptionId); // ❌
}

class SupabaseDbPort implements DbPort {
  @override
  Future<void> rpcValidateReception(String receptionId) async {
    await client.rpc('validate_reception', params: {'p_reception_id': receptionId});
  } // ❌
}
```

**Après** : Supprimer complètement.

---

### 7. `test/fixtures/fake_db_port.dart`

**Actions** :
- [ ] Supprimer `rpcValidateReception()` (lignes ~74-122)
- [ ] Ou marquer comme `@Deprecated` si utilisé par des tests legacy (à migrer ensuite)

---

## Recherche globale

### Commandes de vérification

```bash
# 1. Rechercher toutes les références legacy
grep -r "createDraft\|validateReception\|validateSortie\|SortieDraftService" lib/ test/

# 2. Vérifier les imports
grep -r "reception_service_v2\|reception_service_v3\|sortie_draft_service" lib/ test/

# 3. Vérifier les statuts brouillon
grep -r "statut.*brouillon\|brouillon.*statut" lib/ test/

# 4. Lister les fichiers à modifier
find lib/ test/ -name "*.dart" -exec grep -l "createDraft\|validateReception" {} \;
```

---

## Checklist de validation

- [ ] Aucune occurrence de `createDraft` dans le code
- [ ] Aucune occurrence de `validateReception` dans le code
- [ ] Aucune occurrence de `validateSortie` dans le code
- [ ] Aucune occurrence de `SortieDraftService` dans le code
- [ ] Aucune occurrence de `reception_service_v2` ou `reception_service_v3` dans le code
- [ ] Aucune occurrence de `brouillon` dans le code (sauf documentation)
- [ ] Fichiers legacy supprimés
- [ ] Providers legacy supprimés
- [ ] Écrans legacy migrés ou supprimés
- [ ] Tests compilent sans erreur
- [ ] Application démarre sans erreur

---

## Tests après nettoyage

### Test 1 : Compilation

```bash
flutter analyze
flutter test --no-pub
```

### Test 2 : Vérification runtime

- [ ] L'application démarre correctement
- [ ] L'écran de création de réception fonctionne
- [ ] L'écran de création de sortie fonctionne
- [ ] Aucune référence à "brouillon" dans l'UI

---

## Notes importantes

- **Ordre** : Faire ce nettoyage **après** la Phase 1 (migration SQL) pour éviter de casser l'app avant que la DB soit prête.
- **Tests** : S'assurer que tous les tests passent après le nettoyage.
- **Documentation** : Mettre à jour la documentation si nécessaire.

---

**Dernière mise à jour** : 2025-12-21

