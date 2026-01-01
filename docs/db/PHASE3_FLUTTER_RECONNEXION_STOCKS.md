# Phase 3 - Reconnexion de l'app Flutter aux nouveaux stocks & KPI

**Projet** : ML_PP MVP — Module Stock / Sorties / Réceptions  
**Date** : 06/12/2025  
**Mise à jour** : 01/01/2026 - Migration complète vers `v_stock_actuel` terminée ✅  
**Prérequis** : Phase 1 complétée ✅, Phase 2 (SQL) complétée ✅

---

## ✅ **MIGRATION COMPLÈTE TERMINÉE** (01/01/2026)

**Tous les modules utilisent désormais `v_stock_actuel` comme source de vérité unique** (conformément au contrat AXE A).

- ✅ Dashboard : Agrégation depuis `v_stock_actuel` via `fetchStockActuelRows()  
- ✅ Citernes : Agrégation depuis `v_stock_actuel` par `citerne_id`  
- ✅ Module Stock : Agrégation depuis `v_stock_actuel` pour les totaux  
- ✅ Ajustements : Visibles immédiatement dans tous les modules  

Voir `docs/db/CONTRAT_STOCK_ACTUEL.md` pour le contrat officiel.

---

---

## 🎯 Objectif global Phase 3

**Maintenir la cohérence des stocks en temps réel lors de chaque nouvelle réception ou sortie, tout en garantissant que toute l'app Flutter lit les stocks depuis une seule vérité unique :**

```
stocks_journaliers → v_stocks_citerne_global (+ vues propriétaires) → StockService (Dart) → Providers Riverpod → UI / KPI
```

**En pratique, la Phase 3 se décompose en 2 gros blocs :**

1. **Stock Engine côté SQL (v2/v3)** – Verrouiller proprement les triggers pour maintenir la cohérence en temps réel
2. **Unification Flutter sur la vérité unique stock** – Créer le service + providers + refacto des écrans et KPI

**Supprimer toute logique de calcul de stock côté Flutter.**

**Ajouter des tests minimaux pour sécuriser la régression.**

---

## 🧱 Bloc A – Stock Engine SQL (v2/v3)

### Contexte

Tu as déjà :
- `stock_upsert_journalier()` avec `proprietaire_type`, `depot_id`, `source` + contrainte UNIQUE `(citerne_id, produit_id, date_jour, proprietaire_type)`
- Trigger unifié réceptions `receptions_apply_effects()` qui crédite les stocks via `stock_upsert_journalier()`
- Trigger unifié sorties `fn_sorties_after_insert()` qui débite les stocks, vérifie le stock disponible, etc.

**Donc, côté engine, tu es quasi en Phase "v2/v3".** La Phase 3 va surtout :
- Verrouiller que toutes les sorties et réceptions passent par ces triggers
- Supprimer les vieux triggers / fonctions redondantes pour éviter tout double comptage
- S'aligner avec les nouvelles vues (`v_mouvements_stock`, `v_stocks_citerne_global`, `v_kpi_stock_global`, `v_kpi_stock_owner`, `v_stocks_citerne_owner`)

---

### A.1 – Audit et nettoyage des triggers

#### But

Lister tous les triggers actifs et conserver uniquement ceux qui passent par `stock_upsert_journalier()`.

#### Actions

1. **Lister tous les triggers actifs sur** :
   - `receptions`
   - `sorties_produit`
   - `stocks_journaliers`

2. **Conserver uniquement** :
   - `trg_receptions_apply_effects` (+ log)
   - `trg_sorties_after_insert`
   - `trg_sorties_check_produit_citerne`
   - `trg_sortie_before_upd_trg`

3. **Dropper tout trigger / fonction obsolète qui ferait** :
   - un autre calcul de stock
   - un autre chemin de validation métier "parallèle"

#### Livrables

- [ ] Liste complète des triggers actifs documentée
- [ ] Triggers obsolètes identifiés et supprimés
- [ ] Un seul chemin pour impacter `stocks_journaliers` : `stock_upsert_journalier()` appelé depuis les triggers unifiés

#### Fichiers à créer/modifier

- `docs/db/PHASE3_AUDIT_TRIGGERS.md` (nouveau - liste des triggers)
- `supabase/migrations/2025-12-XX_cleanup_old_triggers.sql` (nouveau - suppression des triggers obsolètes)

---

### A.2 – Sceller `stock_upsert_journalier()` comme "truth engine"

#### But

Vérifier et documenter que `stock_upsert_journalier()` est la seule fonction qui modifie `stocks_journaliers`.

#### Actions

1. **Vérifier que la signature est bien celle décrite dans la doc** :
   ```sql
   stock_upsert_journalier(
     citerne_id, 
     produit_id, 
     date_jour, 
     delta_ambiant, 
     delta_15c, 
     p_proprietaire_type, 
     p_depot_id, 
     p_source
   )
   ```

2. **Confirmer** :
   - Normalisation de `proprietaire_type` en UPPERCASE / trim
   - `ON CONFLICT (...) DO UPDATE` pour cumuler les deltas
   - Préservation des ajustements manuels (`source <> 'SYSTEM'`) – déjà posée dans le rebuild

#### Livrables

- [ ] Signature de `stock_upsert_journalier()` documentée
- [ ] Comportement validé (normalisation, cumul, préservation)
- [ ] Aucune autre fonction ne modifie directement `stocks_journaliers`

#### Fichiers à créer/modifier

- `docs/db/PHASE3_STOCK_ENGINE_SPEC.md` (nouveau - spécification de `stock_upsert_journalier()`)

---

### A.3 – Re-validation par script

#### But

Utiliser `scripts/validate_stocks.sql` comme garde-fou après chaque modif de trigger / fonction.

#### Actions

1. **Exécuter quelques réceptions / sorties de test**
2. **Lancer `scripts/validate_stocks.sql`**
3. **Vérifier les métriques clés** :
   - Stock global
   - Stock par citerne
   - Stock par propriétaire (Monaluxe / Partenaire)

#### Livrables

- [ ] Script de validation exécuté après chaque modification
- [ ] Métriques validées (stock global, par citerne, par propriétaire)
- [ ] Aucune régression détectée

#### Fichiers à utiliser

- `scripts/validate_stocks.sql` (existant)

---

## 🧭 Bloc B – Unification Flutter sur la vérité unique stock

C'est le gros morceau "visible" pour toi et pour les users. Il est déjà planifié dans le CHANGELOG comme Phase 2 Flutter, mais on considère que dans notre conversation, tout ça = Phase 3.

---

## 🧩 Étape 3.1 – Cartographie & gel de l'existant

### But

Savoir exactement qui consomme quoi aujourd'hui.

### Actions

1. **Lister les fichiers Flutter qui** :
   - lisent `stocks_journaliers` directement,
   - recalculent du stock à partir de `receptions` / `sorties_produit`,
   - calculent des KPI de type : stock total, stock par citerne, stock par propriétaire.

2. **Typiquement** :
   - `dashboard_admin_screen.dart` ou équivalent
   - `stocks_screen.dart`
   - `citernes_screen.dart`
   - éventuels providers : `stockKpiProvider`, `tankStockProvider`, etc.

3. **Noter pour chacun** :
   - quelle table il interroge,
   - quels champs il utilise,
   - comment il les agrège.

### Livrable

Une mini-table récap (document ou commentaire) qu'on utilisera pour cocher au fur et à mesure.

**Fichier** : `docs/db/PHASE3_CARTOGRAPHIE_EXISTANT.md` (à créer)

---

## 🧱 Étape 3.2 – Modèles Dart pour les nouvelles vues

### But

Créer des model classes pour mapper les résultats SQL.

### Modèles à créer

#### 1. `KpiStockGlobal`

```dart
class KpiStockGlobal {
  final double stockAmbiantTotal;
  final double stock15cTotal;
  final int nbCiternes;
  final int nbDepots;
  final DateTime? dateDernierMouvement;
  
