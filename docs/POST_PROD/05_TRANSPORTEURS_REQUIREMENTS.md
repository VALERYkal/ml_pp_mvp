# POST-PROD — Transporteurs — Requirements (v1)

## 1. Objectif
Mettre en place le module **Transporteurs** pour gérer :
- les transporteurs utilisés par Monaluxe pour livrer chez les clients,
- les **missions** (courses) associées aux livraisons (BL),
- les **avances** versées avant/pendant mission,
- les **décomptes** (montant dû final),
- les **paiements** (total/partiel),
- le **relevé transporteur** (solde).

Chaîne documentaire cible :
**Bon de Livraison (BL) → Mission → Avances → Décompte → Paiements → Relevé transporteur**

---

## 2. Invariants (socle PROD)
- Flux immuable : CDR → Réception → Stock → Sortie
- Stock actuel : v_stock_actuel
- RLS + triggers intacts
- IDs produits canoniques intacts
- Aucun reset PROD, aucune suppression destructive

---

## 3. Concepts & définitions

### 3.1 Transporteur
Entité partenaire logistique (peut avoir plusieurs chauffeurs/camions).
V1 : gestion simple (identité, contacts, notes, statut actif/inactif).

### 3.2 Mission (course)
Document qui représente une prestation de transport réalisée par un transporteur.
Règles v1 :
- Une mission est liée à **un transporteur**
- Une mission est liée à **1..n BL** (souvent groupés par tournée)
- Une mission a un statut et une période (date départ, date arrivée)
- Une mission peut avoir un montant dû (décompte) après exécution

### 3.3 Avance transporteur
Paiement anticipé (cash/virement) avant la fin de mission.
Règles v1 :
- Une avance est liée à une mission
- Une mission peut avoir plusieurs avances
- Traçabilité : date, montant, devise, référence

### 3.4 Décompte
Montant final à payer pour la mission (après livraison).
Règles v1 :
- Le décompte est lié à une mission
- Il peut intégrer : montant brut, retenues, pénalités (v2), ajustements
- V1 : un seul montant final simple

### 3.5 Paiement transporteur
Paiement effectué au transporteur pour apurer tout ou partie du décompte.
Règles v1 :
- Paiements partiels possibles
- 1 paiement lié à une mission (v1)

Calcul v1 (règle officielle) :
- total_avances = somme(avances RECORDED)
- total_paiements = somme(paiements RECORDED)
- reste_a_payer = montant_decompte - total_avances - total_paiements
- si reste_a_payer < 0 : trop-perçu (crédit transporteur)

Note v1 : les avances restent une catégorie distincte pour le terrain, mais elles sont déduites automatiquement du décompte dans le calcul du reste à payer.

### 3.6 Relevé transporteur
Vue consolidée montrant :
- missions
- avances
- décomptes
- paiements
- solde (dû ou trop-perçu)

---

## 4. Workflow cible (v1)

### 4.1 Création mission depuis des BL
1) Sélectionner un transporteur
2) Sélectionner 1..n BL CONFIRMED (même transporteur/tournée)
3) Créer mission (dates, chauffeur/plaque si utile)
4) Statut = DRAFT

### 4.2 Exécution mission
- Mission passe IN_PROGRESS quand départ effectif
- Mission passe DELIVERED quand toutes les livraisons sont confirmées (BL)

### 4.3 Avances
- Ajouter une ou plusieurs avances pendant la mission
- Avances visibles dans le détail mission

### 4.4 Décompte et paiements
1) Créer décompte (montant final dû)
2) Enregistrer paiements (total/partiel)
3) Statut mission : SETTLED quand reste à payer = 0

---

## 5. Statuts (v1)

### Mission
- DRAFT
- IN_PROGRESS
- DELIVERED
- SETTLED
- CANCELLED

### Avance
- RECORDED
- CANCELLED (admin)

### Décompte
- DRAFT
- VALIDATED
- CANCELLED (admin)

### Paiement transporteur
- RECORDED
- CANCELLED (admin)

---

## 6. Permissions (v1)
- OPERATEUR : créer mission, ajouter avances, passer DELIVERED (si autorisé)
- GERANT/DIRECTEUR : valider décompte, clôturer mission SETTLED
- FINANCE : enregistrer paiements, consulter relevés
- PCA/LECTURE : lecture seule
- ADMIN : tout

---

## 7. UX (écrans minimum v1)

### 7.1 Transporteur (fiche 360°)
Onglets :
- Missions
- Avances
- Décomptes
- Paiements
- Relevé

### 7.2 Écrans dédiés
- Liste missions + détail (avec BL liés)
- Ajout avance (dans mission)
- Décompte (dans mission)
- Paiements (dans mission)
- Relevé transporteur (filtrable)

---

## 8. Critères d'acceptation (v1)
- Créer une mission et y associer plusieurs BL confirmés
- Enregistrer une avance sur mission
- Créer un décompte et le valider
- Enregistrer un paiement partiel et voir le reste à payer
- Mission passe SETTLED quand reste à payer = 0
- Relevé transporteur cohérent (missions, avances, paiements, solde)

---

## 9. Non-objectifs (v1)
- Tarification automatique par km/zone
- SLA, pénalités automatiques, incidents détaillés
- Paiement multi-missions (v2)
- Gestion avancée des chauffeurs/vehicules (post-v1)
