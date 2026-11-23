-- R1 : TotalCharges vide -> 0 lorsque tenure = 0
with latest as (
    {{ latest_by(source('raw', 'telco'), 'customer_id') }}
),

cleaned as (
    select
        *,
        case
            when tenure = '0' and btrim(coalesce(total_charges, '')) = '' then '0'
            else total_charges
        end as total_charges_filled
    from latest
)

select
    {{ to_varchar('customer_id', 10) }} as customer_id,
    {{ to_integer('tenure', 'smallint') }} as tenure,
    {{ to_varchar('contract', 14) }} as contract,
    {{ to_boolean('paperless_billing', 'Yes', 'No') }} as paperless_billing,
    {{ to_varchar('payment_method', 25) }} as payment_method,
    {{ to_number('monthly_charges', 'numeric(6, 2)') }} as monthly_charges,
    {{ to_number('total_charges_filled', 'numeric(8, 2)') }} as total_charges
from cleaned
