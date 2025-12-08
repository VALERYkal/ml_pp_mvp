# Plan de migration - Stocks Engine (4 phases)

**Objectif** : Corriger les incohérences entre DB et app en rendant la DB la seule source de vérité pour les stocks.

**Branch** : `feature/stocks-engine`

**Date de début** : 2025-12-06  
**Phase 1 complétée** : 2025-12-06 ✅

---

## Phase 1 – Verrouiller la "vérité métier" (sans toucher à Flutter)

### Objectif
S'assurer que mathématiquement tout est cohérent côté DB avant de toucher à l'app.

### Règle officielle du stock (à documenter)

**Stock par jour, par (date_jour, citerne_id, produit_id, proprietaire_type)**

- `stock_ambiant` et `stock_15c` = **cumul fin de journée**, pas delta
- **Réception** = `+volume` (crédit)
- **Sortie** = `-volume` (débit)

### Tâches

1. **Créer la vue v_mouvements_stock et la fonction SQL de recompute**
   - Fichier : `supabase/migrations/2025-12-06_rebuild_stocks_offline.sql`
   - Vue : `v_mouvements_stock` (agrège réceptions et sorties avec deltas)
   - Fonction : `rebuild_stocks_journaliers(p_depot_id, p_start_date, p_end_date)`
   - Logique :
     - Supprime uniquement les lignes `source = 'SYSTEM'` dans le périmètre
     - Recalcule les stocks cumulés à partir de `v_mouvements_stock`
     - Utilise des window functions pour calculer les cumuls
     - Laisse intact les ajustements manuels (`source ≠ 'SYSTEM'`)

2. **Tests manuels**
   - [ ] Exécuter `rebuild_stocks_journaliers()` sur un environnement de test
   - [ ] Vérifier la cohérence : somme des mouvements = stocks cumulés
   - [ ] Vérifier la préservation des ajustements manuels
   - [ ] Tester les filtres optionnels (dépot, période)
   - [ ] Documenter les résultats dans `docs/db/stocks_tests.md`

### Livrables Phase 1

- [ ] Vue `v_mouvements_stock` créée et testée
- [ ] Migration SQL `rebuild_stocks_journaliers()` fonctionnelle
- [ ] Tests manuels validés (recompute global, partiel, préservation ajustements)
- [ ] Documentation des règles métier dans `docs/db/stocks_rules.md`

### Fichiers à créer/modifier

- `supabase/migrations/2025-12-06_rebuild_stocks_offline.sql`
- `docs/db/stocks_rules.md`
- `docs/db/stocks_tests.md`

---

## Phase 2 – Unification Flutter sur la vérité unique Stock

### Objectif
Faire en sorte que toute l'app (écrans + KPI) lise les stocks à partir de la même vérité unique : `stocks_journaliers → v_stocks_citerne_global → services Dart → UI / KPI`

### Tâches détaillées

Voir le plan complet dans : `docs/db/PHASE2_STOCKS_UNIFICATION_FLUTTER.md`

#### Étape 2.1 — Figer le contrat SQL "vérité unique stock"
- [ ] Vue `v_stocks_citerne_global` créée et documentée
- [ ] Vues KPI créées si nécessaire (`v_kpi_stock_depot`, `v_kpi_stock_proprietaire_global`)
- [ ] Documentation des vues dans `docs/db/stocks_views_contract.md`

#### Étape 2.2 — Créer un service Flutter unique de lecture du stock
- [ ] `StockService` créé avec toutes les méthodes nécessaires
- [ ] Providers Riverpod créés (`stocksParCiterneProvider`, `stockDepotGlobalProvider`, `kpiStockProvider`)
- [ ] Tests unitaires pour `StockService`

#### Étape 2.3 — Rebrancher le module Citernes sur le nouveau service
- [ ] `CiterneListScreen` utilise `stocksParCiterneProvider`
- [ ] `CiterneDetailScreen` utilise `stocksParCiterneProvider`
- [ ] Widget dashboard citernes utilise `stocksParCiterneProvider`
- [ ] Vérification manuelle : valeurs affichées = valeurs SQL

#### Étape 2.4 — Rebrancher le module "Stocks / Inventaire" sur la vérité unique
- [ ] `StocksListScreen` utilise `stocks_journaliers` directement
- [ ] Suppression de toute logique de calcul côté Dart
- [ ] Filtres (dépôt, produit, propriétaire) fonctionnels

#### Étape 2.5 — Rebrancher les KPIs Dashboard sur les vues
- [ ] `kpiStockProvider` créé avec DTO `StockKpiModel`
- [ ] Toutes les cartes Dashboard utilisent `kpiStockProvider`
- [ ] Suppression de toute logique de calcul dans les widgets Dashboard

