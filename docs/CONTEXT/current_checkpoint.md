# Current Checkpoint — Volumetric Migration

## Date

Mars 2026

---

# Environment Status

## STAGING

STAGING contient :

- moteur volumétrique ASTM
- lookup grid dataset
- golden dataset installé
- triggers volumétriques actifs
- nouvelles colonnes densité

Le moteur volumétrique fonctionne correctement.

---

## PROD

PROD utilise encore l’ancien moteur volumétrique.

Il manque :

- schéma astm
- lookup grid dataset
- triggers volumétriques
- nouvelles colonnes densité

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

La stratégie choisie est :

purge contrôlée des transactions.

Les tables suivantes seront vidées :

sorties_produit  
receptions  
stocks_journaliers

Ensuite :

le nouveau moteur volumétrique sera activé.

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

# Goal

Activer en production :

le moteur volumétrique lookup-grid conforme API MPMS 11.1.
