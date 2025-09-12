-- Empêche plus d'un CDR "ouvert" (non déchargé) par plaque_camion
create unique index if not exists ux_cdr_unique_open_plaque
  on public.cours_de_route(plaque_camion)
  where statut in ('CHARGEMENT','TRANSIT','FRONTIERE','ARRIVE');
