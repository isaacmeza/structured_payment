#!/usr/bin/env python3
# AI disclosure: This file was created with AI assistance.
"""Render manuscript tables directly from compact Stata CSV files.

Regression-table strings are already publication-formatted by Stata and are
kept verbatim.  Balance and targeting tables use compact numeric CSVs whose
rounding and fixed LaTeX layouts are defined here.  The script uses only the
Python standard library.
"""

from __future__ import annotations

import argparse
import csv
import os
import re
import tempfile
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from pathlib import Path
from typing import Callable, Iterable


ROOT = Path(__file__).resolve().parents[1]
CSV_DIR = ROOT / "Tables" / "reg_results"
TABLE_DIR = ROOT / "Tables"


class TableInputError(ValueError):
    """Raised when a Stata CSV does not match the expected table contract."""


def read_esttab(name: str, columns: int) -> list[list[str]]:
    """Read esttab's Excel-safe CSV syntax without changing displayed text."""
    path = CSV_DIR / name
    if not path.is_file():
        raise TableInputError(f"Required input is missing: {path}")

    rows: list[list[str]] = []
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        for line_number, line in enumerate(handle, start=1):
            # esttab prefixes each quoted cell with '=' so Excel treats it as a
            # formula string.  Remove only those field-boundary prefixes, then
            # let csv.reader handle quoting and any embedded punctuation.
            normalized = re.sub(r"(^|,)=\"", r'\1"', line)
            parsed = next(csv.reader([normalized]))
            if not parsed:
                continue
            if len(parsed) not in (1, columns + 1):
                raise TableInputError(
                    f"{path}:{line_number}: expected 1 or {columns + 1} "
                    f"fields, found {len(parsed)}"
                )
            if len(parsed) == 1:
                parsed.extend([""] * columns)
            rows.append(parsed)
    return rows


def read_direct_table(
    name: str,
    columns: list[str],
    expected_statistics: list[str],
    key_name: str = "statistic",
) -> dict[str, dict[str, str]]:
    """Read and strictly validate a compact, table-shaped Stata CSV."""
    path = CSV_DIR / name
    if not path.is_file():
        raise TableInputError(f"Required input is missing: {path}")

    expected_header = [key_name, *columns]
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != expected_header:
            raise TableInputError(
                f"{path}: expected columns {expected_header}; "
                f"found {reader.fieldnames}"
            )
        rows = list(reader)

    observed = [record[key_name] for record in rows]
    if observed != expected_statistics:
        raise TableInputError(
            f"{path}: unexpected row structure\n"
            f"expected: {expected_statistics}\nobserved: {observed}"
        )
    if len(set(observed)) != len(observed):
        raise TableInputError(f"{path}: statistic identifiers must be unique")

    for line_number, record in enumerate(rows, start=2):
        for column in columns:
            value = record[column].strip()
            record[column] = value
            if value == "":
                continue
            try:
                Decimal(value)
            except InvalidOperation as error:
                raise TableInputError(
                    f"{path}:{line_number}: {column} is not numeric: {value!r}"
                ) from error
    return {record[key_name]: record for record in rows}


def format_number(value: str, decimals: int) -> str:
    """Round like Excel/Stata display output and omit immaterial trailing zeroes."""
    if value == "":
        return ""
    quantum = Decimal(1).scaleb(-decimals)
    rounded = Decimal(value).quantize(quantum, rounding=ROUND_HALF_UP)
    if rounded == 0:
        return "0"
    text = format(rounded, "f")
    return text.rstrip("0").rstrip(".") if "." in text else text


def formatted_direct_row(
    records: dict[str, dict[str, str]],
    statistic: str,
    decimals: int,
    columns: Iterable[str],
) -> list[str]:
    return [format_number(records[statistic][column], decimals) for column in columns]


