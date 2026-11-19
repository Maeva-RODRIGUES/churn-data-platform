{{ config(alias='customers', unique_key='customer_id') }}
-- depends_on: {{ ref('core_geo_enrichment') }}

select * from {{ ref('stg_customers') }}
