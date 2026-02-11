# POST-PROD — Navigation Fonctionnelle (v1)

## 1. Objectif
Définir une navigation claire, modulaire et user-friendly
pour intégrer les modules POST-PROD sans complexifier l'interface.

Navigation maximum : 2 niveaux.

---

# 2. Structure principale (Sidebar / NavigationRail)

## SECTION 1 — OPÉRATIONS (existant, inchangé)
- Dashboard
- Cours de Route
- Réceptions
- Sorties
- Stock
- Citernes

---

## SECTION 2 — COMMERCIAL

### Clients
- Bons de Livraison (BL)
- Factures clients
- Encaissements
- Relevé client

---

## SECTION 3 — FOURNISSEURS (Procurement)

### Fournisseurs
- SBLC
- Proformas
- Factures finales
- Paiements
- Relevé fournisseur

---

## SECTION 4 — LOGISTIQUE

### Transporteurs
- Missions
- Avances
- Décomptes
- Paiements
- Relevé transporteur

---

## SECTION 5 — CONTRÔLE

- Écarts & Anomalies
- Reporting & Audit

---

# 3. Accès transversal

## Depuis une fiche :
- Fournisseur → voir ses écarts
- Client → voir ses écarts
- Transporteur → voir ses écarts
- Facture → voir paiements
- Mission → voir avances/décompte

Bouton standard : "Voir écarts liés"

---

# 4. Navigation par rôle

## OPERATEUR
- Opérations
- BL
- Missions
- Écarts (création / suivi)

## FINANCE
- Fournisseurs
- Clients
- Transporteurs
- Reporting

## GERANT / DIRECTEUR
- Accès complet
- Reporting global

## PCA
- Lecture seule
- Reporting complet

---

# 5. Règles UX clés

1. Une entité = une fiche 360° (avec onglets)
2. Pas plus de 2 niveaux de profondeur
3. Les écarts ne sont jamais cachés
4. Les soldes (reste à payer / encaisser) sont visibles en badge
5. Les statuts sont affichés par couleur

---

# 6. Évolution future (v2+)

- Douanes / Import
- Contrats clients
- Contrats transporteurs
- Multi-organisation
- Intégration comptable
