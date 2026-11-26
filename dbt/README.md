# dbt : RAW → STAGING → CORE

`sql/ddl` reste la seule définition de CORE (clés, CHECK). dbt matérialise STAGING en vues, puis insère dans les tables CORE existantes (incrémental `merge`, `full_refresh: false`, `on_schema_change: fail`).

## Lancer

```bash
# Variables POSTGRES_* du .env exportées dans le shell
poetry run dbt build --project-dir dbt --profiles-dir dbt
```

Le DDL doit être appliqué avant : sinon `on-run-start` arrête dbt avant toute écriture.

## Règles

| Où | Quoi | Effet |
|---|---|---|
| STAGING | dernière ligne par clé selon `_loaded_at` (RAW cumule les lots) | un client = une ligne |
| STAGING | conversions strictes : valeur hors format → `NULL` | rejet par le `NOT NULL` de CORE, jamais de troncature |
| Tests RAW | `unique_per_batch` : pas deux fois la même clé dans un lot | bloque tout l'aval |
| Tests STAGING (error) | `unique`, `not_null`, `relationships`, `accepted_values` | bloquent l'écriture en CORE |
| CHECK du DDL | règles métier | le modèle échoue, CORE inchangé |
| Tests (warn) | plages observées, réciproque de R1 | alerte sans rejet |
| `core_constraints_present` | toutes les contraintes du DDL sont en base | détecte une table recréée sans contraintes |

## Limites

- `merge` ne supprime pas : un client absent d'un nouveau lot reste en CORE.
- Pas d'atomicité entre modèles : si `core_contracts` échoue après `core_customers`, on relance après correction (merge idempotent).
- Réappliquer le DDL ne restaure pas une contrainte supprimée (`CREATE TABLE IF NOT EXISTS`) : seul `core_constraints_present` le voit.