  KpiStockGlobal({
    required this.stockAmbiantTotal,
    required this.stock15cTotal,
    required this.nbCiternes,
    required this.nbDepots,
    this.dateDernierMouvement,
  });
  
  factory KpiStockGlobal.fromJson(Map<String, dynamic> json) {
    // Mapping depuis v_kpi_stock_global
  }
}
```

#### 2. `KpiStockDepot`

```dart
class KpiStockDepot {
  final String depotId;
  final String depotNom;
  final String? produitId;
  final String? produitNom;
  final double stockAmbiantTotal;
  final double stock15cTotal;
  final int nbCiternes;
  final DateTime? dateDernierMouvement;
  
  KpiStockDepot({
    required this.depotId,
    required this.depotNom,
    this.produitId,
    this.produitNom,
    required this.stockAmbiantTotal,
    required this.stock15cTotal,
    required this.nbCiternes,
    this.dateDernierMouvement,
  });
  
  factory KpiStockDepot.fromJson(Map<String, dynamic> json) {
    // Mapping depuis v_kpi_stock_depot
  }
}
```

#### 3. `KpiStockOwner`

```dart
class KpiStockOwner {
  final String? depotId;
  final String? depotNom;
  final String proprietaireType; // 'MONALUXE' ou 'PARTENAIRE'
  final double stockAmbiantTotal;
  final double stock15cTotal;
  final int nbCiternes;
  final DateTime? dateDernierMouvement;
  
