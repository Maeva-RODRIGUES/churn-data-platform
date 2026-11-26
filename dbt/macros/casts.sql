-- Conversions strictes : une valeur hors format donne NULL, rejeté par le NOT NULL
-- de CORE. Jamais de correction silencieuse (un ::varchar(n) explicite tronque).

{% macro to_varchar(column, length) -%}
    (case when char_length({{ column }}) <= {{ length }} then {{ column }} end)::varchar({{ length }})
{%- endmacro %}

{% macro to_char(column, length) -%}
    (case when char_length({{ column }}) = {{ length }} then {{ column }} end)::char({{ length }})
{%- endmacro %}

{% macro to_integer(column, type='integer') -%}
    (case
        when {{ column }} ~ '^-?[0-9]+(\.0+)?$' then {{ column }}::numeric
    end)::{{ type }}
{%- endmacro %}

{% macro to_number(column, type) -%}
    (case
        when {{ column }} ~ '^-?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][-+]?[0-9]+)?$' then {{ column }}
    end)::{{ type }}
{%- endmacro %}

{% macro to_boolean(column, true_value, false_value) -%}
    (case {{ column }} when '{{ true_value }}' then true when '{{ false_value }}' then false end)
{%- endmacro %}

-- Dernière version de chaque clé quand RAW cumule plusieurs lots
{% macro latest_by(relation, key) -%}
    select * from (
        select
            *,
            row_number() over (partition by {{ key }} order by _loaded_at desc) as _row_rank
        from {{ relation }}
    ) as ranked
    where _row_rank = 1
{%- endmacro %}
