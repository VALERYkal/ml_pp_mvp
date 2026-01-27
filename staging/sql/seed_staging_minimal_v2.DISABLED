-- Seed minimal STAGING (compatible schéma PROD)
-- Ids fixes pour tests et scripts
begin;

-- 1) Dépôt
insert into public.depots (id, nom)
values ('11111111-1111-1111-1111-111111111111', 'DEPOT STAGING')
on conflict (id) do update set nom = excluded.nom;

-- 2) Produit
insert into public.produits (id, nom)
values ('22222222-2222-2222-2222-222222222222', 'DIESEL STAGING')
on conflict (id) do update set nom = excluded.nom;

-- 3) Citerne
insert into public.citernes (
  id, depot_id, produit_id, nom,
  capacite_totale, capacite_securite,
  localisation, statut
)
values (
  '33333333-3333-3333-3333-333333333333',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  'TANK STAGING 1',
  50000, 2000,
  'ZONE A', 'active'
)
on conflict (id) do update set
  depot_id = excluded.depot_id,
  produit_id = excluded.produit_id,
  nom = excluded.nom,
  capacite_totale = excluded.capacite_totale,
  capacite_securite = excluded.capacite_securite,
  localisation = excluded.localisation,
  statut = excluded.statut;

commit;

