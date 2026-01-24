# Documentation ML_PP MVP — Manifeste IA-First

## 🎯 Objectif
Cette documentation est conçue pour permettre :
- une **maintenance fiable par une intelligence artificielle**
- une reprise humaine sans dépendance au contexte oral
- une évolution du système **sans régression métier ou technique**

Toute modification du code, de la base de données ou de l’architecture
doit être précédée par la lecture des sections appropriées ci-dessous.

---

## 🧠 Principe fondamental (NON NÉGOCIABLE)

> **REFERENCE > DECISIONS > RUNBOOKS > PLANS > TESTING > ARCHIVE**

En cas de contradiction :
- `00_REFERENCE` fait toujours foi
- `01_DECISIONS` interdit de “re-décider”
- `02_RUNBOOKS` dicte comment agir
- `04_PLANS` peut évoluer
- `03_TESTING` guide l’exécution
- `90_ARCHIVE` ne doit jamais guider une décision active

---

## 📂 Structure officielle de la documentation

### `00_REFERENCE/` — Sources de vérité (CONTRACTUELLES)
À lire **avant toute modification**.
- PRD
- logique métier
- schémas DB
- architecture
- user stories
- contrats transactionnels

❌ Ne jamais modifier sans décision formelle.

---

### `01_DECISIONS/` — Décisions actées (ADR-like)
Explique **pourquoi** certaines options ont été choisies.
- audits
- validations officielles
- clôtures d’axes
- durcissements DB

❌ Ne pas remettre en question sans nouveau document de décision.

---

### `02_RUNBOOKS/` — Procédures opérationnelles
Explique **quoi faire quand X arrive**.
- release gate
- staging
- incidents
- post-mortems
- prod-ready status

✅ Prioritaire pour l’IA en situation d’exécution.

---

### `04_PLANS/` — Plans & roadmaps
Explique **ce qui est prévu**.
- sprints
- roadmaps
- plans d’exécution
- modernisations

⚠️ Peut devenir obsolète → vérifier date & contexte.

---

### `03_TESTING/` — Stratégie & conventions de tests
Explique **comment tester sans casser**.
- guides de tests
- conventions CI
- DB strict testing
- analyses de bugs structurantes

Obligatoire avant toute création/modification de tests.

---

### `90_ARCHIVE/` — Historique figé
Traçabilité, audits, états passés.
❌ Ne jamais utiliser comme source active de décision.

---

## 🚦 Règles pour toute IA mainteneuse

1. Lire `README_DOCS.md` **en premier**
2. Lire `00_REFERENCE/` avant tout changement métier ou DB
3. Vérifier `01_DECISIONS/` avant toute refactorisation “intelligente”
4. Suivre `02_RUNBOOKS/` pour toute action sensible
5. Ne jamais baser une décision sur `90_ARCHIVE/`

---

## ✅ État
Documentation :
- structurée
- cohérente
- prête pour maintenance IA long terme

Dernière refonte majeure : **Janvier 2026**

