# Sécurité — Table `stocks_adjustments`

**Dernière mise à jour** : 2026-02-12  
**Contexte** : Session critique Web PROD (RLS + endpoint)

---

## Table : `stocks_adjustments`

- **Row Level Security (RLS)** : `rowsecurity = true`
- RLS activé et validé en PROD.

## Accès autorisé

- **admin** : lecture / écriture
- **directeur** : lecture / écriture
- **gérant** : lecture / écriture

## Accès refusé

- **pca** (Préposé Compteur d'Accès) : **pas d'accès** aux ajustements.
  - Lecture seule globale sur les données métier (hors ajustements).
  - Conforme à la séparation des responsabilités : le PCA ne gère pas les ajustements de stock.

## Conformité

Conforme séparation des responsabilités et politique de sécurité des données (ajustements réservés aux rôles opérationnels habilités).
