# Contexte général post-production — ML_PP MVP

**Document officiel de référence**  
**Version :** 1.0.0  
**Date :** 2026-02-08  
**Statut :** Référence plateforme et métier, orientée décision et audit  

---

## 1. Positionnement

**ML_PP** (Monaluxe Petrol Platform) est une plateforme industrielle de gestion logistique pétrolière **en production** et **en exploitation réelle**. Toute évolution fonctionnelle après la mise en production doit s’inscrire dans un cadre post-prod explicite : s’appuyer sur le socle existant, ne jamais le déstabiliser.

Ce document décrit le **contexte général post-prod** : socle considéré comme acquis, philosophie des évolutions, stratégie par phases et navigation cible. Il ne contient **aucun détail technique** (pas de code, pas de schéma) et vise à rester lisible et opposable dans le temps (6 à 12 mois).

---

## 2. Socle logistique (acquis et figé)

Le socle logistique de ML_PP est **stable et validé**. Il constitue la preuve matière et opérationnelle de la plateforme. En post-prod, ce socle **n’est pas modifié** ; les évolutions s’y **branchent** sans le transformer.

### 2.1 Composants du socle

| Domaine | Rôle |
|--------|------|
| **Cours de route (CDR)** | Cadre opérationnel du déplacement camion (Monaluxe / Partenaire). |
| **Réceptions** | Entrée physique des produits (Monaluxe / Partenaire), preuve de réception. |
| **Stocks** | Snapshots, indicateurs, traçabilité auditable. |
| **Sorties** | Chargement au dépôt (preuve de sortie matière). |
| **Citernes** | Gestion des capacités et du stock physique par citerne. |
| **Ajustements de stock** | Corrections encadrées et tracées, hors flux standard. |
| **Logs / Audit** | Supervision et traçabilité des actions ; hors opérations courantes. |

### 2.2 Principe

Ce socle assure **la preuve matière** : ce qui est reçu, stocké et sorti est enregistré, cohérent et auditable. Aucune évolution post-prod ne doit remettre en cause cette chaîne ni en modifier le comportement nominal.

---

## 3. Philosophie post-prod

### 3.1 Séparation des responsabilités

- **Logistique** = preuve matière (réception, stock, sortie, citernes, ajustements).
- **Finance / Contrat** = engagement économique (garanties, factures, paiements, comptes).

Les deux mondes sont **strictement séparés** dans la conception des évolutions.

### 3.2 Règles de dépendance

- **La finance ne déclenche jamais la logistique.**  
  Aucun module financier ou contractuel ne peut initier ou modifier un flux de réception, de stock ou de sortie.
- **La logistique prouve ; la finance s’appuie sur la preuve.**  
  Les engagements et soldes financiers se fondent sur les données logistiques validées (réceptions, quantités, références), jamais l’inverse.

Toute évolution post-prod doit respecter cette philosophie pour rester compatible avec le socle et la gouvernance.

---

## 4. Stratégie post-prod (ordre strict)

Les évolutions post-prod sont découpées en **phases** dont l’ordre est **imposé**. Une phase ne démarre pas tant que la précédente n’est pas finalisée et déployée dans le périmètre défini.

### 4.1 Phase 1 — Fournisseurs (prioritaire)

**Objectif :** Finaliser et déployer l’ensemble de la chaîne fournisseur avant toute autre évolution métier.

**Périmètre (dans l’ordre de mise en œuvre) :**

1. **Fournisseurs** — Référentiel (existant en lecture seule ; à compléter si besoin).
2. **SBLC** (Standby Letter of Credit) — Garantie uniquement ; pas d’appel ni d’automatisation.
3. **Factures Proforma** — Cadre contractuel amont.
4. **Factures Fournisseurs (finales)** — Dette réelle, basée sur la preuve (réceptions).
5. **Paiements Fournisseurs** — Tracabilité des règlements.
6. **Compte Fournisseur** — Position nette et justification du solde.

**Règle absolue :** Tant que la chaîne Fournisseurs n’est pas **entièrement finalisée et déployée**, aucun module **Client** ou **Transporteur** ne doit être implémenté.

---

### 4.2 Phase 2 — Clients (futur, volontairement bloqué)

**Statut :** Non démarrée ; bloquée jusqu’à clôture de la Phase 1.

**Périmètre prévu (à titre de cadrage) :**

- Clients  
- Livraisons Clients (entité distincte des Sorties)  
- Factures Clients  
- Paiements Clients  
- Compte Client  

Aucune décision d’implémentation ni de calendrier n’est prise tant que la Phase 1 n’est pas close.

---

### 4.3 Phase 3 — Transporteurs Clients (futur, volontairement bloqué)

**Statut :** Non démarrée ; bloquée jusqu’à clôture de la Phase 2.

**Périmètre prévu (à titre de cadrage) :**

- Transporteurs pris en charge par Monaluxe  
- Transporteur identifié au chargement (Sortie)  
- Transporteur responsable à la Livraison Client  
- Paiement en deux temps : avance au chargement, solde à J+30 après livraison  
- Écarts de livraison : tracés, imputés au transporteur, **jamais** corrigés dans le stock  

Aucune décision d’implémentation ni de calendrier n’est prise tant que la Phase 2 n’est pas close.

---

## 5. Navigation cible (référence)

La cible de navigation de la plateforme, du point de vue métier et utilisateur, est la suivante. Elle sert de **référence** pour les évolutions d’interface et d’accès aux fonctionnalités.

| Entrée | Rôle |
|--------|------|
| **Dashboard** | Point d’entrée et vue d’ensemble selon le rôle. |
| **Opérations** | Accès aux flux logistiques (Cours de route, Réceptions, Sorties, Stocks, Citernes, Ajustements). |
| **Fournisseurs** | Chaîne fournisseur (référentiel, SBLC, Proformas, Factures, Paiements, Compte). |
| **Clients** | Futur ; bloqué jusqu’à Phase 2. |
| **Transporteurs** | Futur ; bloqué jusqu’à Phase 3. |
| **Supervision** | Logs, audit, contrôles. |
| **Administration** | Paramétrage et gouvernance de la plateforme. |

Cette structure reflète la séparation socle logistique / finance-contrat et l’ordre des phases post-prod.

---

## 6. Synthèse décisionnelle

- **Socle logistique** : CDR, Réceptions, Stocks, Sorties, Citernes, Ajustements, Logs — **acquis et non modifié** en post-prod.  
- **Philosophie** : Logistique = preuve ; Finance/Contrat = engagement ; la finance s’appuie sur la preuve, ne la déclenche pas.  
- **Stratégie** : Phase 1 Fournisseurs à finaliser et déployer en premier ; Phase 2 Clients et Phase 3 Transporteurs **bloquées** jusqu’à clôture des phases précédentes.  
- **Navigation cible** : Dashboard, Opérations, Fournisseurs, Clients (futur), Transporteurs (futur), Supervision, Administration.  

Ce document est la **référence officielle** du contexte général post-prod. Toute évolution doit être compatible avec ce cadre. Les détails techniques, fonctionnels ou de mise en œuvre figurent dans les documents dédiés (exigences, plans, runbooks).

---

**Document créé le :** 2026-02-08  
**Version :** 1.0.0  
**Type :** Document officiel de référence (contexte post-prod, orienté métier et plateforme)
