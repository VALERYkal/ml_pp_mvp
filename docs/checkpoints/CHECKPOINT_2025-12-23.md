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

## 📋 Prochaine étape proposée

**Ajouter un test anti-régression `_filterToLatestDate` multi-dates** :
- Vérifier que quand plusieurs `date_jour` reviennent d'une requête, le repository ne garde que le plus récent
- Test unitaire ciblé sur la méthode `_filterToLatestDate` ou test d'intégration via `fetchCiterneGlobalSnapshots`

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