def require_sequence(rows: list[list[str]], labels: Iterable[str], source: str) -> None:
    observed = [row[0] for row in rows]
    expected = list(labels)
    if observed != expected:
        raise TableInputError(
            f"{source}: unexpected row structure\n"
            f"expected: {expected}\nobserved: {observed}"
        )


def row(label: str, values: Iterable[str]) -> str:
    return f"{label} & " + " & ".join(values) + r" \\"


def blank(columns: int) -> str:
    return row("", [""] * columns)


def finish(lines: list[str]) -> str:
    return "\n".join(lines) + "\n"


def decomposition_values(values: list[str]) -> list[str]:
    if len(values) != 7:
        raise TableInputError("A decomposition panel must contain seven outcomes")
    return values[:6] + [""] + values[6:]


DECOMPOSITION_HEADER = [
    r"\begin{tabular}{lcccccccc}",
    r"\toprule",
    r"      &       & \multicolumn{5}{c}{Components of FC}  &       &  \\",
    r"\cmidrule{3-7}      & FC    & Interest pymnt & Fee pymnt & Def$\times$Ppl pymnt & Lost pawn value & Default &       & CR \\",
    r"\cmidrule{2-2}\cmidrule{9-9}      &       & $\sum_t P^I_{it}$ & $\sum_t P^F_{it}$ & $\mathds{1}(\text{Def}_i)\times\sum_t P^C_{it}$ & $\mathds{1}(\text{Def}_i)\times \text{Value-Loan}_i$ & $\mathds{1}(\text{Def}_i)$ &       &  \\",
    r"\midrule",
]


def render_decomposition(
    csv_name: str,
    first_label: str,
    second_label: str,
    suppress_fee: bool = False,
) -> str:
    rows = read_esttab(csv_name, 7)
    require_sequence(
        rows,
        ["", "", first_label, "", second_label, "", "N", "R-sq", "Control Mean", "Standard errors in parentheses", "* p<0.1, ** p<0.05, *** p<0.01"],
        csv_name,
    )
    coefficient_1, se_1 = rows[2][1:], rows[3][1:]
    coefficient_2, se_2 = rows[4][1:], rows[5][1:]
    stats = [rows[6][1:], rows[7][1:], rows[8][1:]]
    if suppress_fee:
        coefficient_1[2] = "-"
        coefficient_2[2] = "-"
        se_1[2] = ""
        se_2[2] = ""
        for values in stats:
            values[2] = ""

    lines = DECOMPOSITION_HEADER + [
        row("", decomposition_values([f"({index})" for index in range(1, 8)])),
        r"\midrule",
        r"\midrule",
        row(first_label, decomposition_values(coefficient_1)),
        row("", decomposition_values(se_1)),
        row(second_label, decomposition_values(coefficient_2)),
        row("", decomposition_values(se_2)),
        blank(8),
        r"\midrule",
        row("Observations", decomposition_values(stats[0])),
        row("R-squared", decomposition_values(stats[1])),
        row("Control Mean", decomposition_values(stats[2])),
        r"\bottomrule",
        r"\bottomrule",
        r"\end{tabular}%",
    ]
    return finish(lines)


def render_table1() -> str:
    return render_decomposition("Table1.csv", "Mandatory structured", "Choice")


def panel_a_values(values: list[str]) -> list[str]:
    return values[:4] + [""] + values[4:5] + [""]


def panel_bc_values(values: list[str]) -> list[str]:
    return values[5:9] + [""] + values[9:11]


