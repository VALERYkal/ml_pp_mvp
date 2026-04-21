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
- Schéma **ASTM** désormais accessible en PROD pour les rôles applicatifs requis (`authenticated`, `anon`) ; incident Réception PROD `403/42501` résolu (grant `USAGE` sur schéma `astm`)
- Pack canonique et **invariants VOL15** synchronisés (`docs/system_invariants.md`, `docs/CONTEXT/system_invariants.md`)
- **Lot fournisseur** introduit et **industrialisé** (STAGING + PROD) :
  - table `public.fournisseur_lot`
  - relation optionnelle `cours_de_route.fournisseur_lot_id`
  - **intégrité CDR ↔ lot garantie par la DB** (trigger)
  - **workflow statut lot porté par la DB** :
    - `ouvert → cloture → facture`
    - transitions invalides bloquées
  - module frontend aligné (UI pilotée par DB)
  - couverture app : création lot, liste `/cours/lots`, `/cours/lots/new`, lien formulaire / détail CDR, colonne **Réf. lot** desktop ; liste CDR : **Nouveau camion**, **Lot fournisseur**, **Dépôt** retiré du tableau desktop — **sans** changement du pilotage **`statut`** CDR en DB.
- **Finance fournisseur lot** :
  - module **actif en PROD** (**GO contrôlé** — déploiement **2026-04-12**, voir sections dédiées ci-dessous)
  - **read model durci (2026-04-19)** : **`public.v_fournisseur_facture_lot`** = **source de lecture consolidée** pour **rapprochement** et **paiement affiché** (recalcul **`montant_regle_usd` / `solde_restant_usd` / `statut_paiement`** en vue depuis agrégat **`fournisseur_paiement_lot_min`**) ; enrichissements lecture **`lot_reference`**, **`fournisseur_nom`** ; **STAGING** validé sur cas réels ; **PROD** : **structure et vues alignées** + **index unique** confirmé — **aucune facture** en PROD au moment du contrôle → **validation structurelle** uniquement ; **validation métier** sur premier cas réel ou test contrôlé **à planifier**
  - **UI V1 opérationnelle**
  - **création facture** disponible
  - **paiement** : écriture **`fournisseur_paiement_lot_min`** ; lecture soldes / statut paiement **via la vue** (pas de recalcul Flutter)
  - **rapprochement** en lecture via **vues** (**LEFT JOIN**, **`A_RAPPROCHER`**)
  - **verrouillage métier** : **1 lot fournisseur = 1 facture fournisseur active** (**`idx_fournisseur_facture_lot_min_one_facture_per_lot`** — STAGING + PROD)
  - **build Flutter Web** : **`build/web`** régénéré avec succès pendant la session ; **déploiement Firebase** : **non attesté comme terminé** dans ce document
- **Bridge Dart** : `lib/features/lots_finance/` — modèles (`fromMap` / `toMap`), service Supabase, providers Riverpod ; lecture via **vues** ; écriture facture via **`fournisseur_facture_lot_min`** (insert minimale, relecture vue) ; écriture paiement via **`fournisseur_paiement_lot_min`** ; **sans** logique métier financière côté app.
- **Tests** : `test/features/lots_finance/` (modèles, providers, écrans / widgets ciblés) — verts sur le périmètre lots_finance.

---

# NOUVEAU MODULE — FINANCE FOURNISSEUR LOT

- **Chaîne métier** : **LOT** → **Σ réceptions** → **total @20 °C** → **facture** → **rapprochement** → **paiement** ; pivot **`fournisseur_lot`**.
- **Lecture consolidée** : **`public.v_fournisseur_facture_lot`** expose notamment **`facture_id`**, **`invoice_no`**, **`deal_reference`**, **`fournisseur_lot_id`**, **`nb_receptions`**, **`total_volume_15c`**, **`total_volume_20c`**, **`quantite_facturee_20c`**, **`ecart_volume_20c`**, **`statut_rapprochement`**, **`prix_unitaire_usd`**, **`montant_total_usd`**, **`montant_regle_usd`**, **`solde_restant_usd`**, **`statut_paiement`**, **`date_facture`**, **`date_echeance`**, **`created_at`**, **`lot_reference`**, **`fournisseur_nom`** (enrichissement fin de définition de vue : **`LEFT JOIN`** `fournisseur_lot` **`fl`**, **`LEFT JOIN`** `fournisseurs` **`fo`**).
- **Rapprochement lecture** :
  - **`statut_rapprochement`** : **calculé uniquement dans les vues** (`public.v_fournisseur_facture_lot`, `public.v_fournisseur_rapprochement_lot_min`) — **pas** comme vérité d’affichage sur la seule colonne table
  - **LEFT JOIN** sur l’agrégat réceptions : **visibilité** des factures **sans agrégat** exploitable
  - statut de lecture **`A_RAPPROCHER`** : **validé en STAGING** — facture sans agrégat réception → **`nb_receptions` NULL**, **`total_volume_20c` NULL** → **`statut_rapprochement = A_RAPPROCHER`** ; cas avec agrégat → **`LITIGE`** observé conforme attendu
  - distinction **`fournisseur_lot.statut`** vs existence **`fournisseur_facture_lot_min`** : `docs/db/critical_objects.md`
