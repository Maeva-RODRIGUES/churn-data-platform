-- Un lot ne doit pas contenir deux fois la même clé : STAGING, qui garde la
-- dernière ligne par _loaded_at, ne saurait pas laquelle choisir.
{% test unique_per_batch(model, key) %}
    select {{ key }} as source_key, _loaded_at, count(*) as rows_in_batch
    from {{ model }}
    group by {{ key }}, _loaded_at
    having count(*) > 1
{% endtest %}
