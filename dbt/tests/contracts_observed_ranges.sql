-- Plages observées du snapshot : alerte sans rejet (data contracts v0.4)
{{ config(severity='warn') }}

select *
from {{ ref('stg_contracts') }}
where tenure > 72
    or monthly_charges not between 18.25 and 118.75
    or total_charges > 8684.80
