# 📦 **Module Sorties Produit — Documentation Complète**

**Date de documentation :** 19 décembre 2025  
**Statut :** ✅ **FONCTIONNEL & PRODUCTION-READY**  
**Version :** MVP

---

## 🎯 **1. Vision Métier — Module Sorties Produit**

### **Objectif du Module**

Tracer toutes les sorties de carburant depuis les citernes du dépôt vers :

- **Des clients** (stock MONALUXE)
- **Des partenaires** (stock PARTENAIRE)

avec :

- ✅ **Respect strict des volumes disponibles**
- ✅ **Conservation de l'historique**
- ✅ **Impact direct sur les stocks_journaliers** pour le reporting et le dashboard

### **En Pratique**

Chaque sortie :

- **Diminue le stock** d'une citerne donnée
- **Par produit** et **par propriétaire** (MONALUXE vs PARTENAIRE)
- **À une date donnée** (`date_sortie` → `date_jour`)

---

## 🔄 **2. Flux Fonctionnel Côté App (Opérateur / Gérant / Directeur)**

### **2.1. Création d'une Sortie**

#### **Processus Utilisateur**

Depuis l'UI, un opérateur :

1. **Choisit :**
   - Un produit (ex : Gasoil)
   - Une citerne active (ex : TANK1)
   - Un client **OU** un partenaire (jamais les deux)

2. **Remplit :**
   - Index avant / index après
   - Température, densité
   - Chauffeur, plaque camion, transporteur
   - Note (optionnelle)

3. **Soumet le formulaire :**
   - Si le formulaire est incomplet → **validation UI blocante** + messages d'erreurs
   - Si tout est OK → appel à `SortieService.createValidated`

#### **UI Actuelle**

**Bouton "Enregistrer la sortie" :**
- ✅ Désactivé si formulaire invalide
- ✅ Désactivé + loader en cours de soumission (anti double-clic)
- ✅ Vérifie `_canSubmit`, `!busy`, et `validate()`

**En cas de succès :**
- ✅ Toast utilisateur : "Sortie enregistrée avec succès."
- ✅ Log console détaillé : `[SORTIE] Succès • Volume: XXX L • Citerne: YYY`
- ✅ Redirection vers la liste des sorties

**En cas d'erreur métier (ex : stock insuffisant) :**
- ✅ Message SQL détaillé dans les logs console (debug/diagnostic)
- ✅ Toast lisible expliquant qu'il n'y a pas assez de stock :
  - "Stock insuffisant dans la citerne.\nVeuillez ajuster le volume ou choisir une autre citerne."
- ✅ Les champs restent remplis → l'opérateur peut corriger le volume

### **2.2. Liste / Dashboard**

La sortie validée apparaît immédiatement dans :

- ✅ **La liste des sorties** (avec client/partenaire, citerne, volume, date)
- ✅ **Le Dashboard** à deux niveaux :
  - **Sorties du jour @15°C**
  - **Stock total @15°C**, avec détail par propriétaire (MONALUXE / PARTENAIRE) et par dépôt

---

## 🗄️ **3. Flux SQL — Intégration avec stocks_journaliers**

### **3.1. Table `sorties_produit`**

#### **Colonnes Clé**

```sql
- citerne_id, produit_id
- client_id, partenaire_id
- volume_corrige_15c, volume_ambiant
- proprietaire_type (MONALUXE / PARTENAIRE)
- statut (brouillon, validee, rejetee)
- date_sortie
- created_by, validated_by
- index_avant, index_apres
- temperature_ambiante_c, densite_a_15
- chauffeur_nom, plaque_camion, plaque_remorque, transporteur
- note
```

### **3.2. Fonction `stock_upsert_journalier` (v8 paramètres)**

#### **Signature Métier**

```sql
stock_upsert_journalier(
  p_citerne_id,
  p_produit_id,
  p_date_jour,
  p_delta_stock_ambiant,
  p_delta_stock_15c,
  p_proprietaire_type,  -- MONALUXE / PARTENAIRE
  p_depot_id,
  p_source             -- 'RECEPTION' / 'SORTIE' / 'SYSTEM'
)
```

#### **Comportement**

- Gère un `INSERT ... ON CONFLICT` sur :
  - `(citerne_id, produit_id, date_jour, proprietaire_type)`
- Ajoute les deltas + met à jour `updated_at`, `source`, etc.
- **Une ligne par combinaison** : citerne + produit + date + propriétaire

### **3.3. Triggers sur `sorties_produit`**

