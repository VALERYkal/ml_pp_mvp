# Cours de route — Statuts & RLS

## Statuts (DB)
Valeurs **MAJUSCULES** sans accents:
`CHARGEMENT`, `TRANSIT`, `FRONTIERE`, `ARRIVE`, `DECHARGE`.

## RLS
- Policy `cours_de_route_update_status`:
  - rôles autorisés: `{admin, directeur, gerant, operateur}`
  - **WITH CHECK**: si `statut='DECHARGE'`, il doit exister **au moins une réception `validee`** liée (`receptions.cours_de_route_id = id`)

## Intentions
- Interdire tout passage à `DECHARGE` hors validation de réception (garde-fou DB).
- Les autres transitions (CHARGEMENT → TRANSIT → FRONTIERE → ARRIVE) passent par l’app selon les rôles.