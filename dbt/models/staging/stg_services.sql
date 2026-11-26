with latest as (
    {{ latest_by(source('raw', 'telco'), 'customer_id') }}
)

select
    {{ to_varchar('customer_id', 10) }} as customer_id,
    {{ to_boolean('phone_service', 'Yes', 'No') }} as phone_service,
    {{ to_varchar('multiple_lines', 16) }} as multiple_lines,
    {{ to_varchar('internet_service', 11) }} as internet_service,
    {{ to_varchar('online_security', 19) }} as online_security,
    {{ to_varchar('online_backup', 19) }} as online_backup,
    {{ to_varchar('device_protection', 19) }} as device_protection,
    {{ to_varchar('tech_support', 19) }} as tech_support,
    {{ to_varchar('streaming_tv', 19) }} as streaming_tv,
    {{ to_varchar('streaming_movies', 19) }} as streaming_movies
from latest
