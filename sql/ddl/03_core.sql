-- =============================================================================
-- Churn Data Platform — Modèle physique (MPD) PostgreSQL
-- 03 · Couche CORE
-- =============================================================================
-- Traduction physique des data contracts v0.2 (domaines, bornes, nullabilité,
-- clés). Choix de modélisation :
--   - colonnes en snake_case (le nom du champ du contrat figure en commentaire
--     lorsqu'il n'est pas déductible) ;
--   - champs Yes/No et 0/1 typés BOOLEAN ;
--   - contraintes nommées ck_<table>_<règle> pour tracer chaque rejet.
-- Les règles marquées « proposition v0.3 » ne figurent pas encore dans les
-- contrats v0.2 et restent à valider.
-- Ordre de création : enrichissement_geo est référencé par client.

-- -----------------------------------------------------------------------------
-- enrichissement_geo — contrat enrichissement_geo (TBD en v0.2)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS core.enrichissement_geo (
    zipcode            CHAR(5)       NOT NULL,
    revenu_median      INTEGER,
    age_median         NUMERIC(4, 1),
    densite_population NUMERIC(10, 1),
    CONSTRAINT pk_enrichissement_geo PRIMARY KEY (zipcode),
    CONSTRAINT ck_geo_zipcode_format CHECK (zipcode ~ '^[0-9]{5}$'),
    CONSTRAINT ck_geo_revenu_median_range CHECK (revenu_median BETWEEN 0 AND 250000),
    CONSTRAINT ck_geo_age_median_range CHECK (age_median BETWEEN 0 AND 100),
    CONSTRAINT ck_geo_densite_population_positive CHECK (densite_population >= 0)
);

COMMENT ON TABLE core.enrichissement_geo IS 'Contrat enrichissement_geo — US Census ACS 5-Year 2022 + TIGER/Web, une ligne par ZCTA';
COMMENT ON COLUMN core.enrichissement_geo.revenu_median IS 'B19013_001E — NULL si non publié par le Census (sentinelle -666666666)';
COMMENT ON COLUMN core.enrichissement_geo.densite_population IS 'Habitants/km² — NULL si le ZCTA n''a pas d''habitants';

-- -----------------------------------------------------------------------------
-- client — contrat client v0.1.0
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS core.client (
    customer_id    VARCHAR(10) NOT NULL,
    gender         VARCHAR(6)  NOT NULL,
    senior_citizen BOOLEAN     NOT NULL,
    partner        BOOLEAN     NOT NULL,
    dependents     BOOLEAN     NOT NULL,
    zipcode        CHAR(5)     NOT NULL,
    churn          BOOLEAN     NOT NULL,
    CONSTRAINT pk_client PRIMARY KEY (customer_id),
    CONSTRAINT fk_client_zipcode FOREIGN KEY (zipcode) REFERENCES core.enrichissement_geo (zipcode),
    CONSTRAINT ck_client_customer_id_format CHECK (customer_id ~ '^[0-9]{4}-[A-Z]{5}$'),
    CONSTRAINT ck_client_gender CHECK (gender IN ('Female', 'Male')),
    CONSTRAINT ck_client_zipcode_format CHECK (zipcode ~ '^[0-9]{5}$')
);

COMMENT ON TABLE core.client IS 'Contrat client v0.1.0 — source telco.csv';
COMMENT ON COLUMN core.client.senior_citizen IS 'SeniorCitizen (0/1) — client de 65 ans et plus';
COMMENT ON COLUMN core.client.churn IS 'Churn (Yes/No) — VARIABLE CIBLE';

