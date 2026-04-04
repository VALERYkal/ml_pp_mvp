# ARCHITECTURE MAP — ML_PP MVP

## ROLE
Fournir une vue claire du système pour savoir où intervenir sans casser les invariants.

## UPDATE FREQUENCY
À chaque modification structurelle du système (DB, flux métier, modules).

## OBJECTIF
Permettre de :
- comprendre les flux métier
- identifier les zones d’intervention
- éviter les modifications dangereuses

---

# VUE GLOBALE

ML_PP MVP est un système de gestion logistique pétrolière piloté par la base de données.

Principe central :
- DB = source de vérité
- logique métier critique = DB
- frontend = UI + orchestration

---

# FLUX MÉTIER PRINCIPAL

Fournisseur
→ Cours de Route
→ Réception
→ Stock
→ Sortie

---

# MODULES PRINCIPAUX

- Authentification / profils
- Cours de route
- Réceptions
- Stocks
- Sorties produit
- Citernes
- Logs / audit
- Dashboard

---

# RESPONSABILITÉS PAR COUCHE

## Frontend
Flutter :
- affiche
- orchestre
- valide l’expérience utilisateur
- ne porte pas la logique métier critique

## Backend / DB
PostgreSQL / Supabase :
- applique les règles métier
- calcule les volumes
- calcule le stock
- protège la cohérence via triggers, fonctions et vues

---

# TABLES CLÉS

- cours_de_route
- receptions
- sorties_produit
- stocks_journaliers
- citernes
- produits
- clients
- partenaires
- log_actions

---

# SOURCES DE VÉRITÉ OPÉRATIONNELLES

- Stock actuel → v_stock_actuel
- Réception → receptions
- Sortie → sorties_produit
- Flux transport → cours_de_route
- Audit → log_actions

Caches dérivés :
- stocks_snapshot → technique uniquement, non source de vérité métier  
  (voir system_invariants.md)

---

# ZONES D’INTERVENTION

## Si le besoin concerne Cours de Route
Toucher :
- cours_de_route
- écrans / providers CDR

## Si le besoin concerne Réception
Toucher :
- receptions
- triggers / fonctions associées
- écrans / services Réception

## Si le besoin concerne Stock
Toucher :
- v_stock_actuel (lecture métier)
- stocks_journaliers (journal / support)
- fonctions / vues de stock

## Si le besoin concerne Sortie
Toucher :
- sorties_produit
- triggers / fonctions associées
- écrans / services Sortie

---

# ZONES À HAUT RISQUE

Les zones suivantes sont critiques :
- triggers DB
- fonctions DB
- vues de stock
- moteur volumétrique ASTM

Toute modification sur ces zones doit être traitée comme sensible.

---

# RÈGLE D’INTERVENTION

Avant toute modification :
1. Lire current_checkpoint.md
2. Appliquer architecture_rules.md
3. Identifier la zone concernée
4. Vérifier la DB si nécessaire
5. Intervenir dans le périmètre strict