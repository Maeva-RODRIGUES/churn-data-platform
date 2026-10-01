"""Contrôle de conformité des données sources au modèle physique (MPD).

1. Applique le DDL de ``sql/ddl`` (schémas raw / staging / core / mart).
2. Charge les fichiers sources tels quels dans le schéma RAW (COPY).
3. Tente d'insérer chaque ligne dans le schéma CORE et rattache chaque rejet
   à la contrainte violée (une ligne est comptée sur sa première violation).

Deux modes :
- par défaut, les valeurs RAW sont seulement typées (aucune correction) :
  le rapport liste ce que la couche STAGING devra traiter ;
- ``--staging-rules`` applique d'abord les règles STAGING proposées
  (notebook 3.0, section 8) : le rapport vérifie qu'elles suffisent.

Attention : les tables raw.* et core.* de la base ciblée sont vidées.
À lancer uniquement sur une base de développement.

Connexion : variables POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DB,
POSTGRES_USER, POSTGRES_PASSWORD (fichier .env, voir .env.example).

Usage :
    poetry run python scripts/check_mpd_conformance.py
    poetry run python scripts/check_mpd_conformance.py --staging-rules

Code de sortie : 0 si toutes les lignes sont acceptées, 1 sinon.
"""

import argparse
import csv
import os
import sys
from collections import Counter
from collections.abc import Callable
from decimal import Decimal, InvalidOperation
from pathlib import Path

import psycopg2
from dotenv import load_dotenv
from psycopg2 import errors

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DDL_DIR = PROJECT_ROOT / "sql" / "ddl"
DATA_RAW = PROJECT_ROOT / "data" / "raw"
DATA_PROCESSED = PROJECT_ROOT / "data" / "processed"

CENSUS_MISSING = "-666666666"

# Fichier source -> (table RAW, correspondance colonne source -> colonne RAW)
RAW_SOURCES = {
    DATA_RAW / "telco.csv": (
        "raw.telco",
        {
            "customerID": "customer_id",
            "gender": "gender",
            "SeniorCitizen": "senior_citizen",
            "Partner": "partner",
            "Dependents": "dependents",
            "tenure": "tenure",
            "PhoneService": "phone_service",
            "MultipleLines": "multiple_lines",
            "InternetService": "internet_service",
            "OnlineSecurity": "online_security",
            "OnlineBackup": "online_backup",
            "DeviceProtection": "device_protection",
            "TechSupport": "tech_support",
            "StreamingTV": "streaming_tv",
            "StreamingMovies": "streaming_movies",
            "Contract": "contract",
            "PaperlessBilling": "paperless_billing",
            "PaymentMethod": "payment_method",
            "MonthlyCharges": "monthly_charges",
            "TotalCharges": "total_charges",
            "Churn": "churn",
            "zipcode": "zipcode",
        },
    ),
    DATA_RAW / "telco_satisfaction.csv": (
        "raw.telco_satisfaction",
        {
            "customerID": "customer_id",
            "nb_appels_support": "nb_appels_support",
            "duree_moy_appel_min": "duree_moy_appel_min",
            "score_satisfaction": "score_satisfaction",
            "nps_score": "nps_score",
            "motif_contact_principal": "motif_contact_principal",
            "derniere_interaction_jours": "derniere_interaction_jours",
            "incident_facturation": "incident_facturation",
        },
    ),
    DATA_RAW / "telco_noisy_feedback_prep.csv": (
        "raw.telco_noisy_feedback",
        {
            "": "source_index",
            "Unnamed: 0": "source_index_2",
            "customerID": "customer_id",
            "gender": "gender",
            "SeniorCitizen": "senior_citizen",
            "Partner": "partner",
            "Dependents": "dependents",
            "tenure": "tenure",
            "PhoneService": "phone_service",
            "MultipleLines": "multiple_lines",
            "InternetService": "internet_service",
            "OnlineSecurity": "online_security",
            "OnlineBackup": "online_backup",
            "DeviceProtection": "device_protection",
            "TechSupport": "tech_support",
            "StreamingTV": "streaming_tv",
            "StreamingMovies": "streaming_movies",
            "Contract": "contract",
            "PaperlessBilling": "paperless_billing",
            "PaymentMethod": "payment_method",
            "MonthlyCharges": "monthly_charges",
            "TotalCharges": "total_charges",
            "Churn": "churn",
            "CustomerFeedback": "customer_feedback",
            "feedback_length": "feedback_length",
            "sentiment": "sentiment",
            "HasFeedback": "has_feedback",
        },
    ),
    # Cache produit par le notebook 3.0 en attendant le script d'ingestion Census (P4)
    DATA_PROCESSED / "census_zcta_2022.csv": (
        "raw.census_zcta",
        {
            "zipcode": "zipcode",
            "revenu_median": "revenu_median",
            "age_median": "age_median",
            "population_totale": "population_totale",
            "superficie_m2": "superficie_m2",
            "densite_population": "densite_population",
        },
    ),
}


