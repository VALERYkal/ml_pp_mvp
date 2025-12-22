# 🔒 RAPPORT OFFICIEL — AUDIT & VERROUILLAGE DB

## Gestion des stocks Ambiant / 15°C

**ML_PP MVP – Décembre 2025**

**Date** : 13 décembre 2025  
**Statut** : ✅ **VERROUILLÉ** — Base de données conforme à 100%  
**Référentiel** : `docs/db/REGLE_METIER_STOCKS_AMBIANT_15C.md`

---

## 1️⃣ Contexte et objectif

Dans le cadre de la fiabilisation du module Stocks / Sorties / Réceptions de ML_PP MVP, un audit complet de la base de données de production a été mené afin de vérifier la conformité avec la règle métier officielle suivante :

> **Le stock ambiant est la seule source de vérité opérationnelle.**  
> **Le stock à 15°C est une valeur dérivée, analytique, non décisionnelle.**

### Objectifs de l'audit

- ✅ Vérifier l'absence de décisions opérationnelles basées sur le stock à 15°C
- ✅ Garantir l'intégrité structurelle des stocks journaliers
- ✅ Mettre en place des garde-fous DB non contournables
- ✅ Aligner strictement la DB avec le référentiel métier validé

---

## 2️⃣ Vérifications réalisées (résultats)

### 2.1 Réceptions (`receptions`)

#### Test exécuté

```sql
SELECT id
FROM receptions
WHERE statut = 'validee'
  AND volume_ambiant IS NULL;
```

#### Résultat

✅ **Aucune ligne retournée**

#### Conclusion

- Aucune réception validée sans volume ambiant
- Le stock ambiant est déjà utilisé comme valeur primaire côté DB

#### Garde-fou ajouté

```sql
ALTER TABLE receptions
ADD CONSTRAINT receptions_ambiant_required_if_valid
CHECK (
  statut <> 'validee'
  OR volume_ambiant IS NOT NULL
);
```

➡️ **Une réception validée sans stock ambiant est désormais impossible en DB**

---

### 2.2 Sorties (`sorties_produit`)

#### Test exécuté

```sql
SELECT id
FROM sorties_produit
WHERE statut = 'validee'
  AND volume_ambiant IS NULL;
```

#### Résultat

✅ **Aucune ligne retournée**

#### Conclusion

- Aucune sortie validée sans stock ambiant
- La DB impose déjà implicitement la logique terrain

#### Garde-fou ajouté

```sql
ALTER TABLE sorties_produit
ADD CONSTRAINT sorties_ambiant_required_if_valid
CHECK (
  statut <> 'validee'
  OR volume_ambiant IS NOT NULL
);
```

➡️ **Aucune sortie ne peut être validée sans stock ambiant**

---

## 3️⃣ Stocks journaliers (`stocks_journaliers`)

### 3.1 Vérification des doublons

#### Test exécuté

```sql
SELECT
  citerne_id,
  produit_id,
  date_jour,
  proprietaire_type,
  COUNT(*)
FROM stocks_journaliers
GROUP BY 1,2,3,4
HAVING COUNT(*) > 1;
```

#### Résultat

✅ **Aucune ligne retournée**

#### Conclusion

- Aucun doublon structurel
- Les données historiques sont saines

---

### 3.2 Contrainte d'unicité (clé métier)

#### Vérification

```sql
SELECT conname, pg_get_constraintdef(c.oid)
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
WHERE t.relname = 'stocks_journaliers';
```

#### Résultat

```
UNIQUE (citerne_id, produit_id, date_jour, proprietaire_type)
```

#### Conclusion

- La contrainte métier critique est déjà en place
- Impossible d'avoir plusieurs lignes pour la même combinaison :
  - citerne
  - produit
  - date
  - propriétaire

➡️ **Intégrité structurelle confirmée**

---

## 4️⃣ Audit de la fonction critique `validate_sortie`

### 4.1 Décision opérationnelle

