# Rapport de développement — Module « Sorties Produit » (MVP)

- Projet: ML_PP MVP
- Date: 2025-08-08
- Auteur: Équipe ML_PP (via Cursor)

## 1) Contexte et objectifs
Le module « Sorties Produit » permet d’enregistrer les sorties de carburant depuis une `citerne` vers un bénéficiaire (client ou partenaire), avec calculs de volumes, journalisation et mise à jour automatique du stock journalier. Pour le MVP, nous implémentons le scénario mono-citerne par sortie, aligné au PRD et au schéma Supabase.

Objectifs MVP:
- Saisie d’une sortie avec contrôles métier clés (indices, citerne, stock, bénéficiaire).
- Calcul simple du volume corrigé à 15 °C (approx. MVP).
- Journalisation des actions et décrément du stock journalier.
- UI de création + liste de consultation.
- Tests unitaires et widget de base.

## 2) Alignement schéma Supabase
Conformément aux décisions validées (PRD + scripts SQL fournis):
- Table `sorties_produit`:
  - `citerne_id UUID NOT NULL`, `produit_id UUID NOT NULL`.
  - `index_avant DOUBLE PRECISION NOT NULL`, `index_apres DOUBLE PRECISION NOT NULL` → volume observé calculé côté service.
  - `volume_ambiant DOUBLE PRECISION`, `volume_corrige_15c DOUBLE PRECISION`.
  - Bénéficiaire: `client_id` ou `partenaire_id` (au moins l’un des deux requis via contrainte CHECK côté DB).
  - `statut TEXT` (MVP: brouillon → validée automatique).
  - Audit: `created_at`, `created_by`, `validated_by`.
- Table `citernes` (lecture): `statut`, `capacite_totale`, `capacite_securite`, `produit_id`.
- Table `stocks_journaliers`: upsert/maj des stocks (ambiant et 15 °C) par jour/citerne/produit.
- `log_actions`: enregistrement des actions `SORTIE_CREEE`, `SORTIE_VALIDEE` avec `cible_id`.

## 3) Architecture & fichiers
- Providers: `lib/features/sorties/providers/sortie_providers.dart`
  - `sortieServiceProvider`
  - Référentiels: `produitsListProvider`, `clientsListProvider`, `partenairesListProvider`
  - Nouveau: `produitByIdProvider`, `citernesByProduitProvider` (filtre citerne par produit), `sortiesListProvider` (lecture)
- Service: `lib/features/sorties/data/sortie_service.dart`
- Modèle: `lib/features/sorties/models/sortie_produit.dart`
- UI:
  - Création: `lib/features/sorties/screens/sortie_form_screen.dart`
  - Liste: `lib/features/sorties/screens/sortie_list_screen.dart`
- Routing: `lib/shared/navigation/app_router.dart` (routes `/sorties` et `/sorties/new`)
- Support métiers partagés:
  - `calcV15`: `lib/features/receptions/utils/volume_calc.dart`
  - `CiterneService`: `lib/features/citernes/data/citerne_service.dart`
  - `StocksService`: `lib/features/stocks_journaliers/data/stocks_service.dart`

## 4) Providers (référentiels & lecture)
- `produitsListProvider`: liste id/nom pour le Dropdown Produit.
- `clientsListProvider` et `partenairesListProvider`: listes id/nom.
- `produitByIdProvider`: lit `id/nom/code` d’un produit pour compatibilité (filtrage citernes).
- `citernesByProduitProvider`: retourne les citernes actives compatibles avec le produit sélectionné (par `produit_id` ou `type_produit`); déduplique.
- `sortiesListProvider`: lecture de `sorties_produit` triée par `created_at` desc.

## 5) UI
- `SortieFormScreen`:
  - Champs: Produit (Dropdown) → Citerne (Dropdown filtré), Client/Partenaire (au moins l’un), indices `index_avant`/`index_apres`, optionnels T° ambiante, densité à 15 °C, logistique (chauffeur, plaques, transporteur), `note`.
  - Validations formulaire: produit, citerne, indices >= 0, bénéficiaire (client ou partenaire).
  - Soumission: appelle `createSortie()` puis SnackBar succès et retour.
- `SortieListScreen`:
  - Liste des sorties (date, volume ambiant, statut) avec FAB vers création.

