"""Cohérence entre le DDL CORE et le projet dbt."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DDL_CORE = (ROOT / "sql" / "ddl" / "03_core.sql").read_text(encoding="utf-8")
DBT = ROOT / "dbt"


def test_constraints_test_lists_every_ddl_constraint():
    in_ddl = set(re.findall(r"CONSTRAINT (\w+)", DDL_CORE))
    test_sql = (DBT / "tests" / "core_constraints_present.sql").read_text(
        encoding="utf-8"
    )
    in_test = set(re.findall(r"\('(\w+)'\)", test_sql))
    assert in_test == in_ddl


def test_every_core_table_has_a_dbt_model():
    in_ddl = set(re.findall(r"CREATE TABLE IF NOT EXISTS core\.(\w+)", DDL_CORE))
    in_dbt = {
        re.search(r"alias='(\w+)'", path.read_text(encoding="utf-8")).group(1)
        for path in (DBT / "models" / "core").glob("*.sql")
    }
    assert in_dbt == in_ddl
