-- Contraintes du DDL absentes de la base (table recréée par dbt, DDL non appliqué...).
-- Liste synchronisée avec sql/ddl/03_core.sql par tests/test_dbt_project.py.
with expected (constraint_name) as (
    values
        ('ck_contracts_contract'),
        ('ck_contracts_monthly_charges_positive'),
        ('ck_contracts_payment_method'),
        ('ck_contracts_tenure_positive'),
        ('ck_contracts_total_charges_positive'),
        ('ck_contracts_total_charges_tenure_zero'),
        ('ck_customers_customer_id_format'),
        ('ck_customers_gender'),
        ('ck_customers_zipcode_format'),
        ('ck_feedback_customer_id_format'),
        ('ck_feedback_length_consistent'),
        ('ck_feedback_length_range'),
        ('ck_feedback_sentiment_range'),
        ('ck_feedback_text_not_blank'),
        ('ck_geo_enrichment_median_age_range'),
        ('ck_geo_enrichment_median_income_range'),
        ('ck_geo_enrichment_population_density_positive'),
        ('ck_geo_enrichment_zipcode_format'),
        ('ck_satisfaction_avg_call_duration_range'),
        ('ck_satisfaction_days_since_last_interaction_range'),
        ('ck_satisfaction_main_contact_reason'),
        ('ck_satisfaction_nps_range'),
        ('ck_satisfaction_score_range'),
        ('ck_satisfaction_support_calls_count_range'),
        ('ck_services_internet_consistency'),
        ('ck_services_internet_options'),
        ('ck_services_internet_service'),
        ('ck_services_multiple_lines'),
        ('ck_services_phone_consistency'),
        ('fk_contracts_customers'),
        ('fk_customers_geo_enrichment'),
        ('fk_feedback_customers'),
        ('fk_satisfaction_customers'),
        ('fk_services_customers'),
        ('pk_contracts'),
        ('pk_customers'),
        ('pk_feedback'),
        ('pk_geo_enrichment'),
        ('pk_satisfaction'),
        ('pk_services')
)

select expected.constraint_name
from expected
left join pg_constraint as c
    on c.conname = expected.constraint_name
    and c.connamespace = 'core'::regnamespace
where c.conname is null
