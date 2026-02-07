# REQUIREMENT DOCUMENT — Chaîne Contractuelle Fournisseur (V2)

Projet : **ML_PP MVP (Monaluxe Petrol Platform)**  
Statut projet : **PROD en exploitation réelle** (activation : **2026-02-05**)  
Type : **Exigences fonctionnelles & métier (document normatif)**  
Portée : **POST-PROD — évolution contrôlée, non destructive**  
Version : **v2.0**  
Date : **2026-02-07**  

---

## 1. Contexte et objectif

ML_PP MVP est en production et opère le flux cœur **immuable** :

**Cours de Route → Réception → Stock → Sortie**

Ce document définit les exigences nécessaires pour introduire la **chaîne contractuelle fournisseur** de façon progressive, audit-ready et compatible PROD, depuis la garantie bancaire (SBLC) jusqu'au paiement des factures finales.

Objectifs :
- Structurer les engagements fournisseurs (proformas)
- Assurer la traçabilité contractuelle des livraisons (CDR)
- Produire une dette fournisseur **réelle** basée sur le reçu (réceptions)
- Tracer paiements, solde, relevé chronologique
- Être défendable en audit (banque, douane, direction)

---

## 2. Périmètre fonctionnel

Chaîne contractuelle couverte :

SBLC (garantie contractuelle)
→ Proforma (engagement fournisseur)
→ Cours de Route (exécution camion)
→ Réceptions (réalité physique)
→ Registre des écarts (quantité/qualité/logistique)
→ Facture Finale (dette réelle)
→ Paiement(s) (traçabilité bancaire)
→ Compte Fournisseur (position nette)
→ Relevé Fournisseur (justification chronologique unique)

Hors périmètre explicite :
- Appel SBLC / automatisation bancaire
- Comptabilité OHADA / fiscalité / FX multi-devises
- Intégrations bancaires (API) / ERP comptable externe

---

## 3. Principes directeurs (NON NÉGOCIABLES)

1. **Aucun changement** ne doit casser ou modifier le flux PROD : CDR → Réception → Stock → Sortie.
2. Les évolutions doivent être **non destructives** (nouvelles tables / vues / fonctions / colonnes nullables).
3. **Le système calcule, l'humain valide** (aucune dette "manuelle libre").
4. **Stock** : déclenché uniquement par la **Réception** (inchangé).
5. **Dette fournisseur** : naît uniquement à la **validation** d'une **Facture Finale**.
6. **SBLC** : garantie dormante, **hors flux**, n'impacte jamais solde/dette/stock.
7. **Facture ≠ Paiement ≠ Solde** (séparation stricte).
8. Tout solde fournisseur doit être **justifiable** par un **relevé chronologique** unique.
9. Toute action structurante est **auditée** (logs) et **historisable** (snapshots immutables).
10. Aucune automatisation bancaire (les paiements sont **déclaratif**).

---

## 4. Acteurs & responsabilités

| Acteur | Responsabilités |
|---|---|
| Admin | Gouvernance complète (création/annulation, corrections autorisées, supervision) |
| Directeur / Gérant | Validation (proforma, facture finale), supervision, arbitrage |
| Opérateur | Exécution logistique (CDR, réceptions existantes), pas de finance |
| PCA | Lecture globale, contrôle et reporting |
| Système | Calculs dérivés, cohérence, traçabilité, garde-fous |

---

## 5. SBLC — Exigences fonctionnelles

### 5.1 Rôle
Le SBLC (Standby Letter of Credit) est une **garantie bancaire** souscrite par Monaluxe en faveur d'un fournisseur.  
Le système **ne déclenche jamais** d'appel SBLC et ne fait **aucune** automatisation bancaire.

### 5.2 Données minimales
- Fournisseur bénéficiaire
- Banque émettrice
- Référence SBLC
- Montant garanti + devise
- Dates (début/fin validité)
- Statut : `ACTIVE | EXPIREE | ANNULEE | SUSPENDUE`

### 5.3 Règles
- Un fournisseur peut avoir **0..N** SBLC actives
- Les SBLC peuvent provenir de banques multiples
- Le système doit afficher :
  - SBLC actives/expirées
  - alertes d'expiration (ex : < 30 jours)
  - **exposition vs couverture SBLC** (informationnel, non bloquant)
- Le SBLC n'impacte jamais stock, dette, solde

---

## 6. Proforma — Exigences fonctionnelles

### 6.1 Rôle
La proforma est le document contractuel amont émis par le fournisseur.  
Elle constitue le **cadre obligatoire opérationnel** des Cours de Route.

### 6.2 Modèle
- Une proforma appartient à **un seul fournisseur**
- Une proforma concerne **un seul produit**
- Une proforma peut couvrir **N CDR**
- Une proforma n'a **aucun impact stock ou financier**

### 6.3 Statuts
`DRAFT → ACTIVE → EN_EXECUTION → CLOTUREE | ANNULEE`

### 6.4 Règles
- Seules les proformas `ACTIVE` peuvent recevoir des CDR
- Le lien CDR ↔ proforma est **obligatoire en pratique** (UI/process)
- Une proforma clôturée est figée (aucun ajout CDR)
- Les CDR `ARRIVE` / `DECHARGE` ne peuvent plus changer de proforma
- La proforma doit supporter une **date de validité** (optionnelle mais recommandée)

### 6.5 Clôture avec snapshot (audit-grade)
À la clôture, le système fige un snapshot immuable :
- Nombre de CDR liés
- Volumes estimés (si fournis)
- Volumes reçus (15°C, via réceptions)
- Écarts (+/-)
- Justification textuelle obligatoire
- Identité du validateur + horodatage

---

## 7. Cours de Route — Intégration (inchangé, règles renforcées)

