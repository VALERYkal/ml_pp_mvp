# 🚀 Release Runbook — D4 Release Gate

**Objectif** : Une seule commande locale pour valider si un commit est livrable (analyze + tests light non-flaky + builds essentiels).

---

## 📋 Commandes Locales

### Web uniquement (par défaut)
```bash
bash scripts/d4_release_gate.sh
```

### Avec Android (optionnel)
```bash
bash scripts/d4_release_gate.sh --android
```

### Avec iOS (optionnel)
```bash
bash scripts/d4_release_gate.sh --ios
```

### Android + iOS (complet)
```bash
bash scripts/d4_release_gate.sh --android --ios
```

---

## 📁 Où Trouver les Logs

Tous les logs sont dans `.ci_logs/` :

- **`d4_analyze.log`** : Sortie de `flutter analyze`
- **`d4_light_tests.log`** : Sortie des tests light (non-flaky)
- **`d4_build_web.log`** : Sortie du build web (release)
- **`d4_build_android.log`** : Sortie du build Android (si `--android`)
- **`d4_build_ios.log`** : Sortie du build iOS (si `--ios`)
- **`d4_timings.txt`** : Durée de chaque phase (pub get, analyze, tests, builds)
- **`d4_env_guard.log`** : Résultats des vérifications d'environnement et anti-secrets

---

## 🛠️ Que Faire Si Ça Casse

### 1. **Analyze échoue (errors détectés)**
- **Symptôme** : `❌ flutter analyze: ERRORS detected`
- **Action** : Consulter `d4_analyze.log`, corriger les erreurs (`error •`), relancer
- **Note** : Les warnings/infos sont tolérés, seules les erreurs bloquent

### 2. **Tests light échouent**
- **Symptôme** : `❌ Tests light FAILED`
- **Action** : Consulter `d4_light_tests.log`, identifier le test en échec, corriger localement, relancer
- **Note** : Les tests flaky sont automatiquement exclus (voir D3.2)

### 3. **Build échoue**
- **Symptôme** : `❌ Build web FAILED` (ou android/ios)
- **Action** : Consulter `d4_build_web.log` (ou `d4_build_android.log` / `d4_build_ios.log`), identifier l'erreur de build, corriger, relancer
- **Note** : Les logs affichent automatiquement les 60 dernières lignes en cas d'échec

---

## ✅ Checklist "Release Candidate"

Avant de marquer un commit comme "Release Candidate", vérifier que :

- [ ] **`bash scripts/d4_release_gate.sh`** passe sans erreur (exit code 0)
- [ ] **Tous les logs** (`d4_*.log`) sont propres (pas de secrets exposés, vérifié automatiquement par `d4_env_guard.sh`)
- [ ] **Timings acceptables** : total < 10 min (vérifier `d4_timings.txt`)
- [ ] **Tests normaux** : tous passent (vérifier compteur dans résumé final)
- [ ] **Builds réussis** : web obligatoire, android/ios si requis par la release

---

## 🔐 Sécurité

**IMPORTANT** : Le script `d4_env_guard.sh` vérifie automatiquement :

- ✅ `SUPABASE_ENV` défini et valide (PROD ou STAGING)
- ✅ Aucun secret dans les logs (patterns: `SUPABASE_ANON_KEY`, `eyJhbGciOi`, `service_role`, etc.)
- ❌ **Échec si secrets détectés** : le script s'arrête avec un message clair (sans exposer la valeur)

**Ne jamais commiter** :
- Les fichiers `.ci_logs/` (déjà dans `.gitignore`)
- Les fichiers contenant des secrets
- Les variables d'environnement avec clés réelles

---

## 📊 Exemple de Sortie (Succès)

```
============================================================
AXE D / D4 — RELEASE GATE
============================================================

Timestamp: 2026-01-10 18:00:00 UTC
Git SHA: abc1234
Flutter version: Flutter 3.x.x
Build targets: web

---- Step 0: Environment Guard ----
✅ SUPABASE_ENV=PROD
✅ No secrets detected in logs
✅ Environment guard PASS

---- Step 1: flutter pub get ----
✅ pub get OK (5s)

---- Step 2: flutter analyze ----
✅ analyze OK (15s, 0 errors)

---- Step 3: Tests light (non-flaky) ----
✅ Tests light OK (120s, normal: 53, flaky skipped: 2)

---- Step 4a: Build web (release) ----
✅ Build web OK (45s)

---- Step 5: Final environment guard (anti-secrets) ----
✅ No secrets detected in logs
✅ Environment guard PASS

============================================================
✅ D4 RELEASE GATE PASS
============================================================

Summary:
  Total duration: 185s
  Tests: normal=53, flaky skipped=2
  Builds: web ✅

Logs location: .ci_logs/
  - analyze: .ci_logs/d4_analyze.log
  - tests: .ci_logs/d4_light_tests.log
  - build web: .ci_logs/d4_build_web.log
  - timings: .ci_logs/d4_timings.txt
```

---

## 🔗 Références

- [CHANGELOG.md](../CHANGELOG.md) : historique des changements D4
- [docs/D3_D6_ROADMAP.md](D3_D6_ROADMAP.md) : roadmap complète D3-D6
- [scripts/d1_one_shot.sh](../scripts/d1_one_shot.sh) : script D1 (tests light/full)
- [scripts/d4_release_gate.sh](../scripts/d4_release_gate.sh) : script D4 (release gate)
- [scripts/d4_env_guard.sh](../scripts/d4_env_guard.sh) : guard anti-secrets
