# POST-PROD — Reporting & Audit (v1) — Requirements

## 1. Objectif
Créer un module **Reporting & Audit** pour donner une vision direction/finance,
sans impacter le socle opérationnel, et avec traçabilité opposable.

Le module doit permettre :
- KPIs Procurement (AP) : reste à payer fournisseurs
- KPIs Sales (AR) : reste à encaisser clients
- KPIs Transporteurs : soldes, avances, reste à payer
- KPIs Écarts : volume/valeur en écart, causes, statuts
- Exports (PDF/Excel) v1
- Journal/Audit : qui a fait quoi, quand, sur quel document

---

## 2. Invariants (socle PROD)
- Flux immuable : CDR → Réception → Stock → Sortie
- Stock actuel : v_stock_actuel
- RLS + triggers intacts
- IDs produits canoniques intacts
- Aucun reset PROD, aucune suppression destructive

---

## 3. Public cible
- PCA / Direction : lecture globale, KPIs, exports
- Finance : suivi AR/AP, encaissements/paiements, contrôles
- Gérant / Directeur : pilotage opérationnel + anomalies
- Admin : tout

---

## 4. Périmètre v1

### 4.1 Dashboards (v1)
1) Dashboard Finance
2) Dashboard Direction
3) Dashboard Audit/Contrôle

### 4.2 KPIs minimum (v1)

#### A) Fournisseurs (AP)
- Total factures finales VALIDATED
- Total payé
- Total reste à payer
- Répartition par fournisseur
- Factures en retard (échéance dépassée)

#### B) Clients (AR)
- Total factures VALIDATED
- Total encaissé
- Total reste à encaisser
- Répartition par client
- Factures en retard (échéance dépassée)

#### C) Transporteurs
- Total décomptes VALIDATED
- Total avances
- Total payé
- Total reste à payer
- Transporteurs en trop-perçu (crédit transporteur)

#### D) Écarts & Anomalies
- Nombre d'écarts OPEN / IN_REVIEW / DISPUTED
- Volume total en écart (par produit)
- Top causes
- Écarts par fournisseur / client / transporteur

---

## 5. Dimensions & filtres (communs)
Tous les écrans KPI doivent offrir :
- période (date_from, date_to)
- entité (fournisseur / client / transporteur)
- statut (facture/paiement/écart)
- produit (si applicable)
- dépôt (si applicable)
- export des résultats filtrés

---

## 6. Exports (v1)
Exports nécessaires :
- Relevé fournisseur (PDF/Excel)
- Relevé client (PDF/Excel)
- Relevé transporteur (PDF/Excel)
- Listing écarts (Excel)
- KPIs (Excel)

V1 : export "simple" (tableaux + totaux), sans mise en page complexe.

---

## 7. Audit & traçabilité (v1)
Exigences :
- Toute création/validation/annulation d'un document post-prod est loggée :
  - qui (user)
  - quoi (type document)
  - action (create/validate/cancel/pay/collect/close)
  - quand (timestamp)
  - référence (id)
- Les exports doivent inclure :
  - période
  - filtre appliqué
  - date génération
  - utilisateur générateur

---

## 8. Permissions (v1)
- OPERATEUR : lecture limitée (aucun export global)
- GERANT/DIRECTEUR : accès dashboards + exports opérationnels
- FINANCE : accès AR/AP + exports
- PCA/LECTURE : lecture globale + exports
- ADMIN : tout

---

## 9. UX (écrans minimum v1)

### 9.1 Reporting Home
Cartes :
- AP (fournisseurs)
- AR (clients)
- Transporteurs
- Écarts
- Exports

### 9.2 Écrans KPI
- Graphiques simples (option)
- Table filtrable
- Totaux en header
- Bouton Export

### 9.3 Journal Audit
Table :
- date
- user
- action
- type document
- référence
- commentaire (si disponible)

---

## 10. Critères d'acceptation (v1)
- Voir une page Reporting avec cartes AP/AR/Transporteurs/Écarts
- Filtrer par période et entité
- Afficher totaux + détail
- Exporter un relevé fournisseur, client, transporteur
- Exporter listing écarts
- Journal audit consultable et filtrable
- Les exports contiennent métadonnées (filtres + date + user)

---

## 11. Non-objectifs (v1)
- BI avancé (drill-down multi-niveaux)
- Alertes automatiques (post-v1)
- Exports "mise en page officielle" complexe (post-v1)
- Connexion à un outil comptable externe (post-v1)
