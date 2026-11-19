with latest as (
    {{ latest_by(source('raw', 'telco'), 'customer_id') }}
)

select
    {{ to_varchar('customer_id', 10) }} as customer_id,
    {{ to_varchar('gender', 6) }} as gender,
    {{ to_boolean('senior_citizen', '1', '0') }} as senior_citizen,
    {{ to_boolean('partner', 'Yes', 'No') }} as partner,
    {{ to_boolean('dependents', 'Yes', 'No') }} as dependents,
    {{ to_char('zipcode', 5) }} as zipcode,
    {{ to_boolean('churn', 'Yes', 'No') }} as churn
from latest
