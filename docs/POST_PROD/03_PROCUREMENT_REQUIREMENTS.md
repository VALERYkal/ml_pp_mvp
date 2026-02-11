# POST-PROD — Procurement (Fournisseurs / AP) — Requirements (v1)

## 1. Objectif
Mettre en place le module **Procurement** pour gérer la chaîne fournisseur complète :

SBLC (garantie) → Proforma → CDR → Réceptions → Facture Finale → Paiements → Relevé fournisseur

Le module Procurement doit :
- Structurer les engagements fournisseurs (avant livraison)
- Consolider les quantités réellement reçues
- Gérer la facturation réelle et les paiements (total/partiel)
- Exposer un relevé fournisseur (solde + échéances)
- Tracer les écarts (proforma vs réceptions) de manière explicite

---

## 2. Invariants (socle PROD)
- Flux immuable : CDR → Réception → Stock → Sortie
- Stock actuel : v_stock_actuel
- RLS + triggers intacts
- IDs produits canoniques intacts
- Aucun reset PROD, aucune suppression destructive

---

## 3. Concepts & définitions

### 3.1 SBLC (Standby Letter of Credit)
Garantie en faveur d'un fournisseur, utilisée uniquement en cas de non-paiement.
Règles :
- Une SBLC est associée à **un fournisseur** (bénéficiaire).
- Un fournisseur peut avoir **plusieurs SBLC** (banques différentes).
- Une SBLC a : montant, devise, dates de validité, statut (ACTIVE/EXPIRED/CLOSED).

### 3.2 Proforma
Document émis par le fournisseur.
Rôle : base de génération des CDR (camions attendus).
Règles :
- Une proforma contient une ou plusieurs lignes produit (produit, quantité prévue, prix unitaire, devise).
- Une proforma peut générer **plusieurs CDR**.
- La proforma est une "prévision" : les quantités réelles viennent des réceptions.

### 3.3 Facture Finale (réelle)
Document final basé sur les volumes réellement réceptionnés.
Règles :
- Elle se base sur un ensemble de réceptions (liées à des CDR associés à la proforma).
- Elle supporte : ajustements, avoirs, litiges.
- Elle supporte les paiements partiels.
- Elle possède une date facture et une échéance (due_date).

### 3.4 Paiement fournisseur
Règlement bancaire réalisé par Monaluxe.
Règles :
- Un paiement peut couvrir une facture totale ou partielle.
- Un paiement peut être alloué à une ou plusieurs factures (option v2) ; en v1, on peut limiter à 1 facture si nécessaire.
- Traçabilité obligatoire : date, montant, devise, référence bancaire.

### 3.5 Relevé fournisseur
Vue consolidée montrant ce que Monaluxe doit au fournisseur (ou l'inverse).
Affiche :
- Solde courant
- Factures ouvertes / échéances
- Paiements effectués
- Avoirs / ajustements

---

## 4. Workflow cible (vue métier)

### 4.1 Création SBLC
1) Créer SBLC (fournisseur, banque, montant, devise, validité)
2) Activer SBLC
3) Suivre expirations (alertes post-v1)

### 4.2 Création Proforma
1) Créer proforma (fournisseur, période, devise, conditions)
2) Ajouter lignes produits
3) Valider proforma
4) Générer/associer les CDR attendus

### 4.3 Réceptions (déjà en PROD)
- Les réceptions se font comme aujourd'hui (socle inchangé)
- Elles sont liées aux CDR, et donc indirectement à la proforma

### 4.4 Génération Facture Finale
1) Sélectionner une proforma
2) Système liste toutes les réceptions réelles liées aux CDR de cette proforma
3) Calculer : quantités réelles par produit + montant
4) Détecter écarts (proforma vs réel)
5) Créer la facture finale
6) Valider la facture finale

### 4.5 Paiement facture
v1 : un paiement est obligatoirement lié à une seule facture finale. Le paiement se crée depuis l'écran de la facture.
1) Enregistrer paiement (montant/devise/date/ref)
2) Affecter à la facture (v1 : une facture)
3) Mettre à jour statut facture : PARTIALLY_PAID ou PAID
4) Relevé fournisseur mis à jour automatiquement

---

## 5. Gestion des écarts (obligatoire)
Le module Procurement doit produire des écarts :
- Quantité proforma vs quantité réceptionnée (par produit)
- Valeur proforma vs valeur facturée réelle
- Écart de prix (si applicable)

Traitement v1 :
- afficher l'écart dans le détail proforma et facture finale
- possibilité de "marquer comme accepté" avec note
- sinon "ouvrir un litige" (connecté au futur module Écarts & Anomalies)

---

## 6. Statuts (v1)
### SBLC
- DRAFT
- ACTIVE
- EXPIRED
- CLOSED

### Proforma
- DRAFT
- VALIDATED
- CLOSED

Une proforma peut passer CLOSED quand tous les CDR associés sont DECHARGE et qu'une facture finale est VALIDATED (ou créée selon décision).

### Facture Finale
- DRAFT
- VALIDATED
- PARTIALLY_PAID
- PAID
- DISPUTED
- CANCELLED

### Paiement
- RECORDED
- CANCELLED (rare, admin)

### Numérotation (v1)
SBLC, Proforma, Facture Finale et Paiement disposent chacun d'une numérotation dédiée (préfixe + année + séquence, format à définir).

---

## 7. Permissions (v1)
- OPERATEUR : lecture proforma/factures, pas de validation ni paiement
- GERANT / DIRECTEUR : valider proforma + valider facture finale
- FINANCE : enregistrer paiements + consulter relevés
- PCA / LECTURE : lecture globale
- ADMIN : tout

---

## 8. UX (écrans minimum v1)
### Fournisseur (fiche 360°)
Onglets :
- Proformas
- Factures finales
- Paiements
- Relevé
- SBLC

### Écrans dédiés
- Liste SBLC + détail
- Liste Proformas + détail (avec CDR associés)
- Liste Factures finales + détail (avec réceptions consolidées)
- Paiements (création + historique)
- Relevé fournisseur (filtrable par période)

---

## 9. Critères d'acceptation (v1)
- Créer une SBLC pour un fournisseur et la marquer ACTIVE
- Créer une proforma avec lignes produits et la valider
- Associer/générer des CDR depuis proforma (au minimum lien)
- Consolider les réceptions liées pour produire une facture finale
- Enregistrer un paiement partiel et voir le reste dû
- Voir un relevé fournisseur cohérent (solde + factures ouvertes + paiements)
- Les écarts proforma vs réel sont visibles dans proforma et facture finale

---

## 10. Non-objectifs (v1)
- Comptabilité générale complète
- Multi-devise avancée (taux, conversion automatique)
- Allocation paiement multi-factures (si on le repousse en v2)
- Gestion fiscale avancée (TVA/impôts)
- Notifications/alertes (post-v1)
