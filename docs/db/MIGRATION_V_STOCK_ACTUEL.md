# Migration vers v_stock_actuel (Source de vérité unique)

**Date** : 2025-12-31  
**Version** : 1.0  
**Statut** : ✅ Contrat créé, documentation mise à jour

---

## Changement majeur

La source de vérité unique pour le stock actuel est maintenant **`v_stock_actuel`**.

**Anciennes sources (dépréciées)** :
- ❌ `v_stock_actuel_snapshot` → Remplacer par `v_stock_actuel`
- ❌ `v_stocks_citerne_global_daily` → Remplacer par `v_stock_actuel` (historique uniquement)
- ❌ `stocks_journaliers` → Utiliser uniquement pour historique/rapports

---

## Contrat officiel

Voir **`docs/db/CONTRAT_STOCK_ACTUEL.md`** pour :
- Règle absolue : toute lecture du stock actuel DOIT utiliser `v_stock_actuel`
- Interdictions strictes
- Cas d'usage autorisés
- Audit & conformité

---

## Documentation mise à jour

Les fichiers suivants ont été mis à jour pour refléter le changement :

1. ✅ **`docs/db/CONTRAT_STOCK_ACTUEL.md`** (NOUVEAU) – Contrat officiel
2. ✅ **`docs/db/stocks_views_contract.md`** – Référence mise à jour
3. ✅ **`docs/db/vues_sql_reference.md`** – Tableau et descriptions mis à jour
4. ✅ **`docs/db/vues_sql_reference_central.md`** – Tableau récapitulatif et règles de choix mis à jour
5. ✅ **`README.md`** – Référence au contrat ajoutée

---

## Prochaines étapes (migration code)

### Phase 1 : Identification des usages

Rechercher tous les usages des anciennes sources :
```bash
# Rechercher v_stock_actuel_snapshot
rg "v_stock_actuel_snapshot" lib/

# Rechercher v_stocks_citerne_global_daily
rg "v_stocks_citerne_global_daily" lib/

# Rechercher stocks_journaliers (pour stock actuel)
rg "stocks_journaliers" lib/ | grep -v "historique\|history\|journal"
```

### Phase 2 : Migration repositories

Fichiers à migrer :
- `lib/data/repositories/stocks_kpi_repository.dart`
- `lib/features/stocks/data/stocks_kpi_providers.dart`
- Tous les repositories utilisant les anciennes vues

**Action** : Remplacer `.from('v_stock_actuel_snapshot')` par `.from('v_stock_actuel')`

### Phase 3 : Migration providers

Fichiers à migrer :
- `lib/features/dashboard/widgets/role_dashboard.dart`
- `lib/features/citernes/providers/citerne_providers.dart`
- Tous les providers consommant les anciennes vues

**Action** : Adapter les providers pour utiliser `v_stock_actuel`

### Phase 4 : Tests & validation

- [ ] Tous les tests passent
- [ ] Vérification fonctionnelle manuelle
- [ ] Validation que les KPI affichent correctement
- [ ] Vérification que les écrans Citernes/Stocks fonctionnent

---

## Notes importantes

- ⚠️ **Ne pas supprimer les anciennes vues** tant que la migration n'est pas complète
- ⚠️ **Tester chaque module** après migration
- ✅ **Documenter** toute exception temporaire si nécessaire

---

## Références

- **Contrat officiel** : `docs/db/CONTRAT_STOCK_ACTUEL.md`
- **Documentation vues** : `docs/db/vues_sql_reference_central.md`
- **Transaction Contract** : `docs/TRANSACTION_CONTRACT.md`

