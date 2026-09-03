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

`DATA_DICTIONARY.md` describes every restricted input and the four processed
datasets constructed from them. The anonymized data reference appears under
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
DATA_DICTIONARY.md         Raw-file guide and processed DB dictionaries
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

See `DATA_DICTIONARY.md` for short descriptions of every supplied file,
observation levels and keys for the four generated `DB/` datasets, categorical
codes, and definitions for all processed variables.

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

## Optional production bootstrap on a cluster

The public replication package does not include the 5,000-replication
production RDS or its checksum. For authorized verification, the authors
supply both files privately to the replicator at the paths below. Once those
files are in place, setting `figure4_bootstrap_mode` to `"cluster"` consumes
the artifact locally; it does not submit a cluster job or require access to a
cluster. Local mode ignores it and rebuilds the reduced bootstrap using the
replication and worker counts in `run_all.do`.

To regenerate the production artifact, first run cleaning, then follow
`cluster/README.md` and submit `cluster/main_figure_04_bootstrap.slurm` from the
cluster copy of the repository. Copy the completed files back to these exact
locations:

```text
_aux/choose_wrong_tot_tut_btsp.rds
_aux/choose_wrong_tot_tut_btsp.rds.sha256
```

Then set the first user setting in `run_all.do` to:

```stata
local figure4_bootstrap_mode "cluster"
```

and run the same `do "DoFiles/run_all.do"` command. Cluster mode consumes and
checks the RDS; it does not submit a cluster job from Stata. The local
replication and worker settings are ignored in cluster mode.

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
created by the analysis pipeline. `Figures/README.md` and `Tables/README.md`
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
