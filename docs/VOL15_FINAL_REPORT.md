# 📊 VOL15 — Rapport final consolidé

## 1. État initial

Avant refonte:

- Usage incohérent de `volume_corrige_15c` comme pseudo-canonique
- Absence de `volume_15c` dans certains modèles Flutter
- Calculs locaux via `calcV15()` utilisés comme vérité métier implicite
- Divergence entre:
  - DB (ASTM + triggers)
  - Frontend (approximation locale)
- UI ambiguë:
  - pas de distinction clair entre valeur officielle et estimation
- Module stocks_adjustments fortement dépendant du legacy
- Services (réception / sortie) partiellement non DB-first

Conséquence:
Risque de divergence fonctionnelle entre stock réel et affichage UI.

---

## 2. Corrections réalisées

### Modèles

- Ajout `volume15c` (JSON: volume_15c)
- Conservation `volumeCorrige15c`
- Ajout getter:
  - `effectiveVolume15c => volume15c ?? volumeCorrige15c`
  - `hasCanonicalVolume15c`

Alignement:
- Sorties
- Réceptions

---

### Services

#### reception_service.dart
- Suppression logique de calcul métier local
- Payload DB-first:
  - densite_observee_kgm3
  - inputs terrain uniquement
- volume @15°C laissé à la DB

#### sortie_draft_service.dart
- Suppression `calcV15`
- Suppression envoi `volume_corrige_15c`
- Brouillon = inputs uniquement (pas de vérité métier)

---

### Domaine / calculs

#### adjustment_compute.dart
- Introduction `effectiveVolume15c`
- Remplacement logique:
  - AVANT: volumeCorrige15c ?? calcV15
  - APRÈS: effectiveVolume15c ?? calcV15
- calcV15 maintenu comme fallback UX uniquement

#### volume_calc.dart
- Déclassé explicitement:
  - NON canonique
  - NON source de vérité
- Documentation renforcée

---

### UI / Screens

#### Forms (réception / sortie)
- Clarification:
  - volume_15c = calculé en base
  - calcV15 = estimation locale
- UX différenciée:
  - STAGING → DB officielle
  - hors STAGING → estimation + avertissement

#### stocks_adjustment_create_sheet.dart
- Séparation stricte:
  - volume15c ← volume_15c
  - volumeCorrige15c ← volume_corrige_15c
- Suppression coalesce implicite

---

### Tests

- Alignement DB-first
- Suppression dépendance à volume_corrige_15c seul
- Cas couverts:
  - volume_15c présent
  - fallback legacy
  - absence des deux

---

## 3. État final

Le frontend est désormais:

### ✅ DB-first conforme
- Aucun calcul volumétrique critique en frontend

### ✅ Lecture unifiée
- effectiveVolume15c utilisé partout

### ✅ UI cohérente
- Distinction claire:
  - valeur officielle (DB)
  - estimation locale

### ✅ Domaine propre
- Plus de dépendance implicite à volume_corrige_15c

### ✅ Ajustements stabilisés
- Données correctement alimentées
- fallback maîtrisé

---

## 4. Risques résiduels

### 1. calcV15 (approximation)
- Toujours utilisé pour:
  - previews
  - ajustements simulés
- ≠ moteur ASTM DB

Impact:
- écart possible entre simulation et réalité DB

---

### 2. Densité ajustements
- dépendance à `densite_a_15`
- mapping potentiellement incomplet selon tables

---

### 3. Brouillons sans volume @15°C
- affichage vide possible avant validation DB

---

### 4. Legacy hors périmètre
- certains écrans/services non migrés
- chemins non-STAGING

---

## 5. Décision de statut

Statut officiel:

### 🟢 VOL15-SAFE (Frontend)

Avec nuance:

- SAFE pour:
  - lecture
  - affichage
  - contrats métier UI

- COMPATIBLE pour:
  - simulation locale
  - ajustements

Conclusion:

Le frontend est aligné avec l’architecture DB-first.
Aucune divergence métier critique restante.

Le chantier VOL15 est considéré comme:
👉 TERMINÉ pour le frontend

---
