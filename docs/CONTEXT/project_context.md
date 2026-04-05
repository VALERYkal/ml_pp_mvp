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

Workflow canonique :

CHARGEMENT  
TRANSIT  
FRONTIERE  
ARRIVE  
DECHARGE

Pipeline métier :

ARRIVE → réception carburant  
réception validée → CDR = DECHARGE

Le CDR ne possède qu’une seule source de vérité d’état : la colonne `statut` en base de données.

Toute logique applicative parallèle (ex: etat, state machine frontend) a été supprimée.

Les transitions métier sont pilotées par:
- les actions utilisateur (updateStatut)
- les triggers DB (ex: réception → DECHARGE)

Il est interdit d’introduire une seconde machine d’état côté application.

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

**Contrat de lecture app :** **`volume_15c ?? volume_corrige_15c`** (canonique puis legacy) sur les périmètres alignés VOL15.

**Validation STAGING récente :** le chemin critique réception / sortie / stock / RLS a été contrôlé avec succès sur **STAGING** (DB tests + vérifications associées), cohérent avec ce contrat et la volumétrie calculée en base.

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

Les validations récentes sur **STAGING** confirment que les **calculs critiques** (volumétrie, stock, effets de mouvements) restent portés par la **DB** ; le **frontend** assure saisie, lecture et orchestration sans substituer la vérité métier.

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

ML_PP MVP est un **système avancé en stabilisation** après validation récente du **pipeline critique** sur **STAGING** (smoke DB, réception → `stocks_journaliers`, sortie → stock → log, RLS admin / lecture / refus non-admin, alignement **VOL15** lecture côté app sur les flux testés).

Le **moteur volumétrique ASTM** (lookup-grid) est déployé en **STAGING** et en **PRODUCTION** ; les environnements partagent le même principe d’interpolation en base.

Le système calcule en base (selon le pipeline déployé) notamment **densité à 15 °C**, **VCF** et **`volume_15c`**.

Le **frontend VOL15** est aligné sur la DB : lecture **`volume_15c ?? volume_corrige_15c`**, sans logique métier volumétrique critique côté application sur le périmètre traité.

La **validation documentée ici** porte sur les **preuves STAGING** ; elle ne remplace pas un rapport de tests PROD distinct si le périmètre l’exige.
