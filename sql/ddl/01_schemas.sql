-- =============================================================================
-- Churn Data Platform — Modèle physique (MPD) PostgreSQL
-- 01 · Schémas (couches de données du HLD)
-- =============================================================================
-- raw     : copie fidèle des fichiers sources, sans typage ni règle métier
-- staging : nettoyage et normalisation (modèles dbt, P4)
-- core    : modèle de référence typé, contraintes issues des data contracts
-- mart    : tables analytiques et features pour le ML (modèles dbt, P5)

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS mart;

COMMENT ON SCHEMA raw IS 'Copie fidèle des sources (TEXT uniquement, aucune règle métier)';
COMMENT ON SCHEMA staging IS 'Nettoyage et normalisation — modèles dbt';
COMMENT ON SCHEMA core IS 'Modèle de référence typé — contraintes issues des data contracts';
COMMENT ON SCHEMA mart IS 'Tables analytiques et features ML — modèles dbt';
