-- =========================================================
-- ML_PP MVP — FINANCE FOURNISSEUR LOT
-- Vues lecture : LEFT JOIN agrégats lot + statut_rapprochement canonique dans la vue
-- (2026-04-17) — ne modifie pas triggers paiement ni workflow fournisseur_lot
-- =========================================================

begin;

comment on column public.fournisseur_facture_lot_min.statut_rapprochement is
'Colonne persistée (CHECK: A_RAPPROCHER | OK | LITIGE). Non canonique pour la lecture métier du rapprochement volume: utiliser public.v_fournisseur_facture_lot.statut_rapprochement et public.v_fournisseur_rapprochement_lot_min.statut_rapprochement, calcules dans ces vues a partir des agrégats réceptions + quantité facturée.';

-- Agrégat réceptions par lot (inchangé logiquement ; utilisé en LEFT JOIN)
create or replace view public.v_fournisseur_rapprochement_lot_min as
select
  f.id as facture_id,
  f.invoice_no,
  f.deal_reference,
  f.fournisseur_lot_id,

  x.nb_receptions,
  x.total_volume_15c,
  x.total_volume_20c,

  f.quantite_facturee_20c,
  (x.total_volume_20c - f.quantite_facturee_20c) as ecart_volume_20c,

  f.prix_unitaire_usd,
  f.montant_total_usd,

  case
    when x.fournisseur_lot_id is null then 'A_RAPPROCHER'
    when x.total_volume_20c is null then 'A_RAPPROCHER'
    when abs(x.total_volume_20c - f.quantite_facturee_20c) < 0.001 then 'OK'
    when abs(x.total_volume_20c - f.quantite_facturee_20c) < 10 then 'TOLERE'
    else 'LITIGE'
  end as statut_rapprochement

from public.fournisseur_facture_lot_min f
left join (
  select
    cdr.fournisseur_lot_id,
    count(*) as nb_receptions,
    sum(v.volume_15c) as total_volume_15c,
    sum(v.volume_20c) as total_volume_20c
  from public.receptions r
  join public.cours_de_route cdr
    on cdr.id = r.cours_de_route_id
  join public.v_reception_20c v
    on v.reception_id = r.id
  group by cdr.fournisseur_lot_id
) x
  on x.fournisseur_lot_id = f.fournisseur_lot_id;

create or replace view public.v_fournisseur_facture_lot as
select
  f.id as facture_id,
  f.invoice_no,
  f.deal_reference,
  f.fournisseur_lot_id,

  x.nb_receptions,
  x.total_volume_15c,
  x.total_volume_20c,

  f.quantite_facturee_20c,
  (x.total_volume_20c - f.quantite_facturee_20c) as ecart_volume_20c,

  case
    when x.fournisseur_lot_id is null then 'A_RAPPROCHER'
    when x.total_volume_20c is null then 'A_RAPPROCHER'
    when abs(x.total_volume_20c - f.quantite_facturee_20c) < 0.001 then 'OK'
    when abs(x.total_volume_20c - f.quantite_facturee_20c) < 10 then 'TOLERE'
    else 'LITIGE'
  end as statut_rapprochement,

  f.prix_unitaire_usd,
  f.montant_total_usd,

  f.montant_regle_usd,
  f.solde_restant_usd,
  f.statut_paiement,

  f.date_facture,
  f.date_echeance,

  f.created_at

from public.fournisseur_facture_lot_min f
left join (
  select
    cdr.fournisseur_lot_id,
    count(*) as nb_receptions,
    sum(v.volume_15c) as total_volume_15c,
    sum(v.volume_20c) as total_volume_20c
  from public.receptions r
  join public.cours_de_route cdr
    on cdr.id = r.cours_de_route_id
  join public.v_reception_20c v
    on v.reception_id = r.id
  group by cdr.fournisseur_lot_id
) x
  on x.fournisseur_lot_id = f.fournisseur_lot_id;

comment on view public.v_fournisseur_facture_lot is
'Lecture canonique facture lot: une ligne par facture (LEFT JOIN agrégats réceptions). Colonnes agrégées NULL si pas de ligne agrégée. statut_rapprochement (OK | TOLERE | LITIGE | A_RAPPROCHER) calcule ici uniquement, pas depuis fournisseur_facture_lot_min.statut_rapprochement.';

comment on view public.v_fournisseur_rapprochement_lot_min is
'Vue minimale rapprochement: meme logique de jointure et de statut_rapprochement que v_fournisseur_facture_lot (LEFT JOIN, statut calcule dans la vue).';

commit;