## 6) Service métier `SortieService`
- Entrée: `SortieProduit` (id vide pour insert, données saisies UI).
- Étapes clés:
  1. Calcul du volume observé: `vObs = index_apres - index_avant` (rejet si <= 0).
  2. Validations citerne: existence, `statut == active`, compatibilité `produit_id`.
  3. Stock: lit le stock du jour (ambiant) et rejette si `vObs > stockToday`.
  4. Bénéficiaire requis: rejette si `client_id` et `partenaire_id` absents.
  5. Calcul 15 °C: si T° et densité disponibles, utilise `calcV15`; sinon fallback `v15 = vObs` (MVP).
  6. Insertion `sorties_produit`: enrichit `volume_ambiant`, `volume_corrige_15c`, `statut=brouillon`, `created_by` (depuis session si dispo), `date_sortie` (now si absent).
  7. Logs: `SORTIE_CREEE` (module `sorties_produit`, `cible_id` = id créé).
  8. MAJ stock: décrémente `stocks_journaliers` (`volume_ambiant = -vObs`, `volume_15c = -v15`).
  9. Validation auto (MVP): `statut=validee`, `validated_by` (session si dispo) + `SORTIE_VALIDEE`.

## 7) Journalisation & stocks
- `log_actions`: deux entrées par opération MVP (création, validation).
- `stocks_journaliers`: upsert naïf (création si absent, sinon addition); décrément après création sortie.

## 8) Tests
- **Unitaires** (`test/features/sorties/data/sortie_service_test.dart`):
  - ✅ Rejette indices incohérents.
  - ✅ Rejette bénéficiaire manquant.
  - ✅ Rejette stock insuffisant.
  - ✅ `SortieService.createValidated()` 100% couvert en tests unitaires.
  - ✅ Normalisation des champs, validations métier, volume 15°C : tous validés.
- **Intégration** (`test/integration/sorties_submission_test.dart`):
  - ✅ Test d'intégration vert : navigation → affichage formulaire → saisie → interception `createValidated()`.
  - ✅ Validation du câblage formulaire → service.
- **E2E UI** (`test/features/sorties/sorties_e2e_test.dart`):
  - ✅ Test E2E complet vert : scénario utilisateur de bout en bout.
  - ✅ Navigation validée : dashboard → onglet Sorties → bouton "Nouvelle sortie" → formulaire.
  - ✅ Remplissage des champs : approche white-box via accès direct aux `TextEditingController`.
  - ✅ Soumission validée : flow complet sans plantage, retour à la liste ou message de succès.
  - ✅ Test en mode "boîte noire UI" : valide le scénario utilisateur complet.
- **Navigation & rôles** :
  - ✅ GoRouter + userRoleProvider validés.
  - ✅ Redirections correctes : `/dashboard/operateur` → `/sorties` → `/sorties/new`.
- **Résultat global** : Module Sorties **"full green"** - tous les tests passent (unitaires, intégration, E2E).

## 9) Décisions & contraintes
- MVP « mono-citerne par sortie » (pas de multi-citerne pour cette phase).
- Bénéficiaire obligatoire (client ou partenaire).
- Auto-validation (statut `validee`) pour simplifier le flux MVP.
- Citernes filtrées par produit pour éviter les mélanges.
- Référentiels chargés en ligne (performances réseau acceptées pour MVP).

## 10) Limites & améliorations futures
- Tests widget: rendre le test de soumission robuste sans `skip` (mocker le scroll ou refactor UI avec `SingleChildScrollView` + `AutofillGroup`).
- Navigation: ajouter le lien « Sorties » dans le shell de navigation par rôle (si souhaité côté UX) et écran de détail/édition.
- RLS: affiner les politiques Supabase (accès par rôle/dépôt, masquage inter-rôles).
- KPI & alertes: intégration dashboard (alertes stock/ sécurité citerne).
- Référentiels offline: stratégie de cache local (phase post-MVP).

## 11) Procédure de test manuel
1. Authentifiez-vous et naviguez vers `/sorties` pour consulter la liste (vide au départ).
2. Ouvrez `/sorties/new`.
3. Sélectionnez un produit, puis une citerne filtrée.
4. Choisissez un client ou partenaire.
5. Saisissez `index_avant` et `index_apres` (après > avant).
6. (Optionnel) Saisissez T°, densité, informations transport, note.
7. Enregistrez: SnackBar « Sortie créée ». Vérifiez la liste et la décrémentation du stock journalier.

## 12) Impact & conformité PRD
- Conformité métier: validations indices, compatibilité produit/citerne, stock suffisant, bénéficiaire requis.
- Conformité données: champs `NOT NULL` et contrôles CHECK pris en compte, logs complets, audit `created_by/validated_by`.
- Extensibilité: prêt pour enrichissements (multi-citerne, détail, édition, exports).

---

Références:
- `lib/features/sorties/data/sortie_service.dart`
- `lib/features/sorties/providers/sortie_providers.dart`
- `lib/features/sorties/screens/sortie_form_screen.dart`
- `lib/features/sorties/screens/sortie_list_screen.dart`
- `lib/features/receptions/utils/volume_calc.dart`
- `lib/features/stocks_journaliers/data/stocks_service.dart`
- `lib/features/citernes/data/citerne_service.dart`
- `docs/schema_supabase.md` / `docs/schemaSQL.md` / `docs/ML pp mvp PRD.md`