{{ config(alias='geo_enrichment', unique_key='zipcode') }}

select * from {{ ref('stg_geo_enrichment') }}
