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
- **VOL15 frontend** aligné (lecture canonique `volume_15c ?? volume_corrige_15c`, pas de vérité volumétrique critique côté app)
- **DB tests STAGING** du pipeline critique exécutés avec succès (voir **VALIDATION STAGING RÉCENTE**)
- Schéma **ASTM** accessible côté STAGING ; **RLS**, **stock**, **réception**, **sortie** validés sur ce périmètre en STAGING
- Pack canonique et **invariants VOL15** synchronisés (`docs/system_invariants.md`, `docs/CONTEXT/system_invariants.md`)

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

- Refactor CDR: suppression complète de la machine d’état applicative (`etat`, `CdrEtat`, `applyTransition`)
- Alignement total avec la DB: `statut` devient la seule source de vérité
- Suppression des écritures vers un champ non existant en base (`etat`)
- Simplification du module CDR et réduction de dette technique
- Fix alignement STAGING / PROD sur **`sorties_after_insert_trg()`**.
- Correction du **débit stock @15 °C** en sortie (after-insert).
- Harmonisation volumétrique sortie : **`COALESCE(NEW.volume_15c, NEW.volume_corrige_15c, 0)`** pour journal, snapshot et `log_actions.details.volume_15c`.

---

# ÉTAT ACTUEL ALIGNEMENT

- Module CDR désormais aligné avec la DB (aucune divergence état/statut)
- STAGING et PROD **alignés sur la logique critique** du débit sortie @15 °C dans **`sorties_after_insert_trg()`**.
- **Aucun écart bloquant restant** sur ce pipeline stock (after-insert sortie) pour le volume @15 °C, sous réserve de vérification continue via `docs/DB/prod_status.md` / `docs/DB/staging_status.md`.
- Autres écarts **non bloquants** possibles (doc, traçabilité migrations) : voir **ALIGNEMENT STAGING / PROD** ci-dessus.

---

# VALIDATION STAGING RÉCENTE

Constats issus des **DB tests** et vérifications manuelles sur **STAGING** (pas de revendication de rejeu complet des mêmes tests sur PROD).

- Smoke test STAGING (connectivité / base) OK
- Réception → **`stocks_journaliers`** OK
- Sortie → stock → **`log_actions`** OK
- RLS : insert admin OK ; insert non-admin refusé OK ; select lecture OK
- **VOL15** frontend + comportement DB sur le périmètre critique validé en STAGING

---

# FOCUS ACTUEL

- Stabilisation post-validation STAGING (pipeline critique app + DB + RLS)
- Gouvernance du pack canonique maintenue
- Pistes prioritaires : observabilité stock, audit automatique DB / staging–prod, hardening tests / monitoring

---

# ZONES STABLES (NE PAS MODIFIER)

- Réception
- Stock (calcul DB)
- Moteur ASTM
- Triggers, fonctions et vues critiques
- **Pipeline VOL15 côté frontend** (contrat de lecture, services DB-first sur le périmètre traité) — considéré stable ; **ne pas refactorer sans besoin réel**

---

# ZONES EN COURS

- Observabilité stock
- Audit automatique DB / alignement staging–prod
- Hardening tests / monitoring

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
- si le **périmètre critique DB** (stock, volumétrie, RLS, réception/sortie, ASTM) est touché : les **DB tests STAGING** pertinents du projet doivent rester **verts** (hors périmètre : pas d’obligation globale sur tous les tests du dépôt)