#### **BEFORE INSERT/UPDATE : `sorties_before_validate_trg`**

**Condition :** Ne s'applique que si `NEW.statut = 'validee'`.

**Rôles :**

1. **Normalise le `proprietaire_type`**
   - `client_id != null` → `MONALUXE`
   - `partenaire_id != null` → `PARTENAIRE`
   - Cas invalides → exception

2. **Contrôle citerne**
   - Vérifie que la citerne existe
   - Vérifie que `citernes.statut = 'active'`
   - Sinon → exception `SORTIE_CITERNE_INACTIVE`

3. **Contrôle stock suffisant**
   - Calcule `v_date_jour = coalesce(date_sortie, current_date)`
   - Cherche la ligne dans `stocks_journaliers` :
     - Même citerne, produit, `date_jour`, `proprietaire_type`
   - Si pas de ligne → exception `SORTIE_STOCK_INSUFFISANT` (aucun stock)
   - Si `stock_15c < volume_corrige_15c` → exception `SORTIE_STOCK_INSUFFISANT` (stock insuffisant avec détails)

#### **AFTER INSERT : `sorties_after_insert_trg`**

**Condition :** Ne s'applique que si `NEW.statut = 'validee'`.

**Rôles :**

1. **Récupère `depot_id`** à partir de la citerne

2. **Appelle `stock_upsert_journalier` avec delta négatif :**
   ```sql
   stock_upsert_journalier(
     NEW.citerne_id,
     NEW.produit_id,
     v_date_jour,
     -NEW.volume_ambiant,
     -NEW.volume_corrige_15c,
     NEW.proprietaire_type,
     v_depot_id,
     'SORTIE'
   );
   ```

3. **Journalise dans `log_actions` :**
   - `action = 'SORTIE_VALIDE'`
   - `details = sortie_id, citerne_id, produit_id, proprietaire_type, volumes, date, client/partenaire…`
   - `cible_id = NEW.id`

---

## 🔒 **4. Garde-fous Métiers Déjà en Place ✅**

### **Au Niveau SQL**

#### **🔐 Citerne Active Obligatoire**
- → Impossible de valider une sortie sur une citerne inactive.

#### **🧾 Propriétaire Cohérent : MONALUXE vs PARTENAIRE**
- `client_id` → `MONALUXE`
- `partenaire_id` → `PARTENAIRE`
- Mélange / null / incohérence → exception.

#### **📉 Stock à 15°C Suffisant (par citerne / produit / propriétaire / jour)**
- Pas de ligne → sortie refusée
- Stock < volume demandé → sortie refusée
- → Impossible de "vider virtuellement" plus que ce qui est physiquement disponible.

#### **🧩 Intégrité Référentielle**
- FK sur citerne, produit, client, partenaire, `created_by`, etc.

#### **🧠 Traçabilité**
- `log_actions` garde une trace de chaque `SORTIE_VALIDE` avec tous les IDs.

### **Au Niveau Flutter (UI)**

#### **❌ Formulaire Bloquant**
- Si champs obligatoires manquants → validation UI blocante

#### **⛔ Bouton "Valider" Désactivé**
- Si formulaire invalide (`validate()`)
- Si soumission en cours (`!busy`)
- Si conditions métier non remplies (`_canSubmit`)

#### **🔄 Protection Anti Double-Soumission**
- Bouton désactivé + loader pendant l'appel → impossible de double-cliquer

#### **👀 Messages d'Erreurs Très Visibles**
- Par champ (validation formulaire)
- Global (erreur SQL métier affichée en toast)
- Toast lisible pour l'utilisateur
- Logs console détaillés pour diagnostic

---

## 🧪 **5. Tests en Place sur le Module Sorties ✅**

### **Test E2E UI**

**Fichier :** `test/features/sorties/sorties_e2e_test.dart`

**Scénario :**
- "Un opérateur peut créer une sortie MONALUXE via le formulaire et la voir dans la liste."

**Vérifications :**
- Navigation correcte : login → dashboard/operateur → sorties → sorties/new
- Sélection produit + citerne + saisie index/mesures
- Appel service OK et comportement UI attendu

### **Test d'Intégration**

**Fichier :** `test/integration/sorties_submission_test.dart`

**Vérifications :**
- `SortieService.createValidated` est appelé
- Avec les bonnes valeurs
- En fonction des saisies du formulaire

### **Statut des Tests**

✅ **Les deux sont verts**, avec logs montrant :
- Navigation correcte
- Sélection et saisie correctes
- Appel service OK
- Comportement UI attendu

---

