# POST-PROD — Overview

## Contexte
ML_PP (Monaluxe Petrol Platform) est en PROD EN EXPLOITATION depuis le 2026-02-05.
Le socle logistique est validé et ne doit pas être modifié.

## Règle absolue
Toute évolution doit être classée dans une catégorie POST-PROD :
- MAINTENANCE
- AUDIT
- SCALE
- POST-PROD FEATURE

## Invariants intouchables
- Flux métier : CDR → Réception → Stock → Sortie
- Source de vérité stock : v_stock_actuel
- RLS + triggers (sécurité & métier)
- IDs produits canoniques
- Aucun reset PROD
- Aucune suppression destructive (vues, triggers, RLS, contrats)

## Principe POST-PROD
Le POST-PROD ajoute des modules **au-dessus** du socle existant.
Aucune fonctionnalité post-prod ne doit "mélanger" finance/contrats avec les écrans opérationnels.

## Objectif POST-PROD
Faire évoluer ML_PP vers une plateforme ERP pétrolière modulaire :
- Logistique (socle existant)
- Contractuel & financier (nouveaux modules)
- Contrôle (écarts, litiges, audit)
