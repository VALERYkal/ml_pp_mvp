# CHECKPOINT — Stocks KPI / Vue Daily (2025-12-23)

## Statut
✅ Migration Flutter terminée : l'app consomme désormais `public.v_stocks_citerne_global_daily` (support `date_jour`)  
✅ Tests OK : suite Stocks green (10/10) + `flutter test` global passe

## Objectif atteint
- Une seule "vérité stock" côté app : `stocks_journaliers` → vues SQL → repository canonique
- Fin des divergences entre modules (Dashboard / Stocks / Citernes)
- Fin du legacy runtime sur `v_stocks_citerne_global`

## Changements clés
- ✅ Repo canonique : `lib/data/repositories/stocks_kpi_repository.dart`
  - Source globale citerne: `v_stocks_citerne_global_daily`
  - Filtrage date harmonisé: `lte(date_jour)` + `order desc` + `_filterToLatestDate`
- 🧹 Nettoyage:
  - supprimé le repo dupliqué `lib/features/stocks/data/stocks_kpi_repository.dart`
  - providers stocks alignés (logs/commentaires + passage `dateJour`)
  - citernes : commentaires mis à jour (source daily)
  - docs contract : daily = canonique

## Vérifications faites
- `rg -n "v_stocks_citerne_global" -S lib test` → 0 occurrences runtime
- `flutter test` → OK

## Note DB
- `v_stocks_citerne_global` reste en base (legacy / rétrocompatibilité) mais n'est plus utilisée par Flutter.

## Prochaines étapes recommandées
1) (Optionnel) Ajouter 1 test "contrat daily" : quand plusieurs `date_jour` reviennent, le repo ne garde que le plus récent.
2) Vérifier la cohérence fonctionnelle en prod/dev :
   - Dashboard total = somme citernes global daily
   - Breakdown owner = cohérent avec global
3) Si besoin, nettoyer les dernières docs/incidents qui parlent de `v_stocks_citerne_global` comme vue canonique (legacy uniquement).

## Fichiers modifiés

### Supprimés
- `lib/features/stocks/data/stocks_kpi_repository.dart` (repository dupliqué)

### Modifiés
- `lib/data/repositories/stocks_kpi_repository.dart` (déjà migré précédemment)
- `lib/features/stocks/data/stocks_kpi_providers.dart`
- `lib/features/citernes/providers/citerne_providers.dart`
- `lib/features/citernes/screens/citerne_list_screen.dart`
- `test/features/stocks/stocks_kpi_repository_test.dart`
- `docs/db/stocks_views_contract.md`

## Architecture finale

```
stocks_journaliers (DB)
    ↓
v_stocks_citerne_global_daily (SQL view avec date_jour)
    ↓
StocksKpiRepository.fetchCiterneGlobalSnapshots() (lib/data/repositories/)
    ↓
depotStocksSnapshotProvider (Riverpod)
    ↓
Dashboard / Stocks / Citernes (UI)
```

Tous les modules consomment maintenant la même source de vérité avec un filtrage date cohérent.

