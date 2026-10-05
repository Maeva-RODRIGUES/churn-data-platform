-- =============================================================================
-- Churn Data Platform — Modèle physique (MPD) PostgreSQL
-- 03 · Couche CORE
-- =============================================================================
-- Traduction physique des data contracts v0.2 (domaines, bornes, nullabilité,
-- clés). Choix de modélisation :
--   - tables et colonnes nommées en anglais, alignées sur le MCD / MLD
--     (le nom du champ du contrat figure en commentaire lorsqu'il diffère) ;
--   - colonnes en snake_case ;
--   - champs Yes/No et 0/1 typés BOOLEAN ;
--   - contraintes nommées ck_<table>_<règle> pour tracer chaque rejet.
-- Les règles marquées « proposition v0.3 » ne figurent pas encore dans les
-- contrats v0.2 et restent à valider.
-- Ordre de création : geo_enrichment est référencé par customers.

-- -----------------------------------------------------------------------------
-- geo_enrichment — contrat enrichissement_geo (TBD en v0.2)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS core.geo_enrichment (
    zipcode            CHAR(5)       NOT NULL,
    median_income      INTEGER,
    median_age         NUMERIC(4, 1),
    population_density NUMERIC(10, 1),
    CONSTRAINT pk_geo_enrichment PRIMARY KEY (zipcode),
    CONSTRAINT ck_geo_enrichment_zipcode_format CHECK (zipcode ~ '^[0-9]{5}$'),
    CONSTRAINT ck_geo_enrichment_median_income_range CHECK (median_income BETWEEN 0 AND 250000),
    CONSTRAINT ck_geo_enrichment_median_age_range CHECK (median_age BETWEEN 0 AND 100),
    CONSTRAINT ck_geo_enrichment_population_density_positive CHECK (population_density >= 0)
);

COMMENT ON TABLE core.geo_enrichment IS 'Contrat enrichissement_geo — US Census ACS 5-Year 2022 + TIGER/Web, une ligne par ZCTA';
COMMENT ON COLUMN core.geo_enrichment.median_income IS 'revenu_median (B19013_001E) — NULL si non publié par le Census (sentinelle -666666666)';
COMMENT ON COLUMN core.geo_enrichment.median_age IS 'age_median (B01002_001E)';
COMMENT ON COLUMN core.geo_enrichment.population_density IS 'densite_population — habitants/km², NULL si le ZCTA n''a pas d''habitants';

-- -----------------------------------------------------------------------------
-- customers — contrat client v0.1.0
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS core.customers (
    customer_id    VARCHAR(10) NOT NULL,
    gender         VARCHAR(6)  NOT NULL,
    senior_citizen BOOLEAN     NOT NULL,
    partner        BOOLEAN     NOT NULL,
    dependents     BOOLEAN     NOT NULL,
    zipcode        CHAR(5)     NOT NULL,
    churn          BOOLEAN     NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT fk_customers_geo_enrichment FOREIGN KEY (zipcode) REFERENCES core.geo_enrichment (zipcode),
    CONSTRAINT ck_customers_customer_id_format CHECK (customer_id ~ '^[0-9]{4}-[A-Z]{5}$'),
    CONSTRAINT ck_customers_gender CHECK (gender IN ('Female', 'Male')),
    CONSTRAINT ck_customers_zipcode_format CHECK (zipcode ~ '^[0-9]{5}$')
);

COMMENT ON TABLE core.customers IS 'Contrat client v0.1.0 — source telco.csv';
COMMENT ON COLUMN core.customers.senior_citizen IS 'SeniorCitizen (0/1) — client de 65 ans et plus';
COMMENT ON COLUMN core.customers.churn IS 'Churn (Yes/No) — VARIABLE CIBLE';

-- -----------------------------------------------------------------------------
-- contracts — contrat contrat v0.2.0
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS core.contracts (
    customer_id       VARCHAR(10)   NOT NULL,
    tenure            SMALLINT      NOT NULL,
    contract          VARCHAR(14)   NOT NULL,
    paperless_billing BOOLEAN       NOT NULL,
    payment_method    VARCHAR(25)   NOT NULL,
    monthly_charges   NUMERIC(6, 2) NOT NULL,
    total_charges     NUMERIC(8, 2) NOT NULL,
    CONSTRAINT pk_contracts PRIMARY KEY (customer_id),
    CONSTRAINT fk_contracts_customers FOREIGN KEY (customer_id) REFERENCES core.customers (customer_id),
    CONSTRAINT ck_contracts_tenure_range CHECK (tenure BETWEEN 0 AND 72),
    CONSTRAINT ck_contracts_contract CHECK (contract IN ('Month-to-month', 'One year', 'Two year')),
    CONSTRAINT ck_contracts_payment_method CHECK (
        payment_method IN ('Electronic check', 'Mailed check', 'Bank transfer (automatic)', 'Credit card (automatic)')
    ),
    CONSTRAINT ck_contracts_monthly_charges_range CHECK (monthly_charges BETWEEN 18.25 AND 118.75),
    CONSTRAINT ck_contracts_total_charges_range CHECK (total_charges BETWEEN 0 AND 8684.80),
    -- Règle v0.2 : 0.0 uniquement (et obligatoirement) lorsque tenure = 0
    CONSTRAINT ck_contracts_total_charges_tenure_zero CHECK ((tenure = 0) = (total_charges = 0))
);

COMMENT ON TABLE core.contracts IS 'Contrat contrat v0.2.0 — source telco.csv';
COMMENT ON COLUMN core.contracts.total_charges IS 'TotalCharges — 0.0 lorsque tenure = 0 (vide dans la source, conservé en RAW)';

-- -----------------------------------------------------------------------------
-- services — contrat services
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS core.services (
    customer_id       VARCHAR(10) NOT NULL,
    phone_service     BOOLEAN     NOT NULL,
    multiple_lines    VARCHAR(16) NOT NULL,
    internet_service  VARCHAR(11) NOT NULL,
    online_security   VARCHAR(19) NOT NULL,
    online_backup     VARCHAR(19) NOT NULL,
    device_protection VARCHAR(19) NOT NULL,
    tech_support      VARCHAR(19) NOT NULL,
    streaming_tv      VARCHAR(19) NOT NULL,
    streaming_movies  VARCHAR(19) NOT NULL,
    CONSTRAINT pk_services PRIMARY KEY (customer_id),
    CONSTRAINT fk_services_customers FOREIGN KEY (customer_id) REFERENCES core.customers (customer_id),
    CONSTRAINT ck_services_multiple_lines CHECK (multiple_lines IN ('Yes', 'No', 'No phone service')),
    CONSTRAINT ck_services_internet_service CHECK (internet_service IN ('DSL', 'Fiber optic', 'No')),
    CONSTRAINT ck_services_internet_options CHECK (
        online_security IN ('Yes', 'No', 'No internet service')
        AND online_backup IN ('Yes', 'No', 'No internet service')
        AND device_protection IN ('Yes', 'No', 'No internet service')
        AND tech_support IN ('Yes', 'No', 'No internet service')
        AND streaming_tv IN ('Yes', 'No', 'No internet service')
        AND streaming_movies IN ('Yes', 'No', 'No internet service')
    )
);

COMMENT ON TABLE core.services IS 'Contrat services — source telco.csv';

-- -----------------------------------------------------------------------------
-- satisfaction — contrat satisfaction
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS core.satisfaction (
    customer_id                 VARCHAR(10)   NOT NULL,
    support_calls_count         SMALLINT      NOT NULL,
    avg_call_duration_min       SMALLINT      NOT NULL,
    satisfaction_score          NUMERIC(2, 1) NOT NULL,
    nps_score                   SMALLINT      NOT NULL,
    main_contact_reason         VARCHAR(30)   NOT NULL,
    days_since_last_interaction SMALLINT      NOT NULL,
    billing_incident            BOOLEAN       NOT NULL,
    CONSTRAINT pk_satisfaction PRIMARY KEY (customer_id),
    CONSTRAINT fk_satisfaction_customers FOREIGN KEY (customer_id) REFERENCES core.customers (customer_id),
    CONSTRAINT ck_satisfaction_support_calls_count_range CHECK (support_calls_count BETWEEN 0 AND 50),
    CONSTRAINT ck_satisfaction_avg_call_duration_range CHECK (avg_call_duration_min BETWEEN 0 AND 60),
    CONSTRAINT ck_satisfaction_score_range CHECK (satisfaction_score BETWEEN 1.0 AND 5.0),
    CONSTRAINT ck_satisfaction_nps_range CHECK (nps_score BETWEEN -100 AND 100),
    -- Proposition v0.3 : domaine complété avec les 3 valeurs observées absentes du contrat v0.2
    -- (Panne réseau, Aucun contact, Qualité service). Les valeurs restent celles de la source.
    CONSTRAINT ck_satisfaction_main_contact_reason CHECK (
        main_contact_reason IN (
            'Assistance technique', 'Changement forfait', 'Facturation', 'Résiliation', 'Autre',
            'Panne réseau', 'Aucun contact', 'Qualité service'
        )
    ),
    CONSTRAINT ck_satisfaction_days_since_last_interaction_range CHECK (days_since_last_interaction BETWEEN 0 AND 365)
);

COMMENT ON TABLE core.satisfaction IS 'Contrat satisfaction — source telco_satisfaction.csv (données synthétiques, fuite de cible : voir notebook 3.0)';
COMMENT ON COLUMN core.satisfaction.support_calls_count IS 'nb_appels_support';
COMMENT ON COLUMN core.satisfaction.avg_call_duration_min IS 'duree_moy_appel_min';
COMMENT ON COLUMN core.satisfaction.satisfaction_score IS 'score_satisfaction';
COMMENT ON COLUMN core.satisfaction.main_contact_reason IS 'motif_contact_principal';
COMMENT ON COLUMN core.satisfaction.days_since_last_interaction IS 'derniere_interaction_jours';
COMMENT ON COLUMN core.satisfaction.billing_incident IS 'incident_facturation (0/1)';

-- -----------------------------------------------------------------------------
-- feedback — contrat feedback v0.2.0 (cardinalité 0:1 avec customers)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS core.feedback (
    customer_id       VARCHAR(10)   NOT NULL,
    customer_feedback VARCHAR(1000),
    feedback_length   SMALLINT,
    sentiment         DOUBLE PRECISION,
    has_feedback      BOOLEAN       NOT NULL,
    CONSTRAINT pk_feedback PRIMARY KEY (customer_id),
    CONSTRAINT fk_feedback_customers FOREIGN KEY (customer_id) REFERENCES core.customers (customer_id),
    CONSTRAINT ck_feedback_customer_id_format CHECK (customer_id ~ '^[0-9]{4}-[A-Z]{5}$'),
    CONSTRAINT ck_feedback_length_range CHECK (feedback_length BETWEEN 0 AND 2000),
    CONSTRAINT ck_feedback_sentiment_range CHECK (sentiment BETWEEN -1.0 AND 1.0),
    CONSTRAINT ck_feedback_has_feedback_text CHECK (has_feedback = (customer_feedback IS NOT NULL)),
    CONSTRAINT ck_feedback_length_consistent CHECK (
        customer_feedback IS NULL OR feedback_length = char_length(customer_feedback)
    ),
    -- Proposition v0.3 : sans verbatim, longueur et sentiment sont absents (NULL), pas nuls (0)
    CONSTRAINT ck_feedback_no_score_without_text CHECK (
        has_feedback OR (feedback_length IS NULL AND sentiment IS NULL)
    )
);

COMMENT ON TABLE core.feedback IS 'Contrat feedback v0.2.0 — source telco_noisy_feedback_prep.csv (verbatims LLM, fuite de cible : voir notebook 3.0)';
COMMENT ON COLUMN core.feedback.sentiment IS 'Score de sentiment hérité de la source, méthode non documentée (sentiment_legacy)';