def render_table2() -> str:
    rows = read_esttab("Table2.csv", 11)
    require_sequence(
        rows,
        ["", "", "Mandatory structured", "", "Choice", "", "N", "R-sq", "Control Mean", "Standard errors in parentheses", "* p<0.1, ** p<0.05, *** p<0.01"],
        "Table2.csv",
    )
    labels = ["Mandatory structured", "", "Choice", ""]
    data_rows = [rows[2][1:], rows[3][1:], rows[4][1:], rows[5][1:]]
    stats = [rows[6][1:], rows[7][1:], rows[8][1:]]
    lines = [
        r"\begin{tabular}{lccccccc}",
        r"\toprule",
        r"      & \multicolumn{7}{c}{Panel A  : Speed of payment} \\",
        r"\cmidrule{2-8}      & Days to & \% of payment & $\Pr($Recovery & Loan duration  &       & Loan duration &  \\",
        r"      &  1st payment &  in 1st visit &  in 1st visit) & (days) &       &  $|$ recovery &  \\",
        row(r"\cmidrule{1-5}\cmidrule{7-8}     ", ["(1)", "(2)", "(3)", "(4)", "", "(5)", ""]),
    ]
    for index, (label, values) in enumerate(zip(labels, data_rows)):
        prefix = r"\cmidrule{1-5}\cmidrule{7-8}" if index == 0 else ""
        lines.append(row(prefix + label, panel_a_values(values)))
    lines += [
        blank(7),
        row(r"\cmidrule{1-5}\cmidrule{7-8}Observations", panel_a_values(stats[0])),
        row("R-squared", panel_a_values(stats[1])),
        row("Control Mean", panel_a_values(stats[2])),
        blank(7),
        r"\midrule",
        r"      & \multicolumn{4}{c}{Panel B  : Variables related to default} &       & \multicolumn{2}{c}{Panel C  : Visit variables} \\",
        r"\cmidrule{2-8}      & $\Pr($+ payment & \% of pay & $\Pr($payment $=0$ &       &       &       & \# of visits \\",
        r"      &  \& default) &  $|$ def  &  $|$ def) & $\Pr($ payment $=0$) &       & \# of visits &  $|$ def \\",
        r"\midrule",
        r"\midrule",
        row("", ["(6)", "(7)", "(8)", "(9)", "", "(10)", "(11)"]),
        r"\midrule",
        r"\midrule",
    ]
    lines.extend(row(label, panel_bc_values(values)) for label, values in zip(labels, data_rows))
    lines += [
        blank(7),
        row(r"\cmidrule{1-5}\cmidrule{7-8}Observations", panel_bc_values(stats[0])),
        row("R-squared", panel_bc_values(stats[1])),
        row("Control Mean", panel_bc_values(stats[2])),
        r"\bottomrule",
        r"\bottomrule",
        r"\end{tabular}%",
    ]
    return finish(lines)


def render_table3() -> str:
    rows = read_esttab("Table3.csv", 4)
    require_sequence(
        rows,
        ["", "", "ATE", "", "ToT", "", "TuT", "", "E[Y1]", "", "E[Y0]", "", "ToT-TuT", "", "ASB", "", "ASL", "", "N", "H_0 : ASG=0", r"H_0 : ASG$\leq$ 0", "Standard errors in parentheses", "* p<0.1, ** p<0.05, *** p<0.01"],
        "Table3.csv",
    )
    label_map = {
        "E[Y1]": r"$\mathbb{E}[Y_1]$",
        "E[Y0]": r"$\mathbb{E}[Y_0]$",
        "ToT-TuT": "ASG",
    }
    lines = [
        r"\begin{tabular}{lcccc}",
        r"\toprule",
        r"      & CR \% benefit & FC benefit & \% (1-Default) & \% (1-Refinance) \\",
        r"\midrule",
        row("", ["(1)", "(2)", "(3)", "(4)"]),
        r"\midrule",
        r"\midrule",
    ]
    for index in (2, 4, 6, 8, 10):
        lines.append(row(label_map.get(rows[index][0], rows[index][0]), rows[index][1:]))
        lines.append(row("", rows[index + 1][1:]))
    lines.append(r"\midrule")
    for index in (12, 14, 16):
        lines.append(row(label_map.get(rows[index][0], rows[index][0]), rows[index][1:]))
        lines.append(row("", rows[index + 1][1:]))
    lines += [
        r"\midrule",
        row("Observations", rows[18][1:]),
        row(r"$H_0$ : ASG=0", rows[19][1:]),
        row(r"$H_0$ : ASG$\leq$ 0", rows[20][1:]),
        r"\bottomrule",
        r"\bottomrule",
        r"\end{tabular}%",
    ]
    return finish(lines)