#### Bloc analysé

```sql
if coalesce(v_stock_avant,0) < v_row.volume_ambiant then
  raise exception 'INSUFFICIENT_STOCK';
end if;
```

#### Conclusion

- ✅ **La décision de blocage est basée exclusivement sur `stock_ambiant`**
- ❌ **Le stock à 15°C n'intervient jamais dans la décision**

➡️ **Conformité totale avec la règle métier**

---

### 4.2 Dérive identifiée (corrigée)

#### Ancien comportement

```sql
v_v15 := coalesce(v_row.volume_corrige_15c, v_row.volume_ambiant);
```

#### Problème

- Assimilation implicite : 15°C = ambiant si absent
- Violation conceptuelle de la règle :
  - Le stock à 15°C est toujours dérivé, jamais implicite

---

### 4.3 Correction appliquée (PATCH PROD)

#### Nouveau comportement

```sql
v_v15 := case
  when v_row.volume_corrige_15c is not null then v_row.volume_corrige_15c
  else null
end;
```

Et lors de la mise à jour du stock :

```sql
stock_15c = case
  when v_v15 is not null then greatest(0, sj.stock_15c - v_v15)
  else sj.stock_15c
end
```

#### Effet

- Le stock ambiant est toujours décrémenté
- Le stock 15°C n'évolue que si explicitement calculé
- Aucun 15°C implicite ou reconstruit

➡️ **Alignement strict avec le référentiel officiel**

---

## 5️⃣ Conclusion officielle

### ✅ Confirmations définitives

- ✅ Le stock ambiant est la seule vérité opérationnelle en DB
- ✅ Aucune décision terrain n'est basée sur le stock à 15°C
- ✅ Les données historiques sont saines
- ✅ Les garde-fous critiques sont en place
- ✅ La DB est désormais non contournable métierment

### 🔒 Statut

> **Base de données conforme à 100% à la règle métier officielle**  
> **"Gestion des stocks – Ambiant & 15°C"**

---

## 6️⃣ Prochaines étapes (non incluses dans ce rapport)

### 📋 Audit des vues SQL

- Audit des vues `v_stocks_*`
- Audit des vues `v_kpi_*`
- Vérification de la cohérence des agrégations

### 🖥️ Audit UI / Dashboard

- Vérification de l'affichage (ambiant en premier)
- Vérification des libellés (précision du type)
- Vérification de la hiérarchie visuelle

---

## 7️⃣ Garde-fous en place

### Contraintes CHECK ajoutées

1. **`receptions_ambiant_required_if_valid`**
   - Table : `receptions`
   - Effet : Impossible de valider une réception sans `volume_ambiant`

2. **`sorties_ambiant_required_if_valid`**
   - Table : `sorties_produit`
   - Effet : Impossible de valider une sortie sans `volume_ambiant`

### Contraintes UNIQUE existantes

1. **`stocks_journaliers`**
   - Clé : `(citerne_id, produit_id, date_jour, proprietaire_type)`
   - Effet : Intégrité structurelle garantie

### Fonctions corrigées

1. **`validate_sortie()`**
   - Décision basée uniquement sur `stock_ambiant`
   - Stock 15°C géré explicitement (pas d'implicite)

---

## 8️⃣ Références

- **Règle métier officielle** : `docs/db/REGLE_METIER_STOCKS_AMBIANT_15C.md`
- **Règles stocks journaliers** : `docs/db/stocks_rules.md`
- **Table `receptions`** : Schéma Supabase
- **Table `sorties_produit`** : Schéma Supabase
- **Table `stocks_journaliers`** : Schéma Supabase

---

## 9️⃣ Historique des modifications

| Date | Version | Auteur | Modification |
|------|---------|--------|--------------|
| 2025-12-13 | 1.0 | Équipe ML_PP MVP | Création du rapport d'audit et verrouillage DB |

---

**Document officiel d'audit – Base de données verrouillée et conforme**

