# Checklist de Test - Fix Login Redirect Android

## 📱 Tests Android Requis

### Test 1: Login Réussi - Opérateur
- [ ] Ouvrir l'app sur Android
- [ ] Entrer credentials d'un compte opérateur
- [ ] Cliquer "Se connecter"
- [ ] **Vérifier:** Toast "Connexion réussie" apparaît
- [ ] **Vérifier:** Redirection immédiate vers `/dashboard/operateur`
- [ ] **Vérifier logs:** 
  ```
  ✅ Login OK, session=...
  🔄 Triggering navigation fallback to / ...
  🔁 RouterRedirect: loc=/, isAuth=true, role=UserRole.operateur
     ➜ Authenticated + role ready -> redirecting to /dashboard/operateur
  ```

### Test 2: Login Réussi - Admin
- [ ] Se déconnecter
- [ ] Entrer credentials d'un compte admin
- [ ] Cliquer "Se connecter"
- [ ] **Vérifier:** Redirection vers `/dashboard/admin`

### Test 3: Login Réussi - Gérant
- [ ] Se déconnecter
- [ ] Entrer credentials d'un compte gérant
- [ ] Cliquer "Se connecter"
- [ ] **Vérifier:** Redirection vers `/dashboard/gerant`

### Test 4: Login Réussi - Directeur
- [ ] Se déconnecter
- [ ] Entrer credentials d'un compte directeur
- [ ] Cliquer "Se connecter"
- [ ] **Vérifier:** Redirection vers `/dashboard/directeur`

### Test 5: Login Réussi - Rôle Lecture
- [ ] Se déconnecter
- [ ] Entrer credentials d'un compte lecture
- [ ] Cliquer "Se connecter"
- [ ] **Vérifier:** Redirection vers `/dashboard/lecture`

### Test 6: Profil Pas Encore Prêt
- [ ] Avec un nouveau compte sans profil
- [ ] Se connecter
- [ ] **Vérifier:** Redirection temporaire vers `/splash`
- [ ] **Vérifier:** Puis redirection vers dashboard une fois profil chargé
- [ ] **Vérifier logs:**
  ```
  🔁 RouterRedirect: loc=/, isAuth=true, role=null
     ➜ Authenticated but role not ready -> redirecting to /splash
  ```

### Test 7: Login Échoué
- [ ] Entrer credentials invalides
- [ ] Cliquer "Se connecter"
- [ ] **Vérifier:** Toast d'erreur apparaît
- [ ] **Vérifier:** Reste sur l'écran login (pas de navigation)

### Test 8: Problème Réseau
- [ ] Désactiver le réseau/données
- [ ] Essayer de se connecter
- [ ] **Vérifier:** Message d'erreur approprié
- [ ] **Vérifier:** Reste sur l'écran login

## 🖥️ Tests Autres Plateformes (Non-régression)

### Test 9: Web
- [ ] Login réussi sur web
- [ ] **Vérifier:** Redirection fonctionne toujours

### Test 10: iOS
- [ ] Login réussi sur iOS
- [ ] **Vérifier:** Redirection fonctionne toujours

### Test 11: macOS
- [ ] Login réussi sur macOS
- [ ] **Vérifier:** Redirection fonctionne toujours

## 🔍 Vérifications de Logs

Sur **tous les tests réussis**, vérifier dans les logs la présence de:

1. **Log de succès login:**
   ```
   ✅ Login OK, session={user_id}
   ```

2. **Log de fallback navigation:**
   ```
   🔄 Triggering navigation fallback to / ...
   ```

3. **Log de redirect router:**
   ```
   🔁 RouterRedirect: loc=/, isAuth=true, role=UserRole.xxx, from=...
      ➜ Authenticated + role ready -> redirecting to /dashboard/xxx
   ```

4. **Log du refresh composite (peut apparaître):**
   ```
   🔄 GoRouterCompositeRefresh: auth event received -> notifyListeners()
   🔄 GoRouterCompositeRefresh: role changed null -> UserRole.xxx -> notifyListeners()
   ```

## 📊 Critères de Succès

### ✅ Success si:
- Sur Android: Redirection immédiate après login (< 1 seconde)
- Toast de succès visible avant la redirection
- Aucune erreur dans les logs
- Dashboard correct selon le rôle
- Pas de régression sur autres plateformes

### ❌ Échec si:
- Reste bloqué sur l'écran login après succès
- Délai > 2 secondes avant redirection
- Erreur dans les logs
- Redirection vers mauvais dashboard
- Régression sur web/iOS/macOS

## 🧹 Nettoyage Post-Test

Une fois tous les tests passés avec succès:

- [ ] Retirer les `debugPrint` temporaires de `login_screen.dart` (lignes 144, 154)
- [ ] Retirer les logs détaillés de `app_router.dart` ou les simplifier
- [ ] Garder uniquement un log de redirect de base si nécessaire
- [ ] Mettre à jour cette documentation avec les résultats

## 📝 Notes de Test

Ajouter ici les observations durant les tests:

```
Date: _________
Testeur: _________
Appareil: _________
Version Android: _________

Résultats:
- Test 1: [ ] Pass [ ] Fail - Notes: _______________
- Test 2: [ ] Pass [ ] Fail - Notes: _______________
...

Observations générales:
_____________________________________________
_____________________________________________
```
