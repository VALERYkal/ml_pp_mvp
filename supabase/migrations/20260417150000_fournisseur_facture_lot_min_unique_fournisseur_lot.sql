-- =========================================================
-- ML_PP MVP — FINANCE FOURNISSEUR LOT (C2)
-- Une seule facture active par lot fournisseur (vérité = ligne facture, pas statut lot)
-- =========================================================

begin;

create unique index if not exists idx_fournisseur_facture_lot_min_one_facture_per_lot
  on public.fournisseur_facture_lot_min (fournisseur_lot_id);

comment on index public.idx_fournisseur_facture_lot_min_one_facture_per_lot is
'Garde-fou C2: au plus une ligne facture par fournisseur_lot_id. En cas de doublon insert, erreur 23505.';

commit;
