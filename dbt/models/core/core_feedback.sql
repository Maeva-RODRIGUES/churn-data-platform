{{ config(alias='feedback', unique_key='customer_id') }}
-- depends_on: {{ ref('core_customers') }}

select * from {{ ref('stg_feedback') }}
