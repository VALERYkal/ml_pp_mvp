# POST-PROD — Sales (Clients / AR) — Requirements (v1)

## 1. Objectif
Mettre en place le module **Sales / Clients (AR)** pour gérer :
- les **bons de livraison (BL)** émis pour les clients,
- les **factures clients** basées sur les livraisons,
- les **encaissements** (paiements reçus) total/partiel,
- le **relevé client** (solde + échéances),
- la traçabilité des écarts **Sortie vs Livraison** via le module Écarts.

Chaîne documentaire :
**Sortie (stock) → Bon de Livraison (BL) → Facture Client → Encaissement → Relevé client**

---

## 2. Invariants (socle PROD)
- Flux immuable : CDR → Réception → Stock → Sortie
- Stock actuel : v_stock_actuel
- RLS + triggers intacts
- IDs produits canoniques intacts
- Aucun reset PROD, aucune suppression destructive

---

## 3. Concepts & définitions

### 3.1 Sortie (stock)
Événement opérationnel qui décrémente le stock (déjà en PROD).
La sortie peut alimenter une ou plusieurs livraisons (cas exceptionnel) mais v1 : 1 sortie → 1 BL.

### 3.2 Bon de Livraison (BL)
Document de livraison remis au client (preuve).
Règles v1 :
- Un BL est associé à un client.
- Un BL est associé à une sortie (référence obligatoire).
- Un BL contient les volumes livrés (ambiant + 15°C si disponible).
- Un BL peut être **confirmé** (signature / validation) pour être facturable.

### 3.3 Facture client
Document commercial basé sur un ou plusieurs BL confirmés.
Règles v1 :
- v1 : 1 facture = 1..n BL (plusieurs BL confirmés)
- Une facture ne peut inclure que des BL du même client
- Un BL ne peut appartenir qu'à une seule facture
- Support paiements partiels (reste à payer)

### 3.4 Encaissement
Paiement reçu du client.
Règles v1 :
- v1 : 1 encaissement est lié à une facture
- un encaissement peut être partiel
- une facture calcule reste à payer
- Traçabilité : date, montant, devise, référence (cash/banque)

### 3.5 Relevé client
Vue consolidée :
- solde client
- factures ouvertes
- paiements reçus
- échéances

---

## 4. Workflow cible (v1)

### 4.1 Création BL depuis une sortie
1) L'utilisateur sélectionne une sortie validée
2) Crée un BL (client, date, destinataire, chauffeur/plaque si utile)
3) Saisit volumes livrés
4) Statut BL = DRAFT
5) Confirme BL → statut CONFIRMED

### 4.2 Gestion des écarts Sortie vs Livraison
À confirmation BL :
- calculer delta (sortie vs volumes BL)
- si delta ≠ 0 : créer un écart dans le module Écarts & Anomalies
- l'écart doit référencer : SORTIE + LIVRAISON

### 4.3 Facturation
1) Créer facture à partir d'un ou plusieurs BL CONFIRMED (sélection multi-BL confirmés du même client)
2) Calculer montant (prix unitaire, devise)
3) Statut facture = DRAFT
4) Valider facture → VALIDATED
5) Verrouiller BL une fois facturé

### 4.4 Encaissement
1) Enregistrer paiement reçu (montant, date, ref)
2) Affecter à facture (v1 : une facture)
3) Statut facture : PARTIALLY_PAID ou PAID
4) Relevé client mis à jour

---

## 5. Statuts (v1)

### BL
- DRAFT
- CONFIRMED
- CANCELLED

### Facture client
- DRAFT
- VALIDATED
- PARTIALLY_PAID
- PAID
- DISPUTED
- CANCELLED

### Encaissement
- RECORDED
- CANCELLED (admin)

---

## 6. Permissions (v1)
- OPERATEUR : créer BL, confirmer BL
- GERANT/DIRECTEUR : valider facture, gérer litiges
- FINANCE : enregistrer encaissements, consulter relevés
- PCA/LECTURE : lecture seule
- ADMIN : tout

---

## 7. UX (écrans minimum v1)

### 7.1 Client (fiche 360°)
Onglets :
- Livraisons (BL)
- Factures
- Encaissements
- Relevé

### 7.2 Écrans dédiés
- Liste BL + détail (avec sortie liée)
- Liste Factures client + détail
- Encaissements (création + historique)
- Relevé client (filtrable)

---

## 8. Critères d'acceptation (v1)
- Créer un BL depuis une sortie validée
- Confirmer un BL
- Générer automatiquement un écart si volumes BL ≠ volumes sortie
- Créer une facture à partir de plusieurs BL confirmés (même client)
- Enregistrer un encaissement partiel et voir le reste dû
- Relevé client : solde cohérent, factures ouvertes, paiements

---

## 9. Non-objectifs (v1)
- Multi-BL par sortie (v2)
- Gestion fiscale avancée (TVA etc.)
- Tarification complexe / remises / contrats (post-v1)
- Notifications automatiques (post-v1)
