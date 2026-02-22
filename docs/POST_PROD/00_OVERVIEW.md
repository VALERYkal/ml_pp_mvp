# POST-PROD — Overview

## Contexte
ML_PP (Monaluxe Petrol Platform) est en PROD EN EXPLOITATION depuis le 2026-02-05.
URL active : https://monaluxe.app
Le socle logistique est validé et ne doit pas être modifié.

**Dernière évolution majeure (Feb 2026)** : Phase 2 Action 2 — Governance Integrity avec cycle de vie des alertes (OPEN → ACK → RESOLVED), table `public.system_alerts`, UI enrichie. Dette technique documentée dans `docs/POST_PROD/PHASE2_TECH_DEBT.md`.

## Règle absolue
Toute évolution doit être classée dans une catégorie POST-PROD :
- MAINTENANCE
- AUDIT
- SCALE
- POST-PROD FEATURE

## Invariants intouchables
- Flux métier : CDR → Réception → Stock → Sortie
- Source de vérité stock : v_stock_actuel
- RLS + triggers (sécurité & métier)
- IDs produits canoniques
- Aucun reset PROD
- Aucune suppression destructive (vues, triggers, RLS, contrats)

## Principe POST-PROD
Le POST-PROD ajoute des modules **au-dessus** du socle existant.
Aucune fonctionnalité post-prod ne doit "mélanger" finance/contrats avec les écrans opérationnels.

## Objectif POST-PROD
Faire évoluer ML_PP vers une plateforme ERP pétrolière modulaire :
- Logistique (socle existant)
- Contractuel & financier (nouveaux modules)
- Contrôle (écarts, litiges, audit)

---

## RLS Hardening — Feb 2026

- **Constat** : Audit RLS a révélé des policies `roles = {public}` (dont `SELECT true`) → exposition possible via ANON REST (clé ANON embarquée dans le front Flutter Web).
- **Résultat** : STAGING et PROD durcis — **0 policy `{public}`** restante. Fuites critiques corrigées (ex. `stocks_journaliers`, `citernes`). Toute policy cible désormais `authenticated` (ou rôles explicites) avec conditions.
- **Docs** : `docs/POST_PROD/RUNBOOK_RLS_HARDENING.md`, `12_PHASE2_PROD_DEPLOY_LOG.md` (Entry 2). Standard post-prod : **aucune policy publique** ; revue obligatoire pour toute nouvelle policy.

**Statut README** : Mis à jour (fév 2026) — passage de "Industriel NO-GO" à "Industriel opérationnel" suite au RLS hardening. Voir `README.md` sections « Statut Global », « Maturité Industrielle », « Historique ». Références : [RUNBOOK_RLS_HARDENING.md](RUNBOOK_RLS_HARDENING.md), [PHASE2_TECH_DEBT.md](PHASE2_TECH_DEBT.md).

---

## PROD Operation — Volumetric Migration to ASTM 53B (Gasoil)

**Constat** : Écart volumétrique confirmé entre ML_PP et l'app terrain ASTM : ~50–70 L par opération sur GASOIL. L'app terrain (ASTM 53B) fournit densité observée + température → densité@15 + VCF.

**Risque** : Cumul financier, prévention litiges facturation. Aucune facture fournisseur émise à ce jour ; aucun paiement engagé.

**Statut opérationnel** : **SORTIES FREEZE** en exploitation contrôlée jusqu'à completion de la migration. Deux sorties prévues aujourd'hui dépendent du stock actuel → opérations gelées.

**Périmètre** : GASOIL uniquement ; 8 réceptions depuis début du mois ; 2 citernes ; chronologie validée, aucune édition post-validation.

**Stratégie choisie** : Industriel strict — ML_PP devient la source officielle du calcul volumétrique (moteur ASTM en Dart, résultats stockés en DB avec garde-fous).

**Plan général** : Backup → Validation moteur → Simulation (8 réceptions) → Migration DB → Rebuild stock → Reprise opérations.

**STOP gate** : Aucune modification DB avant backup complet et rapport de simulation validé.

**Runbook** : [RUNBOOK_VOLUMETRICS_ASTM_53B_MIGRATION.md](RUNBOOK_VOLUMETRICS_ASTM_53B_MIGRATION.md)

**Backup PROD 2026-02-21** : `backups/prod_pre_astm53b_20260221_2253_data.dump` — Snapshot de référence avant migration du calcul volume@15°C vers ASTM 53B (réceptions GASOIL).

- **Moteur volumétrique ASTM 53B (Étape A)** : ajout d'un module core dédié (`lib/core/volumetrics/astm53b_engine.dart`) avec API stable (densité observée + température + volume observé → densité@15, VCF, volume@15) et tests unitaires taggés `astm53b`. À ce stade, le moteur lève encore un `UnimplementedError` : aucune formule ASTM n'est utilisée en PROD tant que les golden cases et les tolérances n'ont pas été validés.