def render_oa3() -> str:
    panel_files = [f"TableOA3{suffix}.csv" for suffix in "abcde"]
    panels = [read_esttab(name, 6) for name in panel_files]
    simple_labels = ["", "", "Mandatory structured", "", "N", "R-sq", "Control Mean", "Standard errors in parentheses", "* p<0.1, ** p<0.05, *** p<0.01"]
    full_labels = ["", "", "Mandatory structured", "", "Choice", "", "N", "R-sq", "Control Mean", "Standard errors in parentheses", "* p<0.1, ** p<0.05, *** p<0.01"]
    for name, rows in zip(panel_files[:4], panels[:4]):
        require_sequence(rows, simple_labels, name)
    require_sequence(panels[4], full_labels, panel_files[4])

    descriptions = [
        r"Panel A : $\quad$ Control  = 0           $\quad\quad$                 Mandatory structured  = 0",
        r"Panel B : $\quad$ Control  = 0         $\quad\quad$                    Mandatory structured = 1",
        r"Panel C : $\quad$ Control  = 1        $\quad\quad$                     Mandatory structured = 0",
        r"Panel D : $\quad$ Control  = 1       $\quad\quad$                      Mandatory structured = 1",
        r"Panel E : $\quad$ Prediction with lasso-logit model",
    ]
    lines = [
        r"\begin{tabular}{lcccccc}",
        r"\toprule",
        r"      & FC    & Interest pymnt & Principal pymnt & Lost pawn value & Default & CR \\",
        r"\midrule",
    ]
    for panel_index, (description, rows) in enumerate(zip(descriptions, panels)):
        lines += [
            rf"      & \multicolumn{{6}}{{c}}{{{description}}} \\",
            r"\midrule",
            r"\midrule",
            row("", [f"({6 * panel_index + offset})" for offset in range(1, 7)]),
            r"\midrule",
            r"\midrule",
            row("Mandatory structured", rows[2][1:]),
            row("", rows[3][1:]),
        ]
        stat_start = 4
        if panel_index == 4:
            lines += [row("Choice", rows[4][1:]), row("", rows[5][1:])]
            stat_start = 6
        lines += [
            blank(6),
            r"\midrule",
            row("Observations", rows[stat_start][1:]),
            row("R-sq", rows[stat_start + 1][1:]),
            row("Control Mean", rows[stat_start + 2][1:]),
        ]
        if panel_index < 4:
            lines += [r"\midrule", r"\midrule", blank(6), r"\midrule"]
    lines += [r"\bottomrule", r"\bottomrule", r"\end{tabular}%"]
    return finish(lines)


def render_oa4() -> str:
    rows = read_esttab("TableOA4.csv", 10)
    require_sequence(
        rows,
        ["", "", "Mandatory structured", "", "Choice", "", "N", "R-sq", "Control Mean", "Standard errors in parentheses", "* p<0.1, ** p<0.05, *** p<0.01"],
        "TableOA4.csv",
    )
    labels = ["Mandatory structured", "", "Choice", ""]
    data_rows = [rows[2][1:], rows[3][1:], rows[4][1:], rows[5][1:]]
    stats = [rows[6][1:], rows[7][1:], rows[8][1:]]
    headings = [
        r"      & FC    & FC (subj.value) & FC +  tc & FC - interest & FC (subj.value) + tc - int \\",
        r"      & CR    & CR (subj.value) & CR +  tc & CR - interest & CR (subj.value) + tc - int \\",
    ]
    lines = [r"\begin{tabular}{lccccc}", r"\toprule"]
    for panel_index, heading in enumerate(headings):
        subset = slice(panel_index * 5, panel_index * 5 + 5)
        if panel_index == 1:
            lines += [r"\midrule", r"\midrule", blank(5), r"\midrule"]
        lines += [
            heading,
            r"\midrule",
            row("", [f"({panel_index * 5 + offset})" for offset in range(1, 6)]),
            r"\midrule",
            r"\midrule",
        ]
        lines.extend(row(label, values[subset]) for label, values in zip(labels, data_rows))
        lines += [
            blank(5),
            r"\midrule",
            row("Observations", stats[0][subset]),
            row("R-squared", stats[1][subset]),
            row("Control Mean", stats[2][subset]),
        ]
    lines += [r"\bottomrule", r"\bottomrule", r"\end{tabular}%"]
    return finish(lines)


