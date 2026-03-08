# ML_PP MVP — Architecture Map

## Purpose

Ce document fournit une vue d’ensemble rapide de l’architecture du système ML_PP MVP.

Il permet à un développeur ou à une IA de comprendre immédiatement :

- les flux métier
- les composants techniques
- la logique volumétrique
- les interactions entre modules

---

# System Overview

ML_PP MVP est un système de gestion logistique pour un dépôt pétrolier.

Le système suit le flux physique du carburant :

Fournisseur  
→ Transport camion  
→ Cours de Route  
→ Réception dépôt  
→ Stock citerne  
→ Sortie client

Chaque étape est enregistrée dans la base de données et impacte les stocks.

---

# High Level Architecture

Frontend

Flutter Web  
Riverpod  
GoRouter

↓

API

Supabase

↓

Backend

PostgreSQL

↓

Business Logic

DB Triggers  
DB Functions  
Volumetric Engine

---

# Core Business Flow

## 1 — Transport

Table :

cours_de_route

Statuts :

CHARGEMENT  
TRANSIT  
FRONTIERE  
ARRIVE  
DECHARGE

---

## 2 — Réception carburant

Table :

receptions

Inputs terrain :

index_avant  
index_apres  
temperature  
densite_observee

Calculs effectués :

volume_ambiant  
densite_a_15  
volume_15c

---

## 3 — Stock

Table :

stocks_journaliers

Le stock est recalculé automatiquement après :

- réception
- sortie produit

---

## 4 — Sortie carburant

Table :

sorties_produit

Calcul :

volume_corrige_15c

---

# Volumetric Engine

Le système utilise un moteur volumétrique basé sur :

API MPMS 11.1.

Architecture :

lookup grid volumetric interpolation.

---

# Volumetric Pipeline

Inputs terrain :

volume_observe  
temperature  
densite_observee

↓

lookup grid interpolation

↓

densite_a_15  
VCF  
volume_15c

↓

écriture en base

---

# Key Database Components

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

Fonctions volumétriques :

astm.compute_v15_from_lookup_grid  
astm.lookup_15c_bilinear_v2  
astm.assert_lookup_grid_domain

---

# Triggers

Triggers critiques :

receptions_compute_15c_before_ins  
sorties_produit triggers

Ces triggers :

- exécutent les calculs volumétriques
- garantissent la cohérence des données

---

# Lookup Grid Dataset

Table :

astm.lookup_grid

Configuration :

produit = GASOIL  
source = ASTM_OFFICIAL_APP  
method = API_MPMS_11_1  
batch = GASOIL_P0_2026-02-28

Dataset :

63 points

Axes :

9 densités  
7 températures

Domaine :

densité 820 → 860 kg/m3  
température 10 → 40 °C

---

# Rounding Policy

Réceptions :

volume_15c arrondi à 1 décimale

Sorties :

volume_corrige_15c arrondi au litre entier

---

# System Principle

Principe architectural central :

La logique métier critique est exécutée dans la base de données.

Cela garantit :

- cohérence métier
- auditabilité
- robustesse du système

---

# Environment Setup

STAGING :

moteur volumétrique actif  
dataset installé  
triggers actifs

PROD :

ancien moteur volumétrique encore actif  
migration prévue

---

# Next Major Operation

Activation du moteur volumétrique ASTM en production.
