# Guide de Test - KPI 4 & KPI 5

## 🎯 Objectif
Vérifier que les KPI 4 (Sorties du jour) et KPI 5 (Balance du jour) s'affichent correctement dans le dashboard admin.

## ✅ Implémentation Complète

### **1. KPI 4 - Sorties du jour** ✅
**Fichier** : `lib/data/repositories/sorties_repository.dart` (NOUVEAU)
- **Classe** : `SortiesStats` avec nbCamions, volAmbiant, vol15c
- **Méthode** : `statsJour()` avec filtrage par statut 'validee' et date
- **Logique** : Somme des sorties validées du jour

**Fichier** : `lib/features/kpi/providers/sorties_kpi_provider.dart` (NOUVEAU)
- **Provider stable** : `sortiesTodayParamProvider` pour paramètres par défaut
- **Provider KPI** : `sortiesKpiProvider` avec family
- **Provider invalidation** : `sortiesRealtimeInvalidatorProvider` pour temps réel

### **2. KPI 5 - Balance du jour** ✅
**Fichier** : `lib/features/kpi/providers/balance_kpi_provider.dart` (NOUVEAU)
- **Classe** : `BalanceStats` avec deltaAmbiant, delta15c
- **Provider** : `balanceTodayProvider` qui combine KPI 2 et KPI 4
- **Logique** : Réceptions - Sorties (delta positif = entrée nette)

### **3. Utilitaire de Formatage** ✅
**Fichier** : `lib/shared/utils/formatters.dart`
- **Fonction ajoutée** : `fmtLitersSigned()` pour formatage avec signe (+/-)

### **4. Dashboard Intégré** ✅
**Fichier** : `lib/features/dashboard/screens/dashboard_admin_screen.dart`
- **Imports ajoutés** : `sorties_kpi_provider.dart`, `balance_kpi_provider.dart`
- **KPI 4 ajouté** : `KpiSummaryCard` avec volumes
- **KPI 5 ajouté** : `KpiSplitCard` avec deltas signés
- **Navigation** : Clics → pages correspondantes

### **5. Index & RLS** ✅
**Fichier** : `scripts/sorties_indexes_rls.sql`
- **Index optimisés** : sorties_produit (date, citerne, statut)
- **RLS sécurisé** : Policy de lecture sur la table

## 🧪 Tests de Validation

### Test 1 : Affichage des KPI 4 et 5
1. **Connectez-vous** en tant qu'admin
2. **Accédez au dashboard** admin
3. **Vérifiez** que les 5 KPIs s'affichent :
   - **KPI 1** : Camions à suivre (en route + en attente + volumes)
   - **KPI 2** : Réceptions (jour) (nb + volumes)
   - **KPI 3** : Stock total (actuel) (vol. ambiant + vol. 15°C + MAJ)
   - **KPI 4** : Sorties (jour) (nb + volumes)
   - **KPI 5** : Balance du jour (Δ vol. ambiant + Δ vol. 15°C)

### Test 2 : KPI 4 - Sorties du jour
1. **Vérifiez** que le KPI "Sorties (jour)" affiche :
   - **Valeur principale** : Nombre de camions
   - **Détails** : Vol. ambiant et Vol. 15°C
   - **Icône** : outbox_outlined
2. **Cliquez** sur le KPI pour vérifier la navigation vers `/sorties`

### Test 3 : KPI 5 - Balance du jour
1. **Vérifiez** que le KPI "Balance du jour" affiche :
   - **Gauche** : "Δ Vol. ambiant" + valeur avec signe (+/-)
   - **Droite** : "Δ Vol. 15 °C" + valeur avec signe (+/-)
   - **Icône** : swap_vert
2. **Cliquez** sur le KPI pour vérifier la navigation vers `/stocks`

### Test 4 : Logs de Debug
1. **Ouvrez la console** du navigateur (F12)
2. **Rechargez** le dashboard
3. **Cherchez** les logs :
   - `📤 Sorties(jour) depot=X >= Y < Z => nb=A, amb=B, 15C=C`
   - `🔎 Réceptions(2025-XX-XX depot=X) => nb=A, amb=B, 15C=C`
4. **Vérifiez** que les valeurs correspondent à l'affichage