#### Étape 2.6 — Harmonisation de l'affichage dans Réceptions / Sorties
- [ ] Écrans Réception/Sortie utilisent `stocksParCiterneProvider` pour afficher le stock
- [ ] Cohérence vérifiée avec les autres écrans

#### Étape 2.7 — Tests et garde-fous
- [ ] Script SQL de validation créé
- [ ] Tests unitaires `StockService` créés
- [ ] Tests widget Dashboard créés
- [ ] Page debug stock créée (optionnel)

### Livrables Phase 2

- [ ] Contrat SQL figé et documenté
- [ ] Service Flutter unique (`StockService`) créé
- [ ] Tous les modules rebranchés sur la vérité unique
- [ ] Tests créés et validés
- [ ] Aucune logique de calcul côté Dart (tout dans SQL)

### Fichiers à créer/modifier

- `supabase/migrations/2025-12-XX_views_stocks.sql` (mise à jour avec `v_stocks_citerne_global`)
- `docs/db/stocks_views_contract.md` (contrat des vues SQL)
- `docs/db/PHASE2_STOCKS_UNIFICATION_FLUTTER.md` (plan détaillé)
- `lib/features/stocks/data/stock_service.dart` (nouveau)
- `lib/features/stocks/providers/stock_providers.dart` (nouveau)
- Modules à refactorer : Citernes, Stocks, Dashboard, KPI

---

## Phase 3 – Reconnexion de l'app Flutter aux nouveaux stocks & KPI

### Objectif
Faire en sorte que TOUS les écrans UI (Dashboard, Stocks, Citernes) lisent uniquement les vues SQL (`v_kpi_stock_*`, `v_stocks_citerne_*`) et supprimer toute logique de calcul de stock côté Flutter.

### Tâches détaillées

Voir le plan complet dans : `docs/db/PHASE3_FLUTTER_RECONNEXION_STOCKS.md`

#### Étape 3.1 – Cartographie & gel de l'existant
- [ ] Liste des fichiers Flutter qui consomment des stocks créée
- [ ] Table récap créée (`docs/db/PHASE3_CARTOGRAPHIE_EXISTANT.md`)

#### Étape 3.2 – Modèles Dart pour les nouvelles vues
- [ ] `KpiStockGlobal` créé
- [ ] `KpiStockDepot` créé
- [ ] `KpiStockOwner` créé
- [ ] `CiterneStockSnapshot` créé
- [ ] `CiterneStockOwnerSnapshot` créé
- [ ] Tests unitaires pour le mapping JSON → modèles

#### Étape 3.3 – Services Supabase dédiés aux vues
- [ ] `StockKpiService` créé avec toutes les méthodes
- [ ] Tests unitaires avec Supabase mocké

#### Étape 3.4 – Providers Riverpod
- [ ] `globalStockKpiProvider` créé
- [ ] `depotStockKpiProvider` créé
- [ ] `ownerStockKpiProvider` créé
- [ ] `citerneStockProvider` créé
- [ ] `citerneStockOwnerProvider` créé

#### Étape 3.5 – Recâbler le Dashboard Admin
- [ ] Dashboard Admin utilise `globalStockKpiProvider`
- [ ] Suppression de toute logique de calcul manuel
- [ ] Vérification manuelle : valeurs affichées = valeurs SQL

#### Étape 3.6 – Recâbler l'écran Stocks Journaliers
- [ ] `StocksListScreen` utilise `citerneStockProvider`
- [ ] Suppression de toute logique de calcul côté Dart
- [ ] Filtres fonctionnent
- [ ] Vérification manuelle : valeurs affichées = valeurs SQL

#### Étape 3.7 – Recâbler l'écran Citernes
- [ ] `CiterneListScreen` utilise `citerneStockProvider`
- [ ] Affichage des valeurs totales et par propriétaire
- [ ] Suppression de toute logique de calcul côté Dart
- [ ] Vérification manuelle : valeurs affichées = valeurs SQL

#### Étape 3.8 – Mini tests & non-régression
- [ ] Tests unitaires pour tous les modèles
- [ ] Tests unitaires pour `StockKpiService`
- [ ] 1-2 tests d'intégration widget

#### Étape 3.9 – Nettoyage & documentation
- [ ] Anciens services/providers supprimés
- [ ] Documentation architecture créée (`docs/db/PHASE3_ARCHITECTURE_FLUTTER_STOCKS.md`)
- [ ] CHANGELOG mis à jour

### Livrables Phase 3

- [ ] Modèles Dart créés pour toutes les vues SQL
- [ ] Service `StockKpiService` créé
- [ ] Providers Riverpod créés
- [ ] Dashboard, Stocks, Citernes rebranchés sur les nouveaux providers
- [ ] Toute logique de calcul côté Dart supprimée
- [ ] Tests créés et validés
- [ ] Documentation architecture créée

