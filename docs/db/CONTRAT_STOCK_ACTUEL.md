# Contrat DB — Source de vérité du Stock Actuel

**Date** : 2025-12-31  
**Version** : 1.0  
**Statut** : ✅ DB-STRICT | Production Ready | Verrouillé (Axe A)

---

## Objectif

Définir de manière **unique et non ambiguë** la source de vérité du stock actuel dans ML_PP MVP.

---

## Règle absolue

👉 **Toute lecture du stock actuel DOIT utiliser la vue :**

```
public.v_stock_actuel
```

---

## Définition

`v_stock_actuel` est une vue canonique qui expose :

- le stock actuel corrigé (ambiant et 15°C)
- par dépôt, citerne, produit et propriétaire
- en tenant compte :
  - des mouvements validés (réceptions / sorties)
  - des corrections officielles (`stocks_adjustments`)

---

## Interdictions

Il est **strictement interdit** d'utiliser pour le stock actuel :

- ❌ `stocks_journaliers` (historique uniquement)
- ❌ `stocks_snapshot` (table interne)
- ❌ toute vue legacy ou calcul Flutter
- ❌ `v_stock_actuel_snapshot` (ancienne source, dépréciée)
- ❌ `v_stocks_citerne_global_daily` (vue daily, historique uniquement)

Ces objets sont **internes** ou **historiques**.

---

## Logique de calcul (simplifiée)

```
stock_actuel = stock_snapshot + Σ(stocks_adjustments)
```

---

## Cas d'usage autorisés

- ✅ Dashboards KPI
- ✅ Écrans Citernes
- ✅ Écrans Stocks
- ✅ Détails Produit / Propriétaire
- ✅ Validation métier (sorties, réceptions)

---

## Audit & conformité

- ✅ Aucune écriture directe sur le stock
- ✅ Toute correction passe par `stocks_adjustments`
- ✅ Toute valeur affichée est recalculable et auditée
- ✅ Source unique garantit la cohérence entre modules

---

## Migration depuis anciennes sources

### Anciennes sources (dépréciées)

- `v_stock_actuel_snapshot` → Remplacer par `v_stock_actuel`
- `v_stocks_citerne_global_daily` → Remplacer par `v_stock_actuel` (agrégation côté app si besoin)
- `stocks_journaliers` → Utiliser uniquement pour historique/rapports

### Plan de migration

1. **Phase 1** : Mise à jour des repositories Flutter
2. **Phase 2** : Mise à jour des providers
3. **Phase 3** : Mise à jour des écrans UI
4. **Phase 4** : Suppression des références legacy

---

## Références

- **Vue SQL** : `public.v_stock_actuel`
- **Documentation vues** : `docs/db/vues_sql_reference.md`
- **Transaction Contract** : `docs/TRANSACTION_CONTRACT.md`
- **Règles métier** : `docs/db/REGLE_METIER_STOCKS_AMBIANT_15C.md`

---

**Ce contrat est verrouillé et ne peut être modifié sans validation direction + équipe technique.**

