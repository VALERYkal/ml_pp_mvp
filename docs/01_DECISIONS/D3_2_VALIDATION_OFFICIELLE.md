# ✅ Validation Officielle — D3.2 (Quarantine Tests Flaky)

**Date de validation** : 10 janvier 2026  
**Statut** : ✅ TERMINÉ & VERROUILLÉ

---

## 📋 Ce qui est objectivement correct et solide

### ✅ Flag `--include-flaky` : clair, explicite, extensible
- Mode LIGHT (défaut) : exclut automatiquement les tests flaky
- Mode FULL (`--full`) : inclut automatiquement les tests flaky
- Option explicite : `--include-flaky` force l'inclusion indépendamment du mode
- **Extensibilité** : facile d'ajouter d'autres flags (`--exclude-tags`, etc.)

### ✅ Détection flaky robuste
- **File-based** : `*_flaky_test.dart` (convention claire, détectable au niveau du système de fichiers)
- **Tag-based** : `@Tags(['flaky'])` (flexible, permet de marquer des tests individuels dans un fichier)
- **Déduplication implicite** : si un fichier est déjà flaky (suffixe), il n'est pas compté deux fois
- **Fallback robuste** : utilise `rg` (ripgrep) si disponible, sinon `grep` (compatible partout)

### ✅ Exécution en 2 phases
- **Phase A = normal** (gating) : doit passer pour que le build continue
- **Phase B = flaky** (truthful, visible) : exécutée si `--include-flaky`, log séparé, actuellement gating aussi pour truthfulness
- **Séparation claire** : les échecs flaky sont visibles mais ne polluent pas le log des tests normaux

### ✅ Logs séparés
- `.ci_logs/d1_test.log` : tests normaux (phase A)
- `.ci_logs/d1_flaky.log` : tests flaky (phase B, si exécutée)
- **Avantage** : diagnostic immédiat, logs consultables en artefacts CI

### ✅ Compteurs visibles → signal immédiat de régression
- Affichage format : `Discovered: Z test files total (X normal + Y flaky)`
- **Détection automatique** : si le nombre de tests normaux diminue anormalement, c'est visible immédiatement

### ✅ POC propres
- Pas de logique métier touchée : tests POC minimalistes (`expect(true, isTrue)`)
- Commentaires clairs : chaque test POC documente sa raison d'être flaky
- Tracking doc : référencé dans `docs/D3_D6_ROADMAP.md`

### ✅ CI-compatible
- **PR light** = stable : exclut les tests flaky → feedback rapide et fiable
- **Nightly/full** = exhaustif : inclut les tests flaky → validation complète et truthful

---

## 📌 Point important

**Le fait que les tests flaky POC soient des `expect(true, isTrue)` est une bonne chose à ce stade.**

👉 **D3.2 valide l'infrastructure, pas la correction des flaky.** C'est exactement l'objectif.

L'infrastructure est en place :
- Détection automatique ✅
- Quarantine (exclusion du PR light) ✅
- Tracking (exécution en nightly/full) ✅
- Logs séparés ✅
- Compteurs visibles ✅

Une fois l'infrastructure validée, il sera facile d'identifier les vrais tests flaky (via logs CI, historique d'échecs, etc.) et de les marquer progressivement.

---

## 🎯 Tests flaky actuellement détectés (POC)

| Test | Type | Raison | Fichier |
|------|------|--------|---------|
| Timing-sensitive | File-based | `DateTime.now()` + async operations | `test/features/stocks_adjustments/stocks_adjustments_timing_flaky_test.dart` |
| Async timing | Tag-based | `pumpAndSettle` + `Future.delayed` | `test/features/receptions/reception_async_flaky_test.dart` |

---

## ✅ Critères de validation (DoD)

- [x] Flag `--include-flaky` fonctionnel et documenté
- [x] Détection file-based (`*_flaky_test.dart`) opérationnelle
- [x] Détection tag-based (`@Tags(['flaky'])`) opérationnelle
- [x] Exécution en 2 phases (A: normal, B: flaky) implémentée
- [x] Logs séparés (`.ci_logs/d1_test.log` + `.ci_logs/d1_flaky.log`)
- [x] Compteurs visibles (`X normal + Y flaky = Z total`)
- [x] POC propres (2 tests de démonstration, commentaires clairs)
- [x] CI-compatible (PR light stable, nightly/full exhaustif)
- [x] Syntaxe bash valide (`bash -n scripts/d1_one_shot.sh`)
- [x] Documentation complète (CHANGELOG + roadmap)

---

## 📊 Statut final

**D3.2 — TERMINÉ & VERROUILLÉ (10/01/2026)**

✅ Infrastructure de quarantaine des tests flaky opérationnelle  
✅ PR light stable (feedback rapide et fiable)  
✅ Nightly/full exhaustif (validation complète et truthful)  
✅ Prêt pour la phase suivante (identification des vrais tests flaky via logs CI)

---

## 🔗 Références

- [CHANGELOG.md](../CHANGELOG.md) : historique détaillé des changements
- [docs/D3_D6_ROADMAP.md](D3_D6_ROADMAP.md) : roadmap complète D3-D6
- [scripts/d1_one_shot.sh](../scripts/d1_one_shot.sh) : script central de validation
- [.github/workflows/flutter_ci.yml](../.github/workflows/flutter_ci.yml) : workflow PR light
- [.github/workflows/flutter_ci_nightly.yml](../.github/workflows/flutter_ci_nightly.yml) : workflow nightly full
