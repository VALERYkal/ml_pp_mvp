# PLAN POST-PROD — CHAÎNE CONTRACTUELLE FOURNISSEUR (V2)

Projet : ML_PP MVP (Monaluxe Petrol Platform)  
Statut : PROD en exploitation réelle  
Type : Plan de mise en œuvre POST-PROD (ERP-grade)  
Référence : REQUIREMENT_FOURNISSEUR_CONTRACT_CHAIN v2.0  
Version : v2.0  
Date : 2026-02-07  

---

## 1. Contexte

La plateforme ML_PP MVP est en production et opère le flux cœur immuable :

**Cours de Route → Réception → Stock → Sortie**

Le présent document définit le **plan de mise en œuvre progressive** de la chaîne contractuelle fournisseur, sans modification du flux cœur existant, conformément aux exigences post-production validées.

Ce plan est conçu pour :
- préserver la stabilité PROD,
- garantir la traçabilité contractuelle et financière,
- atteindre un niveau **audit / banque / douane**,
- éviter toute dette technique ou fonctionnelle.

---

## 2. Principes non négociables (Gates globaux)

Toute itération doit respecter strictement les règles suivantes :

1. ❌ Aucun impact sur le flux cœur PROD.
2. ❌ Aucune migration destructive (tables existantes, vues, triggers).
3. ✅ Nouvelles tables uniquement ou colonnes nullables.
4. ✅ RLS conforme aux rôles existants.
5. ✅ Logs obligatoires dans `log_actions` pour chaque action métier clé.
6. ✅ CI PR light verte avant merge.
7. ✅ Backup validé avant toute migration PROD.

---

## 3. Definition of Done (DoD) standard

Une User Story ou un Sprint est considéré comme terminé uniquement si :

- **DB**
  - tables / vues / indexes créés,
  - RLS appliquée,
  - triggers ou fonctions si nécessaires,
  - aucun impact sur schéma existant.

- **Application**
  - service / repository (Clean Architecture),
  - providers testables,
  - UI minimale (liste / détail / action).

- **Tests**
  - tests unitaires sur règles métier,
  - smoke tests UI.

- **Documentation**
  - entrée CHANGELOG.md,
  - mini-runbook si nécessaire.

---

## 4. Découpage des sprints

### SPRINT 1 — Référentiel Fournisseurs (lecture)

**Objectif**  
Rendre le référentiel fournisseur exploitable dans l’application sans aucun impact financier.

**User Stories**
- US-F1.1-01 : Liste fournisseurs
- US-F1.1-02 : Fiche fournisseur (lecture)

**Livrables**
- Écrans :
  - FournisseursListScreen
  - FournisseurDetailScreen (sections vides pour finance)
- Repository fournisseur (read-only)
- Tests fetch + smoke UI

**Release**
- SAFE PROD (lecture uniquement)

---

### SPRINT 2 — SBLC (registre + gouvernance)

**Objectif**  
Tracer les garanties bancaires et exposer le risque fournisseur sans automatisation.

**User Stories**
- US-F1.2-01 : Enregistrer une SBLC
- US-F1.2-02 : Consulter SBLC fournisseur

**Livrables**
- Table `finance_sblc`
- Vue couverture SBLC par fournisseur
- Badges :
  - SBLC ACTIVE (n)
  - COUVERT / PARTIEL / NON COUVERT
- Alertes expiration

**Release**
- SAFE PROD (registre + indicateurs)

---

### SPRINT 3 — Proforma fournisseur (cadre contractuel)

**Objectif**  
Introduire la proforma comme cadre contractuel obligatoire des CDR.

**User Stories**
- US-F1.3-01 : Créer proforma (mono-produit)
- US-F1.3-02 : Activer proforma
- US-F1.3-03 : Lier CDR à proforma

**Livrables**
- Tables :
  - `finance_proformas`
  - `finance_proforma_cdr`
- UI :
  - liste / détail proforma
  - liaison CDR
- Règles :
  - proforma ACTIVE obligatoire
  - interdiction ARRIVE / DECHARGE

**Release**
- SAFE PROD (pas d’impact stock/finance)

---

### SPRINT 4 — Suivi Proforma & Clôture (audit-grade)

**Objectif**  
Permettre le pilotage prévu vs réel et figer contractuellement l’exécution.

**User Stories**
- US-F2.1-01 : Suivi proforma
- US-F2.1-02 : Clôture proforma avec snapshot

**Livrables**
- Vues KPI proforma
- Table snapshot de clôture
- UI dashboard + action clôture
- Justification obligatoire

**Release**
- SAFE PROD (lecture + clôture contrôlée)

---

### SPRINT 5 — Écarts & Facture Finale (dette réelle)

**Objectif**  
Créer une dette fournisseur calculée sur base du réel reçu.

**User Stories**
- US-F3.1-01 : Générer facture finale calculée
- US-F3.1-02 : Valider facture finale

**Livrables**
- Table `finance_ecarts_fournisseur`
- Tables facture finale + snapshot réceptions
- Fonction SQL de calcul
- UI calcul / validation
- Blocage si écarts non traités

**Release**
- SAFE PROD (dette créée uniquement à validation)

---

### SPRINT 6 — Paiements & Relevé fournisseur

**Objectif**  
Tracer les paiements et fournir un relevé officiel justifiant le solde.

**User Stories**
- US-F4.1-01 : Enregistrer paiement
- US-F4.2-01 : Consulter relevé fournisseur

**Livrables**
- Table paiements
- Vue relevé chronologique (solde cumulatif)
- UI relevé + filtres
- Statut facture PAYEE automatique

**Release**
- SAFE PROD (audit-grade)

---

## 5. Décisions ERP figées (V2)

- Une proforma = une devise
- Une facture finale = même devise que la proforma
- Paiements = même devise (FX hors scope)
- Prix unitaire figé depuis proforma
- Facture finale par proforma (pas par période en v2)

---

## 6. Conclusion

Ce plan garantit :
- stabilité PROD,
- traçabilité complète,
- conformité audit,
- montée en puissance maîtrisée vers un ERP pétrolier complet.

Toute modification future doit :
- créer une nouvelle version,
- être validée formellement,
- rester compatible PROD.

---

