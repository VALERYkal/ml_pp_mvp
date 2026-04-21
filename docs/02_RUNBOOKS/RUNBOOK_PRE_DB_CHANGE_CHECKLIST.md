# RUNBOOK — PRE DB CHANGE CHECKLIST

## OBJECTIF
Check minimal obligatoire avant toute intervention DB sur zone critique.

## QUAND L'UTILISER
Avant toute action sur :
- RLS
- triggers
- fonctions critiques
- moteur ASTM
- réceptions
- sorties
- stock

## CHECKLIST MINIMALE
- [ ] backup validé si PROD
- [ ] périmètre identifié (RLS / trigger / fonction / vue / grants)
- [ ] triggers critiques listés et contrôlés
- [ ] fonctions critiques identifiées
- [ ] grants schéma vérifiés
- [ ] grants EXECUTE fonctions critiques vérifiés
- [ ] policies RLS lues sur table concernée
- [ ] comparaison STAGING / PROD si incident ou divergence
- [ ] pack canonique mis à jour après incident/résolution

## CHECKLIST CIBLEE ASTM
- [ ] USAGE sur schéma `astm`
- [ ] EXECUTE sur fonctions `astm.*`
- [ ] trigger Réception présent (`trg_receptions_compute_15c_before_ins`)
- [ ] trigger/fonction appelle bien `astm.*`
- [ ] script `docs/DB_CHANGES/2026-04-21_astm_grants_guard.sql` exécuté
- [ ] résultat archivé / copié dans la trace d’intervention

## SORTIE ATTENDUE
- GO : tous les checks critiques au vert
- NO-GO : au moins un check KO, correction obligatoire avant modification