  KpiStockOwner({
    this.depotId,
    this.depotNom,
    required this.proprietaireType,
    required this.stockAmbiantTotal,
    required this.stock15cTotal,
    required this.nbCiternes,
    this.dateDernierMouvement,
  });
  
  factory KpiStockOwner.fromJson(Map<String, dynamic> json) {
    // Mapping depuis v_kpi_stock_owner
  }
}
```

#### 4. `CiterneStockSnapshot`

```dart
class CiterneStockSnapshot {
  final String citerneId;
  final String citerneNom;
  final String produitId;
  final String produitNom;
  final String produitCode;
  final double stockAmbiantTotal;
  final double stock15cTotal;
  final double stockAmbiantMonaluxe;
  final double stock15cMonaluxe;
  final double stockAmbiantPartenaire;
  final double stock15cPartenaire;
  final double capaciteTotale;
  final double capaciteSecurite;
  final double ratioUtilisation;
  final String? depotId;
  final String? depotNom;
  final DateTime? dateDernierMouvement;
  
  CiterneStockSnapshot({
    required this.citerneId,
    required this.citerneNom,
    required this.produitId,
    required this.produitNom,
    required this.produitCode,
    required this.stockAmbiantTotal,
    required this.stock15cTotal,
    required this.stockAmbiantMonaluxe,
    required this.stock15cMonaluxe,
    required this.stockAmbiantPartenaire,
    required this.stock15cPartenaire,
    required this.capaciteTotale,
    required this.capaciteSecurite,
    required this.ratioUtilisation,
    this.depotId,
    this.depotNom,
    this.dateDernierMouvement,
  });
  
  factory CiterneStockSnapshot.fromJson(Map<String, dynamic> json) {
    // Mapping depuis v_stocks_citerne_global
  }
}
```

#### 5. `CiterneStockOwnerSnapshot`

```dart
class CiterneStockOwnerSnapshot {
  final String citerneId;
  final String citerneNom;
  final String produitId;
  final String produitNom;
  final String proprietaireType; // 'MONALUXE' ou 'PARTENAIRE'
  final double stockAmbiant;
  final double stock15c;
  final DateTime? dateJour;
  final String? depotId;
  final String? depotNom;
  
  CiterneStockOwnerSnapshot({
    required this.citerneId,
    required this.citerneNom,
    required this.produitId,
    required this.produitNom,
    required this.proprietaireType,
    required this.stockAmbiant,
    required this.stock15c,
    this.dateJour,
    this.depotId,
    this.depotNom,
  });
  
  factory CiterneStockOwnerSnapshot.fromJson(Map<String, dynamic> json) {
    // Mapping depuis v_stocks_citerne_owner
  }
}
```

### Dossier

```
lib/features/stocks/models/
├── kpi_stock_global.dart
├── kpi_stock_depot.dart
├── kpi_stock_owner.dart
├── citerne_stock_snapshot.dart
└── citerne_stock_owner_snapshot.dart
```

### Livrables

- [ ] Tous les modèles créés avec `fromJson`
- [ ] Tests unitaires pour le mapping JSON → modèles

---

## 🛰️ Étape 3.3 (B.1) – Service Flutter unique de lecture du stock ✅ COMPLÉTÉE

### But

Introduire une couche `StocksKpiService` dédiée aux vues KPI de stock, afin d'orchestrer les appels au `StocksKpiRepository` et d'offrir un point d'entrée unique pour le Dashboard.

### Fichier créé

**`lib/features/stocks/data/stocks_kpi_service.dart`**

### Résultat

**Classe `StocksDashboardKpis`** :
- Agrégat complet de tous les KPIs nécessaires au Dashboard
- Contient : `globalByDepotProduct`, `byOwner`, `citerneByOwner`, `citerneGlobal`

**Classe `StocksKpiService`** :
- Encapsule `StocksKpiRepository`
- Méthode principale : `loadDashboardKpis({depotId?, produitId?})`
- Méthode utilitaire : `loadDashboardKpisForDepot(String depotId)`

**Providers ajoutés** (dans `stocks_kpi_providers.dart`) :
- ✅ `stocksKpiServiceProvider` - Injection du service
- ✅ `stocksDashboardKpisProvider` - Provider family pour charger l'agrégat complet

### Caractéristiques

- ✅ **Aucune régression** : Tous les providers Phase 3.2 restent compatibles et inchangés
- ✅ **Point d'entrée unique** : Le Dashboard peut consommer un seul provider agrégé
- ✅ **Testabilité** : Service facilement overridable via Riverpod
- ✅ **Pas de logique métier** : Tout est en lecture seule, orchestration uniquement

### Service à créer

```dart
// lib/features/stocks/data/stock_service.dart
class StockService {
  final SupabaseClient client;
  
  StockService(this.client);
  
