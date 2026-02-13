# Runbook — Monitoring & Alerting (ML_PP)

## Objectif (règle des 2 minutes)
Pouvoir répondre en moins de 2 minutes à :
- La PROD est-elle UP ?
- Si non, pourquoi ?
- Depuis quand ?
- Est-ce un incident technique ou un incident métier ?
- Qui doit agir ?

## Périmètre
Phase 1 = "Niveau 0 + Niveau 1"
- Niveau 0 : disponibilité (site web)
- Niveau 1 : erreurs applicatives front (Flutter Web)

Les niveaux suivants (métier, backend/sécurité) sont planifiés mais pas encore déployés.

---

## ✅ État actuel — Implémenté

### Niveau 0 — Disponibilité (UptimeRobot)
- Monitor: HTTP(s) sur https://monaluxe.app
- Intervalle: 5 minutes (limite version gratuite)
- Résultat attendu: alerte si HTTP != 200 / timeout / downtime.

**Test effectué**
- ✅ A2 (test uptime): alerte reçue.

**Limites connues**
- Pas de "SSL expiry checks" / "domain expiry reminders" en free.
- Pas de "smoke endpoint" dédié (on surveille la home/SPA).

---

### Niveau 1 — Erreurs applicatives (Sentry)
- Produit: Sentry
- Intégration: sentry_flutter (Flutter Web)
- Configuration via --dart-define
  - SENTRY_DSN
  - APP_ENV (ex: production / staging)
  - APP_RELEASE (ex: mlpp-web)

**Règles d'alerting configurées**
1) Rule #1 — New issue created
- Trigger: "A new issue is created"
- IF: tag environment == production
- THEN: notification aux membres/assignees configurés
- Action interval: 24h

2) Rule #2 — Spike d'événements (anti "incident silencieux")
- Trigger: "Number of events in an issue is more than 10 in 5 minutes"
- + (optionnel/présent selon configuration): "A new issue is created"
- IF: tag environment == production
- THEN: notification (Suggested Assignees, fallback All Project Members)
- Action interval: 24h

**Tests effectués**
- ✅ B2 (test notification Sentry): alerte reçue.

---

## Procédures (opérationnel)

### Si UptimeRobot alerte "DOWN"
1) Confirmer rapidement depuis un navigateur externe (4G si possible)
2) Vérifier Firebase Hosting (statut domaine / dernières releases)
3) Vérifier Supabase (status page + latence API si suspicion)
4) Si impact confirmé : déclencher incident interne + appliquer runbook rollback (si disponible)

### Si Sentry alerte "New issue" ou "Spike"
1) Ouvrir l'Issue Sentry → "Stack Trace" + "Tags"
2) Identifier:
- environment (production/staging)
- release
- browser.name
3) Classer:
- Erreur bloquante (login, dashboard, réception, sortie)
- Erreur non bloquante (noise / plugin / navigateur)
4) Action:
- Mitigation immédiate si possible (feature flag / revert / hotfix)
- Sinon: créer ticket correctif et prioriser

---

## Checkpoints & validation
- ✅ A2 (test uptime) : OK
- ✅ B2 (test notification Sentry) : OK
- ✅ C (doc runbook ajouté) : OK

---

## Next (Phase 2 — à planifier)
Niveau 2 (métier):
- invariants SQL: stock négatif, snapshot absent, mélange propriétaire, sorties incohérentes, CDR bloqués, etc.
Niveau 3 (backend/sécurité):
- 401/403 spikes (RLS), 5xx, requêtes lentes, rate limiting, etc.