def render_oa5() -> str:
    return render_decomposition(
        "TableOA5.csv", "Promise Mandate", "Promise Choice", suppress_fee=True
    )


def render_oa6() -> str:
    rows = read_esttab("TableOA6.csv", 5)
    require_sequence(
        rows,
        ["", "", "Mandatory structured", "", "Choice", "", "N", "R-sq", "Control Mean", "Standard errors in parentheses", "* p<0.1, ** p<0.05, *** p<0.01"],
        "TableOA6.csv",
    )
    lines = [
        r"\begin{tabular}{lccccc}",
        r"\toprule",
        r"      & \multicolumn{5}{c}{Ever pawns again (ITT)} \\",
        r"\cmidrule{2-6}      &       & After 90 days & Within 90 days & Different collateral & Cond. on rec \\",
        r"\midrule",
        r"\midrule",
        row("", ["(1)", "(2)", "(3)", "(4)", "(5)"]),
        r"\midrule",
        r"\midrule",
        row("Mandatory structured", rows[2][1:]),
        row("", rows[3][1:]),
        row("Choice", rows[4][1:]),
        row("", rows[5][1:]),
        blank(5),
        r"\midrule",
        row("Observations", rows[6][1:]),
        row("R-squared", rows[7][1:]),
        row("Control Mean", rows[8][1:]),
        r"\bottomrule",
        r"\bottomrule",
        r"\end{tabular}%",
    ]
    return finish(lines)


DIRECT_ARM_COLUMNS = ["control", "mandatory", "choice"]


def validate_direct_balance_rows(
    records: dict[str, dict[str, str]],
    source: str,
) -> None:
    """Require exactly the cells used by the OA balance-table layouts."""
    for statistic, record in records.items():
        for column in DIRECT_ARM_COLUMNS:
            if record[column] == "":
                raise TableInputError(
                    f"{source}: {statistic}/{column} must not be blank"
                )
        p_value_expected = statistic.endswith("_mean") or statistic.endswith(
            "_median"
        )
        if p_value_expected == (record["p_value"] == ""):
            requirement = "nonblank" if p_value_expected else "blank"
            raise TableInputError(
                f"{source}: {statistic}/p_value must be {requirement}"
            )


def direct_estimate_row(
    records: dict[str, dict[str, str]],
    statistic: str,
    arm_decimals: int,
    p_decimals: int = 2,
) -> list[str]:
    values = formatted_direct_row(
        records, statistic, arm_decimals, DIRECT_ARM_COLUMNS
    )
    values.append(format_number(records[statistic]["p_value"], p_decimals))
    return values


def direct_se_row(
    records: dict[str, dict[str, str]], statistic: str, decimals: int
) -> list[str]:
    values = formatted_direct_row(records, statistic, decimals, DIRECT_ARM_COLUMNS)
    return [f"({value})" for value in values] + [""]


