# BUG-YYYY-MM — <Titre court>

## Métadonnées

- **Date** : YYYY-MM-DD
- **Module** : <ex: Stocks / Dashboard / Réceptions>
- **Impact** : <UI incorrecte / données erronées / blocage fonctionnel>
- **Sévérité** : <Low / Medium / High / Critical>
- **Statut** : ✅ Résolu / 🟡 Mitigé / 🔴 Ouvert
- **Tags** :
  - `<TAG-1>`
  - `<TAG-2>`

---

## Contexte

Décrire le contexte métier + écran concerné (1–3 phrases).

---

## Symptômes observés

- Ce que l'utilisateur voit (UI)
- Ce que la DB contient (réalité)
- Ex: "Stock total = 0.0 L alors que la vue SQL retourne > 0"

---

## Reproduction minimale

1. …
2. …
3. …

> Objectif : permettre de reproduire en < 2 minutes.

---

## Observations DB (preuves)

### Requête de vérification

```sql
-- Colle ici la requête exacte utilisée
SELECT ...
FROM ...
WHERE ...;
```

### Résultat attendu

```
...
```

### Résultat observé

```
...
```

---

## Chaîne technique (de bout en bout)

```
UI → Providers → Service → Repository → SQL
```

| Couche | Fichier | Classe/Fonction |
|--------|---------|-----------------|
| **UI** | `lib/features/.../screens/xxx.dart` | Widget concerné |
| **Provider(s)** | `lib/features/.../providers/xxx.dart` | `xxxProvider` |
| **Service** | `lib/features/.../data/xxx_service.dart` | `XxxService.method()` |
| **Repository** | `lib/data/repositories/xxx_repository.dart` | `XxxRepository.method()` |
| **Source SQL** | Vue/Table/Fonction | `v_xxx` ou `table_xxx` |

---

## Cause racine

Décrire précisément **pourquoi** ça se produit :

- [ ] Non déterminisme (ex: pas d'ORDER BY)
- [ ] Filtre trop strict (ex: `eq(date_jour)` au lieu de `<=`)
- [ ] Date instable (`DateTime.now` avec ms)
- [ ] autoDispose loop / rebuild infini
- [ ] Mapping incorrect (type mismatch)
- [ ] RLS / permission manquante
- [ ] Autre : ...

**Explication détaillée** :

> ...

---

## Correctif appliqué

### Patch conceptuel

**Avant** :
```dart
// Code problématique
```

**Après** :
```dart
// Code corrigé
```

### Détails techniques

- **Fichier** : `lib/.../xxx.dart`
- **Fonction** : `methodName()`
- **Points clés** :
  - ...
  - ...

---

## Validation

### Tests automatisés

```bash
flutter test test/features/xxx/
```

**Résultat** : ✅ X/X tests passent

### Validation manuelle

- [ ] Scénario 1 : ...
- [ ] Scénario 2 : ...

### Non-régression

- [ ] Module A : fonctionne toujours
- [ ] Module B : fonctionne toujours
- [ ] Aucune erreur console

---

## Prévention / Règles à appliquer

### Règle 1 : <Nom de la règle>

**Contexte** : ...

**Règle** :
- ✅ Faire : ...
- ❌ Ne pas faire : ...

### Règle 2 : <Nom de la règle>

**Contexte** : ...

**Règle** :
- ✅ Faire : ...
- ❌ Ne pas faire : ...

---

## Notes / Suivi

- **PR/Commit** : <lien si disponible>
- **Issue liée** : <lien si disponible>
- **TODO** : <action de suivi si nécessaire>

---

## Checklist incident

- [ ] Repro 100% confirmée
- [ ] Requête SQL de preuve archivée
- [ ] Root cause écrite sans hypothèse
- [ ] Fix décrit + fichier et fonction
- [ ] Tests verts
- [ ] Entrée CHANGELOG ajoutée

---

**Date de résolution** : YYYY-MM-DD  
**Auteur du correctif** : ...  
**Validé par** : ...
