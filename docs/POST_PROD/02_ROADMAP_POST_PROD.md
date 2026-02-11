# POST-PROD — Roadmap (v1)

## 1. Objectif
Séquençer les travaux POST-PROD afin de construire une plateforme ERP pétrolière
(logistique + contractuel + financier + contrôle) sans impacter le socle PROD.

## 2. Principes (non négociables)
- Le socle Opérations reste inchangé : CDR → Réception → Stock → Sortie
- Stock actuel : v_stock_actuel (contrat)
- RLS + triggers intacts
- IDs produits canoniques intacts
- Toute évolution = MAINTENANCE / AUDIT / SCALE / POST-PROD FEATURE

---

## 3. Phasage recommandé

### PHASE 0 — Préparation (Documentation & Cadre)
**Livrables**
- POST_PROD/00_OVERVIEW.md
- POST_PROD/01_ARCHITECTURE_FONCTIONNELLE_GLOBALE.md
- POST_PROD/INDEX.md

**Critères d'acceptation**
- Documentation relue et validée
- Le périmètre POST-PROD est clair (modules, objectifs, non-objectifs)

---

### PHASE 1 — PROCUREMENT (Fournisseurs / AP)
**Objectif**
Mettre en place la chaîne fournisseur complète :
SBLC → Proforma → CDR → Réceptions → Facture Finale → Paiements → Relevé fournisseur

**Jalons**
1) SBLC (garantie)
2) Proforma (source des CDR)
3) Liaison Proforma → génération/association CDR
4) Facture Finale (basée sur réceptions réelles)
5) Paiements (total / partiel, allocation)
6) Relevé fournisseur (solde & échéances)

**Critères d'acceptation**
- Un fournisseur peut avoir plusieurs SBLC (banques différentes)
- Une proforma peut générer plusieurs CDR (camions)
- Les réceptions réelles alimentent la consolidation facture finale
- Les paiements partiels sont supportés (reste dû calculé)
- Un relevé fournisseur affiche : solde, factures ouvertes, paiements, échéances

**Non-objectifs (phase 1)**
- Comptabilité générale complète
- Tarification avancée multi-conditions
- Gestion fiscale (TVA/impôts) complexe

---

### PHASE 2 — ÉCARTS & ANOMALIES (centre unique)
**Objectif**
Tracer, expliquer et traiter les différences volumétriques et financières.

**Types d'écarts**
1) Proforma vs Réception (fournisseur)
2) Volume sorti/chargé vs volume livré client
3) Écarts transporteurs (pertes, litiges, ajustements)

**Critères d'acceptation**
- Un écran unique liste les écarts (filtrable par période, entité, statut)
- Chaque écart possède : cause, pièces jointes/notes, statut, responsable
- Statuts : OUVERT → EN_COURS → RÉSOLU (minimum)
- L'écart peut aboutir à : litige, ajustement document, avoir, note explicative

---

### PHASE 3 — SALES (Clients / AR)
**Objectif**
Gérer la vente : livraisons → factures → encaissements → relevé client.

**Jalons**
1) Livraisons client (liées aux sorties)
2) Factures client (basées sur livraisons)
3) Encaissements (total / partiel, allocation)
4) Relevé client

**Critères d'acceptation**
- Une sortie peut être associée à une livraison client
- Factures émises depuis livraisons confirmées
- Encaissements partiels supportés
- Relevé client : solde, factures ouvertes, paiements, échéances

---

### PHASE 4 — TRANSPORTEURS
**Objectif**
Gérer les prestataires logistiques mandatés par Monaluxe.

**Jalons**
1) Missions / courses (liées aux livraisons)
2) Avances (avant mission)
3) Décompte & paiement (après mission)
4) Relevé transporteur

**Critères d'acceptation**
- Avances et paiements tracés par mission
- Solde transporteur calculable (avances vs dû)
- Liens visibles entre livraisons, missions et paiements

---

## 4. Dépendances (ordre logique)
- Phase 1 (Procurement) avant Phase 3 (Sales) recommandée
- Phase 2 (Écarts) peut démarrer dès Phase 1 (au moins pour Proforma vs Réceptions)
- Phase 4 (Transporteurs) dépend de la structuration des livraisons (Phase 3)

---

## 5. Prochain document à écrire
- 03 — Procurement (spécifications détaillées SBLC / Proforma / Facture finale / Paiements / Relevé)
