# Table production workflow

The twelve generated manuscript tables use one deterministic, workbook-free
pipeline:

```text
Stata estimation -> Tables/reg_results/Table*.csv
                 -> PythonScripts/render_tables.py
                 -> Tables/*.tex
```

For regression tables, Stata's `esttab` strings already contain the displayed
rounding, trailing zeros, parentheses, and significance stars; Python preserves
them verbatim. OA Tables 1--2 and SA Table 1 instead export compact,
full-precision numeric CSVs because their statistics are assembled from
several commands. Python applies their explicit manuscript display precision.
In both cases, Stata owns the statistics and Python owns only validation and
layout: headers, panels, labels, spacing, rules, and deliberately suppressed
cells.

Each table-producing do-file calls `DoFiles/render_table.do` immediately after
writing its CSV. The helper renders to a temporary file, checks that it exists,
and only then replaces the numbered table fragment. Consequently, running an
individual analysis do-file produces the same final TEX output as running a
master.

## Generated-table lineage

| Generated fragment | Python table ID | Direct Stata source |
| --- | --- | --- |
| `Table1.tex` | `Table1` | `Tables/reg_results/Table1.csv` from `DoFiles/main/decomposition_main_te.do` |
| `Table2.tex` | `Table2` | `Tables/reg_results/Table2.csv` from `DoFiles/main/mechanisms.do` |
| `Table3.tex` | `Table3` | `Tables/reg_results/Table3.csv` from `DoFiles/main/tot_tut.do` |
| `TableOA1.tex` | `TableOA1` | `Tables/reg_results/TableOA1.csv` from `DoFiles/appendix/ss_att.do` |
| `TableOA2.tex` | `TableOA2` | `Tables/reg_results/TableOA2.csv` from `DoFiles/appendix/ss_balance.do` |
| `TableOA3.tex` | `TableOA3` | `Tables/reg_results/TableOA3a.csv`--`TableOA3e.csv` from `DoFiles/appendix/censoring_imp.do` |
| `TableOA4.tex` | `TableOA4` | `Tables/reg_results/TableOA4.csv` from `DoFiles/appendix/fc_robustness.do` |
| `TableOA5.tex` | `TableOA5` | `Tables/reg_results/TableOA5.csv` from `DoFiles/appendix/decomposition_main_te_promise.do` |
| `TableOA6.tex` | `TableOA6` | `Tables/reg_results/TableOA6.csv` from `DoFiles/appendix/repeat_loans.do` |
| `TableOA8.tex` | `TableOA8` | `Tables/reg_results/TableOA8.csv` from `DoFiles/appendix/decomposition_main_te_subsample.do` |
| `TableOA9.tex` | `TableOA9` | `Tables/reg_results/TableOA9.csv` from `DoFiles/appendix/learning_exp.do` |
| `TableSA1.tex` | `TableSA1` | `Tables/reg_results/TableSA1.csv` from `DoFiles/appendix/wide_narrow_forests.do` |

The renderer encodes the manuscript's one-sided Table 3 label directly as
`$H_0$: ASG$\leq 0$`; there is no Excel refresh or manual post-export edit.

OA Table 1 contains exactly 18 keyed data rows, OA Table 2 contains 19, and SA
Table 1 contains six. Their CSVs omit workbook addresses, overall statistics,
and any other values not printed in the manuscript.

## Static exception

`TableOA7.tex` is the supplied English transcription of the OA-7 questionnaire
and is retained as the static numbered table output.

The OA-2 renderer corrects the former workbook typo by showing the control-arm
standard error for “Pawn before” consistently as `(0.015)`.
