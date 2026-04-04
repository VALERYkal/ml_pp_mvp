# CURRENT CHECKPOINT — ML_PP MVP

## ROLE
Point d’entrée principal pour comprendre l’état actuel du système et agir sans dérive.

## UPDATE FREQUENCY
À chaque modification significative (DB, logique métier, structure, règles).

## LECTURE ORDER
1. current_checkpoint.md
2. architecture_rules.md
3. architecture_map.md
4. DB/critical_objects.md

---

# PROJECT STATUS

- Application en production
- Système logistique stable
- Moteur volumétrique ASTM actif (lookup-grid)
- STAGING et PROD alignés sur les fondamentaux critiques
- DB = source de vérité

---

# ALIGNEMENT STAGING / PROD

Constats issus de `docs/DB/staging_status.md` et `docs/DB/prod_status.md` (investigations 2026-04-04).

| Écart (avant correction) | Impact métier | Statut |
|--------------------------|---------------|--------|
| **`public.sorties_after_insert_trg()`** : PROD débitait le stock @15 °C avec **`volume_corrige_15c` seul** ; STAGING utilisait **`COALESCE(NEW.volume_15c, NEW.volume_corrige_15c, 0)`**. | Sortie avec **`volume_15c` renseigné** et **`volume_corrige_15c` NULL** → risque de **débit 0** @15 °C (incohérence stock / snapshot / journal). | **Corrigé en PROD** (2026-04-04) — fonction alignée sur STAGING ; migration versionnée : `supabase/migrations/20260404120000_sorties_after_insert_trg_coalesce_volume_15c.sql`. |
| Doc pouvant citer `receptions_apply_effects()` / `fn_sorties_after_insert()` vs wiring réel `reception_after_ins_trg()` / `sorties_after_insert_trg()`. | Risque d’intervention sur le mauvais objet. | **Non corrigé** (désalignement documentaire partiel — hors périmètre de la correction ci-dessus). |
| Dernière migration Supabase : entrée exacte **non confirmée** sur les instances inspectées. | Traçabilité release imparfaite. | **Non corrigé** (constat uniquement). |

**ÉCART CRITIQUE (rappel) :** `sorties_after_insert_trg()` — PROD utilisait **`volume_corrige_15c` seul** ; STAGING **`COALESCE(volume_15c, volume_corrige_15c)`**. **Statut : corrigé en PROD** (alignement logique after-insert sortie).

---

# FIXES RÉCENTS CRITIQUES

- Fix alignement STAGING / PROD sur **`sorties_after_insert_trg()`**.
- Correction du **débit stock @15 °C** en sortie (after-insert).
- Harmonisation volumétrique sortie : **`COALESCE(NEW.volume_15c, NEW.volume_corrige_15c, 0)`** pour journal, snapshot et `log_actions.details.volume_15c`.

---

# ÉTAT ACTUEL ALIGNEMENT

- STAGING et PROD **alignés sur la logique critique** du débit sortie @15 °C dans **`sorties_after_insert_trg()`**.
- **Aucun écart bloquant restant** sur ce pipeline stock (after-insert sortie) pour le volume @15 °C, sous réserve de vérification continue via `docs/DB/prod_status.md` / `docs/DB/staging_status.md`.
- Autres écarts **non bloquants** possibles (doc, traçabilité migrations) : voir **ALIGNEMENT STAGING / PROD** ci-dessus.

---

# FOCUS ACTUEL

- Mise en place du pack canonique IA
- Structuration documentaire
- Sécurisation des interactions IA

---

# ZONES STABLES (NE PAS MODIFIER)

- Réception
- Stock (calcul DB)
- Moteur ASTM
- Triggers, fonctions et vues critiques

---

# ZONES EN COURS

- Documentation canonique
- Gouvernance IA

---

# RISQUES

- Modification des triggers DB
- Altération des vues de stock
- Désalignement staging / prod
- Utilisation de docs non alignés avec la DB

---

# SOURCES DE VÉRITÉ

- DB → vérité métier (stock, volumétrie, logique)
- Invariants → règles
- Code → implémentation
- Pack canonique → représentation contrôlée

---

# ORDRE DE LECTURE IA

1. CONTEXT
2. DB
3. DB_GOVERNANCE
4. REFERENCE
5. SUPPORT

---

# RÈGLES CRITIQUES

- Ne jamais modifier la DB sans migration
- Ne jamais recalculer le stock côté application
- Ne jamais implémenter de logique métier critique en frontend
- Toujours valider staging avant prod
- Ne jamais inventer :
  - tables
  - champs
  - logique métier

---

# QUAND VÉRIFIER LA DB

Vérification obligatoire si :
- modification DB
- logique métier critique
- incohérence détectée
- doute sur stock ou volume

Sinon :
- se fier au pack canonique

---

# COMMANDES IA

- respecte strictement current_checkpoint.md
- vérifie architecture_rules.md
- vérifie la DB si nécessaire
- ne touche pas aux zones stables
- propose sans casser la DB

---

# DEFINITION OF DONE

Une modification est validée si :
- respecte les règles
- ne casse aucune zone stable
- validée en staging si DB impactée
- cohérente avec la DB
- pack canonique mis à jour
