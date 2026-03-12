# Backup instructions — Production migration

Before running any destructive step of the ASTM volumetric migration, a full backup of the production database is **mandatory**.

## When to run

- **Before** executing `03_purge_receptions.sql`
- After GO/NO-GO checklist is validated
- Within the same maintenance window as the migration

## Methods

### Option A — Supabase Dashboard

1. Open the Supabase project for **production**.
2. Go to **Settings → Database**.
3. Use **Backup** or **Create backup** (depending on plan).
4. Wait for completion and note the backup identifier and timestamp.

### Option B — pg_dump (self-hosted or direct connection)

```bash
# Full database
pg_dump "$PROD_DATABASE_URL" -Fc -f "backup_prod_pre_astm_$(date +%Y%m%d_%H%M).dump"

# Verify
pg_restore --list "backup_prod_pre_astm_YYYYMMDD_HHMM.dump" | head -50
```

### Option C — Restore test (recommended)

After creating the backup, verify it can be restored on a **non-production** instance:

```bash
# Example: restore to a local or staging DB
pg_restore --clean --if-exists -d "$TEST_DATABASE_URL" "backup_prod_pre_astm_YYYYMMDD_HHMM.dump"
```

## Checklist

- [ ] Backup completed and file/identifier recorded
- [ ] `pg_restore --list` (or equivalent) executed successfully
- [ ] Restore test passed (optional but recommended)
- [ ] Backup path/URL documented for rollback (see runbook Section 7)

## Rollback

If migration fails, rollback uses this backup. See **docs/RUNBOOKS/RUNBOOK_PROD_VOLUMETRIC_MIGRATION.md** Section 7 (Rollback).