### Fichiers à créer/modifier

**Modèles Dart**
- `lib/features/stocks/models/kpi_stock_global.dart` (nouveau)
- `lib/features/stocks/models/kpi_stock_depot.dart` (nouveau)
- `lib/features/stocks/models/kpi_stock_owner.dart` (nouveau)
- `lib/features/stocks/models/citerne_stock_snapshot.dart` (nouveau)
- `lib/features/stocks/models/citerne_stock_owner_snapshot.dart` (nouveau)

**Services**
- `lib/features/stocks/data/stock_kpi_service.dart` (nouveau)

**Providers**
- `lib/features/stocks/providers/stock_kpi_providers.dart` (nouveau)

**Écrans à refactorer**
- `lib/features/dashboard/screens/dashboard_admin_screen.dart`
- `lib/features/dashboard/providers/admin_kpi_provider.dart`
- `lib/features/stocks_journaliers/screens/stocks_list_screen.dart`
- `lib/features/stocks_journaliers/providers/stocks_providers.dart`
- `lib/features/citernes/screens/citerne_list_screen.dart`
- `lib/features/citernes/providers/citerne_providers.dart`

**Documentation**
- `docs/db/PHASE3_FLUTTER_RECONNEXION_STOCKS.md` (plan détaillé)
- `docs/db/PHASE3_CARTOGRAPHIE_EXISTANT.md` (cartographie)
- `docs/db/PHASE3_ARCHITECTURE_FLUTTER_STOCKS.md` (architecture)

---

## Phase 4 – Créer la "Stock Engine" (fonction + triggers minces)

### Objectif
Faire en sorte que les nouvelles réceptions/sorties gardent la DB cohérente sans rebuild.

### Tâches

1. **Créer la fonction cœur v2**
   - Fichier : `supabase/migrations/2025-12-XX_stock_engine_v2.sql`
   - Fonction : `stock_upsert_journalier_v2(...)`
   - Logique validée à la Phase 1

2. **Créer de nouveaux triggers v2**
   - `trg_receptions_after_insert_v2` → appelle `stock_upsert_journalier_v2(...)`
   - `trg_sorties_after_insert_v2` → appelle `stock_upsert_journalier_v2(...)`

3. **Désactiver les anciens triggers**
   - Renommer les anciens triggers avec suffixe `_old`
   - Une fois testé : `DROP TRIGGER ..._old;`

4. **Tests manuels + doc**
   - [ ] Créer 1-2 réceptions de test
   - [ ] Créer 1-2 sorties de test
   - [ ] Vérifier `stocks_journaliers` directement
   - [ ] Documenter dans `docs/db/stocks_tests.md`

### Livrables Phase 4

- [ ] Migration SQL `stock_engine_v2.sql` fonctionnelle
- [ ] Nouveaux triggers v2 actifs
- [ ] Anciens triggers désactivés
- [ ] Tests manuels validés

### Fichiers à créer/modifier

- `supabase/migrations/2025-12-XX_stock_engine_v2.sql`
- `docs/db/stocks_tests.md` (mise à jour)

---

## Phase 5 – Finalisation et optimisation (optionnel)

### Objectif
Optimisation, nettoyage et amélioration continue après les Phases 1, 2 et 3.

### Tâches (optionnelles)

1. **Optimisation des performances**
   - [ ] Ajouter des index sur les vues si nécessaire
   - [ ] Optimiser les requêtes SQL avec EXPLAIN ANALYZE
   - [ ] Mise en cache côté Flutter si nécessaire

2. **Amélioration de l'UX**
   - [ ] Page debug stock pour admin
   - [ ] Alertes automatiques sur stocks bas
   - [ ] Graphiques d'évolution des stocks

3. **Nettoyage final**
   - [ ] Supprimer la logique morte dans les anciens providers
   - [ ] Mettre à jour toute la documentation
   - [ ] Revue de code complète

### Livrables Phase 4

- [ ] Optimisations de performance validées
- [ ] Documentation complète et à jour
- [ ] Code nettoyé et maintenable

### Fichiers à modifier

- Tous les fichiers modifiés dans les phases précédentes
- Documentation globale

---

## Checklist globale

### Phase 1 ✅ COMPLÉTÉE
- [x] Migration `rebuild_stocks_offline.sql` créée
- [x] Vue `v_mouvements_stock` créée et validée
- [x] Fonction `rebuild_stocks_journaliers()` implémentée
- [x] Tests manuels validés (cohérence mathématique vérifiée)
- [x] Documentation règles métier
- [x] Vue `v_stocks_citerne_global` créée
- [x] Rapport Phase 1 documenté

