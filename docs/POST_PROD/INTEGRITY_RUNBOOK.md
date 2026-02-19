# INTEGRITY CHECKS — INCIDENT RUNBOOK
## ML_PP MVP — Phase 2 Observabilité

---

## 1. Objectif

Ce document décrit la procédure de gestion des alertes issues de la vue :

```
public.v_integrity_checks
```

Ces contrôles sont :

- **Lecture seule**
- **Calculés côté base de données**
- **Exposés dans l'UI** via Governance → Integrity Checks
- **Limités à 200 lignes**
- **Triés par priorité métier** (CRITICAL > WARN)

---

## 2. Accès à l'écran

**UI :**
- Menu → GOUVERNANCE → Integrity Checks

**Rôles autorisés :**
- `admin`
- `directeur`
- `pca`

---

## 3. Structure d'un check

| Champ      | Description                        |
|-----------|-------------------------------------|
| check_code| Code métier du contrôle            |
| severity  | CRITICAL / WARN                    |
| entity_type | Type d'entité concernée (CDR, STOCK, CITERNE, etc.) |
| entity_id | UUID de l'entité                   |
| message   | Description lisible                |
| payload   | Données JSON complémentaires       |
| detected_at | Timestamp UTC                    |

---

## 4. Niveaux de gravité

### 4.1 Convention Monaluxe — Définition CRITICAL

Les contrôles suivants doivent être classés **CRITICAL** :

#### 1. STOCK_NEGATIF
- **Condition :** `stock_15c < 0`
- **Risque :** Incohérence physique immédiate. Impact financier et réglementaire potentiel.

#### 2. STOCK_OVER_CAPACITY
- **Condition :** `volume_citerne > capacite_max`
- **Risque :** Risque opérationnel et sécurité.

#### 3. SORTIE_STOCK_INSUFFISANT
- **Condition :** Sortie validée avec stock insuffisant au moment de la validation.
- **Risque :** Incohérence comptable et traçabilité rompue.

#### WARN (non critique)
- **Exemple :** `CDR_ARRIVE_STALE`
- Retard opérationnel, mais pas incohérence physique.

#### Règle officielle
- **CRITICAL** = incohérence physique, sécurité ou intégrité comptable.
- **WARN** = anomalie opérationnelle ou délai.

---

### WARN
- Anomalie à surveiller.
- Pas de blocage immédiat.
- Exemple :
  - `CDR_ARRIVE_STALE`

### CRITICAL
- Risque opérationnel immédiat.
- Action requise dans la journée.
- Exemples typiques (à confirmer en Phase 2B) :
  - `STOCK_NEGATIF`
  - `STOCK_OVER_CAPACITY`
  - `CITERNE_INACTIVE_USED`

---

## 5. Procédure Incident

### Étape 1 — Identifier
1. Ouvrir **Integrity Checks**
2. Filtrer sur **CRITICAL**
3. Lire le message
4. Ouvrir le détail et analyser le payload

### Étape 2 — Vérification SQL (lecture seule)

**Exemple générique :**
```sql
select *
from public.v_integrity_checks
where check_code = 'CODE_ICI';
```

**Exemple ciblé par entité :**
```sql
select *
from public.v_integrity_checks
where entity_id = 'UUID_ICI';
```

⚠️ **Ne jamais modifier les données directement en PROD sans décision formelle.**

### Étape 3 — Diagnostic métier

Selon `entity_type` :

| entity_type | Vérification                      |
|-------------|-----------------------------------|
| CDR        | Vérifier statut, réception liée   |
| STOCK      | Vérifier mouvements récents        |
| CITERNE    | Vérifier capacité / statut        |
| RECEPTION  | Vérifier validation                |

### Étape 4 — Action corrective

Les actions correctives doivent être réalisées :
- via l'**application**
- ou via **procédure DBA validée**

Toute correction doit être tracée dans :
- `log_actions`

### Étape 5 — Clôture

- Un check **disparaît automatiquement** lorsque la condition SQL n'est plus vraie.
- **Aucune suppression manuelle.**

---

## 6. Gouvernance

- Les checks **ne doivent jamais être ignorés**.
- Les **CRITICAL** doivent être traités **le jour même**.
- Les **WARN** doivent être analysés **sous 48h**.
- Toute anomalie récurrente doit faire l'objet d'un **ticket technique**.

---

## 7. Évolution future (Phase 3)

À venir :
- Notification automatique si CRITICAL > 0
- Email / Slack
- Historisation des checks
- KPI "Health Score"
