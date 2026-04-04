# ML_PP MVP — Project Context

## Project

ML_PP MVP (Monaluxe Petrol Platform) est un système de gestion logistique pour un dépôt pétrolier.

L’application permet de gérer :

- les transports fournisseurs (Cours de Route)
- les réceptions carburant
- les sorties carburant vers clients
- les stocks citernes
- les calculs volumétriques carburant
- la traçabilité des opérations

Le système est conçu comme un **ERP pétrolier minimal (MVP)** avec une logique métier industrialisable.

---

# Business Domain

Le système modélise les flux physiques du carburant dans un dépôt.

Pipeline métier :

Fournisseur  
→ Transport camion  
→ Cours de Route  
→ Réception dépôt  
→ Stock citerne  
→ Sortie vers client

Chaque mouvement est journalisé et impacte les stocks.

---

# Core Modules

## 1 — Cours de Route (CDR)

Représente un transport carburant entre un fournisseur et le dépôt.

Statuts possibles :

CHARGEMENT  
TRANSIT  
FRONTIERE  
ARRIVE  
DECHARGE

Pipeline :

ARRIVE → réception carburant  
réception validée → CDR = DECHARGE

---

## 2 — Réceptions

Une réception correspond à l’arrivée d’un camion carburant dans le dépôt.

Données terrain saisies :

- index_avant
- index_apres
- température ambiante
- densité observée

Le système calcule :

- volume_ambiant
- densite_a_15
- volume_15c

---

## 3 — Sorties produit

Une sortie correspond à une livraison carburant vers un client.

Données saisies :

- index compteur
- température
- densité

Le système calcule en base :

- **`volume_15c`** (colonne cible pour le volume à 15 °C, moteur ASTM lookup-grid)  
- **`volume_corrige_15c`** (maintenue en parallèle pour **compatibilité transitoire** et conventions d’arrondi métier associées)

**Migration progressive :** le frontend lit en priorité **`volume_15c`** avec repli sur **`volume_corrige_15c`** ; les modèles et payloads d’écriture ne sont pas entièrement harmonisés sur un seul nom — convergence ultérieure possible hors périmètre actuel.

---

## 4 — Stocks

Les stocks sont calculés automatiquement.

Table principale :

stocks_journaliers

Les mouvements impactant le stock :

- receptions
- sorties_produit

**Lecture du stock actuel :** la vue **`v_stock_actuel`** est la **source de vérité métier**. **`stocks_snapshot`** est un **cache technique** ; en cas d’écart, les corrections métier ne passent pas par une édition directe arbitraire du snapshot comme substitut de la vérité stock.

---

# Architecture

Frontend :

Flutter Web

Frameworks utilisés :

Riverpod  
GoRouter

---

Backend :

Supabase

Base de données :

PostgreSQL

---

# Architectural Principle

Principe clé du projet :

**la logique métier critique est exécutée dans la base de données.**

Cela inclut :

- calcul volumétrique
- validation métier
- calcul des stocks
- triggers automatiques
- journalisation des opérations

Ce choix garantit :

- cohérence métier
- auditabilité
- robustesse du système

---

# Data Model Core Tables

Tables principales :

cours_de_route  
receptions  
sorties_produit  
stocks_journaliers  
citernes  
produits  
clients  
partenaires

---

# Volumetric Requirement

Le système doit produire des calculs volumétriques conformes aux standards pétroliers :

API MPMS 11.1

Le volume standard utilisé est :

**Volume à 15°C**

---

# Project Status

ML_PP MVP est un système avancé en phase de stabilisation.

The ASTM volumetric engine is now deployed in both STAGING and PRODUCTION.

Both environments run the lookup-grid interpolation engine.

The system now computes:

- densite_a_15
- VCF
- volume_15c

directly in the database using ASTM lookup-grid interpolation.

The application runtime path is identical between STAGING and PROD.
