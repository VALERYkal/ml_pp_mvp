# Guide de Test - KPI Réceptions du Jour

## 🎯 Objectif
Vérifier que le KPI "Réceptions du jour" fonctionne correctement avec les nouvelles améliorations.

## ✅ Améliorations Appliquées

### 1. Repository (`lib/data/repositories/receptions_repository.dart`)
- ✅ **Filtre par `date_reception`** : Utilise la colonne DATE au lieu de `created_at`
- ✅ **Statut validé** : Ne compte que les réceptions avec `statut = 'validee'`
- ✅ **Logs détaillés** : Affiche le jour, le dépôt (si applicable) et les totaux
- ✅ **Gestion d'erreurs** : PostgrestException avec diagnostic RLS

### 2. Dashboard Admin (`lib/features/dashboard/screens/dashboard_admin_screen.dart`)
- ✅ **Navigation fonctionnelle** : `onTap: () => context.go('/receptions')`
- ✅ **Message d'erreur clair** : "Réceptions indisponibles" au lieu de l'erreur technique
- ✅ **Style cohérent** : Texte rouge pour les erreurs

### 3. RLS Policies (`scripts/fix_receptions_rls_policies.sql`)
- ✅ **Policies sécurisées** : Lecture autorisée sur `receptions` et `citernes`
- ✅ **Vérification** : Script de test pour valider les policies
- ✅ **Requête de test** : Commentée pour vérifier le KPI manuellement

## 🧪 Tests à Effectuer

### Test 1 : Affichage Normal
1. **Connectez-vous** en tant qu'admin
2. **Accédez au dashboard** admin
3. **Vérifiez** que le KPI "Réceptions (jour)" s'affiche
4. **Observez** les valeurs :
   - Nombre de camions
   - Volume ambiant
   - Volume 15°C

### Test 2 : Logs de Debug
1. **Ouvrez la console** du navigateur (F12)
2. **Rechargez** le dashboard
3. **Cherchez** le log : `🔎 Réceptions(YYYY-MM-DD) => nb=X, amb=Y, 15C=Z`
4. **Vérifiez** que les valeurs correspondent à l'affichage

### Test 3 : Navigation
1. **Cliquez** sur le KPI "Réceptions (jour)"
2. **Vérifiez** que vous êtes redirigé vers `/receptions`
3. **Confirmez** que la page des réceptions s'affiche

### Test 4 : Gestion d'Erreurs
1. **Déconnectez-vous** de Supabase (simulation d'erreur)
2. **Rechargez** le dashboard
3. **Vérifiez** que le message "Réceptions indisponibles" s'affiche
4. **Reconnectez-vous** et vérifiez que le KPI redevient normal

### Test 5 : RLS Policies (si erreur "permission denied")
1. **Exécutez** le script `scripts/fix_receptions_rls_policies.sql` dans Supabase
2. **Vérifiez** que les policies sont créées
3. **Testez** le KPI à nouveau

## 🔍 Diagnostic des Problèmes

### Problème : KPI ne s'affiche pas
**Solutions :**
- Vérifiez les logs de la console pour les erreurs
- Exécutez le script RLS si nécessaire
- Vérifiez que la table `receptions` contient des données

### Problème : Valeurs incorrectes
**Solutions :**
- Vérifiez que les colonnes `volume_ambiant` et `volume_corrige_15c` existent
- Vérifiez que le statut des réceptions est bien `'validee'`
- Vérifiez que `date_reception` est bien une colonne DATE

### Problème : Erreur de navigation
**Solutions :**
- Vérifiez que la route `/receptions` existe dans le router
- Vérifiez que l'écran `ReceptionListScreen` est bien importé

## 📊 Données de Test

Pour tester avec des données réelles, vous pouvez :

1. **Créer des réceptions de test** dans Supabase :
```sql
INSERT INTO public.receptions (statut, date_reception, volume_ambiant, volume_corrige_15c, citerne_id)
VALUES 
  ('validee', current_date, 1000.0, 950.0, 'citerne-1'),
  ('validee', current_date, 2000.0, 1900.0, 'citerne-2'),
  ('en_attente', current_date, 500.0, 475.0, 'citerne-3');
```

2. **Vérifier le KPI** : Il devrait afficher 2 camions (seules les réceptions validées)

## 🎉 Résultat Attendu

Le KPI "Réceptions (jour)" devrait maintenant :
- ✅ **S'afficher correctement** avec les bonnes valeurs
- ✅ **Se mettre à jour** automatiquement selon la date
- ✅ **Naviguer** vers la page des réceptions au clic
- ✅ **Gérer les erreurs** avec un message clair
- ✅ **Afficher des logs** utiles pour le debug

## 📝 Notes

- Les logs de debug peuvent être supprimés en production
- Le script RLS n'a besoin d'être exécuté qu'une seule fois
- Le KPI se base sur la date UTC du jour courant