def render_oa1() -> str:
    expected = [
        "takeup_mean",
        "takeup_se",
        "num_borrowers_mean",
        "num_borrowers_se",
        "num_borrowers_median",
        "num_pawns_borrower_mean",
        "num_pawns_borrower_se",
        "num_pawns_borrower_median",
        "num_pawns_mean",
        "num_pawns_se",
        "num_pawns_median",
        "average_loan_mean",
        "average_loan_se",
        "average_loan_median",
        "total_borrowed_mean",
        "total_borrowed_se",
        "total_borrowed_median",
        "observations",
    ]
    records = read_direct_table(
        "TableOA1.csv",
        [*DIRECT_ARM_COLUMNS, "p_value"],
        expected,
    )
    validate_direct_balance_rows(records, "TableOA1.csv")
    median_label = (
        r"\rowcolor[rgb]{ .949,  .949,  .949} "
        r"\multicolumn{1}{r}{median}"
    )
    lines = [
        r"\begin{tabular}{lcccr}",
        r"\toprule",
        r"      & Control & Structure & Choice & \multicolumn{1}{c}{p-value} \\",
        r"\midrule",
        r"\midrule",
        row("Take-up", direct_estimate_row(records, "takeup_mean", 3)),
        row("", direct_se_row(records, "takeup_se", 2)),
        r"\midrule",
        row(
            "Number of borrowers",
            direct_estimate_row(records, "num_borrowers_mean", 1),
        ),
        row("", direct_se_row(records, "num_borrowers_se", 2)),
        row(
            median_label,
            direct_estimate_row(records, "num_borrowers_median", 1),
        ),
        r"\midrule",
        row(
            "Number of pawns/borrower",
            direct_estimate_row(records, "num_pawns_borrower_mean", 1),
        ),
        row("", direct_se_row(records, "num_pawns_borrower_se", 2)),
        row(
            median_label,
            direct_estimate_row(records, "num_pawns_borrower_median", 1),
        ),
        r"\midrule",
        row(
            "Number of pawns",
            direct_estimate_row(records, "num_pawns_mean", 1),
        ),
        row("", direct_se_row(records, "num_pawns_se", 1)),
        row(
            median_label,
            direct_estimate_row(records, "num_pawns_median", 1),
        ),
        r"\midrule",
        row(
            "Amt borrowed/borrower",
            direct_estimate_row(records, "average_loan_mean", 1),
        ),
        row("", direct_se_row(records, "average_loan_se", 1)),
        row(
            median_label,
            direct_estimate_row(records, "average_loan_median", 1),
        ),
        r"\midrule",
        row(
            "Total borrowed",
            direct_estimate_row(records, "total_borrowed_mean", 0),
        ),
        row("", direct_se_row(records, "total_borrowed_se", 0)),
        row(
            median_label,
            direct_estimate_row(records, "total_borrowed_median", 1),
        ),
        r"\midrule",
        row(
            "Obs",
            formatted_direct_row(
                records, "observations", 0, DIRECT_ARM_COLUMNS
            )
            + [""],
        ),
        r"\bottomrule",
        r"\bottomrule",
        r"\end{tabular}%",
    ]
    return finish(lines)


