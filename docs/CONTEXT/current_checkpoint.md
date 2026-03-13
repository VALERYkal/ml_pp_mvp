# Current Checkpoint — Volumetric Migration

## Date

Mars 2026

---

# Environment Status

## STAGING

- ASTM volumetric engine active
- lookup grid dataset installed
- golden dataset installed
- volumetric triggers active

---

## PROD

- ASTM volumetric engine active
- lookup grid dataset installed
- volumetric triggers active
- historical receptions recalculated

---

# Data State

PROD contient :

8 réceptions historiques.

Volumes approximatifs :

39291  
39296  
39391  
36971  
38312  
39330  
37383  
33445

Ces volumes ont été calculés avec l’ancien moteur.

---

# Migration Strategy

The migration has been completed.

Strategy executed: controlled purge of legacy transactions, then installation of ASTM schema, lookup grid dataset, volumetric functions and triggers, replay of the 8 historical receptions, reconstruction of stocks, system reopening.

The new volumetric engine is now active in production.

---

# Required Schema Changes

Réceptions :

ajouter

densite_observee_kgm3  
densite_a_15_kgm3  
densite_a_15_g_cm3

Sorties :

ajouter

densite_a_15_kgm3  
densite_a_15_g_cm3

---

# Migration Steps

1 backup base production  
2 purge transactions  
3 migration schéma tables  
4 création schéma astm  
5 installation golden dataset  
6 installation fonctions interpolation  
7 installation moteur volumétrique  
8 installation triggers  
9 smoke tests  
10 réouverture système

---

# Current Work Status

Nous avons déjà :

analysé staging  
analysé production  
comparé les schémas  
validé le moteur volumétrique  
validé le dataset  
rédigé le runbook de migration

---

# Next Step

Préparer le package final d’activation production :

- scripts SQL
- installation dataset
- installation fonctions
- activation triggers
- tests volumétriques

---

# Migration Result

Production is now aligned with staging on the ASTM lookup-grid volumetric runtime.

All receptions and stock calculations now use the new volumetric engine.

---

# Goal

Activer en production :

le moteur volumétrique lookup-grid conforme API MPMS 11.1.

(Goal achieved: the lookup-grid engine is now active in both STAGING and PROD.)
