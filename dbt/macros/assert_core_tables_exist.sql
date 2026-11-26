{% macro assert_core_tables_exist() %}
    {% if execute %}
        {% set expected = [] %}
        {% for node in graph.nodes.values() if node.resource_type == 'model' and node.config.schema == 'core' %}
            {% do expected.append(node.alias) %}
        {% endfor %}
        {% set existing = run_query(
            "select table_name from information_schema.tables where table_schema = 'core'"
        ).columns[0].values() %}
        {% set missing = expected | reject('in', existing) | list %}
        {% if missing %}
            {{ exceptions.raise_compiler_error(
                "Tables CORE absentes : " ~ missing | sort | join(', ') ~ ". Appliquer sql/ddl avant dbt."
            ) }}
        {% endif %}
    {% endif %}
    select 1
{% endmacro %}
