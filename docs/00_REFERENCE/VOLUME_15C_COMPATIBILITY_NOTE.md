# Note de compatibilité — `volume_15c` et `volume_corrige_15c`

**Projet** : ML_PP MVP  
**Objet** : règles de lecture et coexistence des colonnes volume à 15 °C.  
**Public** : développeurs Flutter, intégrateurs, audit technique.

---

## 1. Pourquoi deux colonnes coexistent

- **`volume_corrige_15c`** : nom et contrat **historiques** (legacy), encore présents en base et dans une partie du code (modèles JSON, certains champs Dart).  
- **`volume_15c`** : colonne **cible** introduite pour aligner le schéma sur la sémantique « volume à 15 °C » explicite, en particulier sur **`sorties_produit`** après migration STAGING puis PROD.

La migration validée est en mode **compatibilité** : les deux colonnes sont **remplies** sur le chemin runtime sorties (selon la version déployée des triggers), **sans** suppression de l’ancienne.

---

## 2. Colonne cible vs legacy

| Rôle | Colonne | Remarque |
|------|---------|----------|
| **Cible canonique (volume @15 °C)** | **`volume_15c`** | À privilégier pour toute **nouvelle** lecture applicative. |
| **Legacy / compatibilité** | **`volume_corrige_15c`** | À conserver tant que les données anciennes ou le code ne sont pas entièrement migrés. |

---

## 3. Règle de lecture recommandée (Flutter / agrégations)

Pour interpréter le volume corrigé à 15 °C à partir d’une ligne `Map` ou équivalent Supabase :

```text
valeur_15c_effective = volume_15c ?? volume_corrige_15c
```

(en Dart typiquement : cast `num?` puis `?.toDouble()`, avec `??` entre les deux clés, puis défaut métier si besoin, **sans** utiliser `volume_ambiant` comme substitut du volume @15 °C sauf règle métier explicite documentée ailleurs).

Cette règle a été appliquée sur les périmètres **lecture** migrés (KPI, repositories, providers sorties, écrans d’ajustements de stock), **sans** modification des payloads d’écriture dans le cadre de cette phase.

---

## 4. Ce qui n’a pas encore été fait (hors périmètre actuel)

- **Suppression** de `volume_corrige_15c` : **non**.  
- **Backfill historique** destructif ou `UPDATE` massif sur `sorties_produit` : **non** revendiqué ; la table reste soumise à la gouvernance d’immutabilité en conditions normales.  
- **Harmonisation complète** des modèles Dart / Freezed sur un seul nom de propriété miroir de `volume_15c` : **non**.  
- **Refactor** des services d’écriture pour n’exposer qu’une seule clé JSON : **non** dans cette migration de compatibilité.

Toute évolution ultérieure doit faire l’objet d’un **ADR**, de scripts versionnés et d’un runbook dédié.

---

## 5. Références

- Synthèse migration : `docs/00_REFERENCE/VOLUME_15C_MIGRATION_SUMMARY.md`  
- Runbook : `docs/RUNBOOKS/RUNBOOK_VOLUME_15C_COMPAT_MIGRATION.md`  
- CHANGELOG : entrée `[Unreleased]` — migration `volume_15c` (compatibilité)
