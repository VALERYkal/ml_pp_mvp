# ML_PP MVP — PROD is LIVE

## Statut
- Environnement : **PRODUCTION**
- Statut : **GO LIVE effectif**
- Tag Git de référence : `prod-j0-2026-02`
- Date GO LIVE : Février 2026
- Client : **Monaluxe**

> ⚠️ Ce dépôt est en **mode PROD**.  
> Toute modification doit être volontaire, tracée et validée.
## Accès & responsabilités
- **PROD** : accès restreint (principle of least privilege)
- **Base de données** : Supabase (Postgres, pooler)
- **Accès psql** : via `.pgpass` local (aucun secret en clair)
- **Modifications** :
  - Pas de changements en PROD sans décision explicite
  - Toute action doit être traçable (commit, tag, runbook)

## Support & exploitation
- Surveillance fonctionnelle post-GO LIVE
- Incidents : diagnostiquer avant toute action corrective
- Référence historique : tag `prod-j0-2026-02`

