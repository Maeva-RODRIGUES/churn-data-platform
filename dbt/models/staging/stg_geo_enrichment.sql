-- R5 : sentinelle Census -666666666 -> NULL
with latest as (
    {{ latest_by(source('raw', 'census_zcta'), 'zipcode') }}
),

cleaned as (
    select
        zipcode,
        nullif(nullif(revenu_median, '-666666666'), '-666666666.0') as revenu_median,
        nullif(nullif(age_median, '-666666666'), '-666666666.0') as age_median,
        nullif(nullif(densite_population, '-666666666'), '-666666666.0') as densite_population
    from latest
)

select
    {{ to_char('zipcode', 5) }} as zipcode,
    {{ to_integer('revenu_median') }} as median_income,
    {{ to_number('age_median', 'numeric(4, 1)') }} as median_age,
    {{ to_number('densite_population', 'numeric(10, 1)') }} as population_density
from cleaned
