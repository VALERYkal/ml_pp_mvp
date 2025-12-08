# 🧪 Tests d'Intégration Auth

**Statut :** ✅ Phase 4 Complétée (2025-12-08)  
**Couverture :** 14 tests passent, 3 skippés

## 📋 Vue d'ensemble

Ce dossier contient les tests d'intégration pour le module d'authentification, validant :
- ✅ Redirection par rôle (6 rôles)
- ✅ Conformité des menus selon les rôles (4 tests)
- ✅ Flux d'authentification (login, logout)
- ✅ Guards de navigation (accès aux routes protégées)

## 🚀 Exécution

```bash
# Tous les tests Auth
flutter test test/integration/auth/auth_integration_test.dart

# Avec output détaillé
flutter test test/integration/auth/auth_integration_test.dart -r expanded

# Un test spécifique
flutter test test/integration/auth/auth_integration_test.dart --plain-name "should redirect admin to admin dashboard"
```

## 📚 Documentation Complète

Pour une documentation détaillée sur :
- Architecture des tests
- Patterns à suivre
- Résolution de problèmes
- Bonnes pratiques

👉 Voir [`docs/testing/auth_integration_tests.md`](../../../docs/testing/auth_integration_tests.md)

## 🔑 Points Clés

### Helpers Principaux

- **`createTestApp({required Profil? profil})`** : Helper pour créer l'app de test avec tous les providers mockés
- **`_FakeSession`** : Simule une session Supabase authentifiée
- **`_FakeCurrentProfilNotifier`** : Contrôle l'état du profil dans les tests
- **`_routerLocation(tester)`** : Helper pour obtenir la location actuelle du router

### Patterns de Test

1. **Test simple de redirection** : Utiliser `createTestApp()` avec un profil
2. **Test avec transitions d'état** : Utiliser des overrides locaux avec `StreamController`
3. **Assertions défensives** : Toujours vérifier l'existence d'un widget avant d'interagir

## ⚠️ Problèmes Courants

### "You must initialize the supabase instance"
✅ **Solution** : `isAuthenticatedProvider` est override dans `createTestApp()` pour éviter l'accès à `Supabase.instance`

### Redirection vers `/login` au lieu du dashboard
✅ **Solution** : Vérifier que `createTestApp()` crée une session fake quand un profil est fourni

### "Bad state: No element"
✅ **Solution** : Utiliser des assertions défensives : `expect(finder, findsOneWidget)` avant d'accéder à un élément

## 📊 Résultats

```
✅ 14 tests passent
⏭️ 3 tests skippés (comme prévu)
❌ 0 test en échec
```

---

**Dernière mise à jour :** 2025-12-08