## 🚀 **6. Pistes / Idées V2 (Sans Impact sur le MVP)**

À stocker dans la roadmap, **sans les implémenter maintenant** :

### **Sorties Multi-Citernes**
Permettre de construire une sortie depuis plusieurs citernes en une seule opération logique.

### **Modèles de Sortie / Favoris**
Pour les clients réguliers, pré-remplir transporteur, plaques, densité typique, etc.

### **Alertes "Seuil Bas par Citerne"**
Alerte dès qu'un `stock_journalier` passe sous un seuil donné.

### **Vue Analytique Sorties**
Par client, par produit, par période, par citerne, avec ratios, etc.

### **Validation Hiérarchique Avancée**
Workflow opérateur → gérant → directeur pour les grosses sorties.

---

## 🏗️ **7. Architecture Technique**

### **Structure des Fichiers**

```
lib/features/sorties/
├── data/
│   ├── sortie_service.dart          # Service Supabase pour créer des sorties
│   └── sortie_draft_service.dart    # Service pour les brouillons (futur)
├── models/
│   └── sortie_produit.dart          # Modèle de données
├── providers/
│   ├── sortie_providers.dart        # Providers Riverpod
│   └── sorties_table_provider.dart  # Provider pour la liste
├── screens/
│   ├── sortie_form_screen.dart      # Formulaire de création
│   └── sortie_list_screen.dart      # Liste des sorties
└── kpi/
    └── sorties_kpi_provider.dart    # KPI pour le dashboard
```

### **Composants Clés**

#### **Service Layer**
- `SortieService.createValidated()` : Crée une sortie validée avec validation métier stricte
- Gère les erreurs SQL et les mappe vers des messages utilisateur lisibles
- Normalise automatiquement `proprietaire_type` en UPPERCASE

#### **Repository KPI**
- `SortiesKpiRepository.getSortiesKpiForDay()` : KPI pour un jour donné
- Agrégation : count, volume15c, volumeAmbient
- Filtrage par dépôt optionnel

#### **Providers Riverpod**
- `sortieServiceProvider` : Service pour créer des sorties
- `sortiesListProvider` : Liste des sorties
- `sortiesKpiTodayProvider` : KPI du jour
- `clientsListProvider`, `partenairesListProvider` : Référentiels

#### **UI Screens**
- `sortie_form_screen.dart` : Formulaire avec validation en temps réel
- `sortie_list_screen.dart` : Liste avec pagination

---

## 📊 **8. Intégration avec le Dashboard**

### **KPIs Affichés**

1. **Carte "Sorties du jour"**
   - Volume total @15°C des sorties du jour
   - Nombre de sorties
   - Volume ambiant total

2. **Carte "Stock total"**
   - Volume total @15°C (mis à jour après chaque sortie)
   - Volume ambiant total
   - Détail par propriétaire (MONALUXE / PARTENAIRE)

3. **Carte "Balance du jour"**
   - Δ volume 15°C = Réceptions - Sorties
   - Mise à jour automatique après chaque sortie

### **Cohérence des Données**

- ✅ Les sorties impactent directement `stocks_journaliers` via le trigger
- ✅ Le dashboard reflète les stocks réels en temps réel
- ✅ Cohérence parfaite entre Réceptions, Sorties et Stocks

---

## ✅ **9. Conclusion**

Le module **Sorties Produit** peut être considéré comme :

- ✅ **Fonctionnel** : Création, validation, liste opérationnelles
- ✅ **Aligné métier** : Respect strict des règles métier (stock, propriétaire, citerne)
- ✅ **Protégé par des garde-fous SQL** : Triggers de validation, contraintes, intégrité référentielle
- ✅ **Testé E2E & Intégration** : Tests automatisés passants
- ✅ **Intégré au Dashboard** : KPIs cohérents avec Réceptions / Stocks journaliers
- ✅ **UX Optimisée** : Messages clairs, protection anti double-clic, validations en temps réel

**Le module Sorties est prêt pour la production MVP.**

---

## 📚 **10. Documents de Référence**

- `docs/releases/SORTIES_MODULE_DOCUMENTATION_2025-12-19.md` : Ce document
- `lib/features/sorties/data/sortie_service.dart` : Service de création
- `lib/features/sorties/screens/sortie_form_screen.dart` : Formulaire UI
- `test/features/sorties/sorties_e2e_test.dart` : Tests E2E
- `test/integration/sorties_submission_test.dart` : Tests d'intégration

---

✍️ **Rédigé pour documenter le module Sorties Produit au 19/12/2025.**

