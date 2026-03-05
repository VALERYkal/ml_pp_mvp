# RUNBOOK PROD — ASTM53B (API MPMS 11.1) Migration

## 1. Objectif
Migration volumétrique vers ASTM 53B (15°C) + validation DB-STRICT validate_sortie.

## 2. Risques
- Impact sur stock réel
- Impact sur 8 réceptions déjà en PROD
- 2 camions non encore encodés
- Risque dérive volumétrique vs application terrain SEP

## 3. Pré-requis

### 3.1 Backup obligatoire PROD
- Dump complet base (schema + data)
- Export séparé des fonctions public.validate_sortie et public.sorties_produit_block_update_delete
- Snapshot table stocks_journaliers
- Snapshot table sorties_produit
- Snapshot table receptions

Aucune modification PROD sans dump vérifié.

### 3.2 Données terrain (ASTM)
- Récupérer les valeurs exactes calculées par l'application SEP pour les 8 réceptions GASOIL déjà en PROD
- Obtenir température observée, densité observée, volume ambiant
- Construire golden comparison cases ML_PP vs SEP

### 3.3 Camions en attente
- Identifier précisément les 2 camions non encore encodés
- Confirmer qu'ils seront encodés uniquement après validation ASTM PROD

### 3.4 Fenêtre d'intervention
- Définir créneau horaire faible activité
- Interdire toute saisie réception/sortie pendant la migration
- Informer l'équipe dépôt

### 3.5 STAGING — Reset CDR only (préparation tests ASTM/UX)

Un **reset STAGING "CDR only"** est requis avant certains tests ASTM/UX pour éviter la pollution historique et valider les golden cases sur une base propre. Le script SQL rejouable est :

`docs/DB_CHANGES/2026-02-25_staging_reset_cdr_only.sql`

- **Pourquoi** : Repartir sur une base saine (receptions=0, sorties_produit=0, stocks_journaliers=0, log_actions scopés=0) tout en conservant **cours_de_route** (CDR inchangé). Compatible DB-STRICT (flags transactionnels).
- **Quand** : Avant une campagne de tests d'intégration B2.2 ou validation moteur ASTM si l'environnement STAGING est pollué.
- **Invariant** : cours_de_route n'est jamais supprimé ; seules les tables de mouvement stock sont purgées.

## 4. Étapes techniques

### 4.1 Freeze opérationnel
- Interdire toute saisie réception / sortie
- Confirmer aucun utilisateur actif sur modules stock

### 4.2 Backup PROD
- pg_dump complet (schema + data)
- Export des fonctions :
  - public.validate_sortie
  - public.sorties_produit_block_update_delete
- Vérifier que le dump est stocké hors serveur PROD

### 4.3 Application SQL (STAGING validé → PROD)

Exécuter le fichier :
docs/DB_CHANGES/2026-02-25_staging_validate_sortie_p0.sql

Vérifier :
- Les 2 fonctions sont bien remplacées
- SECURITY DEFINER présent
- SET search_path = 'public'
- Aucun trigger modifié
- Aucune policy modifiée

### 4.4 Activation applicative

- Déployer version Flutter contenant :
  - moteur ASTM53B
  - router volume15c activable via feature flag
- Laisser feature flag ASTM OFF initialement

### 4.5 Test contrôlé

1. Activer feature flag ASTM
2. Encoder un camion test (non critique)
3. Comparer ML_PP vs SEP
4. Vérifier stocks_journaliers
5. Vérifier log_actions

Si OK → continuer.
Si NOK → rollback immédiat (section 6).

## 5. Smoke tests PROD

### 5.1 Test connexion DB
- Vérifier accès Supabase PROD
- Exécuter requête simple sur depots
- Vérifier aucune erreur RLS

### 5.2 Test lecture stock initial
- Lire stocks_journaliers pour une citerne active
- Noter stock_ambiant et stock_15c avant test

### 5.3 Test réception contrôlée
- Encoder réception test avec :
  - volume ambiant connu
  - température connue
  - densité observée connue
- Vérifier :
  - volume_corrige_15c cohérent
  - crédit correct dans stocks_journaliers
  - log_actions contient RECEPTION_CREEE

### 5.4 Test sortie contrôlée
- Encoder sortie test
- Valider via RPC validate_sortie
- Vérifier :
  - débit correct stock_15c
  - statut = validee
  - log_actions contient SORTIE_VALIDEE

### 5.5 Test cohérence post-opération
- Vérifier absence valeur négative dans stocks_journaliers
- Vérifier aucune ligne dupliquée date_jour/citerne
- Vérifier absence erreur P0001

### 5.6 Validation terrain
- Comparer calcul ML_PP vs application SEP
- Écart toléré maximum : ±5 litres
- Validation écrite responsable dépôt

Si tous les points sont validés → GO.
Sinon → appliquer section 6 (rollback).

### 5.7 Documentation post-intervention

Après intervention :

- Mettre à jour CHANGELOG.md (section [Unreleased] → PROD)
- Documenter date exacte de migration
- Archiver hash commit Flutter déployé
- Archiver dump backup PROD utilisé
- Archiver confirmation terrain SEP (mail / WhatsApp export)
- Noter écarts mesurés (ML_PP vs SEP)

Aucune migration ASTM53B ne sera considérée valide sans ces archives.

## 6. Plan rollback

### 6.1 Condition de rollback immédiat
Rollback obligatoire si :
- Écart > ±5 litres constaté entre ML_PP et SEP sur un golden case
- Incohérence stock_journaliers après validation d'une réception ou sortie
- Erreur P0001 ou blocage RLS inattendu en PROD
- Réclamation terrain dans les 24h suivant déploiement

### 6.2 Procédure technique rollback

1. Désactiver immédiatement toute saisie réception/sortie
2. Restaurer dump complet PROD (schema + data)
3. Vérifier :
   - stocks_journaliers cohérent
   - sorties_produit cohérent
   - receptions cohérent
4. Réactiver application en mode legacy (feature flag OFF)
5. Informer équipe terrain

### 6.3 Communication
- Journaliser incident
- Documenter cause racine
- Mettre à jour runbook
- Aucun nouveau déploiement avant audit

## 7. GO / NO-GO decision