def render_oa2() -> str:
    outcomes = [
        ("appraisal_value", "Subjective value", 0, 0),
        ("trouble_paying_bills", "Trouble paying bills", 2, 3),
        ("present_bias", "Present bias", 2, 2),
        ("makes_budget", "Makes budget", 2, 3),
        ("expected_recovery", "Subj. pr. of recovery", 2, 3),
        ("previous_pawn", "Pawn before", 2, 3),
        ("age", "Age", 2, 3),
        ("female", "Female", 2, 3),
        ("high_school_or_more", "+ High-school", 2, 3),
    ]
    expected = [
        statistic
        for outcome, _, _, _ in outcomes
        for statistic in (f"{outcome}_mean", f"{outcome}_se")
    ] + ["observations"]
    records = read_direct_table(
        "TableOA2.csv",
        [*DIRECT_ARM_COLUMNS, "p_value"],
        expected,
    )
    validate_direct_balance_rows(records, "TableOA2.csv")
    lines = [
        r"\begin{tabular}{lcccc}",
        r"\toprule",
        r"      & \multicolumn{1}{p{4.5em}}{Control} & \multicolumn{1}{p{4.93em}}{Structure} & \multicolumn{1}{p{3.43em}}{Choice} & \multicolumn{1}{p{3.43em}}{p-value} \\",
        r"\midrule",
        r"      & \multicolumn{4}{c}{Panel : Survey Data} \\",
        r"\midrule",
        r"\midrule",
    ]
    for outcome, label, mean_decimals, se_decimals in outcomes:
        lines.append(
            row(
                label,
                direct_estimate_row(records, f"{outcome}_mean", mean_decimals),
            )
        )
        lines.append(row("", direct_se_row(records, f"{outcome}_se", se_decimals)))
    lines += [
        r"\midrule",
        row(
            "Obs",
            formatted_direct_row(
                records, "observations", 0, DIRECT_ARM_COLUMNS
            )
            + [""],
        ),
        r"\bottomrule",
        r"\bottomrule",
        r"\end{tabular}%",
    ]
    return finish(lines)


def render_sa1() -> str:
    rules = [
        ("all_to_status_quo", "All to Status-quo"),
        ("all_to_structure", "All to Structure"),
        ("optimal", "Optimal"),
        ("narrow_rf", "Narrow rule (RF)"),
        ("narrow_logit", "Narrow rule (Logit)"),
        ("allow_choice", "Allow choice"),
    ]
    columns = [
        "incorrectly_control",
        "incorrectly_treatment",
        "overall_error",
    ]
    records = read_direct_table(
        "TableSA1.csv",
        columns,
        [rule for rule, _ in rules],
        key_name="rule",
    )
    for rule, _ in rules:
        for column in columns:
            if records[rule][column] == "":
                raise TableInputError(f"TableSA1.csv: {rule}/{column} is blank")
    lines = [
        r"\begin{tabular}{lccc}",
        r"\toprule",
        r"\multicolumn{1}{c}{Rule} & \% incorrectly  & \% incorrectly  & Overall Error Rate \\",
        r"      & assigned to control  &  assigned to treatment &  \\",
        r"\midrule",
        r"\midrule",
    ]
    lines.extend(
        row(label, formatted_direct_row(records, rule, 2, columns))
        for rule, label in rules
    )
    lines += [r"\bottomrule", r"\bottomrule", r"\end{tabular}%"]
    return finish(lines)


def render_oa8() -> str:
    rows = read_esttab("TableOA8.csv", 14)
    require_sequence(
        rows,
        ["", "", "Mandatory structured", "", "Choice", "", "N", "R-sq", "Control Mean", "Standard errors in parentheses", "* p<0.1, ** p<0.05, *** p<0.01"],
        "TableOA8.csv",
    )
    data_rows = [rows[2][1:], rows[3][1:], rows[4][1:], rows[5][1:]]
    stats = [rows[6][1:], rows[7][1:], rows[8][1:]]
    labels = ["Mandatory structured", "", "Choice", ""]
    lines = DECOMPOSITION_HEADER + [
        row("", decomposition_values([f"({index})" for index in range(1, 8)])),
        r"\midrule",
        r"\midrule",
    ]
    lines.extend(
        row(label, decomposition_values(values[:7]))
        for label, values in zip(labels, data_rows)
    )
    lines += [
        blank(8),
        r"\midrule",
        row("Observations", decomposition_values(stats[0][:7])),
        row("R-squared", decomposition_values(stats[1][:7])),
        row("Control Mean", decomposition_values(stats[2][:7])),
        row("CATE subsample", decomposition_values([r"\checkmark"] * 7)),
        r"\midrule",
        r"\midrule",
        blank(8),
        r"\midrule",
        row("", decomposition_values([f"({index})" for index in range(8, 15)])),
        r"\midrule",
        r"\midrule",
    ]
    lines.extend(
        row(label, decomposition_values(values[7:14]))
        for label, values in zip(labels, data_rows)
    )
    lines += [
        blank(8),
        r"\midrule",
        row("Observations", decomposition_values(stats[0][7:14])),
        row("R-squared", decomposition_values(stats[1][7:14])),
        row("Control Mean", decomposition_values(stats[2][7:14])),
        row("Survey subsample", decomposition_values([r"\checkmark"] * 7)),
        r"\bottomrule",
        r"\bottomrule",
        r"\end{tabular}%",
    ]
    return finish(lines)


