with latest as (
    {{ latest_by(source('raw', 'telco_satisfaction'), 'customer_id') }}
)

select
    {{ to_varchar('customer_id', 10) }} as customer_id,
    {{ to_integer('nb_appels_support', 'smallint') }} as support_calls_count,
    {{ to_integer('duree_moy_appel_min', 'smallint') }} as avg_call_duration_min,
    {{ to_number('score_satisfaction', 'numeric(2, 1)') }} as satisfaction_score,
    {{ to_integer('nps_score', 'smallint') }} as nps_score,
    {{ to_varchar('motif_contact_principal', 30) }} as main_contact_reason,
    {{ to_integer('derniere_interaction_jours', 'smallint') }} as days_since_last_interaction,
    {{ to_boolean('incident_facturation', '1', '0') }} as billing_incident
from latest