  /// Récupère les stocks par dépôt depuis v_stocks_citerne_global
  Future<List<StockCiterneGlobalRow>> getStocksByDepot(String depotId) async {
    final res = await client
        .from('v_stocks_citerne_global')
        .select('*')
        .eq('depot_id', depotId);
    
    return (res as List)
        .map((e) => StockCiterneGlobalRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  
  /// Récupère les stocks par citerne et propriétaire depuis v_stocks_citerne_owner
  Future<List<StockCiterneOwnerRow>> getStocksByCiterneOwner({
    String? depotId,
    String? citerneId,
    String? proprietaireType,
  }) async {
    var query = client.from('v_stocks_citerne_owner').select('*');
    
    if (depotId != null) {
      query = query.eq('depot_id', depotId);
    }
    if (citerneId != null) {
      query = query.eq('citerne_id', citerneId);
    }
    if (proprietaireType != null) {
      query = query.eq('proprietaire_type', proprietaireType);
    }
    
    final res = await query;
    return (res as List)
        .map((e) => StockCiterneOwnerRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  
  /// Récupère le KPI stock global depuis v_kpi_stock_global
  Future<KpiStockGlobalRow> getKpiStockGlobal(String? depotId) async {
    var query = client.from('v_kpi_stock_global').select('*');
    
    if (depotId != null) {
      query = query.eq('depot_id', depotId);
    }
    
    final res = await query.maybeSingle();
    
    if (res == null) {
      throw Exception('Aucun KPI stock global trouvé');
    }
    
    return KpiStockGlobalRow.fromJson(res as Map<String, dynamic>);
  }
  
  /// Récupère les KPIs stock par propriétaire depuis v_kpi_stock_owner
  Future<List<KpiStockOwnerRow>> getKpiStockOwner(String? depotId) async {
    var query = client.from('v_kpi_stock_owner').select('*');
    
    if (depotId != null) {
      query = query.eq('depot_id', depotId);
    }
    
    final res = await query;
    return (res as List)
        .map((e) => KpiStockOwnerRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

### Points importants

- ✅ SELECT direct sur les vues SQL, pas sur les tables
- ✅ Filtrage par `depot_id` si nécessaire (selon profil utilisateur)
- ✅ Mapping robuste (gestion des nulls)

### Dossier

```
lib/features/stocks/data/
└── stock_service.dart
```

### Livrables

- [ ] `StockService` créé avec toutes les méthodes
- [ ] Tests unitaires avec Supabase mocké
- [ ] Mapping JSON → modèles Dart validé

---

## 🌱 Étape 3.4 (B.2) – Providers Riverpod stock ✅ COMPLÉTÉE

### But

Créer les providers qui exposent `StocksKpiRepository` aux écrans.

### Résultat

**Fichier créé** : `lib/features/stocks/data/stocks_kpi_providers.dart`

**6 providers créés** :
- ✅ `stocksKpiRepositoryProvider` - Injection du repository
- ✅ `kpiGlobalStockProvider` - KPI global par dépôt/produit
- ✅ `kpiStockByOwnerProvider` - KPI par propriétaire (MONALUXE/PARTENAIRE)
- ✅ `kpiStocksByCiterneOwnerProvider` - Snapshots par citerne et propriétaire
- ✅ `kpiStocksByCiterneGlobalProvider` - Snapshots globaux par citerne
- ✅ `kpiGlobalStockByDepotProvider` - Filtrage par dépôt (family)
- ✅ `kpiCiterneOwnerByDepotProvider` - Filtrage par dépôt côté SQL (family)

**Voir** : `docs/rapports/PHASE3_2_EXPOSITION_KPI_RIVERPOD_2025-12-06.md` pour le rapport complet.

### Résultat ✅ COMPLÉTÉE

**Fichier créé** : `lib/features/stocks/data/stocks_kpi_providers.dart`

**Providers créés** :
- ✅ `stocksKpiRepositoryProvider` - Injection du repository
- ✅ `kpiGlobalStockProvider` - KPI global par dépôt/produit
- ✅ `kpiStockByOwnerProvider` - KPI par propriétaire (MONALUXE/PARTENAIRE)
- ✅ `kpiStocksByCiterneOwnerProvider` - Snapshots par citerne et propriétaire
- ✅ `kpiStocksByCiterneGlobalProvider` - Snapshots globaux par citerne
- ✅ `kpiGlobalStockByDepotProvider` - Filtrage par dépôt (family)
- ✅ `kpiCiterneOwnerByDepotProvider` - Filtrage par dépôt côté SQL (family)

**Voir** : `docs/rapports/PHASE3_2_EXPOSITION_KPI_RIVERPOD_2025-12-06.md` pour le rapport complet.

### Caractéristiques

- ✅ Utilisation de l'alias `riverpod` pour éviter le conflit avec `Provider` de Supabase
- ✅ Tous les providers utilisent `StocksKpiRepository` (pas de dépendance directe à Supabase)
- ✅ Prévoir un mock facile pour tests plus tard (via injection du repository)

### Livrables

- [x] Tous les providers créés
- [x] Analyse Flutter : aucune erreur
- [ ] Tests avec providers mockés (à faire en Phase 3.8)

---

## 📊 Étape 3.5 (B.5) – Recâbler les KPI Dashboard

### Objectif

Tu as déjà toute l'architecture KPI réceptions / sorties :
- Fonctions pures `computeKpiReceptions()` / `computeKpiSorties()`
- Providers bruts + providers KPI

Pour les stocks, le plan prévoit de créer `lib/features/kpi/stock_kpi_provider.dart`.

Le Dashboard lit 100 % de ses infos à partir des nouveaux providers.

### Actions

1. **Carte Stock total** → `globalStockKpiProvider`
2. **Carte Tendance / Graph éventuelle** → à partir des snapshots, plus tard
3. **Si le Dashboard affiche déjà** :
   - Stock 15°C
   - Stock ambiant
   - Utilisation %
   
   alors il doit désormais consommer `v_kpi_stock_depot` + `v_stocks_citerne_global` (selon design).

### ⚠️ Important

On garde la partie "Cours de route / Réceptions du jour / Sorties du jour" telle quelle pour l'instant : on touche seulement au bloc "Stock".

### Travail

1. **Créer un modèle `KpiStocks`** (si pas déjà fait) avec :
   - `totalAmbient`, `total15c`
   - `totalMonaluxe`, `totalPartenaire`
   - éventuellement % utilisation global

2. **Créer une fonction pure** :
   ```dart
   KpiStocks computeKpiStocks(KpiStockGlobalRow, List<KpiStockOwnerRow>)
   ```

3. **Provider brut** :
   ```dart
   stocksKpiRawProvider(depotId) → lit les deux vues via StockService
   ```

4. **Provider KPI** :
   ```dart
   stocksKpiProvider(depotId) → appelle computeKpiStocks(...)
   ```

5. **Intégration dans `kpiProviderProvider`** pour que le dashboard récupère `KpiSnapshot.stocks`

### Fichiers à créer/modifier

- `lib/features/kpi/stock_kpi_provider.dart` (nouveau)
- `lib/features/kpi/models/kpi_stocks.dart` (nouveau)
- `lib/features/dashboard/screens/dashboard_admin_screen.dart`
- `lib/features/dashboard/providers/admin_kpi_provider.dart`
- `lib/features/dashboard/widgets/kpi_card.dart`

### Exemple de refactoring

**AVANT** :
```dart
// Calcul manuel du stock
final receptions = await getReceptions();
final sorties = await getSorties();
final stock = receptions.sum - sorties.sum;
```

**APRÈS** :
```dart
// Lecture depuis la vue SQL
final kpi = await ref.watch(globalStockKpiProvider.future);
final stock = kpi.stock15cTotal;
```

### Livrables

- [ ] Modèle `KpiStocks` créé
- [ ] Fonction pure `computeKpiStocks()` créée
- [ ] Providers `stocksKpiRawProvider` et `stocksKpiProvider` créés
- [ ] Intégration dans `kpiProviderProvider` effectuée
- [ ] Dashboard Admin utilise `stocksKpiProvider`
- [ ] Suppression de toute logique de calcul manuel
- [ ] Vérification manuelle : valeurs affichées = valeurs SQL

---

## 🛢️ Étape 3.6 (B.4) – Recâbler l'écran Stocks Journaliers

### Objectif

L'écran "Stocks" s'aligne entièrement sur :
- `v_stocks_citerne_global` (vue par citerne),
- éventuellement `v_stocks_citerne_owner` dans une vue détaillée.

### Actions

1. **Le tableau principal lit** :
   - `citerne_nom`,
   - `produit_nom`,
   - `stock_ambiant_total`,
   - `stock_15c_total`.

2. **On supprime** :
   - tout calcul `SUM(receptions) - SUM(sorties)` côté Dart,
   - toute logique qui passe par `stocks_journaliers` brut.

3. **On veille à** :
   - bien gérer les valeurs négatives,
   - afficher un TOTAL cohérent (= somme des lignes).

### Fichiers ciblés

- `lib/features/stocks_journaliers/`
- `lib/features/stocks/screens/...` (liste + détail)

### Travail

1. **Lecture principale** :
   - Snapshot global d'un jour → `v_stocks_citerne_global`
   - Vue par propriétaire → `v_stocks_citerne_owner`

2. **Permettre les filtres** :
   - date/dépôt/produit/propriétaire en jouant sur les paramètres des providers

### Exemple de refactoring

**AVANT** :
```dart
// Lecture directe depuis stocks_journaliers avec calculs
final stocks = await client
    .from('stocks_journaliers')
    .select('*')
    .eq('date_jour', dateStr);
// Puis calculs manuels...
```

**APRÈS** :
```dart
// Lecture depuis la vue SQL
final profil = await ref.watch(profilProvider.future);
final stocks = await ref.watch(stocksByDepotProvider(profil!.depotId).future);
// Affichage direct, pas de calcul
```

### Livrables

- [ ] `StocksListScreen` utilise `citerneStockProvider`
- [ ] Suppression de toute logique de calcul côté Dart
- [ ] Filtres (dépôt, produit, propriétaire) fonctionnent
- [ ] Vérification manuelle : valeurs affichées = valeurs SQL

---

## 🧱 Étape 3.7 (B.3) – Recâbler l'écran Citernes

### Objectif

D'après le plan & CHANGELOG : module citernes doit être rebranché sur `v_stocks_citerne_global`.

Chaque carte citerne reflète exactement le snapshot actuel.

### Actions

1. **Pour chaque citerne** :
   - récupérer son `CiterneStockSnapshot` (total),
   - éventuellement ses lignes `CiterneStockOwnerSnapshot` pour décomposer Monaluxe / Partenaire.

2. **Mettre à jour les champs** :
   - "15°C : … L",
   - "Amb : … L",
   - ratio % (stock / capacité).

### Fichiers concernés

- `lib/features/citernes/screens/citerne_list_screen.dart`
- `lib/features/citernes/providers/citerne_providers.dart`
- éventuellement `TankCard` dans `lib/shared/ui` (déjà améliorée pour afficher les stocks)

### Travail

1. **Remplacer toute logique qui lit directement `stocks_journaliers` ou fait des calculs Dart par** :
   ```dart
   ref.watch(stocksByDepotProvider(depotId))
   ```

2. **Utiliser les champs** :
   - `stock_ambiant_total`
   - `stock_15c_total`
   - `capacity` pour alimenter les cartes

### Exemple de refactoring

**AVANT** :
```dart
// Lecture depuis stock_actuel avec calculs
final stock = await getStockActuel(citerneId, produitId);
final total = stock['ambiant'] + stock['15c']; // Calcul manuel
```

**APRÈS** :
```dart
// Lecture depuis la vue SQL
final profil = await ref.watch(profilProvider.future);
final stocks = await ref.watch(stocksByDepotProvider(profil!.depotId).future);
final citerne = stocks.firstWhere((s) => s.citerneId == citerneId);
final total = citerne.stockAmbiantTotal; // Déjà calculé
```

### Livrables

- [ ] `CiterneListScreen` utilise `citerneStockProvider`
- [ ] Affichage des valeurs totales et par propriétaire
- [ ] Suppression de toute logique de calcul côté Dart
- [ ] Vérification manuelle : valeurs affichées = valeurs SQL

---

## 🧪 Étape 3.8 (B.7) – Tests & garde-fous

### But

Sécuriser les futures évolutions sans partir sur une grosse usine à gaz.

Comme prévu dans le CHANGELOG :
- `test/features/stocks/data/stock_service_test.dart`
- `test/features/dashboard/widgets/dashboard_stocks_test.dart`

### Tests à créer

#### 1. Tests unitaires simples

**StockService** :
- Mappe correctement les colonnes SQL → modèles Dart
- Gère les null / listes vides

**Mapping JSON → modèles** (`fromMap`)
- **`StockService` avec Supabase mocké** (ou JSON statique)

```dart
// test/features/stocks/models/kpi_stock_global_test.dart
test('KpiStockGlobal.fromJson mappe correctement', () {
  final json = {
    'stock_ambiant_total': 189850.0,
    'stock_15c_total': 189181.925,
    'nb_citernes': 2,
    'nb_depots': 1,
  };
  
  final kpi = KpiStockGlobal.fromJson(json);
  
  expect(kpi.stockAmbiantTotal, 189850.0);
  expect(kpi.stock15cTotal, 189181.925);
});
```

#### 2. Tests d'intégration

**Providers** :
- `stocksByDepotProvider` retourne les bons résultats sur données mockées
- `stocksKpiProvider` calcule bien totaux & répartition

**Widgets** :
- Dashboard affiche les bons volumes
- Cartes de citernes montrent les mêmes chiffres que les vues SQL

```dart
// test/features/dashboard/widgets/dashboard_stocks_test.dart
testWidgets('Dashboard affiche les KPIs stock correctement', (tester) async {
  // Mock globalStockKpiProvider
  // Vérifier l'affichage
});
```

### Livrables

- [ ] Tests unitaires pour tous les modèles
- [ ] Tests unitaires pour `StockService` (mapping, gestion null)
- [ ] Tests unitaires pour les providers (résultats mockés)
- [ ] 1-2 tests d'intégration widget (Dashboard, Citernes)

---

## 🧹 Étape 3.9 (B.6) – Harmonisation Réceptions / Sorties

### Objectif

Ici le but est surtout d'affichage cohérent.

### Actions

1. **Utiliser les mêmes formatters** (`fmtL`, etc.) pour les volumes

2. **Ajouter éventuellement dans les écrans Réceptions / Sorties un encart stock** basé sur `stockService`, pour montrer :
   - Stock avant mouvement
   - Stock après mouvement (ou delta)

### Fichiers à modifier

- `lib/features/receptions/screens/reception_screen.dart` (si affiche stock)
- `lib/features/sorties/screens/sortie_detail_screen.dart` (si affiche stock)

### Livrables

- [ ] Formatters unifiés pour les volumes
- [ ] Encarts stock cohérents dans Réceptions/Sorties (optionnel)

---

## 🧹 Étape 3.10 – Nettoyage & documentation

### Actions

1. **Supprimer** :
   - anciens services qui calculent le stock "à la main",
   - anciens providers obsolètes.

2. **Ajouter dans docs/** :
   - un court fichier expliquant la nouvelle architecture stock côté app :
     - "Les écrans lisent uniquement les vues SQL x, y, z."

3. **Mettre à jour le CHANGELOG.md**

### Fichiers à créer/modifier

- `docs/db/PHASE3_ARCHITECTURE_FLUTTER_STOCKS.md` (nouveau)
- `CHANGELOG.md` (mise à jour)

### Livrables

- [ ] Anciens services/providers supprimés
- [ ] Documentation architecture créée
- [ ] CHANGELOG mis à jour

---

## 🔚 Synthèse Phase 3

En résumé, Phase 3 c'est :

1. ✅ Déclarer des modèles Dart propres pour les vues SQL
2. ✅ Encapsuler Supabase dans un service unique de stock/KPI
3. ✅ Exposer via Riverpod
4. ✅ Brancher Dashboard, Stocks, Citernes sur ces providers
5. ✅ Supprimer l'ancienne logique calculée côté app

---

## 📋 Checklist Phase 3

### Bloc A - Stock Engine SQL (v2/v3)

#### A.1 - Audit et nettoyage des triggers
- [ ] Liste complète des triggers actifs documentée
- [ ] Triggers obsolètes identifiés et supprimés
- [ ] Un seul chemin pour impacter `stocks_journaliers`

#### A.2 - Sceller stock_upsert_journalier()
- [ ] Signature de `stock_upsert_journalier()` documentée
- [ ] Comportement validé (normalisation, cumul, préservation)
- [ ] Aucune autre fonction ne modifie directement `stocks_journaliers`

#### A.3 - Re-validation par script
- [ ] Script de validation exécuté après chaque modification
- [ ] Métriques validées (stock global, par citerne, par propriétaire)
- [ ] Aucune régression détectée

### Bloc B - Unification Flutter

#### Étape 3.1 - Cartographie
- [ ] Liste des fichiers Flutter qui consomment des stocks créée
- [ ] Table récap créée (`docs/db/PHASE3_CARTOGRAPHIE_EXISTANT.md`)

### Étape 3.2 - Modèles Dart
- [ ] `KpiStockGlobal` créé
- [ ] `KpiStockDepot` créé
- [ ] `KpiStockOwner` créé
- [ ] `CiterneStockSnapshot` créé
- [ ] `CiterneStockOwnerSnapshot` créé
- [ ] Tests unitaires pour le mapping JSON → modèles

### Étape 3.3 (B.1) - Service Flutter unique ✅ COMPLÉTÉE
- [x] `StocksKpiService` créé avec méthode `loadDashboardKpis()`
- [x] `StocksDashboardKpis` agrégat créé
- [x] Provider `stocksKpiServiceProvider` créé
- [x] Provider `stocksDashboardKpisProvider` créé (family)
- [x] Aucune régression : tous les providers Phase 3.2 restent compatibles
- [ ] Tests unitaires avec Supabase mocké (à faire en Phase 3.8)

### Étape 3.4 (B.2) - Providers Riverpod ✅ COMPLÉTÉE
- [x] `stocksKpiRepositoryProvider` créé
- [x] `kpiGlobalStockProvider` créé
- [x] `kpiStockByOwnerProvider` créé
- [x] `kpiStocksByCiterneOwnerProvider` créé
- [x] `kpiStocksByCiterneGlobalProvider` créé
- [x] `kpiGlobalStockByDepotProvider` créé (family)
- [x] `kpiCiterneOwnerByDepotProvider` créé (family)

### Étape 3.5 (B.5) - KPI Dashboard
- [ ] Modèle `KpiStocks` créé
- [ ] Fonction pure `computeKpiStocks()` créée
- [ ] Providers `stocksKpiRawProvider` et `stocksKpiProvider` créés
- [ ] Intégration dans `kpiProviderProvider` effectuée
- [ ] Dashboard Admin utilise `stocksKpiProvider`
- [ ] Suppression de toute logique de calcul manuel
- [ ] Vérification manuelle : valeurs affichées = valeurs SQL

### Étape 3.6 (B.4) - Écran Stocks Journaliers
- [ ] `StocksListScreen` utilise `stocksByDepotProvider`
- [ ] Lecture depuis `v_stocks_citerne_global` et `v_stocks_citerne_owner`
- [ ] Suppression de toute logique de calcul côté Dart
- [ ] Filtres (date/dépôt/produit/propriétaire) fonctionnent
- [ ] Vérification manuelle : valeurs affichées = valeurs SQL

### Étape 3.7 (B.3) - Écran Citernes
- [ ] `CiterneListScreen` utilise `stocksByDepotProvider`
- [ ] Utilisation des champs `stock_ambiant_total`, `stock_15c_total`, `capacity`
- [ ] Affichage des valeurs totales et par propriétaire
- [ ] Suppression de toute logique de calcul côté Dart
- [ ] Vérification manuelle : valeurs affichées = valeurs SQL

### Étape 3.8 (B.7) - Tests
- [ ] Tests unitaires pour tous les modèles
- [ ] Tests unitaires pour `StockService` (mapping, gestion null)
- [ ] Tests unitaires pour les providers (résultats mockés)
- [ ] 1-2 tests d'intégration widget (Dashboard, Citernes)

### Étape 3.9 (B.6) - Harmonisation Réceptions/Sorties
- [ ] Formatters unifiés pour les volumes
- [ ] Encarts stock cohérents dans Réceptions/Sorties (optionnel)

### Étape 3.10 - Nettoyage
- [ ] Anciens services/providers supprimés
- [ ] Documentation architecture créée
- [ ] CHANGELOG mis à jour

---

## 📁 Fichiers à créer/modifier

### Modèles Dart
- `lib/features/stocks/models/kpi_stock_global.dart` (nouveau)
- `lib/features/stocks/models/kpi_stock_depot.dart` (nouveau)
- `lib/features/stocks/models/kpi_stock_owner.dart` (nouveau)
- `lib/features/stocks/models/citerne_stock_snapshot.dart` (nouveau)
- `lib/features/stocks/models/citerne_stock_owner_snapshot.dart` (nouveau)

### Services
- `lib/features/stocks/data/stocks_kpi_service.dart` (nouveau) ✅

### Providers
- `lib/features/stocks/providers/stock_providers.dart` (nouveau)

### KPI
- `lib/features/kpi/stock_kpi_provider.dart` (nouveau)
- `lib/features/kpi/models/kpi_stocks.dart` (nouveau)

### Écrans à refactorer
- `lib/features/dashboard/screens/dashboard_admin_screen.dart`
- `lib/features/dashboard/providers/admin_kpi_provider.dart`
- `lib/features/stocks_journaliers/screens/stocks_list_screen.dart`
- `lib/features/stocks_journaliers/providers/stocks_providers.dart`
- `lib/features/citernes/screens/citerne_list_screen.dart`
- `lib/features/citernes/providers/citerne_providers.dart`

### Tests
- `test/features/stocks/models/kpi_stock_global_test.dart` (nouveau)
- `test/features/stocks/data/stock_service_test.dart` (nouveau)

### Documentation SQL
- `docs/db/PHASE3_AUDIT_TRIGGERS.md` (nouveau - liste des triggers)
- `docs/db/PHASE3_STOCK_ENGINE_SPEC.md` (nouveau - spécification de stock_upsert_journalier)
- `supabase/migrations/2025-12-XX_cleanup_old_triggers.sql` (nouveau - suppression des triggers obsolètes)
- `test/features/dashboard/widgets/dashboard_stocks_test.dart` (nouveau)

### Documentation
- `docs/db/PHASE3_CARTOGRAPHIE_EXISTANT.md` (nouveau)
- `docs/db/PHASE3_ARCHITECTURE_FLUTTER_STOCKS.md` (nouveau)

---

## 🔗 Références

- Phase 1 : `docs/rapports/PHASE1_STOCKS_STABILISATION_2025-12-06.md`
- Phase 2 : `docs/rapports/PHASE2_STOCKS_NORMALISATION_2025-12-06.md`
- Contrat SQL : `docs/db/stocks_views_contract.md`
- Plan global : `docs/db/stocks_engine_migration_plan.md`

