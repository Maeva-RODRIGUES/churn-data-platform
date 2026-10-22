"""Tests unitaires du typage strict et des règles STAGING du contrôle de conformité."""

from decimal import Decimal

import pytest

import check_mpd_conformance as conformance


@pytest.mark.parametrize(
    ("raw", "expected"),
    [("42", 42), ("106509.0", 106509), ("-3", -3), (None, None)],
)
def test_as_integer_accepts_integral_values(raw, expected):
    assert conformance.as_integer(raw) == expected


@pytest.mark.parametrize("raw", ["1.5", "abc", " ", ""])
def test_as_integer_rejects_non_integral_values(raw):
    with pytest.raises(conformance.TypingError):
        conformance.as_integer(raw)


def test_as_decimal_keeps_precision():
    assert conformance.as_decimal("29.85") == Decimal("29.85")


def test_as_decimal_rejects_blank():
    with pytest.raises(conformance.TypingError):
        conformance.as_decimal(" ")


@pytest.mark.parametrize(
    ("cast", "raw", "expected"),
    [
        (conformance.as_yes_no, "Yes", True),
        (conformance.as_yes_no, "No", False),
        (conformance.as_zero_one, "1", True),
        (conformance.as_zero_one, "0", False),
        (conformance.as_true_false, "True", True),
        (conformance.as_true_false, "False", False),
    ],
)
def test_boolean_casts(cast, raw, expected):
    assert cast(raw) is expected


@pytest.mark.parametrize(
    ("cast", "raw"),
    [
        (conformance.as_yes_no, "yes"),
        (conformance.as_zero_one, "True"),
        (conformance.as_true_false, "1"),
    ],
)
def test_boolean_casts_reject_other_spellings(cast, raw):
    with pytest.raises(conformance.TypingError):
        cast(raw)


@pytest.mark.parametrize("blank", [" ", "", None])
def test_total_charges_zero_when_no_tenure(blank):
    row = {"tenure": "0", "total_charges": blank}
    assert (
        conformance.rule_total_charges_zero_when_no_tenure(row)["total_charges"] == "0"
    )


def test_total_charges_untouched_when_tenure_positive():
    row = {"tenure": "3", "total_charges": " "}
    assert conformance.rule_total_charges_zero_when_no_tenure(row) == row


def test_uppercase_customer_id():
    row = {"customer_id": "0002-bbbbb"}
    assert conformance.rule_uppercase_customer_id(row)["customer_id"] == "0002-BBBBB"


def test_no_score_without_feedback():
    row = {"has_feedback": "False", "feedback_length": "0", "sentiment": "0.0"}
    result = conformance.rule_no_score_without_feedback(row)
    assert result["feedback_length"] is None
    assert result["sentiment"] is None


def test_scores_kept_with_feedback():
    row = {"has_feedback": "True", "feedback_length": "15", "sentiment": "0.4"}
    assert conformance.rule_no_score_without_feedback(row) == row


@pytest.mark.parametrize("sentinel", ["-666666666", "-666666666.0"])
def test_census_sentinel_to_null(sentinel):
    row = {"zipcode": "90003", "revenu_median": sentinel, "age_median": "31.5"}
    result = conformance.rule_census_sentinel_to_null(row)
    assert result == {"zipcode": "90003", "revenu_median": None, "age_median": "31.5"}


def test_rules_do_not_mutate_input():
    row = {"customer_id": "0002-bbbbb"}
    conformance.rule_uppercase_customer_id(row)
    assert row == {"customer_id": "0002-bbbbb"}
