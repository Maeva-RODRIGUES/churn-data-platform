# Churn Data Platform

[![CI](https://github.com/Maeva-RODRIGUES/churn-data-platform/actions/workflows/ci.yml/badge.svg?branch=develop)](https://github.com/Maeva-RODRIGUES/churn-data-platform/actions/workflows/ci.yml)
[![Licence MIT](https://img.shields.io/badge/licence-MIT-blue.svg)](LICENSE)

Plateforme de données pour analyser et prédire le désabonnement (*churn*) de clients télécom :
ingestion des sources, modèle de données PostgreSQL, enrichissement géographique (US Census)
et contrôle de conformité aux data contracts.

## Architecture

Les données traversent quatre couches, chacune dans son schéma PostgreSQL :

| Couche | Rôle | État |
|---|---|---|
| `raw` | Copie fidèle des fichiers sources, colonnes `TEXT`, aucune correction | en place |
| `staging` | Nettoyage et règles de correction (dbt) | règles proposées, notebook 3.0 |
| `core` | Modèle de référence typé : clés, domaines, bornes, cohérence | en place |
| `mart` | Tables d'analyse et de features (dbt) | à venir |

Le détail du modèle physique et des contraintes est dans [`sql/README.md`](sql/README.md).

## Structure du dépôt

```
data/            sources (non versionnées) : raw/ et processed/
notebooks/       exploration et enrichissement (1.0, 2.0, 3.0)
scripts/         check_mpd_conformance.py : contrôle des données contre le MPD
sql/ddl/         DDL PostgreSQL : schémas, couche raw, couche core
tests/           tests unitaires et jeu de données synthétique (fixtures/)
```

## Démarrage

Prérequis : Python 3.12 à 3.14, [Poetry](https://python-poetry.org/) 2.x, Docker.

```bash
poetry install --with dev         # dépendances
poetry run pre-commit install     # contrôles automatiques avant chaque commit
cp .env.example .env              # renseigner POSTGRES_PASSWORD (et CENSUS_API_KEY)
docker compose up -d              # PostgreSQL 16, DDL appliqué au premier démarrage
```

### Données

Les jeux de données ne sont pas versionnés. Source principale :
[Telco Customer Churn](https://www.kaggle.com/datasets/blastchar/telco-customer-churn),
jeu d'exemple IBM (IBM Sample Data Sets) republié sur Kaggle par BlastChar. Licence Kaggle :
« Data files © Original Authors », sans licence ouverte : les droits restent à leurs auteurs.
Le jeu est utilisé ici dans un cadre pédagogique, avec citation de la source, et n'est pas redistribué.

Les fichiers enrichis par IA générative (satisfaction, verbatims) sont des dérivés de ce jeu :
ils ne sont pas versionnés non plus.

- `data/raw/` : fichiers extraits de `data-enrichi.zip`
- `data/processed/census_zcta_2022.csv` : produit par le notebook 3.0 (clé API Census requise)

### Contrôler les données

```bash
poetry run python scripts/check_mpd_conformance.py                  # données brutes
poetry run python scripts/check_mpd_conformance.py --staging-rules  # avec les règles STAGING
```

Le script vide les tables `raw.*` et `core.*` : à lancer uniquement sur une base de développement.

## Qualité et tests

```bash
poetry run pytest                 # tests unitaires
poetry run ruff check .           # lint
poetry run ruff format .          # formatage
```

Sans les vraies données, le contrôle de conformité peut tourner sur le jeu synthétique :
`--data-dir tests/fixtures/data` (voir [`tests/fixtures/data/README.md`](tests/fixtures/data/README.md)).

## Contribuer

- `main` : version stable · `develop` : intégration · `feature/*` : une branche par sujet
- Une PR vers `develop` (puis `develop` → `main`) ; aucun push direct sur `main` ni `develop`.
- Merge possible quand :
  - la CI est verte : `lint`, `notebooks`, `dependencies`, `ddl`, `tests` ;
  - l'autre contributeur a approuvé la PR ;
  - les conversations sont résolues.
- Les notebooks sont versionnés sans leurs sorties (`nbstripout`, appliqué par pre-commit).
- Dependabot ouvre chaque semaine les PR de mise à jour des dépendances.

## Auteurs

- Maëva RODRIGUES ([@Maeva-RODRIGUES](https://github.com/Maeva-RODRIGUES))
- Alexandre Gire ([@Alexvruu](https://github.com/Alexvruu))

## Licence

Code sous licence [MIT](LICENSE). La licence MIT ne couvre pas les données : le jeu Telco Customer Churn (IBM, via Kaggle) et ses dérivés restent soumis aux droits de leurs auteurs (voir [Données](#données)).