**Résultats** : Stocks journaliers mathématiquement justes, cohérence validée (TANK1: 153 300 L, TANK2: 36 550 L). Voir `docs/rapports/PHASE1_STOCKS_STABILISATION_2025-12-06.md` pour le rapport complet.

### Phase 2 - Normalisation et Reconsolidation Stock (SQL) ✅ COMPLÉTÉE
- [x] Vue `v_mouvements_stock` créée (source unique de vérité sur les mouvements)
- [x] Fonction `rebuild_stocks_journaliers()` créée et validée
- [x] Vue `v_stocks_citerne_global` créée et documentée
- [x] Vue `v_stocks_citernes` créée
- [x] Vue `v_dashboard_kpi` créée
- [x] Vue `v_citernes_state` créée
- [x] Contrat SQL figé et documenté (`docs/db/stocks_views_contract.md`)
- [x] Script de validation SQL créé (`scripts/validate_stocks.sql`)
- [x] Table `stocks_journaliers` reconstruite proprement (sans doublons, sans incohérences)
- [x] Stock global cohérent validé (189 850 L ambiant / 189 181.925 L 15°C)
- [x] Stock par tank cohérent validé (TANK1: 153 300 L, TANK2: 36 550 L)
- [x] Stock par propriétaire cohérent validé (Monaluxe: 103 500 L, Partenaire: 86 350 L)
- [x] Rapport Phase 2 documenté (`docs/rapports/PHASE2_STOCKS_NORMALISATION_2025-12-06.md`)

**Résultats** : Moteur de stock robuste, uniformisé, documenté et reconstruit proprement. KPIs totalement fiables. Base solide pour la Phase 3 (recâblage Flutter). Voir `docs/rapports/PHASE2_STOCKS_NORMALISATION_2025-12-06.md` pour le rapport complet.

**Note** : La Phase 2 (SQL) est complétée. La Phase 2 (Flutter - Unification) sera la prochaine étape.

### Phase 3 - Reconnexion Flutter ✅ TERMINÉE
- [x] Repository `StocksKpiRepository` créé (Phase 3.1) ✅
- [x] Providers Riverpod créés (Phase 3.2) ✅
- [x] Service `StocksKpiService` créé (Phase 3.3) ✅
- [x] Dashboard rebranché sur provider agrégé (Phase 3.3.1) ✅
- [x] Capacités intégrées au modèle KPI (Phase 3.4) ✅
- [x] Documentation architecture créée ✅

**Phase 3 complétée** : Voir `docs/rapports/PHASE3_STOCKS_KPI_COMPLETE_2025-12-06.md` pour le rapport complet

**Résultat** : Architecture stabilisée, Dashboard opérationnel, performance optimisée

### Phase 4 - Stock Engine SQL (triggers v2)
- [ ] Migration `stock_engine_v2.sql` créée
- [ ] Nouveaux triggers v2 actifs
- [ ] Anciens triggers désactivés
- [ ] Tests manuels validés

**Note** : Cette phase concerne les triggers SQL pour maintenir la cohérence des stocks.

---

## Phase 4 (Flutter) – Sorties Produit

**Statut** : 🚧 **EN PLANIFICATION**

**Objectif** : Rendre le module Sorties Produit production-ready avec service Flutter propre, formulaire fiable, et tests automatisés verts.

**Découpage** :
- **4.1** – Stabiliser SortieService + tests d'intégration (🔴 HAUTE priorité)
- **4.2** – Nettoyer & finaliser le formulaire Sortie Produit
- **4.3** – Flux de validation & rôles
- **4.4** – Intégration au Dashboard & KPIs
- **4.5** – Documentation & tests finaux

**Voir** : `docs/db/PHASE4_SORTIES_PRODUIT_PLAN.md` pour le plan détaillé

**Phase 4.1 en cours** : `docs/db/PHASE4_1_SORTIES_SERVICE_STABILISATION.md`

### Phase 5 - Finalisation (optionnel)
- [ ] Optimisations de performance validées
- [ ] Documentation complète et à jour
- [ ] Code nettoyé et maintenable

---

## Notes importantes

- **Ne pas modifier Flutter** tant que la Phase 1 n'est pas validée
- **Garder l'état actuel comme "photo bugguée"** pour référence
- **Tester chaque phase** avant de passer à la suivante
- **Documenter chaque étape** pour traçabilité

---

## Références

- Triggers actuels : `supabase/migrations/2025-08-22_fix_statuts_and_triggers.sql`
- Triggers sorties : `supabase/migrations/2025-12-19_sorties_trigger_unified.sql`
- Vue actuelle : `supabase/migrations/2025-09-09_views_and_rls.sql` (v_citerne_stock_actuel)
- Documentation sorties : `docs/db/sorties_trigger_tests.md`

