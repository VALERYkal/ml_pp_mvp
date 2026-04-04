-- Migration : privilèges lecture / exécution sur le schéma astm pour les rôles client Supabase.
-- Permet à anon, authenticated et service_role d’utiliser les tables / fonctions ASTM (lookup volumétrique DB-first).
-- À appliquer via le flux migrations versionné (STAGING puis PROD après validation).

BEGIN;

GRANT USAGE ON SCHEMA astm TO anon, authenticated, service_role;

GRANT SELECT ON ALL TABLES IN SCHEMA astm TO anon, authenticated, service_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA astm TO anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA astm TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA astm
GRANT SELECT ON TABLES TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA astm
GRANT SELECT ON SEQUENCES TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA astm
GRANT EXECUTE ON FUNCTIONS TO anon, authenticated, service_role;

COMMIT;
