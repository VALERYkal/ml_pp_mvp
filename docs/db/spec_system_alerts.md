# spec_system_alerts — Table de persistance des alertes intégrité

## Objectif

Table de persistance et de workflow pour les alertes issues de `public.v_integrity_checks`, alimentée par un job de synchronisation (patch séparé). Permet un cycle de vie OPEN → ACK → RESOLVED.

## Non-objectifs (ce patch)

- Pas de cron/job d’évaluation dans ce patch.
- Pas de notifications automatiques.
- Pas de modification de `v_integrity_checks`.

---

## Schéma

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| id | uuid | PK, default gen_random_uuid() | Identifiant unique |
| check_code | text | NOT NULL | Code métier (ex: STOCK_NEGATIF, CDR_ARRIVE_STALE) |
| severity | text | NOT NULL, CHECK IN ('CRITICAL','WARN') | Niveau de gravité |
| entity_type | text | NOT NULL | Type d’entité (CDR, CITERNE_STOCK, etc.) |
| entity_id | uuid | NOT NULL | UUID de l’entité concernée |
| message | text | NOT NULL | Message lisible |
| payload | jsonb | NOT NULL, default '{}' | Données complémentaires |
| status | text | NOT NULL, default 'OPEN', CHECK IN ('OPEN','ACK','RESOLVED') | État du workflow |
| first_detected_at | timestamptz | NOT NULL, default now() | Première détection |
| last_detected_at | timestamptz | NOT NULL, default now() | Dernière détection (mise à jour par le job) |
| acknowledged_by | uuid | NULL | Utilisateur qui a ACK |
| acknowledged_at | timestamptz | NULL | Date/heure ACK |
| resolved_by | uuid | NULL | Utilisateur qui a RESOLVED |
| resolved_at | timestamptz | NULL | Date/heure RESOLVED |
| created_at | timestamptz | NOT NULL, default now() | Création |
| updated_at | timestamptz | NOT NULL, default now() | Dernière modification (trigger) |

**Contrainte d’unicité** : `UNIQUE (check_code, entity_type, entity_id)` — une seule alerte par anomalie et par entité.

---

## Workflow

| État | Sémantique |
|------|------------|
| OPEN | Alerte détectée, non traitée |
| ACK | Pris en charge par un opérateur (admin/directeur) |
| RESOLVED | Clôturée (cause traitée ou acceptée) |

Transitions : OPEN → ACK → RESOLVED.

---

## Règle de déduplication

Une ligne par couple `(check_code, entity_type, entity_id)`. Le job de sync fera :
- **INSERT** si aucune ligne n’existe pour ce triplet.
- **UPDATE** `last_detected_at` (et éventuellement `message`, `payload`) si une ligne existe déjà et que la condition est toujours vraie dans `v_integrity_checks`.

---

## Mise à jour de last_detected_at

Le job de synchronisation (patch 2.2) met à jour `last_detected_at` à chaque passage lorsque l'anomalie est toujours présente dans la vue.

---

## Sync job semantics (Patch 2.2)

Fonction : `public.sync_system_alerts_from_integrity(p_limit int DEFAULT 200)`.

### Upsert

Pour chaque ligne de `v_integrity_checks` (LIMIT p_limit) :

- **INSERT** si aucune ligne n'existe pour `(check_code, entity_type, entity_id)`.
- **UPDATE** si la ligne existe : `severity`, `message`, `payload`, `last_detected_at` = now().
- Ne jamais modifier `first_detected_at` après création.
- Si statut existant = ACK : conserver `acknowledged_by`, `acknowledged_at`.

### Reopen (RESOLVED → OPEN)

Si une alerte est en RESOLVED et que la vérification réapparaît dans la vue :

- `status` = 'OPEN'
- `resolved_by`, `resolved_at` = NULL
- `acknowledged_by`, `acknowledged_at` = NULL (nouveau cycle)
- Mise à jour de `severity`, `message`, `payload`, `last_detected_at` = now()

### Auto-resolve

Toute alerte en OPEN ou ACK dont `(check_code, entity_type, entity_id)` n'est plus présent dans le snapshot courant :

- `status` = 'RESOLVED'
- `resolved_by` = NULL (résolution système)
- `resolved_at` = now()
- Aucune suppression de lignes.

### p_limit

Par défaut 200. Limite le nombre de lignes prises en compte dans `v_integrity_checks` à chaque exécution.

### Scheduler

Pas de cron/pg_cron dans ce patch. La fonction est appelée manuellement ou par un job externe.

---

## RLS

- **admin, directeur** : accès complet (SELECT, INSERT, UPDATE, DELETE).
- **pca** : SELECT uniquement (lecture seule).
- **Autres rôles** : aucun accès.

Pas de politique pour `anon`.

---

## Rollback (STAGING)

Table (Patch 2.1) :
```sql
DROP TABLE IF EXISTS public.system_alerts CASCADE;
```

Fonction sync (Patch 2.2) :
```sql
DROP FUNCTION IF EXISTS public.sync_system_alerts_from_integrity(int);
```

Ne pas supprimer les fonctions partagées (`public.update_updated_at_column`, `app_*`).
