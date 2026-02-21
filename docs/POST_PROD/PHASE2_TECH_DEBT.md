# Phase 2 — Dette technique documentée

**Contexte** : Dette technique identifiée lors du déploiement Phase 2 — Action 2.4 (Governance ACK/RESOLVE workflow). Ces éléments sont connus et volontairement différés.

---

## 🧨 TECH-DEBT — Governance ACK/RESOLVE Workflow

### Problèmes identifiés

| # | Problème | Description |
|---|----------|-------------|
| 1 | `acknowledged_by` reste null dans certains cas | L'audit utilisateur n'est pas systématiquement renseigné |
| 2 | UI ne désactive pas bouton ACK après mutation | L'état visuel du bouton peut rester "actif" après un ACK réussi |
| 3 | Snackbar affiche succès même si mutation partielle | Feedback utilisateur potentiellement trompeur |
| 4 | Policy UPDATE compare `p.id = auth.uid()` au lieu de `p.user_id = auth.uid()` | La policy RLS `system_alerts_update_admin_directeur` compare l'ID du profil (`profils.id`) avec `auth.uid()` au lieu de `profils.user_id` |
| 5 | Provider Riverpod ne refetch pas après mutation | Rafraîchissement des données potentiellement incomplet |

### Impact

- **Non bloquant**
- **Fonctionnel en exploitation**
- Incohérence UI / audit partiel

### Priorité

**P3** (non critique)

### Référence

- Déploiement : Entry 3 — `docs/POST_PROD/12_PHASE2_PROD_DEPLOY_LOG.md`
- Tracker : Action 2 — `docs/POST_PROD/11_PHASE2_TRACKER.md`
