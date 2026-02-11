# POST-PROD — Écarts & Anomalies (v1) — Requirements

## 1. Objectif
Créer un module central **Écarts & Anomalies** qui :
- détecte et trace les différences (volumes, montants, documents),
- permet le traitement (analyse, justification, décision),
- alimente audit, reporting, et futurs litiges.

Le module doit couvrir au minimum :
1) Proforma vs Réception réelle (fournisseur)
2) Sortie/chargé vs Livré client (transport/livraison)
3) Écarts transporteurs (pertes, litiges, ajustements)

---

## 2. Invariants (socle PROD)
- Flux immuable : CDR → Réception → Stock → Sortie
- Stock actuel : v_stock_actuel
- RLS + triggers intacts
- IDs produits canoniques intacts
- Aucun reset PROD, aucune suppression destructive

---

## 3. Définitions
### 3.1 Écart
Différence mesurable entre :
- une **référence attendue** (prévision, document source)
- et une **réalité constatée** (réception, livraison, facture réelle)

Un écart doit être traçable, justifiable, et clôturable.

### 3.2 Anomalie
Événement irrégulier ou incohérent (données manquantes, incohérence de statuts, doublons),
pouvant générer un écart ou nécessiter investigation.

---

## 4. Types d'écarts (v1)

### 4.1 Fournisseur — Proforma vs Réception
**Source attendue** : Proforma (quantités prévues, prix)
**Réel** : Réceptions liées aux CDR de la proforma

Écarts calculés :
- écart volume (par produit)
- écart valeur (si prix applicable)
- écart nombre de camions (si pertinent)

### 4.2 Client — Sortie/chargé vs Livraison
**Attendu** : Volume sorti (chargé) depuis les citernes
**Réel** : Volume livré client (confirmé)

Écarts calculés :
- écart volume ambiant + volume 15°C (si disponible)
- différence par livraison / par client

### 4.3 Transporteur — Sortie/Livraison vs Mission
**Attendu** : Mission et conditions transport
**Réel** : Livraison + confirmations + incidents

Écarts calculés :
- pertes / manquants
- retards / incidents (option v2)
- litiges (si contesté)

---

## 5. Cycle de vie (workflow) — v1

### Statuts
- OPEN (créé / détecté)
- IN_REVIEW (analyse en cours)
- RESOLVED (clos avec décision)
- DISPUTED (litige ouvert, si nécessaire)

### Règle
Un écart ne disparaît jamais :
il passe à un statut final avec justification et auteur.

### Règles de transition
- OPEN → IN_REVIEW : note optionnelle
- IN_REVIEW → RESOLVED : cause + décision + note obligatoire
- IN_REVIEW → DISPUTED : note obligatoire
- RESOLVED/DISPUTED : non modifiables sauf admin

---

## 6. Création des écarts (détection)
Deux modes v1 :

### 6.1 Automatique (recommandé)
Création automatique lorsqu'un document "réel" est validé :
- À validation facture finale : écarts Proforma vs Réceptions (si delta ≠ 0)
- À confirmation livraison : écart Sortie vs Livraison (si delta ≠ 0)

### 6.2 Manuel (obligatoire)
Un utilisateur autorisé peut créer un écart manuellement si :
- données incomplètes
- incident terrain
- contestation

---

## 7. Références & traçabilité (v1)
Chaque écart doit référencer au minimum :
- **reference_type** : PROFORMA / FACTURE_FINALE / RECEPTION / SORTIE / LIVRAISON / MISSION
- **reference_id**

Optionnel : secondary_reference_type / secondary_reference_id (ex. facture finale liée à proforma).

---

## 8. Traitement d'un écart (actions v1)
La clôture RESOLVED exige une note justifiant la décision.
Sur un écart, l'utilisateur peut :

1) **Ajouter une note**
2) **Ajouter une pièce justificative** (lien / référence, v1 simple)
3) **Classer une cause** (liste contrôlée)
4) **Proposer une décision**
5) **Clôturer**

### Causes (v1 — liste simple)
- PERTE_TRANSPORT
- ERREUR_SAISIE
- DIFFERENCE_TEMPERATURE_DENSITE
- MANQUANT_FOURNISSEUR
- LIVRAISON_PARTIELLE
- AUTRE

### Décisions (v1)
- ACCEPTE_AVEC_NOTE (on accepte l'écart)
- AJUSTEMENT_REQUIS (un ajustement document/stock sera fait via module dédié)
- LITIGE (passer DISPUTED)
- ANNULER (rare, admin)

---

## 9. Permissions (v1)
- OPERATEUR : créer écart manuel, ajouter note, passer en IN_REVIEW
- GERANT/DIRECTEUR : clôturer RESOLVED, marquer litige DISPUTED
- FINANCE : consulter + traiter les écarts liés aux factures/paiements
- PCA/LECTURE : lecture seule
- ADMIN : tout (dont ANNULER)

---

## 10. UX (écrans minimum v1)

### 10.1 Écran Liste (centre unique)
Filtres :
- période
- type (fournisseur/client/transporteur)
- statut
- entité (fournisseur/client/transporteur)
- produit (si applicable)

Colonnes :
- date
- type
- entité
- référence (proforma / facture / livraison)
- delta volume
- delta valeur (si applicable)
- statut
- owner (responsable)

### 10.2 Détail écart
Sections :
- Résumé (type, références, delta)
- Historique (notes, changements statut)
- Pièces (v1 : liens)
- Actions (changer statut, clôturer)

---

## 11. Reporting (v1)
KPI minimum :
- nombre d'écarts OPEN
- top causes
- volume total en écart (par produit)
- écarts par fournisseur / client / transporteur

---

## 12. Critères d'acceptation (v1)
- Un écart Proforma vs Réception est créé automatiquement quand delta ≠ 0
- Un écart Sortie vs Livraison est créable manuellement (et automatiquement si livraison confirmée existe)
- La liste affiche filtres + statuts
- Un écart peut être passé OPEN → IN_REVIEW → RESOLVED avec note obligatoire
- Un écart peut être marqué DISPUTED
- Lecture seule pour PCA/LECTURE
- Historique consultable sur le détail

---

## 13. Non-objectifs (v1)
- Gestion documentaire complète (uploads, OCR)
- Workflow d'approbation multi-niveaux complexe
- SLA / pénalités automatiques
- Notifications automatiques (post-v1)