- **Paiement affiché (lecture)** : **`montant_regle_usd`**, **`solde_restant_usd`**, **`statut_paiement`** issus du **recalcul en vue** (agrégat **`SUM(montant_paye_usd)`** sur **`fournisseur_paiement_lot_min`** joint sur **`p.fournisseur_facture_id = f.id`**) — **pas** la lecture directe des colonnes homonymes persistées sur **`fournisseur_facture_lot_min`** pour l’affichage métier ; **correction** documentée : avant correction, cas **sans paiement** pouvait afficher **`solde_restant_usd = 0`** avec **`montant_total_usd > 0`** ; après correction : cas sans paiement validés en STAGING (**`montant_regle_usd = 0`**, **`solde_restant_usd = montant_total_usd`**, **`statut_paiement = A_PAYER`**) ; cas partiel validé (**`PARTIEL`** avec soldes cohérents). Les **triggers** après insert paiement (**`trg_fournisseur_paiement_lot_min_after_ins`**, **`trg_fournisseur_paiement_lot_min_check_overpay`**) **restent en place** ; le **correctif principal** porté par la **vue** — l’UI **ne doit pas** déduire paiement depuis seules les colonnes table.
- **Création facture** : `INSERT` dans **`fournisseur_facture_lot_min`** ; relecture via **`v_fournisseur_facture_lot`**
- **Unicité lot → facture** : **index unique** côté DB sur **`fournisseur_lot_id`** ; second enregistrement même lot → **blocage** (erreur **`23505`**)
- **Objets DB (PROD)** :
  - fonction : `public.compute_volume_20c_from_reception(...)`
  - vues : `public.v_reception_20c`, `public.v_fournisseur_rapprochement_lot_min`, `public.v_fournisseur_facture_lot`
  - tables : `public.fournisseur_facture_lot_min`, `public.fournisseur_paiement_lot_min`
  - triggers sur `public.fournisseur_paiement_lot_min` : `trg_fournisseur_paiement_lot_min_after_ins` (recalcul totaux facture après insert paiement), `trg_fournisseur_paiement_lot_min_check_overpay` (blocage surpaiement).
- **Statut** : déploiement PROD en **GO contrôlé / sous surveillance** ; pas d’équivalence avec un périmètre « figé » sans retour terrain.
- **Projection @20 °C** : **approximation contrôlée**, héritée du **prototype STAGING** puis répliquée en PROD ; **provisoire** — **ne pas** la traiter comme volumétrie métier définitivement validée (voir `docs/DB/prod_status.md`, points de vigilance).
- **UI V1** : écrans **liste factures lot**, **détail facture lot**, **création facture**, **ajout paiement** (écran dédié + route **`/finance/factures-lot/:factureId/add-paiement`**) ; navigation **GoRouter** (`/finance/factures-lot`, `/finance/factures-lot/:factureId`, …) ; interaction utilisateur réelle ; module **utilisable** côté app (lecture **vues** ; écriture **tables minimales** ; **sans** calcul métier frontend).

---

## FINANCE LOT — UI V1

- **Écrans** : liste factures lot ; détail facture lot ; **création facture** ; **ajout paiement** (écran **`AddPaiementFactureScreen`**).
- **Navigation** : routes GoRouter intégrées au shell existant ; entrée menu **Finance lot** (`/finance/factures-lot`).
- **Création facture (C1)** : flux dédié ; persistance **`fournisseur_facture_lot_min`** ; relecture liste / détail via **vues**.
- **Filtrage lots facturables (C2)** : lots **déjà facturés** exclus du formulaire de création ; alignement avec la règle **1 lot = 1 facture active** ; doublon intercepté côté DB (**`23505`**) si contournement.
- **Lecture** : factures et agrégats via **`v_fournisseur_facture_lot`** (soldes / **`statut_paiement`** / rapprochement **tels que la vue**) ; liste historique paiements : lecture **`fournisseur_paiement_lot_min`** ou champs déjà portés par la vue selon l’écran — **aucun** recalcul `volume_20c`, `statut_rapprochement`, `montant_regle`, `solde`, `statut_paiement` côté Flutter.
- **Écriture** : facture via **`fournisseur_facture_lot_min`** ; paiement via **`fournisseur_paiement_lot_min`** ; refresh post-action (invalidation providers lecture).
- **Logique métier** : **absente** du frontend sur le périmètre finance lot (pas d’arbitrage rapprochement / volumétrie / statuts de lecture hors contrats DB + vues).
- **Projection @20 °C** : toujours **provisoire** (inchangé côté vérité métier).

### Cadrage UX / direction produit (session 2026-04-19)

