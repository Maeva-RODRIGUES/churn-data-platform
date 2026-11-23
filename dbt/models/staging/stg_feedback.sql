-- R4 : une ligne seulement s'il y a un verbatim ; R2 : identifiant en majuscules
with with_text as (
    select *, upper(customer_id) as customer_id_upper
    from {{ source('raw', 'telco_noisy_feedback') }}
    where btrim(coalesce(customer_feedback, '')) <> ''
),

latest as (
    {{ latest_by('with_text', 'customer_id_upper') }}
)

select
    {{ to_varchar('customer_id_upper', 10) }} as customer_id,
    {{ to_varchar('customer_feedback', 1000) }} as customer_feedback,
    {{ to_integer('feedback_length', 'smallint') }} as feedback_length,
    {{ to_number('sentiment', 'double precision') }} as sentiment
from latest
