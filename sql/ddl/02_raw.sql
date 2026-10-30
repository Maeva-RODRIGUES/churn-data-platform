-- =============================================================================
-- Churn Data Platform — Modèle physique (MPD) PostgreSQL
-- 02 · Couche RAW
-- =============================================================================
-- Une table par fichier source, toutes les colonnes en TEXT : les valeurs sont
-- conservées telles quelles (casse, blancs, sentinelles). Les anomalies sont
-- traitées en STAGING, jamais à l'ingestion.
-- Noms de colonnes : nom source converti en snake_case.

CREATE TABLE IF NOT EXISTS raw.telco (
    customer_id       TEXT,
    gender            TEXT,
    senior_citizen    TEXT,
    partner           TEXT,
    dependents        TEXT,
    tenure            TEXT,
    phone_service     TEXT,
    multiple_lines    TEXT,
    internet_service  TEXT,
    online_security   TEXT,
    online_backup     TEXT,
    device_protection TEXT,
    tech_support      TEXT,
    streaming_tv      TEXT,
    streaming_movies  TEXT,
    contract          TEXT,
    paperless_billing TEXT,
    payment_method    TEXT,
    monthly_charges   TEXT,
    total_charges     TEXT,
    churn             TEXT,
    zipcode           TEXT,
    _source_file      TEXT        NOT NULL DEFAULT 'telco.csv',
    _loaded_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.telco_satisfaction (
    customer_id                TEXT,
    nb_appels_support          TEXT,
    duree_moy_appel_min        TEXT,
    score_satisfaction         TEXT,
    nps_score                  TEXT,
    motif_contact_principal    TEXT,
    derniere_interaction_jours TEXT,
    incident_facturation       TEXT,
    _source_file               TEXT        NOT NULL DEFAULT 'telco_satisfaction.csv',
    _loaded_at                 TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Source feedback retenue par le data contract v0.2 (couverture réaliste de 25 %)
CREATE TABLE IF NOT EXISTS raw.telco_noisy_feedback (
    source_index      TEXT,  -- index pandas exporté (colonne sans nom)
    source_index_2    TEXT,  -- index pandas exporté (« Unnamed: 0 »)
    customer_id       TEXT,
    gender            TEXT,
    senior_citizen    TEXT,
    partner           TEXT,
    dependents        TEXT,
    tenure            TEXT,
    phone_service     TEXT,
    multiple_lines    TEXT,
    internet_service  TEXT,
    online_security   TEXT,
    online_backup     TEXT,
    device_protection TEXT,
    tech_support      TEXT,
    streaming_tv      TEXT,
    streaming_movies  TEXT,
    contract          TEXT,
    paperless_billing TEXT,
    payment_method    TEXT,
    monthly_charges   TEXT,
    total_charges     TEXT,
    churn             TEXT,
    customer_feedback TEXT,
    feedback_length   TEXT,
    sentiment         TEXT,
    has_feedback      TEXT,
    _source_file      TEXT        NOT NULL DEFAULT 'telco_noisy_feedback_prep.csv',
    _loaded_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indicateurs US Census par ZCTA (ACS 5-Year 2022 + TIGER/Web)
CREATE TABLE IF NOT EXISTS raw.census_zcta (
    zipcode            TEXT,
    revenu_median      TEXT,
    age_median         TEXT,
    population_totale  TEXT,
    superficie_m2      TEXT,
    densite_population TEXT,
    _source_file       TEXT        NOT NULL DEFAULT 'census_zcta_2022.csv',
    _loaded_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Réponses brutes de l'API US Census (ACS 5-Year, TIGER/Web), une ligne par appel.
-- Exception au tout-TEXT : la réponse est un document JSON, conservée telle quelle
-- en JSONB. Sentinelles (-666666666) et typage traités en STAGING.
CREATE TABLE IF NOT EXISTS raw.census_api_responses (
    endpoint     TEXT        NOT NULL,  -- acs5 ou tiger_zcta
    request_url  TEXT        NOT NULL,  -- URL appelée, sans la clé API
    http_status  SMALLINT    NOT NULL,
    payload      JSONB       NOT NULL,
    _loaded_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- La clé API ne doit jamais être stockée (incident du 22/10)
    CONSTRAINT ck_census_api_responses_no_api_key CHECK (request_url !~* '[?&]key=')
);