-- -----------------------------------------------------------------------------
-- contrat — contrat contrat v0.2.0
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS core.contrat (
    customer_id       VARCHAR(10)   NOT NULL,
    tenure            SMALLINT      NOT NULL,
    contract          VARCHAR(14)   NOT NULL,
    paperless_billing BOOLEAN       NOT NULL,
    payment_method    VARCHAR(25)   NOT NULL,
    monthly_charges   NUMERIC(6, 2) NOT NULL,
    total_charges     NUMERIC(8, 2) NOT NULL,
    CONSTRAINT pk_contrat PRIMARY KEY (customer_id),
    CONSTRAINT fk_contrat_client FOREIGN KEY (customer_id) REFERENCES core.client (customer_id),
    CONSTRAINT ck_contrat_tenure_range CHECK (tenure BETWEEN 0 AND 72),
    CONSTRAINT ck_contrat_contract CHECK (contract IN ('Month-to-month', 'One year', 'Two year')),
    CONSTRAINT ck_contrat_payment_method CHECK (
        payment_method IN ('Electronic check', 'Mailed check', 'Bank transfer (automatic)', 'Credit card (automatic)')
    ),
    CONSTRAINT ck_contrat_monthly_charges_range CHECK (monthly_charges BETWEEN 18.25 AND 118.75),
    CONSTRAINT ck_contrat_total_charges_range CHECK (total_charges BETWEEN 0 AND 8684.80),
    -- Règle v0.2 : 0.0 uniquement (et obligatoirement) lorsque tenure = 0
    CONSTRAINT ck_contrat_total_charges_tenure_zero CHECK ((tenure = 0) = (total_charges = 0))
);

COMMENT ON TABLE core.contrat IS 'Contrat contrat v0.2.0 — source telco.csv';
COMMENT ON COLUMN core.contrat.total_charges IS 'TotalCharges — 0.0 lorsque tenure = 0 (vide dans la source, conservé en RAW)';

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
    CONSTRAINT fk_services_client FOREIGN KEY (customer_id) REFERENCES core.client (customer_id),
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
    customer_id                VARCHAR(10)   NOT NULL,
    nb_appels_support          SMALLINT      NOT NULL,
    duree_moy_appel_min        SMALLINT      NOT NULL,
    score_satisfaction         NUMERIC(2, 1) NOT NULL,
    nps_score                  SMALLINT      NOT NULL,
    motif_contact_principal    VARCHAR(30)   NOT NULL,
    derniere_interaction_jours SMALLINT      NOT NULL,
    incident_facturation       BOOLEAN       NOT NULL,
    CONSTRAINT pk_satisfaction PRIMARY KEY (customer_id),
    CONSTRAINT fk_satisfaction_client FOREIGN KEY (customer_id) REFERENCES core.client (customer_id),
    CONSTRAINT ck_satisfaction_nb_appels_support_range CHECK (nb_appels_support BETWEEN 0 AND 50),
    CONSTRAINT ck_satisfaction_duree_moy_appel_range CHECK (duree_moy_appel_min BETWEEN 0 AND 60),
    CONSTRAINT ck_satisfaction_score_range CHECK (score_satisfaction BETWEEN 1.0 AND 5.0),
    CONSTRAINT ck_satisfaction_nps_range CHECK (nps_score BETWEEN -100 AND 100),
    -- Proposition v0.3 : domaine complété avec les 3 valeurs observées absentes du contrat v0.2
    -- (Panne réseau, Aucun contact, Qualité service)
    CONSTRAINT ck_satisfaction_motif_contact CHECK (
        motif_contact_principal IN (
            'Assistance technique', 'Changement forfait', 'Facturation', 'Résiliation', 'Autre',
            'Panne réseau', 'Aucun contact', 'Qualité service'
        )
    ),
    CONSTRAINT ck_satisfaction_derniere_interaction_range CHECK (derniere_interaction_jours BETWEEN 0 AND 365)
);

COMMENT ON TABLE core.satisfaction IS 'Contrat satisfaction — source telco_satisfaction.csv (données synthétiques, fuite de cible : voir notebook 3.0)';
COMMENT ON COLUMN core.satisfaction.incident_facturation IS 'incident_facturation (0/1)';

-- -----------------------------------------------------------------------------
-- feedback — contrat feedback v0.2.0 (cardinalité 0:1 avec client)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS core.feedback (
    customer_id       VARCHAR(10)   NOT NULL,
    customer_feedback VARCHAR(1000),
    feedback_length   SMALLINT,
    sentiment         DOUBLE PRECISION,
    has_feedback      BOOLEAN       NOT NULL,
    CONSTRAINT pk_feedback PRIMARY KEY (customer_id),
    CONSTRAINT fk_feedback_client FOREIGN KEY (customer_id) REFERENCES core.client (customer_id),
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
