# USER STORIES — Chaîne Contractuelle Fournisseur (V2)

Projet : **ML_PP MVP (Monaluxe Petrol Platform)**  
Statut : **POST-PROD — PROD en exploitation réelle**  
Référence : `REQUIREMENT_FOURNISSEUR_CONTRACT_CHAIN_V2.md`  
Objectif : Décliner les exigences contractuelles fournisseur en **User Stories actionnables**, planifiables par sprint, sans impact sur le flux cœur PROD.

---

## PHASE 1 — STRUCTURATION CONTRACTUELLE (SANS FINANCE)

### EPIC 1.1 — Référentiel Fournisseurs (lecture)

#### US-F1.1-01 — Consulter la liste des fournisseurs
**En tant que** Admin / Directeur / Gérant / PCA  
**Je veux** consulter la liste des fournisseurs  
**Afin de** identifier les partenaires actifs et accéder à leur situation contractuelle.

**Critères d'acceptation**
- Liste paginée avec : nom, pays, statut (actif/inactif)
- Recherche et tri disponibles
- Accès en lecture seule
- Aucun impact financier ou stock

---

#### US-F1.1-02 — Consulter la fiche fournisseur
**En tant que** Admin / Directeur / Gérant / PCA  
**Je veux** consulter la fiche détaillée d'un fournisseur  
**Afin de** visualiser sa situation contractuelle globale.

**Critères d'acceptation**
- Informations générales fournisseur
- Indicateurs visibles :
  - SBLC : AUCUNE / ACTIVE (n)
  - Proformas actives / clôturées
  - Factures finales (si existantes)
- Accès au relevé fournisseur (si existant)
- Lecture seule

---

### EPIC 1.2 — SBLC (registre de garanties)

#### US-F1.2-01 — Enregistrer une SBLC
**En tant que** Admin  
**Je veux** enregistrer une SBLC pour un fournisseur  
**Afin de** tracer l'existence d'une garantie bancaire.

**Critères d'acceptation**
- Fournisseur obligatoire
- Banque, référence, montant, devise, dates requis
- Statut initial : ACTIVE
- Plusieurs SBLC actives autorisées par fournisseur
- Aucune automatisation bancaire

---

#### US-F1.2-02 — Consulter les SBLC d'un fournisseur
**En tant que** Admin / Directeur / Gérant / PCA  
**Je veux** consulter les SBLC d'un fournisseur  
**Afin de** évaluer la couverture contractuelle.

**Critères d'acceptation**
- Liste des SBLC avec statut :
  ACTIVE / EXPIREE / ANNULEE / SUSPENDUE
- Alerte visuelle si expiration proche
- Indicateur couverture vs exposition (informationnel)
- Lecture seule

---

### EPIC 1.3 — Proforma Fournisseur (cadre contractuel)

#### US-F1.3-01 — Créer une proforma fournisseur
**En tant que** Admin / Directeur / Gérant  
**Je veux** créer une proforma fournisseur  
**Afin de** structurer contractuellement des livraisons à venir.

**Critères d'acceptation**
- Fournisseur obligatoire
- Produit unique par proforma
- Référence unique par fournisseur
- Statut initial : DRAFT
- Aucun impact stock ou financier

---

#### US-F1.3-02 — Activer une proforma
**En tant que** Admin / Directeur / Gérant  
**Je veux** activer une proforma  
**Afin de** l'utiliser comme source officielle des CDR.

**Critères d'acceptation**
- Transition : DRAFT → ACTIVE
- Une proforma ACTIVE peut recevoir des CDR
- Journalisation obligatoire

---

#### US-F1.3-03 — Lier un CDR à une proforma
**En tant que** Opérateur / Admin  
**Je veux** lier un CDR à une proforma ACTIVE  
**Afin de** tracer l'exécution logistique contractuelle.

**Critères d'acceptation**
- Proforma ACTIVE uniquement
- Fournisseur & produit cohérents
- Interdit si CDR ARRIVE ou DECHARGE
- Le lien devient figé après ARRIVE

---

## PHASE 2 — SUIVI LOGISTIQUE & CLÔTURE (PRÉVU VS RÉEL)

### EPIC 2.1 — Suivi proforma

