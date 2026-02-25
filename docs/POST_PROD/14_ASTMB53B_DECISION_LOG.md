# Decision Log — ASTM53B Migration

Date : 2026-02-25  
Branche : feature/astm11-1-validation-P0  
PR : #89  

## Contexte

Écart terrain confirmé 50–70 litres par réception
entre ML_PP et application SEP.

Cause suspectée :
Formule volumétrique legacy incorrecte.

Décision :
Migration vers standard API MPMS 11.1 (ASTM 53B — 15°C).

## Portée

- Réceptions
- Sorties
- Stocks journaliers
- validate_sortie (DB-STRICT)

## Risques identifiés

- Impact sur 8 réceptions déjà encodées en PROD
- 2 camions non encore encodés
- Impact potentiel sur stock réel
- Impact reporting financier

## Statut

En attente validation terrain finale avant activation PROD.
Feature flag ASTM encore OFF en PROD.
