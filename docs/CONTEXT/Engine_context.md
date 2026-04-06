# Volumetric Engine — Technical Context

## Purpose

Le moteur volumétrique de ML_PP MVP calcule le volume carburant standardisé à 15°C.

Ce calcul est nécessaire pour :

- les réceptions carburant
- les sorties carburant
- la cohérence des stocks

Le moteur implémente les principes de :

API MPMS 11.1

---

# Previous System

The system previously allowed manual entry of densite_a_15 (density at 15°C).

The current architecture enforces observed density input (densite_observee) and computes densite_a_15 in the database. Manual densite_a_15 is no longer accepted for the volumetric path; the density at 15°C must be calculated by the engine, not entered by the user.

---

# New Volumetric Model

Le nouveau modèle utilise :

densité observée terrain.

Inputs :

volume_observe  
temperature  
densite_observee

Outputs calculés :

densite_a_15  
VCF  
volume_15c

---

# Engine Architecture

Le moteur est exécuté entièrement dans PostgreSQL.

Il repose sur :

lookup grid volumetric interpolation.

---

# Core Function

Fonction principale :

astm.compute_v15_from_lookup_grid()

Arguments :

volume_observe_l  
temperature_c  
densite_observee_kgm3  
produit_code  
source  
method_version  
batch_id

Outputs :

densite_a_15_kgm3  
vcf  
volume_15c_l

---

# Lookup Grid

Le moteur utilise un dataset volumétrique appelé :

lookup grid.

Table :

astm.lookup_grid

---

# Dataset Configuration

produit_code = GASOIL  
source = ASTM_OFFICIAL_APP  
method_version = API_MPMS_11_1  
batch_id = GASOIL_P0_2026-02-28

---

# Dataset Structure

Nombre de points :

63

Axes :

9 densités  
7 températures

---

# Dataset Domain

densité observée :

820 → 860 kg/m3

température :

10 → 40 °C

---

# Domain Guard

Une fonction empêche les calculs hors domaine.

Fonction :

astm.assert_lookup_grid_domain()

Si les inputs sortent du domaine du dataset :

une exception est levée.

---

# Interpolation

Le calcul volumétrique utilise :

interpolation bilinéaire.

Fonction :

astm.lookup_15c_bilinear_v2()

---

# Production Deployment

The ASTM lookup-grid volumetric engine is now deployed in both STAGING and PRODUCTION.

All volumetric computations are executed inside PostgreSQL.

The engine uses the lookup grid dataset (astm_lookup_grid_15c) and bilinear interpolation.

---

# Sorties — volume à 15 °C (complément)

Pour les **sorties**, le pipeline ASTM (lookup-grid) alimente désormais aussi le volume standardisé à 15 °C via la colonne cible **`volume_15c`** sur **`sorties_produit`**, en complément du chemin historique.

**`volume_corrige_15c`** reste **écrite et conservée** pour compatibilité transitoire et pour la politique d’**arrondi métier** sorties (litre entier) documentée sur ce champ. La logique de calcul ASTM (domaine, interpolation, `compute_v15_from_lookup_grid`) n’est pas remplacée par une saisie manuelle du volume @15 °C.

**Lecture applicative :** **`volume_15c ?? volume_corrige_15c`** sur les périmètres Flutter migrés.

---

# Reception Trigger

Le calcul volumétrique est exécuté automatiquement lors d’une réception.

Trigger :

receptions_compute_15c_before_ins

Pipeline :

volume_ambiant  
→ validation domaine  
→ interpolation lookup grid  
→ calcul volume_15c

---

# Rounding Policy

Réceptions :

volume_15c arrondi à 1 décimale.

Sorties :

volume_corrige_15c arrondi au litre entier.

Cette convention est volontaire et documentée.

---

# Note — lot fournisseur

Le **lot fournisseur** est un objet **logistique amont** (regroupement de CDR sous une référence fournisseur). Il **n’alimente pas** le moteur ASTM, **n’intervient pas** dans les calculs volumétriques ni dans les volumes persistés pour réception / sortie / stock.
