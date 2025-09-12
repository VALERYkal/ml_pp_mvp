# Guide de Test - KPI 1 Enrichi (Camions + Volumes)

## 🎯 Objectif
Vérifier que le KPI "Camions à suivre" affiche maintenant le nombre de camions ET les volumes prévus (L) sans rien casser.

## ✅ Améliorations Appliquées

### **1. Repository Enrichi** ✅
**Fichier** : `lib/data/repositories/cours_de_route_repository.dart`
- **Nouvelle classe** : `CoursCounts` avec volumes en litres
- **Nouvelle méthode** : `countsEnRouteEtAttente()` avec volumes
- **Compatibilité** : Ancienne méthode `countsCamionsASuivre()` préservée
- **Logs détaillés** : Affiche nb camions + volumes + filtres

### **2. Provider Stable** ✅
**Fichier** : `lib/features/kpi/providers/cours_kpi_provider.dart`
- **Provider stable** : `coursDefaultParamProvider` pour paramètres par défaut
- **Provider KPI** : `coursKpiProvider` avec record value-type
- **Provider invalidation** : `coursRealtimeInvalidatorProvider` pour temps réel

### **3. Widget Enrichi** ✅
**Fichier** : `lib/features/kpi/widgets/kpi_split_card.dart`
- **Nouveau widget** : `KpiSplitCard` avec sous-lignes optionnelles
- **Affichage** : Nombre de camions + volume prévu (L)
- **Design** : Card avec métriques gauche/droite + sous-métriques

### **4. Dashboard Intégré** ✅
**Fichier** : `lib/features/dashboard/screens/dashboard_admin_screen.dart`
- **Remplacement** : Ancien KPI → nouveau KPI enrichi
- **Navigation** : Clic → page des cours de route
- **Formatage** : Volumes avec `fmtCompact()` (K/M/B)

### **5. Index & RLS** ✅
**Fichier** : `scripts/cours_de_route_indexes_rls.sql`
- **Index optimisés** : statut, dépôt, produit, composite
- **RLS sécurisé** : Policy de lecture sur `cours_de_route`
- **Tests** : Requêtes de validation

## 🧪 Tests de Validation

### Test 1 : Affichage du KPI Enrichi
1. **Connectez-vous** en tant qu'admin
2. **Accédez au dashboard** admin
3. **Vérifiez** que le KPI "Camions à suivre" s'affiche avec :
   - **Gauche** : "En route" + nombre + "Volume prévu" + litres
   - **Droite** : "En attente de déchargement" + nombre + "Volume prévu" + litres

### Test 2 : Logs de Debug
1. **Ouvrez la console** du navigateur (F12)
2. **Rechargez** le dashboard
3. **Cherchez** le log : `🚚 KPI1: enRoute=X (YL), attente=Z (WL)`
4. **Vérifiez** que les valeurs correspondent à l'affichage

### Test 3 : Navigation
1. **Cliquez** sur le KPI "Camions à suivre"
2. **Vérifiez** que vous êtes redirigé vers `/cours`
3. **Confirmez** que la page des cours de route s'affiche

### Test 4 : Filtrage par Dépôt
1. **Changez** de profil utilisateur (si possible)
2. **Observez** que le KPI se met à jour avec le bon `depotId`
3. **Vérifiez** que les volumes correspondent au dépôt

### Test 5 : Gestion d'Erreurs
1. **Simulez** une erreur (déconnexion Supabase)
2. **Rechargez** le dashboard
3. **Vérifiez** que le message "KPI Cours indisponible" s'affiche
4. **Reconnectez-vous** et vérifiez que le KPI redevient normal

## 🔍 Diagnostic des Problèmes

### Problème : KPI ne s'affiche pas
**Solutions :**
- Vérifiez que `coursKpiProvider` est bien importé
- Vérifiez que la table `cours_de_route` contient des données
- Vérifiez les logs de la console pour les erreurs

### Problème : Volumes affichés à 0
**Solutions :**
- Vérifiez que la colonne `volume` existe dans `cours_de_route`
- Vérifiez que les volumes sont bien en litres
- Vérifiez que les statuts correspondent ('CHARGEMENT','TRANSIT','FRONTIERE','ARRIVE')

### Problème : KPI s'affiche mais avec des valeurs incorrectes
**Solutions :**
- Vérifiez que les index sont créés (script SQL)
- Vérifiez que les filtres par dépôt fonctionnent
- Vérifiez que les statuts sont bien en majuscules

### Problème : Erreur de navigation
**Solutions :**
- Vérifiez que la route `/cours` existe dans le router
- Vérifiez que l'écran `CoursRouteListScreen` est bien importé

## 📊 Données de Test

Pour tester avec des données réelles, vous pouvez :

1. **Créer des cours de test** dans Supabase :
```sql
INSERT INTO public.cours_de_route (statut, volume, depot_destination_id, produit_id)
VALUES 
  ('CHARGEMENT', 1000.0, 'DEP001', 'PROD001'),
  ('TRANSIT', 2000.0, 'DEP001', 'PROD002'),
  ('FRONTIERE', 1500.0, 'DEP002', 'PROD001'),
  ('ARRIVE', 800.0, 'DEP001', 'PROD003');
```

2. **Vérifier le KPI** : 
   - En route : 3 camions (1000+2000+1500 = 4500L)
   - En attente de déchargement : 1 camion (800L)

## 🎉 Résultat Attendu

Le KPI "Camions à suivre" devrait maintenant :
- ✅ **Afficher le nombre** de camions en route et en attente
- ✅ **Afficher les volumes** prévus en litres (formaté K/M/B)
- ✅ **Se mettre à jour** selon le profil et le dépôt
- ✅ **Naviguer** vers la page des cours au clic
- ✅ **Gérer les erreurs** avec un message clair
- ✅ **Être performant** avec les index optimisés

## 📝 Notes Techniques

### **Structure des Données**
- **En route** : statuts 'CHARGEMENT', 'TRANSIT', 'FRONTIERE'
- **En attente de déchargement** : statut 'ARRIVE'
- **Volume** : supposé en litres (à convertir si nécessaire)

### **Performance**
- **Index créés** : statut, dépôt, produit, composite
- **RLS activé** : Sécurité au niveau des lignes
- **Provider stable** : Évite les recréations inutiles

### **Compatibilité**
- **Ancien provider** : `camionsASuivreProvider` toujours fonctionnel
- **Nouveau provider** : `coursKpiProvider` avec volumes enrichis
- **Migration douce** : Pas de breaking changes

## 🚀 Prochaines Étapes

1. **Exécuter le script SQL** pour les index et RLS
2. **Tester le KPI** en suivant ce guide
3. **Vérifier** que les volumes s'affichent correctement
4. **Appliquer** la même logique aux autres KPIs si nécessaire
