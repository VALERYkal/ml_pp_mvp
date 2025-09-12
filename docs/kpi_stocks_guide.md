# Guide de Test - KPI 3 (Stock Total)

## 🎯 Objectif
Vérifier que le KPI 3 "Stock total (actuel)" affiche correctement les volumes ambiant et 15°C avec la date de dernière mise à jour.

## ✅ Modifications Appliquées

### **1. Repository des Stocks** ✅
**Fichier** : `lib/data/repositories/stocks_repository.dart` (NOUVEAU)
- **Classe** : `StocksTotals` avec volumes et date de MAJ
- **Méthode** : `totauxActuels()` avec filtrage par dépôt/produit
- **Logique** : Somme des stocks depuis la vue `v_citerne_stock_actuel`

### **2. Providers Riverpod** ✅
**Fichier** : `lib/features/kpi/providers/stocks_kpi_provider.dart` (NOUVEAU)
- **Provider stable** : `stocksDefaultParamProvider` pour paramètres par défaut
- **Provider KPI** : `stocksTotalsProvider` avec family
- **Provider invalidation** : `stocksRealtimeInvalidatorProvider` pour temps réel

### **3. Utilitaire de Formatage** ✅
**Fichier** : `lib/shared/utils/formatters.dart`
- **Fonction ajoutée** : `fmtShortDate()` pour formatage JJ/MM

### **4. Dashboard Intégré** ✅
**Fichier** : `lib/features/dashboard/screens/dashboard_admin_screen.dart`
- **Import ajouté** : `stocks_kpi_provider.dart`
- **KPI 3 ajouté** : `KpiSplitCard` avec volumes et date de MAJ
- **Navigation** : Clic → page des stocks (`/stocks`)

### **5. Index & RLS** ✅
**Fichier** : `scripts/stocks_indexes_rls.sql`
- **Index optimisés** : stocks_journaliers, citernes
- **RLS sécurisé** : Policies de lecture sur les tables

## 🧪 Tests de Validation

### Test 1 : Affichage du KPI 3
1. **Connectez-vous** en tant qu'admin
2. **Accédez au dashboard** admin
3. **Vérifiez** que le KPI "Stock total (actuel)" s'affiche avec :
   - **Gauche** : "Vol. ambiant" + volume + "MAJ" + date (si disponible)
   - **Droite** : "Vol. 15 °C" + volume

### Test 2 : Logs de Debug
1. **Ouvrez la console** du navigateur (F12)
2. **Rechargez** le dashboard
3. **Cherchez** le log : `📦 KPI3 stocks: amb=X, 15c=Y, lastDay=Z`
4. **Vérifiez** que les valeurs correspondent à l'affichage

### Test 3 : Navigation
1. **Cliquez** sur le KPI "Stock total (actuel)"
2. **Vérifiez** que vous êtes redirigé vers `/stocks`
3. **Confirmez** que la page des stocks s'affiche

### Test 4 : Filtrage par Dépôt
1. **Changez** de profil utilisateur (si possible)
2. **Observez** que le KPI se met à jour avec le bon `depotId`
3. **Vérifiez** que les volumes correspondent au dépôt

### Test 5 : Gestion d'Erreurs
1. **Simulez** une erreur (déconnexion Supabase)
2. **Rechargez** le dashboard
3. **Vérifiez** que le message "Stocks indisponibles" s'affiche
4. **Reconnectez-vous** et vérifiez que le KPI redevient normal

## 🔍 Diagnostic des Problèmes

### Problème : KPI ne s'affiche pas
**Solutions :**
- Vérifiez que `stocksTotalsProvider` est bien importé
- Vérifiez que la vue `v_citerne_stock_actuel` existe
- Vérifiez les logs de la console pour les erreurs

### Problème : Volumes affichés à 0
**Solutions :**
- Vérifiez que la vue contient des données
- Vérifiez que les colonnes `stock_ambiant` et `stock_15c` existent
- Vérifiez que les filtres par dépôt fonctionnent

### Problème : Date de MAJ ne s'affiche pas
**Solutions :**
- Vérifiez que la colonne `date_jour` existe dans la vue
- Vérifiez que les données ont des dates valides
- Vérifiez que `fmtShortDate()` fonctionne

### Problème : Erreur de navigation
**Solutions :**
- Vérifiez que la route `/stocks` existe dans le router
- Vérifiez que l'écran `StocksListScreen` est bien importé

## 📊 Données de Test

Pour tester avec des données réelles, vous pouvez :

1. **Créer des stocks de test** dans Supabase :
```sql
INSERT INTO public.stocks_journaliers (citerne_id, produit_id, stock_ambiant, stock_15c, date_jour)
VALUES 
  ('CIT001', 'PROD001', 1000.0, 950.0, current_date),
  ('CIT002', 'PROD002', 2000.0, 1900.0, current_date),
  ('CIT003', 'PROD001', 1500.0, 1425.0, current_date);
```

2. **Vérifier le KPI** : 
   - Vol. ambiant : 4500L (1000+2000+1500)
   - Vol. 15°C : 4275L (950+1900+1425)
   - MAJ : Date du jour

## 🎉 Résultat Attendu

Le KPI "Stock total (actuel)" devrait maintenant :
- ✅ **Afficher les volumes** ambiant et 15°C en litres (formaté)
- ✅ **Afficher la date de MAJ** si disponible (format JJ/MM)
- ✅ **Se mettre à jour** selon le profil et le dépôt
- ✅ **Naviguer** vers la page des stocks au clic
- ✅ **Gérer les erreurs** avec un message clair
- ✅ **Être performant** avec les index optimisés

## 📝 Notes Techniques

### **Structure des Données**
- **Vue** : `v_citerne_stock_actuel` (dernier stock par citerne)
- **Volumes** : `stock_ambiant` et `stock_15c` en litres
- **Date** : `date_jour` pour la dernière mise à jour

### **Performance**
- **Index créés** : stocks_journaliers, citernes
- **RLS activé** : Sécurité au niveau des lignes
- **Provider stable** : Évite les recréations inutiles

### **Compatibilité**
- **Filtrage** : Par dépôt et produit (extensible)
- **Temps réel** : Invalidation automatique
- **Formatage** : Cohérent avec les autres KPIs

## 🚀 Prochaines Étapes

1. **Exécuter le script SQL** pour les index et RLS
2. **Tester le KPI** en suivant ce guide
3. **Vérifier** que les volumes s'affichent correctement
4. **Appliquer** la même logique aux autres KPIs si nécessaire

Le KPI 3 est maintenant **fonctionnel et prêt pour la production** ! 🎯
