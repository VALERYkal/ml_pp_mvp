# CHECKPOINT — Stocks KPI / Vue Daily (2025-12-23)

## ✅ Ce qui est fait

### Migration daily + tests green
- ✅ Migration Flutter terminée : l'app consomme désormais `public.v_stocks_citerne_global_daily` (support `date_jour`)
- ✅ Tests OK : suite Stocks green (10/10) + `flutter test` global passe
- ✅ Repository canonique aligné : `lib/data/repositories/stocks_kpi_repository.dart`
- ✅ Repository dupliqué supprimé : `lib/features/stocks/data/stocks_kpi_repository.dart`
- ✅ Providers et commentaires mis à jour dans tous les modules (Stocks, Citernes, Dashboard)

### Contrat + nettoyage docs
- ✅ Contrat canonique créé : `docs/db/stocks_views_contract.md` avec structure imposée (But, Vue canonique, Vue legacy, Exemples SQL/Dart)
- ✅ Références docs nettoyées : mentions "vue principale" pointent vers `v_stocks_citerne_global_daily`
- ✅ Notes legacy ajoutées : clarifications que `v_stocks_citerne_global` est legacy conservée en DB, l'app n'y touche plus

## ✅ PHASE 3 — UI & Providers (2025-12-23) — TERMINÉE

### Alignement UI 100% sur snapshot daily canonique
- ✅ **Dashboard** : Utilise `depotStocksSnapshotProvider` avec date normalisée pour stock total ET breakdown propriétaire
- ✅ **Date normalisation** : Date normalisée une seule fois en amont dans `depotStocksSnapshotProvider` pour éviter rebuild loops
- ✅ **Citernes** : Utilise déjà `depotStocksSnapshotProvider` avec date normalisée
- ✅ **Guards de régression** : Assertions debug ajoutées pour vérifier normalisation date et cohérence dates dans résultats
- ✅ **Logs debug** : Tous les `debugPrint` wrappés avec `kDebugMode` pour éviter spam en release

### Changements clés Phase 3
- `depotStocksSnapshotProvider` : Normalisation date améliorée (évite `DateTime.now()` instable)
- `role_dashboard.dart` : Stock total utilise maintenant `snapshot.totals` au lieu de `data.stocks` pour cohérence
- Guards ajoutés : Vérification normalisation date + vérification dates distinctes dans résultats

### Tests
- ✅ `flutter test test/features/stocks/stocks_kpi_repository_test.dart` → 8/8 passent
- ✅ `flutter test test/features/dashboard/` → 26/26 passent

## ✅ PHASE 4 — Stocks KPI Hardening (2025-12-23) — TERMINÉE

### Objectif
Rendre les fallbacks explicites, améliorer l'hygiène des logs (kDebugMode), ajouter des tests anti-régression ciblés.

### Changements clés Phase 4

#### Politique de fallback explicite
- ✅ **Paramètre `allowFallbackInDebug`** : Ajouté à `DepotStocksSnapshotParams` pour contrôler explicitement le comportement de fallback
  - Par défaut : `false` en debug (force la détection des problèmes), `true` en release (évite les crashes)
  - Assertion debug : Si `allowFallbackInDebug == false` et qu'un fallback est utilisé, une assertion échoue avec message explicite
- ✅ **Logs d'erreur wrappés** : Tous les `debugPrint` d'erreur wrappés avec `kDebugMode` pour éviter spam en release
- ✅ **Messages améliorés** : Messages d'erreur clarifiés pour indiquer clairement quand un fallback est utilisé

#### Log hygiene
- ✅ **Tous les logs wrappés** : Vérification complète que tous les `debugPrint` sont wrappés avec `kDebugMode`
- ✅ **Réduction verbosité** : Logs critiques uniquement, pas de spam sur les rebuilds

#### Tests anti-régression
- ✅ **Test 1** : `returns isFallback=false for normal fixtures` — Vérifie que avec des données valides, `isFallback` est toujours `false` (même avec `allowFallbackInDebug: false`)
- ✅ **Test 2** : `normalizes dateJour to 00:00:00.000` — Vérifie que la date est normalisée avant d'être passée au repository et dans le snapshot retourné
- ✅ **Test 3** : `ensures all citerneRows have same date_jour` — Vérifie la cohérence des dates dans les snapshots citernes (gardefou si le repository ne filtre pas correctement)

### Fichiers modifiés Phase 4
- `lib/features/stocks/data/stocks_kpi_providers.dart` : Politique de fallback, logs wrappés
- `test/features/stocks/depot_stocks_snapshot_provider_test.dart` : 3 nouveaux tests anti-régression

### DB Migration
- ✅ **View SQL frozen** : Migration `supabase/migrations/20251223_1200_stocks_views_daily.sql` créée
  - Vue canonique `v_stocks_citerne_global_daily` versionnée et idempotente (CREATE OR REPLACE VIEW)
  - Required for new environments : cette migration doit être exécutée pour créer la vue dans tout nouvel environnement
  - Contract checks ajoutés au checklist de release (VIEW CONTRACT — daily global)

### Validation Phase 4
```bash
flutter analyze
flutter test test/features/stocks/stocks_kpi_repository_test.dart -r expanded
flutter test test/features/stocks/depot_stocks_snapshot_provider_test.dart -r expanded
flutter test test/features/dashboard/ -r expanded
```

## 📋 Prochaine étape proposée

**Ajouter un test anti-régression `_filterToLatestDate` multi-dates** :
- ✅ **FAIT** : Test ajouté dans `test/features/stocks/stocks_kpi_repository_test.dart`
- Vérifie que quand plusieurs `date_jour` reviennent d'une requête, le repository ne garde que le plus récent

## Architecture finale

```
stocks_journaliers (DB)
    ↓
v_stocks_citerne_global_daily (SQL view avec date_jour) ← VUE CANONIQUE
    ↓
StocksKpiRepository.fetchCiterneGlobalSnapshots() (lib/data/repositories/)
    ↓
depotStocksSnapshotProvider (Riverpod)
    ↓
Dashboard / Stocks / Citernes (UI)
```

## Fichiers modifiés (dernière passe)

### Créés
- `docs/db/stocks_views_contract.md` (contrat canonique)

### Modifiés (nettoyage docs)
- `docs/db/PHASE2_STOCKS_UNIFICATION_FLUTTER.md`
- `docs/sql_checks/stock_release_checklist.md`
- `docs/incidents/BUG-2025-12-stocks-multi-proprietaire-incoherence.md`
- `docs/incidents/BUG-2025-12-citernes-provider-loop.md`

### Note DB
- `v_stocks_citerne_global` reste en base (legacy / rétrocompatibilité) mais n'est plus utilisée par Flutter.
