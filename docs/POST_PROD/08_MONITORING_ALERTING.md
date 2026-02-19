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

### Monitoring métier — Implémenté partiellement
- **v_integrity_checks** : vue SQL temps réel des anomalies (stock négatif, surcapacité, CDR stale, écarts 15°C). Source de vérité pour détection.
- **system_alerts** : couche de persistance et workflow (OPEN → ACK → RESOLVED). Alimentée par le job de sync (patch séparé). Permet ACK/RESOLVE par admin/directeur.
- **Écran Integrity Checks** : exploitable en PROD, lit aujourd’hui `v_integrity_checks`. Une future évolution lira `system_alerts` et proposera les actions ACK/RESOLVE.

### À documenter
- Monitoring backend/sécurité (RLS/5xx/latence)
- Mini "cockpit santé" interne (option post Phase 2)
