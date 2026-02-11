RAPPORT — État DB PROD (public) — Snapshot du 11 février 2026
0) Contexte et méthode (source des faits)
Nous avons :
Validé la connexion Postgres PROD via pooler Supabase (port 6543) en corrigeant l’erreur de DB name (postgre → postgres).
Listé tables (\dt public.*) et vues (\dv public.*).
Exporté le schéma public schema-only (sans owner/privileges) :
Fichier : /tmp/ml_pp_prod_schema_public.sql (≈ 3669 lignes)
Copié ensuite dans le repo : docs/DB_SNAPSHOTS/ml_pp_prod_schema_public_2026-02-11.sql
Ce rapport reflète l’état effectif de PROD au moment de l’extraction.
1) Inventaire des objets DB
1.1 Tables public (16)
citernes
clients
cours_de_route
depots
fournisseurs
log_actions
partenaires
prises_de_hauteur
produits
profils
receptions
sorties_produit
stocks_adjustments
stocks_journaliers
stocks_journaliers_bak (table backup/historique, à traiter avec prudence)
stocks_snapshot
Lecture rapide :
Le cœur “opérations stock” est basé sur :
receptions (entrées)
sorties_produit (sorties)
stocks_snapshot (source de vérité “stock actuel”, par citerne+produit+propriétaire)
stocks_journaliers (journal quotidien, écriture interdite hors triggers)
stocks_adjustments (ajustements correctifs / régularisations)
1.2 Vues public (12)
cours_route (vue d’affichage CDR, security_invoker=on)
current_user_profile (vue “profil courant” basée sur auth.uid)
logs (projection simplifiée de log_actions)
stock_actuel (ancienne vue: derniers stocks_journaliers par citerne/produit)
v_citerne_stock_actuel
v_citerne_stock_snapshot_agg
v_kpi_stock_global
v_mouvements_stock
v_stock_actuel ✅ (contrat stock actuel corrigé)
v_stock_actuel_owner_snapshot
v_stock_actuel_snapshot
v_stocks_snapshot_corrige
Point clé :
v_stock_actuel est la vue contractuelle qui expose le stock actuel corrigé (snapshot + adjustments).
Il existe encore stock_actuel (basé sur stocks_journaliers) mais le socle moderne est clairement orienté snapshot.
2) Modèles de données principaux (tables clés)
2.1 cours_de_route (CDR)
Champs notables :
fournisseur_id, depot_destination_id, produit_id
plaque_camion, plaque_remorque, chauffeur_nom, transporteur, depart_pays
date_chargement, volume
statut (check constraint) : CHARGEMENT, TRANSIT, FRONTIERE, ARRIVE, DECHARGE
created_at
Invariants :
Statuts en MAJUSCULES ASCII (sans accents) confirmés.
Un CDR “ARRIVE” est pré-requis pour autoriser certaines réceptions (voir triggers).
2.2 receptions
Champs notables :
lien éventuel : cours_de_route_id
citerne_id, produit_id, partenaire_id
indices : index_avant, index_apres
volumes : volume_ambiant, volume_15c, volume_corrige_15c, volume_observe
physique : temperature_ambiante_c, densite_a_15
propriété : proprietaire_type (MONALUXE ou PARTENAIRE)
statut : validee / rejetee (minuscule)
traçabilité : created_by, validated_by, created_at, date_reception
Contraintes importantes :
index_apres > index_avant
indices ≥ 0
si statut='validee' alors volume_ambiant requis
si proprietaire_type='PARTENAIRE' alors partenaire_id requis
check proprietaire_type in (MONALUXE, PARTENAIRE)
check statut in (validee, rejetee)
2.3 sorties_produit
Champs notables :
citerne_id, produit_id
bénéficiaire : client_id ou partenaire_id (au moins un requis)
volumes : volume_ambiant, volume_corrige_15c
indices : index_avant, index_apres
propriété : proprietaire_type (MONALUXE ou PARTENAIRE)
opérationnel : chauffeur_nom, plaque_camion, plaque_remorque, transporteur
statut : brouillon / validee / rejetee (minuscule)
date_sortie (timestamp)
audit : created_by, validated_by, created_at
Contraintes :
si statut='validee' volume_ambiant requis
indices ≥ 0
check proprietaire_type in (MONALUXE, PARTENAIRE)
check statut in (brouillon, validee, rejetee)
check bénéficiaire : client_id IS NOT NULL OR partenaire_id IS NOT NULL
2.4 stocks_snapshot (source de vérité “stock actuel”)
On sait (via contraintes + vues) :
Unicité : (citerne_id, produit_id, proprietaire_type) via ux_stocks_snapshot
Utilisée par :
stock_snapshot_apply_delta(...) (apply delta)
v_stocks_snapshot_corrige (snapshot + adjustments)
v_stock_actuel (vue finale)
Idée structurante :
La DB traite stocks_snapshot comme référence du stock “réel”.
Les opérations receptions/sorties appliquent des deltas au snapshot via trigger.
2.5 stocks_journaliers (journal quotidien, écritures verrouillées)
Unicité : (citerne_id, produit_id, date_jour, proprietaire_type)
Colonnes : stock_ambiant, stock_15c, source, depot_id, timestamps
Écritures interdites hors transaction “autorisée” (voir trigger stocks_journaliers_block_writes et set_config('app.stocks_journaliers_allow_write','1',true))
Conclusion :
stocks_journaliers est un journal alimenté uniquement par les triggers contrôlés.
On garde la traçabilité quotidienne sans permettre des “modifs manuelles”.
2.6 stocks_adjustments (ajustements)
Référence mouvement : mouvement_type (RECEPTION ou SORTIE) + mouvement_id uuid
deltas : delta_ambiant, delta_15c
reason (min 10 caractères)
created_by obligatoire
contexte optionnel : depot_id, citerne_id, produit_id, proprietaire_type
Unicité dédup : (mouvement_type, mouvement_id, delta_ambiant, delta_15c, reason)
Rôle :
Apporter des corrections “auditables” sans casser l’historique.
Réintégré dans le stock actuel via v_stocks_snapshot_corrige.
3) Vues : organisation du “contrat stock”
3.1 v_stocks_snapshot_corrige
Joint stocks_snapshot avec une agrégation des stocks_adjustments par (depot,citerne,produit,proprietaire)
Produit :
stock base (snapshot)
delta_total adjustments
stock corrigé = GREATEST(base + delta, 0)
last_movement_at, updated_at
3.2 v_stock_actuel
Expose le stock corrigé comme stock final :
stock_ambiant_corrige → stock_ambiant
stock_15c_corrige → stock_15c
Contient aussi les champs de debug/audit : base + deltas.
✅ Conclusion : pour toute feature POST-PROD, la source stock doit être v_stock_actuel (contrat).
4) Triggers et logique “DB strict”
4.1 Triggers recensés (principaux)
receptions_after_ins : AFTER INSERT ON receptions WHEN statut='validee' → reception_after_ins_trg()
trg_receptions_check_cdr_arrive : BEFORE INSERT ON receptions → receptions_check_cdr_arrive()
trg_receptions_set_created_by : BEFORE INSERT ON receptions → receptions_set_created_by_default()
trg_receptions_set_volume_ambiant : BEFORE INSERT/UPDATE ON receptions → receptions_set_volume_ambiant()
trg_receptions_log_created : AFTER INSERT ON receptions → receptions_log_created()
trg_receptions_check_produit_citerne : BEFORE INSERT/UPDATE (citerne_id, produit_id) ON receptions → check produit/citerne
trg_00_receptions_block_update_delete : BEFORE DELETE/UPDATE ON receptions → blocage/immutabilité
trg_00_sorties_produit_block_update_delete : BEFORE DELETE/UPDATE ON sorties → blocage/immutabilité
trg_00_sorties_set_created_by : BEFORE INSERT ON sorties → sorties_set_created_by_default()
trg_01_sorties_set_volume_ambiant : BEFORE INSERT/UPDATE ON sorties → sorties_set_volume_ambiant()
trg_sortie_before_ins & trg_sortie_before_upd : contrôles complets WHEN statut='validee' → sorties_before_validate_trg()
trg_sorties_after_insert : AFTER INSERT ON sorties WHEN statut='validee' → sorties_after_insert_trg()
trg_sorties_check_produit_citerne : BEFORE INSERT/UPDATE ON sorties → cohérence citerne/produit
stocks_journaliers_block_writes : bloque toute écriture directe sur stocks_journaliers
trg_*stocks_adjustments* : blocage update/delete + check ref + set context + created_by
4.2 Exemple concret : réception validée
Fonction reception_after_ins_trg() (SECURITY DEFINER) fait :
autorise l’écriture contrôlée dans stocks_journaliers via set_config('app.stocks_journaliers_allow_write','1',true)
récupère depot_id depuis citernes
applique un upsert journalier (delta jour) : stock_upsert_journalier(...)
applique le delta sur snapshot : stock_snapshot_apply_delta(...)
si cours_de_route_id non null : met le CDR à DECHARGE
écrit un log dans log_actions (action RECEPTION_VALIDE)
✅ Donc : “Réception validée” = stock + snapshot + log + MAJ CDR.
Important : on voit aussi une fonction receptions_apply_effects() qui ressemble à une ancienne implémentation “apply”, mais le trigger actif observé est receptions_after_ins → reception_after_ins_trg().
4.3 Sortie validée : contrôles + stock + log
sorties_before_validate_trg() (SECURITY DEFINER) :
normalise propriétaire (MONALUXE/PARTENAIRE)
vérifie citerne active
exige volumes
contrôle le stock dispo depuis le SNAPSHOT (source de vérité)
protège capacité sécurité, cohérence, etc.
sorties_after_insert_trg() :
applique delta négatif sur stocks_snapshot (et/ou journaliers selon logique)
log SORTIE_VALIDE
👉 Le pattern est clair :
toute opération critique passe par trigger DB + log.
5) Fonctions “rôles” et gouvernance accès
5.1 Fonctions utilitaires
public.user_role() : renvoie le rôle depuis profils via auth.uid()
public.role_in(role, allowed_roles[]) : helper booléen
Ces fonctions sont utilisées partout dans :
RLS policies
triggers SECURITY DEFINER (contrôles)
5.2 RLS : principes observés
RLS activée sur la plupart des tables (ENABLE ROW LEVEL SECURITY)
Policies du type :
lecture “authenticated” pour référentiels (clients, produits, etc.)
policies spécifiques pour insert/update selon rôles
logs : lecture staff/admin, insert contrôlé
sorties : policies plus sophistiquées (draft immuable, etc.)
profils : policies “own profile”
Conclusion :
La DB gouverne strictement qui peut lire/écrire.
L’application doit être vue comme un “client” de la DB : elle demande mais la DB décide.
6) Contraintes structurantes pour le POST-PROD
6.1 Invariants techniques (à ne jamais casser)
Stock actuel = v_stock_actuel (snapshot + adjustments)
stocks_journaliers : pas d’écriture directe (uniquement triggers)
Réceptions/sorties : immutabilité une fois validées (hors admin)
Propriétaire stock strict : MONALUXE vs PARTENAIRE
CDR statuts en MAJUSCULES
Validations/opérations importantes loggées dans log_actions
6.2 Implications directes pour POST-PROD (Sales/Procurement/Transporteurs)
Toute couche “finance/commerce” doit référencer les mouvements existants :
Sales : BL doit pointer sur sorties_produit.id
Procurement : facture finale fournisseur doit pointer sur réceptions/CDR (selon design)
Écarts : doivent référencer des objets existants (sortie/bl, etc.)
Reporting : doit s’adosser aux vues contractuelles + tables post-prod
Audit : on réutilise log_actions comme journal global (ou table dédiée uniquement si nécessaire)
7) Ce qu’on a clarifié dans le métier POST-PROD (dans les docs)
En parallèle des docs POST_PROD commit/merge :
1 sortie → 1 BL : validé comme règle v1 (simple)
1 facture client = 1..n BL : tu as confirmé que la facture peut couvrir plusieurs BL
Encaissements partiels : nécessaires → solde restant dû
Transporteurs :
avances multiples
avances déduites automatiquement du décompte :
reste_a_payer = montant_decompte - total_avances - total_paiements
si négatif → trop-perçu (crédit transporteur)
Ces règles doivent influencer le schéma POST-PROD futur.
8) Réponse à ta question : “sur quoi je base le schéma SQL POST-PROD ? ai-je accès au MVP ?”
Oui : désormais on a un accès direct au schéma PROD public via ton dump schema-only.
Ce que j’ai produit jusqu’ici côté POST-PROD était basé sur :
le contexte projet que tu avais déjà fourni (flux CDR→Réception→Stock→Sortie, RLS, triggers stricts, etc.)
les docs POST_PROD écrites
Mais maintenant, on a la référence réelle : tables, contraintes, triggers, vues et RLS actuelles.
Donc le prochain travail (POST-PROD SQL v1) pourra être :
aligné parfaitement sur les conventions et invariants constatés
non destructif (add-only), compatible RLS/triggers
cohérent avec log_actions et les patterns SECURITY DEFINER
9) Checklist de reprise (pour dev/IA)
Si quelqu’un reprend :
Lire docs/POST_PROD/INDEX.md (architecture + modules).
Lire le snapshot DB : docs/DB_SNAPSHOTS/ml_pp_prod_schema_public_2026-02-11.sql
Comprendre “contrat stock” :
stocks_snapshot (truth)
stocks_adjustments (corrections)
v_stock_actuel (vue finale)
Comprendre le pattern DB strict :
triggers sur receptions/sorties
stocks_journaliers write-block + allow flag
log systématique dans log_actions
Respecter RLS + fonctions user_role/role_in
Point d’attention (important)
On a identifié la présence de fonctions “apply” (receptions_apply_effects, sorties_apply_effects) qui semblent être des versions antérieures ou alternatives.
Dans l’état actuel, les triggers actifs observés appellent plutôt :
reception_after_ins_trg
sorties_before_validate_trg
sorties_after_insert_trg
=> En POST-PROD, on évite de “réinventer” : on suit le style trigger+SECURITY DEFINER+log_actions.