# --- Typage strict : toute valeur hors format attendu est rejetée, jamais corrigée ---


class TypingError(ValueError):
    pass


def as_text(value: str | None) -> str | None:
    return value


def as_integer(value: str | None) -> int | None:
    if value is None:
        return None
    try:
        number = Decimal(value)  # accepte "106509.0" (export pandas d'une colonne avec NaN)
    except InvalidOperation as exc:
        raise TypingError(value) from exc
    if number != number.to_integral_value():
        raise TypingError(value)
    return int(number)


def as_decimal(value: str | None) -> Decimal | None:
    if value is None:
        return None
    try:
        return Decimal(value)
    except InvalidOperation as exc:
        raise TypingError(value) from exc


def boolean_from(mapping: dict[str, bool]) -> Callable[[str | None], bool | None]:
    def cast(value: str | None) -> bool | None:
        if value is None:
            return None
        if value not in mapping:
            raise TypingError(value)
        return mapping[value]

    return cast


as_yes_no = boolean_from({"Yes": True, "No": False})
as_zero_one = boolean_from({"1": True, "0": False})
as_true_false = boolean_from({"True": True, "False": False})


# Table CORE -> (table RAW, [(colonne CORE, colonne RAW, typage)]) — dans l'ordre des clés étrangères
CORE_MAPPINGS = {
    "core.enrichissement_geo": (
        "raw.census_zcta",
        [
            ("zipcode", "zipcode", as_text),
            ("revenu_median", "revenu_median", as_integer),
            ("age_median", "age_median", as_decimal),
            ("densite_population", "densite_population", as_decimal),
        ],
    ),
    "core.client": (
        "raw.telco",
        [
            ("customer_id", "customer_id", as_text),
            ("gender", "gender", as_text),
            ("senior_citizen", "senior_citizen", as_zero_one),
            ("partner", "partner", as_yes_no),
            ("dependents", "dependents", as_yes_no),
            ("zipcode", "zipcode", as_text),
            ("churn", "churn", as_yes_no),
        ],
    ),
    "core.contrat": (
        "raw.telco",
        [
            ("customer_id", "customer_id", as_text),
            ("tenure", "tenure", as_integer),
            ("contract", "contract", as_text),
            ("paperless_billing", "paperless_billing", as_yes_no),
            ("payment_method", "payment_method", as_text),
            ("monthly_charges", "monthly_charges", as_decimal),
            ("total_charges", "total_charges", as_decimal),
        ],
    ),
    "core.services": (
        "raw.telco",
        [
            ("customer_id", "customer_id", as_text),
            ("phone_service", "phone_service", as_yes_no),
            ("multiple_lines", "multiple_lines", as_text),
            ("internet_service", "internet_service", as_text),
            ("online_security", "online_security", as_text),
            ("online_backup", "online_backup", as_text),
            ("device_protection", "device_protection", as_text),
            ("tech_support", "tech_support", as_text),
            ("streaming_tv", "streaming_tv", as_text),
            ("streaming_movies", "streaming_movies", as_text),
        ],
    ),
    "core.satisfaction": (
        "raw.telco_satisfaction",
        [
            ("customer_id", "customer_id", as_text),
            ("nb_appels_support", "nb_appels_support", as_integer),
            ("duree_moy_appel_min", "duree_moy_appel_min", as_integer),
            ("score_satisfaction", "score_satisfaction", as_decimal),
            ("nps_score", "nps_score", as_integer),
            ("motif_contact_principal", "motif_contact_principal", as_text),
            ("derniere_interaction_jours", "derniere_interaction_jours", as_integer),
            ("incident_facturation", "incident_facturation", as_zero_one),
        ],
    ),
    "core.feedback": (
        "raw.telco_noisy_feedback",
        [
            ("customer_id", "customer_id", as_text),
            ("customer_feedback", "customer_feedback", as_text),
            ("feedback_length", "feedback_length", as_integer),
            ("sentiment", "sentiment", as_decimal),
            ("has_feedback", "has_feedback", as_true_false),
        ],
    ),
}


# --- Règles STAGING proposées (numérotation : notebook 3.0, section 8) ---
# Chaque règle reçoit une ligne RAW (dict) et renvoie la ligne corrigée.


def rule_total_charges_zero_when_no_tenure(row: dict) -> dict:
    # Règle 1 : TotalCharges = 0.0 lorsque tenure = 0 (data contract v0.2)
    if row["tenure"] == "0" and (row["total_charges"] or "").strip() == "":
        return {**row, "total_charges": "0"}
    return row


def rule_uppercase_customer_id(row: dict) -> dict:
    # Règle 2 : identifiants au format de telco.csv
    return {**row, "customer_id": row["customer_id"].upper()}


def rule_no_score_without_feedback(row: dict) -> dict:
    # Règle 4 : sans verbatim, longueur et sentiment sont absents
    if row["has_feedback"] == "False":
        return {**row, "feedback_length": None, "sentiment": None}
    return row


