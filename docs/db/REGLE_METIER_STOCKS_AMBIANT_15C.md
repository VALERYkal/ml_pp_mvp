# RÈGLE MÉTIER FORMELLE

## Gestion des stocks – Ambiant & 15°C

**ML_PP MVP – Référentiel officiel**

**Version** : 1.0  
**Date** : 13 décembre 2025  
**Statut** : ✅ Approuvé et en vigueur

---

## 1. 🎯 Objet

Cette règle définit la source de vérité, les priorités de calcul et les modalités d'affichage des stocks dans ML_PP MVP, afin d'assurer :

- une exploitation fidèle à la réalité physique du dépôt,
- une cohérence métier entre modules (Réceptions, Sorties, Stocks, Dashboard),
- une distinction claire entre stock opérationnel et stock normalisé.

---

## 2. 🧱 Définitions

### 2.1 Stock ambiant

Le **stock ambiant** est le volume mesuré aux conditions réelles de température du produit au moment du mouvement (réception ou sortie).

👉 Il correspond à :

- la réalité physique dans la citerne,
- la base des décisions opérationnelles,
- la valeur manipulée par les opérateurs terrain.

### 2.2 Stock à 15°C

Le **stock à 15°C** est un volume corrigé selon les normes pétrolières, permettant une comparaison homogène des volumes indépendamment des variations de température.

👉 Il correspond à :

- une valeur normalisée,
- un usage analytique, financier, réglementaire et comparatif,
- une valeur dérivée, jamais indépendante.

---

## 3. 🥇 Principe fondamental (NON NÉGOCIABLE)

> **Le stock ambiant est la seule source de vérité opérationnelle.**  
> **Le stock à 15°C est toujours dérivé du stock ambiant.**

---

## 4. 📐 Règles de calcul

### 4.1 Lors d'un mouvement de stock (réception ou sortie)

Pour chaque mouvement validé :

1. **Le volume ambiant est enregistré comme valeur primaire.**
2. **Le volume à 15°C est calculé à partir :**
   - du volume ambiant,
   - de la température,
   - de la densité à 15°C.

📌 **Le système ne doit jamais recalculer l'ambiant à partir du 15°C.**

### 4.2 Stock journalier

Pour chaque combinaison :

- dépôt
- citerne
- produit
- propriétaire
- date

Le système conserve simultanément :

- `stock_ambiant`
- `stock_15c`

Ces deux valeurs évoluent en parallèle, mais :

- **l'ambiant est référence**
- **le 15°C est miroir normalisé**

---

## 5. 🏭 Règles par citerne

1. Une citerne contient un **stock physique réel** exprimé en ambiant.

2. Le stock total d'une citerne est :
   ```
   Stock citerne = somme des stocks ambiants (tous propriétaires confondus)
   ```

3. La répartition par propriétaire se fait **exclusivement sur la base ambiante**.

4. Le stock à 15°C :
   - est calculé par propriétaire,
   - puis agrégé,
   - mais ne définit jamais la capacité ni la disponibilité réelle.

---

## 6. 📊 Règles d'agrégation (Dashboard & KPI)

### 6.1 Stock total dépôt

Le stock total affiché doit être :

```
Stock total (ambiant) = somme des stocks ambiants de toutes les citernes
```

Le stock à 15°C :

- est affiché comme information secondaire,
- explicitement libellé comme tel.

### 6.2 Stock par propriétaire

Pour chaque propriétaire :

```
Stock propriétaire (ambiant) = somme des stocks ambiants de ce propriétaire
```

Le stock à 15°C :

- est calculé en parallèle,
- affiché comme valeur normalisée,
- jamais confondu avec le stock réel.

---

## 7. 🖥️ Règles d'affichage (UX contractuelle)

### 7.1 Hiérarchie visuelle obligatoire

1. **Stock ambiant** (prioritaire, en premier)
2. **Stock à 15°C** (secondaire, indicatif)

#### Exemple conforme :

```
Stock total dépôt
7 500 L (ambiant)
≈ 7 311 L @15°C
```

#### Exemple interdit :

```
Stock total
7 311 L
```

### 7.2 Toute carte, tableau ou KPI affichant un stock DOIT :

- préciser s'il s'agit d'ambiant ou de 15°C,
- afficher l'ambiant en premier.

---

## 8. ❌ Interdictions explicites

Il est strictement interdit de :

1. **Piloter une citerne sur base du stock à 15°C**
2. **Afficher un stock sans préciser son type**
3. **Sommer des volumes 15°C pour déterminer une disponibilité physique**
4. **Recalculer un stock ambiant à partir du 15°C**

---

## 9. 🧠 Règle de décision opérationnelle

**Toute décision terrain** (chargement, sortie, validation, capacité) se fait **exclusivement sur le stock ambiant**.

Le stock à 15°C :

- ne bloque jamais une opération,
- n'autorise jamais une opération,
- sert uniquement à l'analyse et au reporting.

---

## 10. 🏁 Conclusion officielle

> **ML_PP MVP est conçu pour piloter un dépôt réel, pas un modèle théorique.**

👉 **Le stock ambiant est la réalité.**  
👉 **Le stock à 15°C est une normalisation.**  
👉 **Les deux coexistent, mais n'ont pas le même pouvoir métier.**

---

## 11. 📋 Checklist de conformité

### Pour les développeurs

- [ ] Les volumes ambiants sont toujours enregistrés en premier
- [ ] Les volumes 15°C sont calculés à partir de l'ambiant (jamais l'inverse)
- [ ] Les agrégations de stock utilisent l'ambiant comme base
- [ ] Les affichages précisent toujours le type (ambiant ou 15°C)
- [ ] Les validations métier (capacité, disponibilité) utilisent l'ambiant

### Pour les tests

- [ ] Les tests vérifient que l'ambiant est la source primaire
- [ ] Les tests vérifient que le 15°C est dérivé de l'ambiant
- [ ] Les tests vérifient que les agrégations utilisent l'ambiant
- [ ] Les tests vérifient que les affichages sont correctement libellés

### Pour les revues de code

- [ ] Aucun calcul de disponibilité basé sur le 15°C
- [ ] Aucun recalcul d'ambiant à partir du 15°C
- [ ] Tous les affichages précisent le type de volume
- [ ] L'ambiant est toujours affiché en premier

---

## 12. 🔗 Références

- **Documentation technique** : `docs/db/stocks_rules.md`
- **Vues SQL** : `v_kpi_stock_global`, `v_kpi_stock_owner`, `v_stocks_citerne_global`
- **Table stocks_journaliers** : Colonnes `stock_ambiant`, `stock_15c`
- **Fonction de calcul** : `stock_upsert_journalier()`

---

## 13. 📝 Historique des modifications

| Date | Version | Auteur | Modification |
|------|---------|--------|--------------|
| 2025-12-13 | 1.0 | Équipe ML_PP MVP | Création du référentiel officiel |

---

**Document de référence officiel – Ne pas modifier sans validation métier**

