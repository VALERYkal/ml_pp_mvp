# POST-PROD — Architecture Fonctionnelle Globale (v1)

## 1. Objectif
Définir la structure fonctionnelle globale du POST-PROD afin de transformer ML_PP
en ERP pétrolier spécialisé, sans modifier le socle opérationnel existant.

---

## 2. Socle opérationnel (intouchable)
Le flux suivant reste strictement inchangé :
CDR → Réception → Stock → Sortie

Source de vérité stock : v_stock_actuel

---

## 3. Domaines Fonctionnels

### DOMAINE 1 — OPERATIONS (déjà en PROD)
- Cours de Route (CDR)
- Réceptions
- Sorties
- Stock
- Citernes

Ce domaine est stable et validé.

---

### DOMAINE 2 — PROCUREMENT (Fournisseurs / AP)
Chaîne documentaire :
SBLC → Proforma → CDR → Réceptions → Facture Finale → Paiements → Relevé fournisseur

Objectif :
Gérer l'engagement fournisseur jusqu'au paiement complet, avec gestion des écarts Proforma vs Réceptions.

---

### DOMAINE 3 — SALES (Clients / AR)
Chaîne documentaire :
Sortie → Livraison → Facture client → Encaissement → Relevé client

Objectif :
Suivre les ventes et les créances clients, avec gestion des écarts Sortie vs Livraison (si applicable).

---

### DOMAINE 4 — LOGISTICS (Transporteurs)
Chaîne documentaire :
Mission → Livraison → Avance → Paiement → Relevé transporteur

Objectif :
Tracer les coûts logistiques, avances, paiements et soldes transporteurs.

---

### DOMAINE 5 — CONTROL & AUDIT
- Module Écarts & Anomalies (centre unique)
- Litiges
- Ajustements
- Journal avancé
- Reporting direction

Objectif :
Maîtriser les différences volumes et financières, et assurer une traçabilité opposable.

---

## 4. Principes clés
1. Séparation stricte Opérations / Finance
2. Traçabilité complète des documents
3. Gestion explicite des écarts via un module central (pas de logique dispersée)
4. Préparation multi-organisation (future-ready)

---

## 5. Navigation (règle simple)
Navigation principale par domaines :
Dashboard → Opérations → Stock → Partenaires → Finances → Rapports → Administration