def rule_census_sentinel_to_null(row: dict) -> dict:
    # Règle 5 : sentinelle Census -> NULL
    return {key: (None if value in (CENSUS_MISSING, CENSUS_MISSING + ".0") else value) for key, value in row.items()}


STAGING_RULES = {
    "core.enrichissement_geo": [rule_census_sentinel_to_null],
    "core.contrat": [rule_total_charges_zero_when_no_tenure],
    "core.feedback": [rule_uppercase_customer_id, rule_no_score_without_feedback],
}


# --- Exécution ---


def connect():
    load_dotenv(PROJECT_ROOT / ".env")
    return psycopg2.connect(
        host=os.environ.get("POSTGRES_HOST", "localhost"),
        port=os.environ.get("POSTGRES_PORT", "5432"),
        dbname=os.environ.get("POSTGRES_DB", "churn"),
        user=os.environ.get("POSTGRES_USER", "churn"),
        password=os.environ.get("POSTGRES_PASSWORD", ""),
    )


def apply_ddl(cur) -> None:
    for ddl_file in sorted(DDL_DIR.glob("*.sql")):
        cur.execute(ddl_file.read_text(encoding="utf-8"))


def reset_tables(cur) -> None:
    tables = list(CORE_MAPPINGS)[::-1] + [table for table, _ in RAW_SOURCES.values()]
    cur.execute(f"TRUNCATE {', '.join(tables)}")


def load_raw(cur) -> None:
    for path, (table, columns) in RAW_SOURCES.items():
        if not path.exists():
            sys.exit(f"Fichier source introuvable : {path.relative_to(PROJECT_ROOT)}")
        with path.open(encoding="utf-8", newline="") as f:
            header = next(csv.reader(f))
            unknown = [name for name in header if name not in columns]
            if unknown:
                sys.exit(f"{path.name} : colonnes inattendues {unknown}")
            f.seek(0)
            target = ", ".join(columns[name] for name in header)
            cur.copy_expert(f"COPY {table} ({target}) FROM STDIN WITH (FORMAT csv, HEADER true)", f)


def violation_label(exc: psycopg2.Error) -> str:
    if isinstance(exc, errors.NotNullViolation):
        return f"NOT NULL {exc.diag.column_name}"
    return exc.diag.constraint_name or type(exc).__name__


def load_core(cur, core_table: str, with_staging_rules: bool) -> tuple[int, Counter]:
    raw_table, mapping = CORE_MAPPINGS[core_table]
    raw_columns = sorted({raw_col for _, raw_col, _ in mapping})
    cur.execute(f"SELECT {', '.join(raw_columns)} FROM {raw_table} ORDER BY ctid")
    rows = [dict(zip(raw_columns, values, strict=True)) for values in cur.fetchall()]

    core_columns = ", ".join(core_col for core_col, _, _ in mapping)
    placeholders = ", ".join(["%s"] * len(mapping))
    insert_sql = f"INSERT INTO {core_table} ({core_columns}) VALUES ({placeholders})"

    rejects: Counter = Counter()
    for row in rows:
        if with_staging_rules:
            for rule in STAGING_RULES.get(core_table, []):
                row = rule(row)
        try:
            values = []
            for core_col, raw_col, cast in mapping:
                try:
                    values.append(cast(row[raw_col]))
                except TypingError:
                    raise TypingError(f"type {core_col}") from None
        except TypingError as exc:
            rejects[str(exc)] += 1
            continue

        cur.execute("SAVEPOINT row_insert")
        try:
            cur.execute(insert_sql, values)
            cur.execute("RELEASE SAVEPOINT row_insert")
        except (errors.IntegrityError, errors.DataError) as exc:
            cur.execute("ROLLBACK TO SAVEPOINT row_insert")
            rejects[violation_label(exc)] += 1
    return len(rows), rejects


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--staging-rules", action="store_true", help="appliquer les règles STAGING proposées avant le chargement"
    )
    args = parser.parse_args()

    mode = "avec règles STAGING proposées" if args.staging_rules else "données RAW telles quelles"
    print(f"Contrôle de conformité au MPD — {mode}\n")

    with connect() as conn, conn.cursor() as cur:
        apply_ddl(cur)
        reset_tables(cur)
        load_raw(cur)

        total_rejects = 0
        print(f"{'Table CORE':<24} {'source':>7} {'acceptées':>10} {'rejetées':>9}  Motif de rejet")
        print("-" * 100)
        for core_table in CORE_MAPPINGS:
            n_rows, rejects = load_core(cur, core_table, args.staging_rules)
            n_rejected = sum(rejects.values())
            total_rejects += n_rejected
            reasons = " · ".join(f"{label} ({count})" for label, count in rejects.most_common()) or "—"
            print(f"{core_table:<24} {n_rows:>7} {n_rows - n_rejected:>10} {n_rejected:>9}  {reasons}")

    print(f"\n{'Aucun rejet.' if total_rejects == 0 else f'{total_rejects} lignes rejetées.'}")
    return 0 if total_rejects == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