#### US-F2.1-01 — Visualiser l'avancement d'une proforma
**En tant que** Admin / Directeur / Gérant  
**Je veux** visualiser l'avancement d'une proforma  
**Afin de** suivre l'exécution des livraisons prévues.

**Critères d'acceptation**
- Nombre total de CDR liés
- Répartition par statut (CHARGEMENT / TRANSIT / ARRIVE / DECHARGE)
- Volumes estimés vs volumes reçus (15°C)
- Données en lecture seule

---

#### US-F2.1-02 — Clôturer une proforma avec snapshot
**En tant que** Admin / Directeur / Gérant  
**Je veux** clôturer une proforma  
**Afin de** figer contractuellement son exécution.

**Critères d'acceptation**
- Action manuelle confirmée
- Justification obligatoire
- Génération d'un snapshot immuable :
  - CDR
  - volumes reçus
  - écarts
- Interdiction d'ajouter de nouveaux CDR après clôture

---

## PHASE 3 — ÉCARTS & FACTURE FINALE (DETTE RÉELLE)

### EPIC 3.1 — Registre des écarts fournisseur

#### US-F3.1-01 — Enregistrer un écart fournisseur
**En tant que** Admin / Directeur / Gérant  
**Je veux** enregistrer un écart lié à une réception  
**Afin de** tracer toute divergence contractuelle.

**Critères d'acceptation**
- Écart lié à une réception
- Type : QUANTITE / QUALITE / LOGISTIQUE / AUTRE
- Impact financier optionnel
- Justification obligatoire

---

#### US-F3.1-02 — Traiter un écart fournisseur
**En tant que** Admin / Directeur / Gérant  
**Je veux** traiter un écart fournisseur  
**Afin de** permettre la facturation finale.

**Critères d'acceptation**
- Passage statut : OUVERT → TRAITE
- Justification obligatoire
- Aucun écart non traité ne bloque la réception, mais bloque la facture finale

---

### EPIC 3.2 — Facture Finale Fournisseur

#### US-F3.2-01 — Générer une facture finale calculée
**En tant que** Admin / Directeur / Gérant  
**Je veux** générer une facture finale calculée  
**Afin de** matérialiser la dette basée sur le réel reçu.

**Critères d'acceptation**
- Réceptions existantes requises
- Calcul automatique :
  - volumes 15°C
  - prix unitaire (depuis proforma)
  - montant total
- Statut : CALCULEE
- Lecture seule (avant validation)

---

#### US-F3.2-02 — Valider une facture finale
**En tant que** Admin / Directeur / Gérant  
**Je veux** valider une facture finale  
**Afin de** créer officiellement la dette fournisseur.

**Critères d'acceptation**
- Transition : CALCULEE → VALIDEE
- Aucun écart non traité
- Snapshot immuable des données
- Création effective de la dette

---

## PHASE 4 — PAIEMENTS & RELEVÉ FOURNISSEUR

### EPIC 4.1 — Paiements fournisseur

#### US-F4.1-01 — Enregistrer un paiement fournisseur
**En tant que** Admin / Directeur / Gérant  
**Je veux** enregistrer un paiement fournisseur  
**Afin de** réduire la dette liée à une facture finale.

**Critères d'acceptation**
- Paiement lié à une facture finale VALIDEE
- Montant, devise, date, référence bancaire requis
- Paiements partiels autorisés
- Mise à jour automatique du solde facture

---

### EPIC 4.2 — Relevé de compte fournisseur

#### US-F4.2-01 — Consulter le relevé fournisseur
**En tant que** Admin / Directeur / Gérant / PCA  
**Je veux** consulter le relevé fournisseur  
**Afin de** justifier le solde fournisseur à tout instant.

**Critères d'acceptation**
- Ordre chronologique strict
- Solde cumulatif après chaque mouvement
- Événements autorisés uniquement :
  - FACTURE_FINALE_VALIDEE
  - PAIEMENT_CONFIRME
- Lecture seule
- Liens vers factures et paiements sources

---

## NOTE FINALE

Ces User Stories **v2** constituent la base officielle du backlog fournisseur POST-PROD.  
Elles sont :
- compatibles PROD,
- audit-ready,
- alignées ERP,
- sans dette fonctionnelle.

Toute évolution future doit être versionnée et validée formellement.
