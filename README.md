# Replication package

This package reproduces the numbered tables and figures in *Structured Payment
in Pawnshop Borrowing: Mandates vs. Choice*. Run every command below from the
top-level replication folder (the folder containing this README).

The public source-code repository for this replication package is available on
[GitHub](https://github.com/isaacmeza/structured_payment).

## Verification of results

All results reported in the paper and its appendices were verified by the
RESTUD replicator using the restricted data. The public replication package
does not include the underlying data because the authors do not have permission
to redistribute them.

## Data availability statement

The data underlying this paper are proprietary administrative and survey
records from a Mexican pawn lending company (Anonymous Mexican Pawn Lender,
2012--2013). We obtained access through a personal contact with the company's
CEO, who became our research partner. At the partner's request, we cannot
disclose the name of the company or of the CEO, and we are bound by a
confidentiality agreement and by Mexican lending secrecy law not to redistribute
the data.

The exact data are not publicly available and cannot be obtained from the
authors. There is no public application procedure, fee schedule, or expected
access time for these records. Researchers seeking comparable--but not
identical--data should contact pawn lenders directly to request a collaboration;
in our experience, this is the most viable route.

Any archive containing the files under `Raw/` is confidential and may be shared
only through arrangements authorized by the data provider. Those files must be
omitted from any publicly accessible version of the package. Without authorized
access to them, the code cannot execute the empirical replication.

The authors will preserve the original restricted data securely for at least
five years following publication.

| Source or material | Package-relative path(s), when access is authorized | Access |
|---|---|---|
| Administrative loan, contract, payment, and default records | `Raw/20131014Consilidacion_Agosto_2013.dta`, `Raw/db_product.dta`, `Raw/base_expansion.dta` | No public access; the authors cannot redistribute the files |
| Experimental randomization calendar | `Raw/Muestra Aleatoria en Excel con nombres de sucursales.xlsx` | Same restriction as the administrative records |
| Baseline survey responses | `Raw/Base_Encuestas_Basales_24_05_2013.dta` | Same restriction as the administrative records |
| Provider data dictionary | `Raw/Diccionario_base_Seira.xlsx` | Restricted supporting documentation |

The [Data dictionary](#data-dictionary) describes every restricted input and the
four processed datasets constructed from them. The anonymized data reference appears under
“References” below.

### Statement about rights

We certify that the authors of the manuscript have legitimate access to and
permission to use the data used in the manuscript.

The authors do not have permission to redistribute or publish the proprietary
files under `Raw/`; those files are therefore excluded from the public archive.
We certify that the authors have documented permission to redistribute or
publish all files included in the public replication archive.

### Registration

The experiment was implemented in 2012 and was registered retrospectively on
August 27, 2020 in the AEA RCT Registry as
[AEARCTR-0006284](https://doi.org/10.1257/rct.6284-1.0).

## Software requirements

- **Stata 17 or newer.** The code was tested with StataNow MP 19.5, but it does
  not require the MP edition. Every do-file declares `version 17.0`.
- **R 4.5.3.** The exact package versions are recorded in `renv.lock`.
- **Python 3.9 or newer.** Python formats Stata's table CSVs as LaTeX. The
  renderer uses only the Python standard library and installs no packages.

Excel is not required for the numerical replication. It is needed only to edit
or manually re-export the few static/layout workbooks described under
“Static assets” below.

## Replication files and workspace layout

The public replication package contains source code, environment definitions,
and the static exhibit assets that cannot be generated fully in code. The
restricted inputs are available only through the provider-authorized
arrangements described above. The production Figure 4 bootstrap is also not
included in the package; the authors supply it separately and privately to the
RESTUD replicator. The complete workspace has the following layout:

```text
Raw/                       restricted data/documentation; authorized access only
DoFiles/                   Stata cleaning and analysis programs
RScripts/                  R forest and bootstrap programs
PythonScripts/             standard-library table renderer
environment/               bundled Stata add-ons and R setup utilities
renv/                      R environment bootstrap files (not its library)
cluster/                   optional Main Figure 4 cluster job
_aux/                      run-created files; production artifact is private only
Figures/                   required static assets and generated figures
Tables/                    required static assets and generated table fragments
.Rprofile, renv.lock       automatic R activation and locked dependencies
SOURCE_CHECKSUMS.sha256    hashes of the six restricted Raw files
LICENSE                    MIT license for author-created code/documentation
```

Do not distribute `renv/library/`; it is machine-specific and is rebuilt from
`renv.lock`. The run creates `DB/`, `_aux/`, `Results/`, generated figures,
generated table CSVs, and generated table fragments. These derived files are
not required in a fresh local-mode archive.

The hidden root file `.Rprofile` is required and must remain in the archive.
When moving or recompressing the package, make sure hidden files are retained.

Once available under a provider-authorized arrangement, the six restricted
inputs can be checked before running. On macOS use:

```sh
shasum -a 256 -c SOURCE_CHECKSUMS.sha256
```

On Linux use:

```sh
sha256sum -c SOURCE_CHECKSUMS.sha256
```

See [Data dictionary](#data-dictionary) for short descriptions of every supplied file,
observation levels and keys for the four generated `DB/` datasets, categorical
codes, and definitions for all processed variables.

### Generated data and exhibit dependencies

Both paths rebuild the same four `DB/` datasets in the [dictionary](#data-dictionary)
and write to the interchange/results paths below. The Figure 4 and SA Table 1
summaries use the selected bootstrap RDS.

| Dataset(s) | Created by | Used for final exhibits |
|---|---|---|
| `_aux/main_figure_03_cate.csv`, `_aux/main_figure_03_instr.csv` | Cleaning: `prepare_data_te.do`, `prepare_data_inst_forest.do` | Inputs for Main Figure 3 forests; the CATE input also feeds SA Figure/Table 1 |
| `_aux/main_figure_04_bootstrap_input.csv` | Cleaning: `prepare_data_inst_forest_btsp.do` | Input for either local or production Figure 4 bootstrap |
| `Results/forest/main_figure_03_cate.csv`, `Results/forest/main_figure_03_instr.csv` | `te_grf.R`, `tot_tut_instr_forest.R` | `cate_dist.do` plots Main Figure 3 |
| `_aux/main_figure_04_bootstrap_summary.csv` | `summarize_btsp_tot_tut_instr.R`, from the selected bootstrap RDS | `plot_btsp_choose_wrong_tot_tut.do` plots Main Figure 4 |
| `_aux/cw_cr_tot_tut.csv` | Same bootstrap summary step | Observed-choice error rates in SA Table 1 |
| `_aux/sa_wide_narrow_grf.csv` | `sa_wide_narrow_grf.R` | `wide_narrow_forests.do` creates SA Figure/Table 1 |
| `Tables/reg_results/Table*.csv` | Table-producing Stata analyses | Python renders the final `Tables/Table*.tex` fragments |

Other `_aux/` files, including `time_line_aux.dta` and `pre_admin.dta`, are
intermediate cleaning files, not final exhibits.

### Figure inventory

<details>
<summary>All numbered figures and their sources</summary>

Graphic filenames below are relative to `Figures/`.

`Figures/` contains the 34 graphics included by the main manuscript and its
appendices. Filenames match the exhibit numbers in the paper; lowercase panel
letters follow the order in which panels appear in the corresponding TeX
figure environment.

| Exhibit | Graphic file(s) | Direct source(s) |
|---|---|---|
| Figure 1 | `Figure1.pdf` | `DoFiles/main/consort_dates.do` updates `Figures/Figure1.xlsx`; manual PDF export |
| Figure 2 | `Figure2.pdf` | Static `Figures/ToT-TUT graph.xlsx`; manual PDF export |
| Figure 3 | `Figure3a.pdf`, `Figure3b.pdf`, `Figure3c.pdf` | `DoFiles/cleaning/prepare_data_te.do`, `DoFiles/cleaning/prepare_data_inst_forest.do`; `RScripts/te_grf.R`, `RScripts/tot_tut_instr_forest.R`; `DoFiles/main/cate_dist.do` |
| Figure 4 | `Figure4a.pdf`, `Figure4b.pdf` | `DoFiles/cleaning/prepare_data_inst_forest_btsp.do`; `RScripts/btsp_tot_tut_instr.R`, `RScripts/summarize_btsp_tot_tut_instr.R`; `DoFiles/main/plot_btsp_choose_wrong_tot_tut.do` |
| Figure 5 | `Figure5.pdf` | `DoFiles/main/partition_tut.do` |
| Figure OA-1 | `FigureOA1.png` | Supplied static asset `Figures/FigureOA1.png` |
| Figure OA-2 | `FigureOA2.pdf` | `DoFiles/appendix/weekly_def_rates.do` |
| Figure OA-3 | `FigureOA3a.pdf`--`FigureOA3d.pdf` | `DoFiles/appendix/hist_den_default.do` |
| Figure OA-4 | `FigureOA4.pdf` | `DoFiles/appendix/determinants_choice.do` |
| Figure OA-5 | `FigureOA5a.pdf`, `FigureOA5b.pdf` | `DoFiles/appendix/survival_graph.do` |
| Figure OA-6 | `FigureOA6a.pdf`, `FigureOA6b.pdf` | `DoFiles/appendix/cumulative_porc_pay_time.do` |
| Figure OA-7 | `FigureOA7.pdf` | `DoFiles/appendix/profit_difference.do` |
| Figure OA-8 | `FigureOA8a.pdf`--`FigureOA8d.pdf` | `DoFiles/appendix/profit_difference_robust.do`, `DoFiles/appendix/copula_functions.do` |
| Figure OA-9 | `FigureOA9.pdf` | `DoFiles/appendix/fan_park_bnds.do` |
| Figure OA-10 | `FigureOA10.pdf` | `DoFiles/appendix/te_rankinvariance.do` |
| Figure OA-11 | `FigureOA11.pdf` | `DoFiles/appendix/discounted_noeffect.do` |
| Figure OA-12 | `FigureOA12.pdf` | `DoFiles/appendix/determinants_sure_confidence.do` |
| Figure OA-13 | `FigureOA13a.pdf`, `FigureOA13b.pdf` | `DoFiles/appendix/po_decomposition.do` |
| Figure OA-14 | `FigureOA14.pdf` | `DoFiles/appendix/partition_tut_promise.do` |
| Figure OA-15 | `FigureOA15a.pdf`, `FigureOA15b.pdf` | `DoFiles/appendix/SC_prepayment.do` |
| Figure SA-1 | `FigureSA1.pdf` | `DoFiles/cleaning/prepare_data_te.do`; `RScripts/sa_wide_narrow_grf.R`; `DoFiles/appendix/wide_narrow_forests.do` |

Most graphics are exported directly by the analysis files listed above. Three
graphics require a manual or static step:

- `Figure1.pdf`: `DoFiles/main/consort_dates.do` updates `Figures/Figure1.xlsx`;
  export the workbook's `consort` sheet to PDF manually.
- `Figure2.pdf`: update and export `ToT-TUT graph.xlsx` manually.
- `FigureOA1.png`: static manuscript input; no editable source or generating
  script is currently included.

The analysis scripts do not generate unreported diagnostic graphs.

`FigureOA2.pdf` combines the experimental sample with the supplied
confidentiality-reduced `Raw/base_expansion.dta` observational extract.

</details>

### Table inventory

<details>
<summary>Generated tables and their production workflow</summary>

Generated fragment filenames below are relative to `Tables/`.

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

#### Generated-table lineage

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

</details>

### Bundled environment records

<details>
<summary>Package records, checksums, and maintenance</summary>

#### R environment

The direct project dependencies are `dplyr`, `grf`, `readr`, and `tidyr`; the
lockfile includes their complete recursive dependency closure.

`environment/r/packages.tsv` and `environment/r/sessionInfo.txt` record the
validated package and system environment. The hashes of the lockfile and
activation files can be checked from the repository root with:

```sh
shasum -a 256 -c environment/r/checksums.sha256
```

Run `Rscript environment/r/install.R` only when deliberately rebuilding or
updating the environment. After changing R dependencies, run
`renv::snapshot()` and then rerun the environment check and smoke tests.

#### Stata environment

The installed payload has been tested and is already present under
`environment/stata/ado/plus`; a replicator therefore activates it without
downloading anything. `environment/stata/install.do` refreshes packages
installed from SSC and GitHub. The bundled compatibility copy of `catplot` and the exact
`rforest`/Weka payload must be restored from the replication package if they
are missing. Exact versions and primary-file hashes are recorded in
`environment/stata/packages.tsv`, and `environment/stata/checksums.sha256`
covers every bundled ado, help, scheme, and JAR file. From a terminal at the
repository root, verify it with:

```sh
shasum -a 256 -c environment/stata/checksums.sha256
```

Legacy `catplot` 2.0.2 is bundled because the repository uses syntax removed
from the current release. `rforest` 2.0.3 and its exact Weka/RandomForest JARs
are bundled for the supplementary targeting simulation. On recent Java
versions, Weka can print an `InaccessibleObjectException` warning while the
model and prediction still complete; the smoke test explicitly verifies both.
The three GitHub entries are pinned to exact commits. The environment isolates
Stata add-ons only; it does not install Stata itself or the R
interpreter/packages.

Run `environment/stata/install.do` only when deliberately refreshing packages;
normal replication uses the bundled environment.

</details>

### Data dictionary

<details>
<summary>Restricted inputs and the complete processed-data dictionary</summary>

This guide describes the files supplied under `Raw/` and the four datasets
created under `DB/` by `DoFiles/master_cleaning.do`. The generated `DB/` files
are not distributed in the clean replication archive; they are rebuilt from
the supplied inputs.

#### Supplied files

| File | Description and role |
|---|---|
| `20131014Consilidacion_Agosto_2013.dta` | Administrative pawn-loan ledger. Each row is a movement on a pawn ticket, such as origination, payment, renewal, recovery, or sale/default. This is the main source for the cleaned administrative outcomes and transaction panels. |
| `Base_Encuestas_Basales_24_05_2013.dta` | Baseline intake-survey responses collected around loan origination. Raw responses may contain more than one row for a pawn ticket; `cleaning_master.do` harmonizes them to one pawn-level record and links them to administrative outcomes. |
| `Muestra Aleatoria en Excel con nombres de sucursales.xlsx` | Branch-by-date randomization calendar. Each row is a date and the columns record the assigned experimental arm at each of the six branches. It is used to reconstruct the experiment timeline and take-up statistics. |
| `db_product.dta` | Pawn-level product crosswalk. It contains one row per experimental pawn ticket and supplies the randomized arm and realized contract/product. |
| `base_expansion.dta` | Confidentiality-reduced observational extract used only for OA Figure 2. Each row is an eligible observational loan and retains only its origination date (`fechaaltadelprestamo`) and a sale/default proxy (`def_vta`, equal to 1 when the restricted source recorded a sale date). No loan identifier is retained, so repeated date/outcome rows represent loan multiplicity. It was derived from a restricted transaction database whose raw-to-extract construction is outside the portable package. |
| `Diccionario_base_Seira.xlsx` | Spanish variable dictionary for the omitted restricted parent transaction database. It is provenance documentation, not the dictionary for the two-variable `base_expansion.dta`, and is not read by the code. |

#### Generated DB datasets

The row counts below are from the clean replication run. `prenda` is a pawn
ticket/loan identifier and `NombrePignorante` is the numeric borrower linkage
identifier retained in the source data.

| Code | Dataset | Unit of observation | Rows | Key and purpose |
|---|---|---:|---:|---|
| `M` | `Master.dta` | First-visit pawn ticket | 16,676 | `prenda` is unique. Main analysis file combining administrative outcomes, treatment assignment, and baseline-survey covariates. |
| `A` | `Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta` | Pawn ticket across all retained borrower visits | 26,180 | `prenda` is unique. Administrative pawn-level cross-section used to construct `Master.dta` and OA Table 1. |
| `P` | `Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2fv.dta` | Movement on a first-visit pawn ticket | 48,606 | Multiple rows per `prenda`; no unique row key is retained, and exact duplicate retained rows can represent separate source movements. Compact transaction panel used by OA Figures 6 and 15. |
| `F` | `Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2fv.dta` | First-visit pawn ticket | 16,676 | The pawn identifier is intentionally omitted, so no unique row key is retained and repeated branch/date/product rows represent different pawns. Minimal file used by Main Figure 1. |

The `Datasets` column below uses these four codes. Monetary amounts are Mexican
pesos. Dates are Stata daily dates. Variables described as ratios are stored as
fractions (for example, `0.25`, not 25). Unless stated otherwise, indicators are
`1=yes`, `0=no`, and missing when the underlying response or comparison sample
is unavailable.

#### Common categorical codes

| Variable | Codes |
|---|---|
| `suc` | `3` Calzada; `5` Congreso; `42` Insurgentes; `78` Jose Marti; `80` San Cosme; `104` San Simon. |
| `t_producto` | `1` Control; `2` Mandatory structured; `3` Promise Mandate; `4` Choice; `5` Promise Choice. |
| `producto` | `1` Control; `2` No Choice/Fee; `3` No Choice/Promise; `4` Choice/Fee-SQ; `5` Choice/Fee-NSQ; `6` Choice/Promise-SQ; `7` Choice/Promise-NSQ. |
| `clave_movimiento` | `1` Abono a Capital; `2` Venta con Billete; `3` Desempeno; `4` Empeno; `5` Refrendo; `6` Pase al Moneda. |
| `genero` | `0` Hombre; `1` Mujer. |
| Survey yes/no fields | `0` No; `1` Si. This label applies to `fam_pide`, `pres_antes`, `ahorros`, `cta_tanda`, `fam_comun`, and `rec_cel`. |
| `t_consis1` | `0` chooses 100 tomorrow; `1` chooses 150 in one month. |
| `t_consis2` | `0` chooses 100 in three months; `1` chooses 150 in four months. |

#### Processed variable dictionary

##### Identifiers, assignment, and timing

| Variable | Datasets | Definition |
|---|---|---|
| `prenda` | `M A P` | Pawn ticket/loan identifier; unique only in `M` and `A`. |
| `NombrePignorante` | `M A` | Numeric borrower/pledgor linkage identifier used to connect multiple pawn tickets. |
| `suc` | `M A F` | Branch code; see the common codes above. |
| `suc_x_dia` | `M A P` | Sequential cluster identifier for the branch-by-origination-date combination. |
| `fecha_inicial` | `M A F` | Loan origination/admission date. |
| `fecha_movimiento` | `A P` | Administrative movement date; in `A`, the date of the selected last movement. |
| `HoraMovimiento` | `A P` | Administrative movement time stored as an eight-character string; in `A`, the time of the selected last movement. |
| `clave_movimiento` | `A P F` | Administrative movement type; see the common codes above. In `A` and `F`, this is the selected last movement. |
| `dias_inicio` | `P` | Elapsed days from loan origination to the movement date. |
| `dow` | `A` | Stata day of week for loan origination (`0` Sunday through `6` Saturday). |
| `producto` | `M A F` | Realized contract/product; see the common codes above. |
| `t_producto` | `M A P` | Randomized treatment arm; see the common codes above. |
| `pro_2` | `M A` | Mandatory-structured comparison: 1 for treatment arm 2, 0 for control, missing for all other arms. |
| `pro_6` | `M A` | Choice/Fee-SQ comparison: 1 for product 4, 0 for control product 1, missing for other products. |
| `pro_7` | `M A` | Choice/Fee-NSQ comparison: 1 for product 5, 0 for control product 1, missing for other products. |
| `choose_commitment` | `M A` | Choice-arm take-up indicator: 1 for structured variants 5 or 7 and 0 for status-quo variants 4 or 6; missing outside the choice arms. |
| `visit_number` | `A` | Borrower's chronological pawnshop-visit number, capped at the sample 99th percentile (7). |
| `first_pawn` | `M A` | Indicator for the borrower's first observed distinct pawnshop visit/date. |
| `concluyo_c` | `M A` | Indicator that the loan is classified as ended during the observation window through recovery, default, sale, or a final unpaid condition. |

##### Payments, outcomes, and financial costs

| Variable | Datasets | Definition |
|---|---|---|
| `prestamo_i` | `M A` | Original loan principal in pesos; the cleaning excludes the five loans above 57,000 pesos. |
| `porc_pagos` | `P` | Movement-level customer payment, including any applicable paid fee, divided by loan principal. |
| `first_pay` | `M A` | Total positive payment amount on the pawn's first payment date; 0 if no payment is observed. |
| `sum_p_c` | `M A` | Final cumulative customer payments, including applicable paid fees. |
| `sum_int_c` | `M A` | Final cumulative paid interest. |
| `sum_pay_fee_c` | `M A` | Final cumulative paid structured-payment fees. |
| `sum_inc_int` | `M A` | Cumulative interest incurred under the contractual formula, including accrual through the observation end for unresolved loans. |
| `pays_c` | `M A` | Indicator that cumulative payments are positive. |
| `mn_p105_c` | `M A` | Mean nonzero payment through elapsed day 110, excluding origination and `Pase al Moneda` records; 0 if none. |
| `mn_p210_c` | `M A` | Mean nonzero payment during elapsed days 111--220, excluding origination and `Pase al Moneda` records; 0 if none. |
| `sum_porcp_c` | `M A` | Final cumulative payments divided by principal. |
| `sum_porcp30_c` | `M A` | Cumulative payments divided by principal through day 35 (the named 30-day horizon plus grace period). |
| `sum_porcp60_c` | `M A` | Cumulative payments divided by principal through day 65. |
| `sum_porcp90_c` | `M A` | Cumulative payments divided by principal through day 95. |
| `sum_porcp105_c` | `M A` | Cumulative payments divided by principal through day 110. |
| `sum_porcp150_c` | `M A` | Cumulative payments divided by principal through day 155. |
| `sum_porcp180_c` | `M A` | Cumulative payments divided by principal through day 185. |
| `sum_porcp210_c` | `M A` | Cumulative payments divided by principal through day 220. |
| `sum_porc105_int_c` | `M A` | Maximum cumulative paid interest divided by principal through day 110. |
| `sum_porc210_int_c` | `M A` | Maximum cumulative paid interest divided by principal through day 220. |
| `num_p` | `M A` | Number of nonzero payment transaction rows. |
| `num_v` | `M A` | Number of distinct dates with a nonzero payment (customer payment visits). |
| `des_i_c` | `A` | Recovery indicator: 1 if any recovery movement is observed. |
| `def_i_c` | `A` | Default indicator: ended loan not recovered. Unresolved/censored loans also equal 0 and are distinguished using `concluyo_c`. |
| `ref_c` | `M A` | Indicator that any renewal (`Refrendo`) is observed. |
| `dias_primer_pago` | `M A` | Minimum elapsed day of a principal payment, recovery, or renewal; missing if none is observed. |
| `dias_ultimo_mov` | `M A` | Elapsed days from origination to the last retained movement. |
| `dias_al_desempenyo` | `M A` | Elapsed days to recovery for recovered pawns; same-day recovery is recorded as day 1. |
| `dias_al_default` | `M A` | Default timing based on the last movement, with selected cases assigned to contract-cycle endpoints 105, 210, or 315. |
| `zero_pay_default` | `M A` | Indicator for a classified default with no cumulative payment. |
| `first_dias_des` | `M A` | Recovery timing for the borrower's first observed visit, when recovered. |
| `days_second_pawns` | `M A` | Calendar days from the borrower's first to second observed pawn date; missing if no second date exists. |
| `reincidence` | `M A` | Indicator that the borrower has more than one distinct observed pawn date. |
| `reincidence_other` | `M A` | Repeat-pawn indicator whose second principal is outside plus/minus 2.5% of the first, used as a proxy for different collateral. |
| `fc_i_admin` | `A` | Administrative financial cost in pesos. For recovered/unresolved loans it is interest plus fees; for defaults it is payments plus `(0.3/0.7) * principal`. |
| `cr_i` | `A` | `fc_i_admin / prestamo_i`. |
| `cost_losing_pawn` | `M A` | For defaults, payments minus interest and fees plus `(0.3/0.7) * principal`; 0 otherwise. |
| `downpayment_capital` | `M A` | For defaults, payments minus interest and fees; 0 otherwise. |

##### Baseline survey and Master-only constructed variables

| Variable | Datasets | Definition |
|---|---|---|
| `f_encuesta` | `M` | Baseline survey date. |
| `pr_recup` | `M` | Elicited subjective probability, from 0 to 100, that the borrower will recover the pawn. |
| `genero` | `M` | Reported gender (`0` man, `1` woman). |
| `edad` | `M` | Borrower age in years. |
| `fam_pide` | `M` | Indicator that family asked the respondent for money during the month. |
| `t_consis1` | `M` | Near-term intertemporal choice; see the common codes above. |
| `pres_antes` | `M` | Indicator that the respondent had pawned before. |
| `ahorros` | `M` | Indicator that the respondent reports savings. |
| `cta_tanda` | `M` | Indicator that the respondent participates in a rotating savings group (`tanda`). |
| `fam_comun` | `M` | Indicator that family asking the respondent for money is common. |
| `c_trans` | `M` | Reported transport cost to the branch, treated as pesos in the analysis. Responses are recovered across all pawns belonging to the same borrower; values that remain missing are replaced with the overall mean across pawn observations with nonmissing transport cost. |
| `t_llegar` | `M` | Reported travel time to the branch; the source dataset does not encode a unit. |
| `t_consis2` | `M` | Later intertemporal choice; see the common codes above. |
| `rec_cel` | `M` | Yes/no baseline-survey response concerning a cellphone reminder; the exact question wording appears in `Tables/TableOA7.tex`. |
| `val_pren_orig` | `M` | Cleaned subjective pawn value in pesos after the loan-implied floor, 99th-percentile winsorization, and first regression-imputation step; capped at 2.14489 times principal. It can remain missing when predictors for that first imputation are unavailable. |
| `fc_survey` | `M` | Financial cost in pesos using the final internally cleaned subjective pawn value for defaults and administrative interest/fees otherwise. That final subjective-value variable is not retained separately in `Master.dta`. |
| `cr_survey` | `M` | `fc_survey / prestamo_i`. |
| `fc_tc` | `M` | Administrative financial cost plus transaction cost, where transaction cost is `(c_trans + 62.33) * num_v`. |
| `cr_tc` | `M` | `fc_tc / prestamo_i`. |
| `fc_int` | `M` | Financial cost excluding paid interest. |
| `cr_int` | `M` | `fc_int / prestamo_i`. |
| `fc_fa` | `M` | Fully adjusted financial cost: the final internally cleaned subjective pawn value and transaction cost are included for defaults, while paid interest is excluded. |
| `cr_fa` | `M` | `fc_fa / prestamo_i`. |
| `masqueprepa` | `M` | Indicator for completed high school or more (`educacion >= 3`). |
| `estresado_seguido` | `M` | Indicator for frequent stress according to the baseline response (`f_estres < 3`). |
| `hace_presupuesto` | `M` | Indicator that the household makes an expense budget (`plan_gasto == 2`). |
| `pb` | `M` | Present-bias indicator constructed from the two intertemporal choices: chooses 100 tomorrow over 150 in one month but chooses 150 in four months over 100 in three months. |
| `faltas` | `M` | Share of seven answered household-expense categories for which the respondent reports payment problems (`renta`, `comida`, `medicina`, `luz`, `gas`, `telefono`, and `agua`). |
| `tentado` | `M` | Temptation/self-control indicator (`tempt >= 2`). |
| `low_cost` | `M` | Indicator that transport cost is at or below the pooled sample median after overall-mean imputation. |
| `low_time` | `M` | Indicator that reported travel time is at or below the pooled sample median. |
| `dummy_dow2` | `M` | Origination-day indicator for Tuesday (`dow == 2`); Monday is the omitted observed category. |
| `dummy_dow3` | `M` | Origination-day indicator for Wednesday (`dow == 3`). |
| `dummy_dow4` | `M` | Origination-day indicator for Thursday (`dow == 4`). |
| `dummy_dow5` | `M` | Origination-day indicator for Friday (`dow == 5`). |
| `dummy_dow6` | `M` | Origination-day indicator for Saturday (`dow == 6`). |
| `dummy_suc2` | `M` | Branch indicator for Congreso; Calzada is the omitted branch. |
| `dummy_suc3` | `M` | Branch indicator for Insurgentes. |
| `dummy_suc4` | `M` | Branch indicator for Jose Marti. |
| `dummy_suc5` | `M` | Branch indicator for San Cosme. |
| `dummy_suc6` | `M` | Branch indicator for San Simon. |
| `confidence_100` | `M` | Indicator that `pr_recup == 100`, i.e. complete stated confidence in recovery. |
| `des_c` | `M` | Analysis alias of the administrative recovery indicator `des_i_c`. |
| `def_c` | `M` | Analysis alias of the administrative default indicator `def_i_c`. |
| `fc_admin` | `M` | Analysis alias of `fc_i_admin`, administrative financial cost in pesos using appraised value. |
| `cr` | `M` | Analysis alias of `cr_i`, administrative financial cost divided by principal. |
| `prestamo` | `M` | Analysis alias of `prestamo_i`, original loan principal in pesos. |

</details>

## First-time R setup

Install R 4.5.3 and ensure its `Rscript` executable is available. Then open a
terminal in the replication root and run:

```sh
Rscript environment/r/restore.R
Rscript environment/r/verify.R
```

The first command downloads the versions recorded in `renv.lock` into a
project-local library, so internet access is required for this one-time step.
The second command confirms the R version, library location, and exact package
versions. `.Rprofile` activates this library automatically for all R scripts,
including R processes launched by Stata.

An optional functional check fits small test forests:

```sh
Rscript environment/r/smoke_test.R
```

On Linux, installing locked packages from source may also require the usual C++
compiler and system development libraries. `renv::restore()` reports any
missing system requirement.

## First-time Stata setup

All required community-contributed Stata commands, help files, the graph
scheme, and the `rforest` Java payload are bundled under
`environment/stata/ado/`. Do not install or update these commands from SSC for
an ordinary replication.

Start Stata, change to the replication root, and activate the isolated local
ado environment:

```stata
cd "/path/to/structured_payment_replication"
do "DoFiles/set_environment.do"
do "environment/stata/verify.do"
```

The activation changes Stata's ado paths only for the current session. The
verification command is an environment diagnostic, not a comparison with
historical results.

This manual activation is an optional pre-run check. `run_all.do` invokes the
three master do-files, and each master calls `set_environment.do` to activate
the same project-local Stata environment automatically. Thus, after changing
Stata's working directory to the replication root, users may run
`do "DoFiles/run_all.do"` directly.

Stata's bundled `rscript` command normally finds R automatically at
`/usr/local/bin/Rscript` or `/usr/bin/Rscript` on macOS/Linux and under
`C:/Program Files/R/` on Windows. If R 4.5.3 is elsewhere, set its absolute path
before running the replication:

```stata
global RSCRIPT_PATH "/absolute/path/to/Rscript"
```

For example, the standard macOS framework location is often
`/Library/Frameworks/R.framework/Resources/bin/Rscript`; a Windows installation
may use `C:/Program Files/R/R-4.5.3/bin/Rscript.exe`.

After restoring R, these optional smoke tests exercise the bundled Stata
commands and the complete Stata-to-R/`renv` path:

```stata
do "environment/stata/smoke_test.do"
do "environment/r/stata_smoke_test.do"
```

Python must likewise be callable as `python3` on macOS/Linux or `python` on
Windows. No Python virtual environment is needed.

## Instructions for the replicator

> **Production Figure 4:** The manuscript result uses 5,000 bootstrap
> replications run on the cluster. The resulting RDS and its checksum are not
> included in the public replication package; they are supplied privately to
> the RESTUD replicator and placed under `_aux/`. The default local setting
> below recomputes 50 replications to exercise the complete code path; set the
> mode to `"cluster"` to consume the privately supplied artifact and reproduce
> the production result.

Both paths run the three stages below and rebuild the same cleaned datasets
and forest inputs described under [Generated data and exhibit dependencies](#generated-data-and-exhibit-dependencies).
The mode changes the source of the Figure 4 bootstrap draws:

| | Local path | Cluster path |
|---|---|---|
| Figure 4 bootstrap | Recomputed on this computer; 50 replications by default | Reads the supplied or regenerated 5,000-replication production artifact |
| Bootstrap dataset | Creates `_aux/choose_wrong_tot_tut_btsp.local.rds` | Reads `_aux/choose_wrong_tot_tut_btsp.rds` |
| Final results using these draws | Reduced-replication Figure 4 and the observed-choice row of SA Table 1 | Production Figure 4 and the observed-choice row of SA Table 1 |
| Remaining work | Cleaning, all other estimates, summaries, and plots run locally | The same work runs locally; Stata does not submit a cluster job |

Both modes create `_aux/main_figure_04_bootstrap_summary.csv` for
`Figures/Figure4a.pdf` and `Figures/Figure4b.pdf`, and `_aux/cw_cr_tot_tut.csv`
for the observed-choice row in `Tables/TableSA1.tex`. The reduced local run does
not reproduce the production values for these results. All other exhibits,
including Figure SA-1, use the same computations in both modes. The modes
write to the same final output paths, so reruns replace those outputs; the
local and production bootstrap RDS files remain separate.

### Local path

1. Extract the replication archive and make its top-level
   `structured_payment_replication/` folder the working directory.
2. Complete the one-time R restoration and Stata verification described in the
   two setup sections above.
3. Review the `User settings` block in `DoFiles/run_all.do`.

`DoFiles/run_all.do` is the only file a replicator normally edits. Its short
`User settings` block currently defines the portable local route:

```stata
local figure4_bootstrap_mode "local"
local local_bootstrap_replications 50
local local_bootstrap_workers 12
local appendix_replications 500
```

The local replication count controls the Main Figure 4 Bayesian bootstrap; the
worker setting controls the number of parallel R processes. The appendix count
is shared by OA Figure 15 and SA-1. Reduce the worker count on a computer with
fewer cores or limited memory; changing workers does not change the numbered
random seeds. The 50-replication Figure 4 setting is a reduced local route;
the appendix setting uses the package's 500-replication production count.

4. From Stata, with the replication root as the working directory, run the
   argument-free driver:

```stata
do "DoFiles/run_all.do"
```

It performs three stages in order:

1. `master_cleaning.do` rebuilds the shared Stata datasets and all R inputs.
2. `master.do` produces the main-manuscript tables and figures.
3. `master_appendix.do` produces the online- and supplementary-appendix
   exhibits.

The local Figure 4 bootstrap prints progress at startup and after saved
checkpoints. Runtime is hardware-dependent. One worker is one independent R
process, and each forest fit within a worker is single-threaded.

### Cluster path: production replication

The public replication package does not include the 5,000-replication
production RDS or its checksum. For authorized verification, the authors
supply both files privately to the replicator at the paths below. Once those
files are in place, setting `figure4_bootstrap_mode` to `"cluster"` consumes
the artifact locally; it does not submit a cluster job or require access to a
cluster. Local mode ignores it and rebuilds the reduced bootstrap using the
replication and worker counts in `run_all.do`.

To regenerate the production artifact, complete steps 1 and 2 below. If the
authors have supplied the production RDS and checksum, continue at step 3.
Complete the R and Stata setup above before either route.

#### 1. Prepare the input locally

From the replication-package root, run:

```stata
do "DoFiles/master_cleaning.do"
```

This creates `_aux/main_figure_04_bootstrap_input.csv`. Copy the repository
code (including `.Rprofile`) and that ignored CSV to persistent shared cluster
storage. The raw and cleaned datasets are not needed by the cluster job. Ensure `_aux/` exists
before submission because Slurm opens its log there when the job starts.

Restore the locked R environment once before the first submission, using the
same module that the Slurm job loads automatically:

```sh
module purge
module load R/4.5.3-fasrc01
Rscript environment/r/restore.R
Rscript environment/r/verify.R
```

The submitted job loads `R/4.5.3-fasrc01` itself, so no manual module command is
needed before later `sbatch` calls. `RSCRIPT_BIN` remains available as an
absolute-path override. The job stops if the locked environment is not exact.

#### 2. Submit one multi-core job

From the cluster copy's repository root:

```sh
sbatch cluster/main_figure_04_bootstrap.slurm
```

The production job computes 5,000 replications. This count is fixed because
`master.do cluster` validates the resulting artifact against that public
specification. The job writes the production RDS and its SHA-256 sidecar;
summary CSVs and final figures are created locally in step 3.

The template is configured for Harvard FASRC's `sapphire` partition: one node,
one task, 110 CPUs, 900,000 MB of memory, and an eight-hour wall-time. FASRC's
Sapphire Rapids nodes have two 56-core Intel Xeon CPUs, 112 cores total, and
990 GB of RAM.

The R script uses `$SLURM_CPUS_PER_TASK` workers, with one GRF thread per
worker. Post-run `jobstats` output was not supplied for this run; use
`jobstats JOBID` to check resource use before reducing the memory request or
wall-time.

Use one job only: simultaneous jobs would race on the same checkpoint. A job
array is not appropriate for the current coordinated checkpoint design.

Keep `_aux` on persistent shared storage. If the job stops, submit the same file
again; it resumes from its replication-specific checkpoint when the input,
generator, lockfile, R, and GRF metadata all match.
The Slurm log records a coordinator-only ASCII progress bar at startup and
after every successfully saved checkpoint, with elapsed and estimated
remaining time. It also records the job ID, node name, CPU model and topology,
node memory, R version, start/end timestamps, and total script wall time. Use
those fields together with `jobstats` to document any future production run.

#### 3. Return the result and finish in Stata

Copy the completed files back to these exact locations:

```text
_aux/choose_wrong_tot_tut_btsp.rds
_aux/choose_wrong_tot_tut_btsp.rds.sha256
```

Verify the transfer from the local repository root:

```sh
shasum -a 256 -c _aux/choose_wrong_tot_tut_btsp.rds.sha256
```

On Linux, use `sha256sum -c` instead of `shasum -a 256 -c`.

Then set the first user setting in `run_all.do` to:

```stata
local figure4_bootstrap_mode "cluster"
```

and run the same `do "DoFiles/run_all.do"` command. Cluster mode consumes and
checks the RDS; it does not submit a cluster job from Stata. The local
replication and worker settings are ignored in cluster mode.

The driver deterministically rebuilds the cleaning outputs, then the main
master validates the returned RDS against the regenerated input and current
environment. It requires the 5,000-replication production count, creates the
inexpensive summary, plots Main Figure 4, and then runs the appendix. Keep
`appendix_replications` at the package's production setting of `500` unless a
different shared count is intentionally desired for OA Figure 15 and SA-1.

The SHA-256 transfer check is separate from the RDS metadata validation.

<details>
<summary>Adapting the template to another cluster</summary>

The statistical workflow is not specific to Harvard, but the supplied Slurm
template contains Harvard- and user-specific resource names. On another Slurm
cluster, review these lines before submitting:

| Supplied setting | What to change |
|---|---|
| `--partition=sapphire` | Use a partition that permits one-node, multi-core CPU jobs. |
| `--cpus-per-task=110` | Use no more CPUs than are available on one node; this value becomes the R worker count. |
| `--mem=900000` and `--time=0-08:00` | Replace with limits supported by the selected partition, then refine them from the site's job-accounting tools. |
| No email directives | Add the site's `--mail-user` and `--mail-type` directives if notifications are desired. |
| `module load R/4.5.3-fasrc01` | Replace with the site's exact R 4.5.3 module name. |
| No account/QOS directive | Add `--account`, `--qos`, reservation, or other site-required directives when applicable. |

Keep `--nodes=1` and `--ntasks=1`: the current PSOCK implementation launches
local worker processes on one node and does not distribute work across nodes.
The job reads the allocated worker count from `SLURM_CPUS_PER_TASK`.

The target system must provide an R 4.5.3 interpreter, but the R package
library still comes from this project. Load the target interpreter and run
`Rscript environment/r/restore.R` once on that cluster; do not copy a
`renv/library` built on another operating system. If the site does not use
environment modules, remove the three `module` lines from the Slurm file and
set `RSCRIPT_BIN` to the absolute path of an R 4.5.3 `Rscript` executable.

FASRC's `jobstats` helper may not exist elsewhere; use the site's equivalent,
such as Slurm `sacct` or `seff`, to measure elapsed time, CPU use, and memory.

The script creates its transfer-integrity sidecar with GNU `sha256sum`. On a
system that provides only `shasum`, replace that final command with
`shasum -a 256`.

If the scheduler is PBS, LSF, or another system rather than Slurm, translate
the resource directives,
submission command, job-ID/log variables, and allocated-CPU variable; the
underlying R command can still be run with an explicit `--workers=N` value.

</details>

### Randomness and seeds

Project activation selects Stata's `mt64` random-number generator and sets
`sortseed 20260819` so tied sorts are reproducible. The analyses do not rely on
one session-wide random seed: every stochastic analysis sets an explicit seed
in the file that performs the draw, partition, cross-validation, or forest fit.
This makes results independent of commands run earlier in the Stata session.
The R seeds are defined in `RScripts/te_grf.R`,
`RScripts/tot_tut_instr_forest.R`, `RScripts/btsp_tot_tut_instr.R`, and
`RScripts/sa_wide_narrow_grf.R`. The Stata seeds are defined in
`DoFiles/appendix/censoring_imp.do`,
`DoFiles/appendix/fan_park_bnds.do`,
`DoFiles/appendix/po_decomposition.do`,
`DoFiles/appendix/SC_prepayment.do`, and
`DoFiles/appendix/wide_narrow_forests.do`.
Main Figure 4 assigns a separate deterministic seed to every replication and
estimand, so changing the number of parallel workers does not change a given
replication. No replicator-supplied seed is required.

Exact byte identity between Linux and macOS is not guaranteed
because compiled numerical libraries can differ; compare substantive results
numerically if the cluster and local computer use different platforms.

On Windows, run the driver interactively inside Stata. The bundled `rscript`
bridge cannot launch R from Stata's Windows batch mode. Interactive Stata and
terminal batch Stata are both supported on macOS/Linux.

## Reference runtimes

The local benchmark below was measured on 21 August 2026 on a MacBook Pro
(`Mac17,9`) with an Apple M5 Pro (18 CPU cores: 12 Performance and 6 Super),
64 GB of memory, and macOS 26.5.2 (`25F84`). Software was StataNow/MP 19.5
(configured to use four processors, with the do-files running under
`version 17.0`), R 4.5.3
for Apple silicon, and Python 3.14.4. The run used 50 Main Figure 4 bootstrap
replications with 12 R workers and 500 replications for both OA Figure 15 and
SA-1. One-time environment restoration is not included.

| Local stage | Wall time |
|---|---:|
| Cleaning | 00:00:01.03 |
| Main results | 00:24:21.38 |
| Appendix results | 00:14:22.58 |
| Complete local pipeline (sum of the three stages) | 00:38:44.99 |

These are elapsed wall-clock measurements, not guarantees. They depend on
hardware, thermal state, background load, filesystem performance, and software
startup costs. A disposable driver enabled Stata's return-message timer and
called the same three masters in one session; no analysis do-file or R script
was instrumented. It passed `local 50 12` and appendix `500` explicitly and was
removed after the measurements were checked. The complete-pipeline value is
the sum of the three nonoverlapping master-command times and is equivalent to
`run_all.do` for those settings; `run_all.do` itself was not separately timed.

The detailed values below are inclusive: a do-file's time contains nested
do-files, R scripts, and Python renderer calls, so overlapping parent and child
rows must not be added together. R and Python rows include bridge/process
startup, and repeated shared helpers are aggregated in one row.
`RScripts/project_setup.R` was sourced by each of the five R entry points; its
setup cost was not separable and is included in those parent R rows.
`btsp_tot_tut_instr.R` is one coordinator invocation whose time includes its 12
PSOCK workers. `copula_functions.do` records only the loading of program
definitions; their later execution is included in `profit_difference_robust.do`.
A displayed time of `00:00:00.00` means that the invocation was below Stata's
two-decimal timing resolution.

<details>
<summary>Per-file local timing details</summary>

| File | Calls | Settings/arguments | Total inclusive wall time |
|---|---:|---|---:|
| `DoFiles/run_all.do` | — | Equivalent orchestration: local Figure 4 50/12; appendix 500 | Not separately timed; stage sum 00:38:44.99 |
| `DoFiles/master_cleaning.do` | 1 | — | 00:00:01.03 |
| `DoFiles/set_environment.do` | 3 | — | 00:00:00.00 |
| `environment/stata/activate.do` | 3 | — | 00:00:00.00 |
| `DoFiles/cleaning/cleaning_admin.do` | 1 | — | 00:00:00.75 |
| `DoFiles/cleaning/cleaning_master.do` | 1 | — | 00:00:00.16 |
| `DoFiles/cleaning/prepare_data_te.do` | 1 | — | 00:00:00.04 |
| `DoFiles/cleaning/prepare_data_inst_forest.do` | 1 | — | 00:00:00.04 |
| `DoFiles/cleaning/prepare_data_inst_forest_btsp.do` | 1 | — | 00:00:00.04 |
| `DoFiles/master.do` | 1 | `local 50 12` | 00:24:21.38 |
| `DoFiles/main/decomposition_main_te.do` | 1 | — | 00:00:00.09 |
| `DoFiles/render_table.do` | 12 | Tables 1–3, OA-1–6, OA-8–9, and SA-1 | 00:00:00.62 |
| `PythonScripts/render_tables.py` | 12 | Tables 1–3, OA-1–6, OA-8–9, and SA-1 | 00:00:00.60 |
| `DoFiles/main/mechanisms.do` | 1 | — | 00:00:00.10 |
| `DoFiles/main/tot_tut.do` | 1 | — | 00:00:02.47 |
| `DoFiles/main/consort_dates.do` | 1 | — | 00:00:00.18 |
| `DoFiles/main/check_static_main.do` | 1 | — | 00:00:00.00 |
| `RScripts/te_grf.R` | 1 | — | 00:00:16.91 |
| `RScripts/tot_tut_instr_forest.R` | 1 | — | 00:00:37.85 |
| `DoFiles/main/cate_dist.do` | 1 | — | 00:00:00.60 |
| `RScripts/btsp_tot_tut_instr.R` | 1 | `--reps=50 --workers=12 --local-artifact` | 00:23:19.84 |
| `RScripts/summarize_btsp_tot_tut_instr.R` | 1 | `--expected-reps=50 --local-artifact` | 00:00:01.30 |
| `RScripts/project_setup.R` | 5 | Sourced inside each R entry point | Included in the five R timings |
| `DoFiles/main/plot_btsp_choose_wrong_tot_tut.do` | 1 | — | 00:00:00.20 |
| `DoFiles/main/partition_tut.do` | 1 | — | 00:00:01.83 |
| `DoFiles/master_appendix.do` | 1 | `500` | 00:14:22.58 |
| `DoFiles/appendix/check_static_appendix.do` | 1 | — | 00:00:00.00 |
| `DoFiles/appendix/weekly_def_rates.do` | 1 | — | 00:00:00.16 |
| `DoFiles/appendix/hist_den_default.do` | 1 | — | 00:00:00.30 |
| `DoFiles/appendix/determinants_choice.do` | 1 | — | 00:00:00.13 |
| `DoFiles/appendix/ss_att.do` | 1 | — | 00:00:00.49 |
| `DoFiles/appendix/ss_balance.do` | 1 | — | 00:00:00.13 |
| `DoFiles/appendix/censoring_imp.do` | 1 | — | 00:01:24.48 |
| `DoFiles/appendix/survival_graph.do` | 1 | — | 00:00:00.40 |
| `DoFiles/appendix/cumulative_porc_pay_time.do` | 1 | — | 00:00:01.55 |
| `DoFiles/appendix/fc_robustness.do` | 1 | — | 00:00:00.10 |
| `DoFiles/appendix/profit_difference.do` | 1 | — | 00:00:00.19 |
| `DoFiles/appendix/profit_difference_robust.do` | 1 | — | 00:00:02.68 |
| `DoFiles/appendix/copula_functions.do` | 1 | — | 00:00:00.00 |
| `DoFiles/appendix/decomposition_main_te_promise.do` | 1 | — | 00:00:00.10 |
| `DoFiles/appendix/repeat_loans.do` | 1 | — | 00:00:00.08 |
| `DoFiles/appendix/fan_park_bnds.do` | 1 | — | 00:00:04.19 |
| `DoFiles/appendix/te_rankinvariance.do` | 1 | — | 00:00:00.24 |
| `DoFiles/appendix/decomposition_main_te_subsample.do` | 1 | — | 00:00:00.15 |
| `DoFiles/appendix/learning_exp.do` | 1 | — | 00:00:00.07 |
| `DoFiles/appendix/discounted_noeffect.do` | 1 | — | 00:00:38.16 |
| `DoFiles/appendix/determinants_sure_confidence.do` | 1 | — | 00:00:00.13 |
| `DoFiles/appendix/po_decomposition.do` | 1 | — | 00:02:07.24 |
| `DoFiles/appendix/partition_tut_promise.do` | 1 | — | 00:00:01.46 |
| `DoFiles/appendix/SC_prepayment.do` | 1 | 500 replications | 00:03:03.30 |
| `RScripts/sa_wide_narrow_grf.R` | 1 | — | 00:03:35.72 |
| `DoFiles/appendix/wide_narrow_forests.do` | 1 | 500 replications | 00:03:21.06 |

</details>

The production Figure 4 bootstrap was measured on 2 September 2026:

| Workload | Hardware and settings | Wall time |
|---|---|---:|
| Main Figure 4 production bootstrap | Harvard FASRC `sapphire` partition; two 56-core Intel Xeon Sapphire Rapids CPUs (112 cores and 990 GB RAM per node); 110 CPUs and 900 GB allocated; R/4.5.3-fasrc01; 5,000 replications | 05:57:31 |

The scheduler time includes environment verification and output finalization;
the R bootstrap itself wrote 105,000 rows in 05:56:46.5. The completed-run
Slurm log records the successful final checksum; post-run `jobstats` output
was not supplied for this run.

## Outputs

The run writes:

- cleaned data to `DB/`;
- temporary Stata/R interchange files and bootstrap artifacts to `_aux/`;
- machine-readable estimates to `Results/` and `Tables/reg_results/`;
- final numbered graphics to `Figures/`; and
- final LaTeX table fragments to `Tables/`.

Each table-producing do-file sends its compact Stata CSV through
`PythonScripts/render_tables.py`, so no Excel relinking or Excel-to-LaTeX step
is required.

### Static assets

Three figure images are intentionally supplied rather than programmatically
rendered: `Figures/Figure1.pdf`, `Figures/Figure2.pdf`, and
`Figures/FigureOA1.png`. Main Figure 1's code updates `Figures/Figure1.xlsx`,
but exporting its formatted worksheet to PDF remains manual. Figure 2's
editable source is `Figures/ToT-TUT graph.xlsx`. OA Figure 1 is a static figure
asset. The static OA Table 7 transcription is supplied directly as
`Tables/TableOA7.tex`.

All other numbered figure files and all other numbered table fragments are
created by the analysis pipeline. [Figure inventory](#figure-inventory) and [Table inventory](#table-inventory)
are the complete exhibit inventories: they list every numbered figure and table,
its output file, and the analysis or static source that produces it.

## Running stages or analyses separately

The three stages can also be run interactively after setting the desired
arguments explicitly:

```stata
do "DoFiles/master_cleaning.do"
do "DoFiles/master.do" local 50 12
do "DoFiles/master_appendix.do" 500
```

For cluster mode, replace the second line with
`do "DoFiles/master.do" cluster` after placing the production RDS under
`_aux/`. In a fresh copy, cleaning must precede `master.do`, and `master.do`
must precede `master_appendix.do`.

After cleaning, an individual analysis do-file can also be run directly. For
example:

```stata
do "DoFiles/set_environment.do"
capture mkdir "./Tables"
capture mkdir "./Tables/reg_results"
do "DoFiles/main/decomposition_main_te.do"
```

## References

Anonymous Mexican Pawn Lender. 2012--2013. *Proprietary administrative,
experimental, and survey records for Structured Payment in Pawnshop Borrowing:
Mandates vs. Choice*. Restricted data; no DOI.

## License

Author-created code and documentation in this package are licensed under the
MIT License; see `LICENSE`. The license does not apply to the proprietary data
under `Raw/` or to third-party software bundled under `environment/`, which
remain subject to their respective restrictions and licenses.

**AI disclosure:** This README and the table-rendering helpers
`DoFiles/render_table.do` and `PythonScripts/render_tables.py` were created with
AI assistance. All other Stata do-files and R scripts were created by the
authors.
