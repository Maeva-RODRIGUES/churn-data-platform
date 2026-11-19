-- Réciproque de R1 : vraie sur le snapshot seulement, donc warn
{{ config(severity='warn') }}

select *
from {{ ref('stg_contracts') }}
where total_charges = 0 and tenure <> 0
