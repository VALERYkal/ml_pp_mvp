# SPEC — Écran Intégrité Système

## Route
/governance/integrity

## Accès
- admin
- directeur
- pca (lecture seule)

## Source de données
public.v_integrity_checks

## Pattern
- Repository + Riverpod
- Lecture seule
- Limit 200
- Tri: CRITICAL > WARN

## Fonctions
- Affichage liste alertes
- Filtres severity
- Filtre entity_type
- Compteurs (TOTAL / CRITICAL / WARN)
- Détail JSON payload
- Copier JSON

## Non Objectifs
- Aucune modification DB
- Aucune mutation
- Aucune suppression

## Objectif stratégique
Réduire TTD et TTM des incidents métier.

## Sécurité
- Respect RLS existantes.
- Aucune élévation de privilège.