- 1 CDR = 1 camion réel
- Un CDR doit être rattaché à une proforma `ACTIVE` (obligation opérationnelle)
- Aucun lien direct avec SBLC ou paiements
- Une fois `ARRIVE`/`DECHARGE`, le rattachement proforma est figé

---

## 8. Réceptions — Vérité opérationnelle (inchangé)

- La réception est le transfert de responsabilité
- Elle crédite le stock (flux cœur existant)
- Elle clôt l'exécution logistique du CDR
- Elle fournit le volume de référence 15°C

---

## 9. Registre des écarts fournisseur (NOUVEAU — critique)

### 9.1 Rôle
Tracer toute divergence entre engagement et réalité reçue (quantité, qualité, logistique).

### 9.2 Typologie minimale
- `QUANTITE`
- `QUALITE`
- `LOGISTIQUE`
- `AUTRE`

### 9.3 Règles
- Tout écart est lié à une **réception**
- Un écart peut être :
  - informatif (sans impact financier)
  - impactant (impact financier renseigné/justifié)
- **Aucune facture finale ne peut être validée** si des écarts liés ne sont pas **traités** (statut "traité" + justification)

---

## 10. Facture Finale — Dette réelle fournisseur

### 10.1 Rôle
La facture finale matérialise la dette réelle de Monaluxe envers un fournisseur, basée sur les quantités réellement reçues (15°C) et le cadre contractuel (proforma).

### 10.2 Exigences
- Une facture finale appartient à un fournisseur
- Elle est rattachée à une ou plusieurs proformas (v2 autorise, implémentation initiale recommandée : 1 facture par proforma)
- Elle ne peut être générée que si des réceptions existent
- **Le système calcule** volume & montant, **l'humain valide**

### 10.3 Statuts
`DRAFT → CALCULEE → VALIDEE → PAYEE | LITIGE | ANNULEE`

### 10.4 Règles
- La dette naît uniquement à l'état `VALIDEE`
- À la génération/validation, le système doit **snapshotter** :
  - liste des réceptions incluses
  - volume 15°C effectif par réception (base + ajustements validés)
  - prix unitaire (snapshotté depuis proforma)
  - montant total
- Toute validation doit enregistrer :
  - validateur (user)
  - timestamp
  - justification (obligatoire en cas d'écart)

---

## 11. Paiements — Traçabilité bancaire

### 11.1 Rôle
Tracer les paiements bancaires effectués hors système (déclaratif).

### 11.2 Exigences
- Une facture finale peut recevoir 0..N paiements
- Chaque paiement référence :
  - date
  - montant
  - devise
  - référence bancaire
  - statut (`EN_ATTENTE | CONFIRME | ANNULE`)

### 11.3 Règles
- Paiements partiels autorisés
- Le solde facture est recalculé : `montant_facture - somme(paiements_confirmes)`
- Facture = `PAYEE` si solde = 0
- FX/multi-devise : hors scope (paiement même devise que facture)

---

## 12. Compte Fournisseur (AP opérationnel)

### 12.1 Rôle
Représenter la position financière nette de Monaluxe vis-à-vis d'un fournisseur.

### 12.2 Règles
- Compte fournisseur unique par fournisseur
- Calculé/dérivé uniquement :
  - factures finales `VALIDEE`
  - paiements `CONFIRME`
- Non éditable manuellement
- Le SBLC n'affecte jamais le solde (informationnel uniquement)

---

## 13. Relevé Fournisseur (SOURCE UNIQUE DE JUSTIFICATION)

### 13.1 Rôle
Le relevé fournisseur est la vue chronologique officielle justifiant le solde.

### 13.2 Événements autorisés
- `FACTURE_FINALE_VALIDEE` : augmente la dette
- `PAIEMENT_CONFIRME` : réduit la dette

Aucun autre événement n'est autorisé dans le relevé.

### 13.3 Structure d'une ligne
- Date
- Type (FACTURE / PAIEMENT)
- Référence
- Débit
- Crédit
- Solde cumulatif après mouvement
- Devise
- Lien vers source (facture/paiement)

### 13.4 Règles
- Lecture seule
- Ordre chronologique strict
- Relevé = source unique de justification du solde

---

## 14. Découpage par phases

| Phase | Contenu |
|---|---|
| Phase 1 | Fournisseurs + SBLC + Proforma |
| Phase 2 | Suivi Proforma + clôture snapshot |
| Phase 3 | Écarts + Facture Finale (calcul + validation) |
| Phase 4 | Paiements + Relevé fournisseur |
| Phase 5 | Automatisations (hors scope) |

---

## 15. Logs & audit (obligatoire)

Toute action structurante doit générer un événement dans `log_actions` (ou équivalent) :
- `SBLC_CREEE`, `SBLC_MAJ`, `SBLC_ANNULEE`
- `PROFORMA_CREEE`, `PROFORMA_ACTIVEE`, `PROFORMA_CLOTUREE`, `PROFORMA_ANNULEE`
- `CDR_LIE_PROFORMA`, `CDR_DE_LIE_PROFORMA` (si autorisé avant ARRIVE)
- `ECART_CREE`, `ECART_TRAITE`
- `FACTURE_CALCULEE`, `FACTURE_VALIDEE`, `FACTURE_LITIGE`, `FACTURE_ANNULEE`
- `PAIEMENT_ENREGISTRE`, `PAIEMENT_CONFIRME`, `PAIEMENT_ANNULE`

---

## 16. Statut du document

Ce document **v2.0** est la référence normative pour toute implémentation de la chaîne contractuelle fournisseur.

Toute évolution :
- doit être versionnée,
- validée formellement,
- compatible PROD,
- non destructive,
- traçable.

---
