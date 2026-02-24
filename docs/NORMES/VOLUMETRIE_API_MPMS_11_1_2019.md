# Norme volumétrique officielle – ML_PP

## Référence normative

ML_PP adopte officiellement :

> API MPMS Chapter 11.1 (2019 Edition)  
> Temperature and Pressure Volume Correction Factors for Generalized Crude Oils, Refined Products, and Lubricating Oils

## Portée

Cette norme devient la référence volumétrique officielle interne pour :

- Réceptions produit
- Sorties produit
- Calcul des stocks journaliers
- KPI volumétriques
- Toute opération impliquant une correction de volume à 15°C

## Implémentation technique

- Table utilisée : Table 54B (Refined Products)
- Température de référence : 15 °C
- Unités :
  - Densité observée : kg/m³
  - Température observée : °C
  - Volume observé : Litres
- Volume à 15°C = volumeObserved × VCF
- Arrondi final : au litre le plus proche

## Règles strictes

- Aucun facteur de calibration empirique autorisé
- Aucun alignement sur outil tiers (ex : SEP)
- Les outils externes sont indicatifs mais non normatifs
- Toute évolution du moteur doit référencer explicitement API MPMS 11.1 (2019)

## Position stratégique

ML_PP devient l'autorité volumétrique interne de Monaluxe.

Les écarts avec des outils tiers ne constituent pas une anomalie si ML_PP respecte la norme API MPMS 11.1 (2019).

## Gouvernance

- Toute modification du moteur volumétrique nécessite :
  - PR dédiée
  - Validation technique
  - Mise à jour documentation
  - Journalisation post-production
