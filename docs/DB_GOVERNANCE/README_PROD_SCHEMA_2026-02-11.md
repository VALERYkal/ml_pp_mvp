CHARTE DB STRICT — ML_PP PROD
Version : 2026-02-11
Référence snapshot : docs/DB_SNAPSHOTS/ml_pp_prod_schema_public_2026-02-11.sql
1. OBJECTIF
Cette charte définit les règles intangibles de la base de données PROD de ML_PP MVP (Monaluxe Petrol Platform).
Elle garantit :
Intégrité métier
Traçabilité complète
Non-régression des invariants logistiques
Sécurité RLS stricte
Évolutivité contrôlée POST-PROD
Toute évolution doit respecter cette charte.
2. PRINCIPE FONDATEUR
🔴 La base de données est la source de vérité métier.
Le frontend Flutter n’est qu’un client.
Les règles critiques sont implémentées en SQL (triggers, contraintes, RLS).
Aucune logique critique ne doit exister uniquement côté application.
3. INVARIANTS STRUCTURELS (NON NÉGOCIABLES)
3.1 Flux Logistique Canonique
Le flux validé en PROD est :
Cours de Route (CDR)
        ↓
Réception validée
        ↓
stocks_snapshot (source réelle)
        ↓
v_stock_actuel (vue contractuelle)
        ↓
Sortie validée
Il est interdit de :
Modifier ce flux
Court-circuiter un trigger
Mettre à jour directement les stocks
3.2 Stock — Source de Vérité
Source réelle :
public.stocks_snapshot
Corrections contrôlées :
public.stocks_adjustments
Vue contractuelle :
public.v_stock_actuel
Journal :
public.stocks_journaliers
🔒 Écriture bloquée hors triggers
⚠️ Toute lecture métier doit utiliser v_stock_actuel.
⚠️ Toute écriture stock doit passer par les triggers réception/sortie.
4. TRIGGERS PROTÉGÉS (INTERDIT DE MODIFIER SANS MIGRATION VERSIONNÉE)
Réceptions
reception_after_ins_trg
receptions_check_cdr_arrive
receptions_block_update_delete
Sorties
sorties_before_validate_trg
sorties_after_insert_trg
sorties_produit_block_update_delete
Stock
stocks_journaliers_block_writes
stock_snapshot_apply_delta
Toute modification nécessite :
Migration SQL versionnée
Snapshot DB
Documentation dans /docs/DB_SNAPSHOTS
Validation STAGING
Runbook
5. RLS — SÉCURITÉ STRICTE
5.1 Rôles Autorisés en PROD
Selon CHECK constraint profils.role :
admin
directeur
gerant
lecture
pca
⚠️ Aucun autre rôle n’est autorisé.
5.2 Règle Absolue
Il est interdit :
D’utiliser un rôle absent du CHECK
De créer un rôle côté app uniquement
De modifier une policy RLS sans migration formelle
Toute modification RLS nécessite :
Audit des policies existantes
Test complet des permissions
Documentation explicite
6. STATUTS MÉTIER
6.1 Legacy MVP (existants en PROD)
CDR (MAJUSCULES ASCII)
CHARGEMENT
TRANSIT
FRONTIERE
ARRIVE
DECHARGE
Réceptions
validee
rejetee
Sorties
brouillon
validee
rejetee
Ces statuts sont protégés par CHECK constraints.
6.2 Règle POST-PROD
Nouveaux statuts → MAJUSCULES ASCII uniquement
Aucun remplacement de statut legacy
Toute évolution = migration versionnée
7. LOG CENTRAL UNIQUE
Table : public.log_actions
Colonnes clés :
action
module
niveau
details
user_id
created_at
🔴 Il est interdit de créer une seconde table d’audit.
Toute nouvelle fonctionnalité POST-PROD doit écrire dans log_actions.
8. INTERDICTIONS ABSOLUES
Il est interdit :
D’écrire directement dans stocks_snapshot
D’écrire directement dans stocks_journaliers
De modifier une FK en PROD sans snapshot préalable
De supprimer une contrainte
De modifier un CHECK sans migration documentée
D’ajouter des colonnes dans les tables cœur (receptions, sorties_produit, stocks_snapshot) sans justification formelle
9. ÉVOLUTION POST-PROD — RÈGLES
9.1 Extensions autorisées
Nouvelles tables métiers (finance, AR, fournisseurs)
Nouvelles vues
Fonctions isolées
Tables liées par FK (sans modifier cœur MVP)
9.2 Exemple correct
✔️ Table bons_livraison
FK vers sorties_produit
sortie_id UNIQUE
Aucun changement dans sorties_produit
9.3 Exemple interdit
❌ Ajouter colonnes commerciales dans sorties_produit
10. PROCÉDURE OBLIGATOIRE POUR TOUT CHANGEMENT PROD
Snapshot DB
Rédaction migration SQL versionnée
Test STAGING
Documentation
PR obligatoire
Validation CI
Merge
Tag
Aucune modification directe en PROD.
11. RESPONSABILITÉ
Toute personne (dev ou IA) intervenant sur la DB PROD :
Doit lire cette charte
Doit lire le snapshot courant
Doit respecter les invariants
Ignorer cette charte expose à :
Corruption stock
Incohérence KPI
Blocage RLS
Perte traçabilité
12. STATUT
Cette charte est active à compter du 2026-02-11
Référence commit snapshot : 84e5351
✅ CONCLUSION
ML_PP PROD repose sur :
DB centralisée
Triggers sécurisés
RLS stricte
Snapshot comme vérité
Journal unique
Toute évolution doit préserver ces fondations.