def render_oa9() -> str:
    rows = read_esttab("TableOA9.csv", 2)
    require_sequence(
        rows,
        ["", "", "Mandatory structured", "", "Choice", "", "N", "R-sq", "DepVarMean", "Standard errors in parentheses", "* p<0.1, ** p<0.05, *** p<0.01"],
        "TableOA9.csv",
    )
    lines = [
        r"\begin{tabular}{lcc}",
        r"\toprule",
        r"      & Choose structure in $t+1$ & Ever choose structure in $t+1$ \\",
        row(r"\cmidrule{2-3}$t$  ", ["(1)", "(2)"]),
        r"\midrule",
        r"\midrule",
        row("Mandatory structured (ATE)", rows[2][1:]),
        row("", rows[3][1:]),
        row("Choice  (ITT)", rows[4][1:]),
        row("", rows[5][1:]),
        blank(2),
        r"\midrule",
        row("Observations", rows[6][1:]),
        row("R-sq", rows[7][1:]),
        row("DepVarMean", rows[8][1:]),
        r"\bottomrule",
        r"\bottomrule",
        r"\end{tabular}%",
    ]
    return finish(lines)


RENDERERS: dict[str, tuple[str, Callable[[], str]]] = {
    "Table1": ("Table1.tex", render_table1),
    "Table2": ("Table2.tex", render_table2),
    "Table3": ("Table3.tex", render_table3),
    "TableOA1": ("TableOA1.tex", render_oa1),
    "TableOA2": ("TableOA2.tex", render_oa2),
    "TableOA3": ("TableOA3.tex", render_oa3),
    "TableOA4": ("TableOA4.tex", render_oa4),
    "TableOA5": ("TableOA5.tex", render_oa5),
    "TableOA6": ("TableOA6.tex", render_oa6),
    "TableOA8": ("TableOA8.tex", render_oa8),
    "TableOA9": ("TableOA9.tex", render_oa9),
    "TableSA1": ("TableSA1.tex", render_sa1),
}


def write_atomic(path: Path, contents: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        dir=path.parent, prefix=f".{path.name}.", suffix=".tmp"
    )
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(contents)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_path, path)
    except BaseException:
        temporary_path.unlink(missing_ok=True)
        raise


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render manuscript tables from compact Stata CSVs."
    )
    parser.add_argument(
        "--table",
        action="append",
        choices=tuple(RENDERERS),
        help="table ID to render; repeat the option as needed (default: all)",
    )
    parser.add_argument(
        "--output-file",
        type=Path,
        help="output path for a single --table invocation",
    )
    options = parser.parse_args()
    if options.output_file is not None and (
        options.table is None or len(options.table) != 1
    ):
        parser.error("--output-file requires exactly one --table")
    return options


def main() -> None:
    options = parse_args()
    table_ids = options.table or list(RENDERERS)

    # Validate and construct every requested fragment before replacing any
    # output, so a malformed input cannot leave a partially refreshed group.
    rendered = {table_id: RENDERERS[table_id][1]() for table_id in table_ids}
    for table_id in table_ids:
        default_name = RENDERERS[table_id][0]
        output_path = options.output_file or (TABLE_DIR / default_name)
        write_atomic(output_path, rendered[table_id])
        print(f"Rendered {table_id}: {output_path}")


if __name__ == "__main__":
    main()
