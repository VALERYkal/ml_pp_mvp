# POST-PROD — Monitoring & Alerting (Industriel)

## But
Mettre en place une surveillance "industrielle" progressive, sans surdimensionner l'outillage.

## Phase 1 — Déployée
### Niveau 0 — Uptime
- UptimeRobot : monitor HTTP sur https://monaluxe.app (5 min)
- Alerte opérationnelle reçue lors du test.

### Niveau 1 — Observabilité erreurs front
- Sentry : collecte erreurs Flutter Web
- Règles d'alerte:
  - New Issue (env=production)
  - Spike > 10 events / 5 min (env=production)
- Notification testée et validée.

## Gouvernance
- Ce qui compte: réduire le "temps de découverte" (TTD) et le "temps de mitigation" (TTM)
- Référence opérationnelle: runbook
  - [docs/02_RUNBOOKS/MONITORING_ALERTING.md](../02_RUNBOOKS/MONITORING_ALERTING.md)

## À faire ensuite (Phase 2)
- Monitoring métier (invariants SQL)
- Monitoring backend/sécurité (RLS/5xx/latence)
- Mini "cockpit santé" interne (option post Phase 2)