- **Non revendiqué comme entièrement implémenté** dans le code : libellés métier plus lisibles pour les statuts UI dérivés (**ex.** `LITIGE` → « Litige fournisseur », `A_CONTROLER` → « À vérifier », `A_PAYER` → « À payer », `EN_COURS` → « Paiement en cours », `SOLDE` → « Soldée ») ; **affichage** attendu **`fournisseur_nom`** + **`lot_reference`** (données **déjà** portées par la vue en lecture) ; priorisation **dashboard** ; **détail facture** orienté compréhension rapide ; **ajout paiement** = saisie simple, **validation finale** (surpaiement, etc.) **en DB**. Le **« statut global »** reste un **mapping UX** (`getStatutGlobal` côté app) — **pas** une colonne métier DB.

---

## FINANCE LOT — RÈGLES MÉTIER CRITIQUES

- **1 lot = 1 facture active** (unicité **`fournisseur_lot_id`** en base)
- **Vérité** = **existence des lignes** dans les tables / résultats **vues** — pas de double source applicative
- **Rapprochement** = **définition portée par les vues DB**
- **Aucun calcul** de rapprochement / volumétrie finance lot **côté frontend**

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
- Hardening DB du module lot fournisseur :
  - trigger `trg_cours_de_route_enforce_fournisseur_lot`
  - validation cohérence fournisseur / produit / statut
  - blocage des rattachements invalides CDR ↔ lot
- Implémentation du workflow statut lot en DB :
  - fonction `check_fournisseur_lot_statut_transition`
  - trigger `trg_fournisseur_lot_statut_transition`
  - contrainte CHECK sur les statuts
  - transitions strictement contrôlées
- **Finance fournisseur lot (2026-04-19)** — **vue** **`v_fournisseur_facture_lot`** : recalcul **lecture** paiement depuis **`fournisseur_paiement_lot_min`** (corrige affichage **sans paiement**) ; enrichissements **`lot_reference`** / **`fournisseur_nom`** ; **PROD** : alignement structurel + **index unique** ; **triggers** paiement **inchangés** dans leur rôle (pas de remplacement par évolution UI).

---

# ÉTAT ACTUEL ALIGNEMENT

- Module CDR désormais aligné avec la DB (aucune divergence état/statut)
- STAGING et PROD **alignés sur la logique critique** du débit sortie @15 °C dans **`sorties_after_insert_trg()`**.
- **Aucun écart bloquant restant** sur ce pipeline stock (after-insert sortie) pour le volume @15 °C, sous réserve de vérification continue via `docs/DB/prod_status.md` / `docs/DB/staging_status.md`.
- Incident critique Réception PROD (403 / `permission denied for schema astm`) **clos** : pipeline Réception revalidé en PROD (`CDR ARRIVE → réception → volume_15c → stock → log_actions`).
- Garde-fou SQL des grants critiques ASTM exécuté et validé **vert** sur STAGING et PROD (USAGE schéma + EXECUTE fonctions + présence/câblage trigger Réception).
- Divergence résiduelle STAGING/PROD sur `public.receptions_compute_15c_before_ins()` : garde `app_settings/env` encore présente uniquement en STAGING ; **non causale** sur l’incident, suivi d’alignement restant ouvert.
- Autres écarts **non bloquants** possibles (doc, traçabilité migrations) : voir **ALIGNEMENT STAGING / PROD** ci-dessus.
- Module lot fournisseur :
  - STAGING et PROD alignés sur :
    - intégrité CDR ↔ lot
    - workflow statut lot
  - aucune divergence connue sur ce périmètre

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
- C4 infra hardening minimal en place : garde-fou SQL grants ASTM versionné + checklist PRE-DB CHANGE documentée
- Enrichissement **CDR** par structuration amont **lot fournisseur** (relation optionnelle, vérité toujours `statut` + réception pour le stock)
- Stabilisation du module lot fournisseur (intégrité + workflow DB)
- Préparation des évolutions :
  - audit des transitions lot
  - observabilité métier
- Pistes prioritaires : observabilité stock, audit automatique DB / staging–prod, hardening tests / monitoring

---

# ZONES STABLES (NE PAS MODIFIER)

- Réception
- Stock (calcul DB)
- Moteur ASTM
- Triggers, fonctions et vues critiques
- **Pipeline VOL15 côté frontend** (contrat de lecture, services DB-first sur le périmètre traité) — considéré stable ; **ne pas refactorer sans besoin réel**
- Module lot fournisseur (intégrité DB + workflow statut) considéré comme stable
- Toute modification doit passer par migration et validation staging

---

# ZONES EN COURS

- Observabilité stock
- Audit automatique DB / alignement staging–prod
- Hardening tests / monitoring
- **UI** module **finance fournisseur lot** : **V1 livrée** (navigation + écrans + paiement + **cadrage UX C3** documenté ci-dessus) ; consolidation terrain et observabilité sous le cadre **GO contrôlé / sous surveillance** (projection 20 °C provisoire inchangée).

---

# NEXT STEP

- Suivi terrain module **finance fournisseur lot** (premiers usages réels, retours métier) sous **GO contrôlé** ; **première validation métier PROD** sur facture / paiement réels ou scénario contrôlé **à exécuter** (voir `docs/db/prod_status.md`) ; pas de revendication d’industrialisation complète sans validation continue.

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