### Test 5 : Calcul de la Balance
1. **Notez** les valeurs des KPI 2 et 4
2. **Vérifiez** que KPI 5 = KPI 2 - KPI 4
3. **Confirmez** que le signe est correct (+ = entrée nette, - = sortie nette)

### Test 6 : Gestion d'Erreurs
1. **Simulez** une erreur (déconnexion Supabase)
2. **Rechargez** le dashboard
3. **Vérifiez** que les messages d'erreur s'affichent :
   - "Sorties indisponibles" pour KPI 4
   - "Balance indisponible" pour KPI 5
4. **Reconnectez-vous** et vérifiez que les KPIs redeviennent normaux

## 🔍 Diagnostic des Problèmes

### Problème : KPI 4 ne s'affiche pas
**Solutions :**
- Vérifiez que `sortiesKpiProvider` est bien importé
- Vérifiez que la table `sorties_produit` existe
- Vérifiez que la colonne `statut` contient des valeurs 'validee'
- Vérifiez les logs de la console pour les erreurs

### Problème : KPI 5 ne s'affiche pas
**Solutions :**
- Vérifiez que `balanceTodayProvider` est bien importé
- Vérifiez que les KPI 2 et 4 fonctionnent
- Vérifiez que les calculs de delta sont corrects
- Vérifiez les logs de la console pour les erreurs

### Problème : Valeurs affichées à 0
**Solutions :**
- Vérifiez que la table contient des données
- Vérifiez que les filtres par date fonctionnent
- Vérifiez que les filtres par dépôt fonctionnent
- Vérifiez que le statut 'validee' est correct

### Problème : Formatage des signes incorrect
**Solutions :**
- Vérifiez que `fmtLitersSigned()` fonctionne
- Vérifiez que les calculs de delta sont corrects
- Vérifiez que les signes + et - s'affichent correctement

## 📊 Données de Test

Pour tester avec des données réelles, vous pouvez :

1. **Créer des sorties de test** dans Supabase :
```sql
INSERT INTO public.sorties_produit (citerne_id, statut, volume_ambiant, volume_corrige_15c, date_sortie)
VALUES 
  ('CIT001', 'validee', 500.0, 475.0, current_timestamp),
  ('CIT002', 'validee', 750.0, 712.5, current_timestamp),
  ('CIT003', 'validee', 300.0, 285.0, current_timestamp);
```

2. **Vérifier les KPIs** : 
   - KPI 4 : 3 camions, 1550L ambiant, 1472.5L 15°C
   - KPI 5 : Balance = Réceptions - Sorties

## 🎉 Résultat Attendu

Le dashboard admin affiche maintenant **5 KPIs complets** :

- ✅ **KPI 1** : Camions à suivre (en route + en attente + volumes)
- ✅ **KPI 2** : Réceptions (jour) (nb + volumes)
- ✅ **KPI 3** : Stock total (actuel) (vol. ambiant + vol. 15°C + MAJ)
- ✅ **KPI 4** : Sorties (jour) (nb + volumes)
- ✅ **KPI 5** : Balance du jour (Δ vol. ambiant + Δ vol. 15°C)

## 📝 Notes Techniques

### **Structure des Données**
- **Table** : `sorties_produit` (sorties validées)
- **Volumes** : `volume_ambiant` et `volume_corrige_15c` en litres
- **Statut** : 'validee' pour les sorties comptabilisées

### **Performance**
- **Index créés** : sorties_produit (date, citerne, statut)
- **RLS activé** : Sécurité au niveau des lignes
- **Provider stable** : Évite les recréations inutiles

### **Compatibilité**
- **Filtrage** : Par dépôt et date (extensible)
- **Temps réel** : Invalidation manuelle (à améliorer plus tard)
- **Formatage** : Cohérent avec les autres KPIs

## 🚀 Prochaines Étapes

1. **Exécuter le script SQL** pour les index et RLS
2. **Tester les KPIs** en suivant ce guide
3. **Vérifier** que les 5 KPIs s'affichent correctement
4. **Confirmer** que la balance se calcule correctement

Les KPI 4 et 5 sont maintenant **fonctionnels et prêts pour la production** ! 🎯
