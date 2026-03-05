# Runbook: CI D1 One-Shot Validation

**Purpose:** Reproduce and validate the same pipeline used by PR CI and Nightly CI locally.  
**Audience:** Developers, DevOps.  
**Last updated:** 2026-03-05.

---

## 1. Purpose of the D1 Script

The script `scripts/d1_one_shot.sh` is the **single source of truth** for Flutter CI in this project. It runs, in order:

1. **Sanity checks** (Flutter and `pubspec.yaml` present)
2. **`flutter pub get`** (unless `--skip-pub-get`)
3. **`flutter analyze`** (non-blocking: warnings do not fail the run; unless `--skip-analyze`)
4. **Codegen** via `scripts/d0_codegen_check.sh` (build_runner + git diff on generated files) or fallback `flutter pub run build_runner build --delete-conflicting-outputs` (unless `--skip-build-runner`)
5. **Test discovery** (splits normal vs flaky tests)
6. **Phase A:** All **normal** tests (unit + widget; optionally integration/e2e depending on mode)
7. **Phase B (optional):** **Flaky** tests, only when `--full` or `--include-flaky` is used

Success is determined by the **exit code of `flutter test`** for the normal (and, if run, flaky) phases. Log scanning is used only for non-blocking warnings.

---

## 2. Steps Executed (Summary)

| Step        | Command / behaviour |
|------------|----------------------|
| Pub get    | `flutter pub get` |
| Analyze    | `flutter analyze` (warnings allowed) |
| Build runner | `scripts/d0_codegen_check.sh` (build_runner + `git diff --exit-code` on `**/*.freezed.dart` and `**/*.g.dart`) or `flutter pub run build_runner build --delete-conflicting-outputs` |
| Tests      | `flutter test -r expanded` on discovered test files, with optional `--dart-define=*` passed through |

Logs are written under `.ci_logs/` (e.g. `pub_get.log`, `analyze.log`, `build_runner.log`, `test_normal.log`, `test_flaky.log`).

---

## 3. Light Mode vs Full Mode

| Aspect | **Light mode** (default) | **Full mode** (`--full`) |
|--------|---------------------------|---------------------------|
| **Trigger** | `./scripts/d1_one_shot.sh web` | `./scripts/d1_one_shot.sh web --full` |
| **Test scope** | Unit + widget only. Excludes: `test/integration/*`, `test/*/integration/*`, `test/e2e/*`, `test/*/e2e/*`, `*_e2e_test.dart` | All tests: unit, widget, integration, e2e |
| **Flaky tests** | Not run | Run (Phase B) |
| **Use case** | Fast PR feedback | Full validation (e.g. Nightly, pre-release) |

Light mode is used by **PR CI** (`.github/workflows/flutter_ci.yml`). Full mode is used by **Nightly CI** (`.github/workflows/flutter_ci_nightly.yml`).

---

## 4. Commands to Reproduce CI Locally

### PR CI (light, no DB)

```bash
chmod +x scripts/d1_one_shot.sh
./scripts/d1_one_shot.sh web
```

### Nightly CI (full, no DB tests)

```bash
./scripts/d1_one_shot.sh web --full --dart-define=RUN_DB_TESTS=0
```

### Nightly CI (full, with DB tests, when STAGING secrets are available)

```bash
./scripts/d1_one_shot.sh web --full \
  --dart-define=RUN_DB_TESTS=1 \
  --dart-define=SUPABASE_ENV=STAGING \
  --dart-define=SUPABASE_URL="$SUPABASE_URL_STAGING" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY_STAGING" \
  --dart-define=TEST_USER_EMAIL="$TEST_USER_EMAIL_STAGING" \
  --dart-define=TEST_USER_PASSWORD="$TEST_USER_PASSWORD_STAGING"
```

(Replace the `$SUPABASE_*` and `$TEST_USER_*` variables with your STAGING secrets; never commit them.)

### Other options

- `--skip-pub-get` / `--skip-analyze` / `--skip-build-runner`: skip corresponding step.
- `--tests-only`: skip pub get, analyze, and build_runner (run only tests).
- `--include-flaky`: run flaky tests even without `--full`.
- Target: first argument can be `web`, `macos`, `ios`, `android` (default: `web`).

---

## 5. Checkpoint (2026-03-05)

- **Result:** D1 one-shot full validation **PASSED** locally.
- **Command used:** `./scripts/d1_one_shot.sh web --full --dart-define=RUN_DB_TESTS=0`
- **Summary:** pub get → OK; flutter analyze → OK (non-blocking warnings); build_runner/codegen check → OK; 85 normal tests PASS; 2 flaky tests PASS (87 test files total).
- **Conclusion:** Flutter application layer is stable and reproducible for the purpose of this checkpoint.

---

## 6. Related

- **PR workflow:** `.github/workflows/flutter_ci.yml`
- **Nightly workflow:** `.github/workflows/flutter_ci_nightly.yml`
- **Codegen guard:** `scripts/d0_codegen_check.sh`
- **Staging reset (volumetric validation):** `docs/02_RUNBOOKS/RUNBOOK_STAGING_RESET_FOR_ASTM.md`
