# POST-PROD — Stratégie d'implémentation technique (v1)

## 0. Objectif
Définir une stratégie technique POST-PROD **non destructive** pour ajouter :
Procurement (AP), Sales (AR), Transporteurs, Écarts, Reporting/Audit,
sans impacter le socle PROD (CDR → Réception → Stock → Sortie).

---

## 1. Invariants (non négociables)
- Flux immuable : CDR → Réception → Stock → Sortie
- Stock actuel : v_stock_actuel (contrat)
- RLS + triggers existants intacts
- IDs produits canoniques intacts
- Aucune suppression destructive
- Aucune opération risquée sur PROD sans backup validé

---

## 2. Conventions DB (v1)

### 2.1 Nommage
- Tables : snake_case, pluriel si nécessaire (ex: proformas, factures_clients)
- Clés primaires : uuid `id`
- Références : `<entite>_id`
- Timestamps : `created_at`, `updated_at` (si utile), `validated_at` (si utile)
- Utilisateurs : `created_by`, `validated_by`

### 2.2 Statuts
- Statuts en MAJUSCULES ASCII, sans accents
- Vocabulaire commun (DRAFT, VALIDATED, CANCELLED, PARTIALLY_PAID, PAID, DISPUTED)
- Toute transition = loggée

### 2.3 Montants / devises
- Montant : numeric/decimal (pas float)
- Devise : code ISO (ex: USD, EUR, CDF)
- On stocke le montant dans la devise d'origine (conversion post-v1)

---

## 3. Audit & Traçabilité

### 3.1 Log central
- Réutiliser `log_actions` comme journal unique quand possible
- Ajouter de nouveaux `action_type` POST-PROD :
  - SBLC_CREATED / SBLC_ACTIVATED / SBLC_EXPIRED / SBLC_CLOSED
  - PROFORMA_CREATED / PROFORMA_VALIDATED / PROFORMA_CLOSED
  - BL_CREATED / BL_CONFIRMED / BL_CANCELLED
  - FACTURE_CLIENT_CREATED / FACTURE_CLIENT_VALIDATED / FACTURE_CLIENT_PAID / FACTURE_CLIENT_CANCELLED
  - FACTURE_FOURNISSEUR_CREATED / ... / PAID / CANCELLED
  - FOURNISSEUR_PAYMENT_RECORDED / FOURNISSEUR_PAYMENT_CANCELLED
  - CLIENT_ENCAISSEMENT_RECORDED / CLIENT_ENCAISSEMENT_CANCELLED
  - TRANSPORTEUR_PAYMENT_RECORDED / TRANSPORTEUR_PAYMENT_CANCELLED
  - ECART_CREATED / ECART_STATUS_CHANGED / ECART_RESOLVED
  - EXPORT_GENERATED

### 3.2 Métadonnées export
Chaque export doit stocker :
- période + filtres
- user
- timestamp
- type export

(v1 : logguer dans log_actions + éventuellement table `exports_history`)

---

## 4. RLS (approche v1)
Objectif : RLS simple, cohérente, sans surprise.
- OPERATEUR : lecture + création limitée (BL, missions, notes écarts)
- FINANCE : lecture + création paiements/encaissements
- GERANT/DIRECTEUR : validation documents
- PCA/LECTURE : lecture seule
- ADMIN : tout

Approche :
- Politiques READ par rôle sur toutes tables POST-PROD
- Politiques WRITE spécifiques (insert/update) par statut et rôle
- Mise à jour de statut via RPC/trigger (recommandé) ou update contrôlé

---

## 5. Ordre d'implémentation (DB puis App)

### Phase 1 — Procurement (AP)
DB :
- sblc
- proformas + proforma_lines
- facture_fournisseur (finale) + lignes consolidées (option)
- paiements_fournisseur
- vues solde fournisseur

App :
- écrans liste/détail fournisseur 360° (read-first)
- création/validation proforma
- génération facture finale depuis réceptions (read-only d'abord)

### Phase 2 — Écarts & Anomalies (centre)
DB :
- table `ecarts` générique + références polymorphes (type + id)
- Colonnes ref_* (option v1) : fournisseur_id, client_id, transporteur_id, produit_id (nullable)
- Index sur (type, statut, created_at) + index sur ref_* pour filtres rapides
- triggers de création (sur validation facture / confirmation BL)

App :
- liste écarts + détail + workflow OPEN → IN_REVIEW → RESOLVED

### Phase 3 — Sales (AR)
DB :
- bons_livraison (BL) : 1 sortie → 1 BL (v1)
- factures_clients : 1 facture = 1..n BL (v1)
- encaissements (partiels)
- vues solde client

App :
- BL depuis sortie
- facture multi-BL
- encaissement partiel

### Phase 4 — Transporteurs
DB :
- transporteurs
- missions (multi BL)
- avances
- decompte
- paiements_transporteur
- calcul reste à payer = decompte - avances - paiements
- vues solde transporteur

App :
- mission depuis BL
- avances + décompte + paiements

### Phase 5 — Reporting & Audit
DB :
- vues KPI AP/AR/transporteurs/ecarts
- exports (v1 excel)
App :
- dashboards + exports + journal

---

## 6. Stratégie migrations (non destructive)
- Une migration = ajout de tables / colonnes / vues uniquement
- Pas de drop sans décision formelle
- Scripts versionnés dans `docs/migrations/` et `supabase/migrations/`
- Prévoir un rollback "safe" (désactiver feature flags / masquer UI)

---

## 7. Feature flags (recommandé)
- Activer les modules POST-PROD progressivement par rôle
- Permettre un déploiement sans exposer fonctionnalités incomplètes

---

## 8. Critères de validation technique (v1)
- Aucun test existant cassé
- Aucun changement sur v_stock_actuel / triggers stock / RLS existante
- Tables POST-PROD avec RLS active
- Logs action_type présents
- Exports disponibles en staging avant prod
