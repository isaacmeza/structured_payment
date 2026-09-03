# Regenerating the Main Figure 4 production bootstrap

Only the production Bayesian bootstrap for Main Figure 4 needs the cluster.
Cleaning, the inexpensive R summary, plotting, and the remaining exhibits
continue to run under the ordinary Stata masters. The portable replication
archive does not include the 5,000-replication production artifact. The
completed artifact and checksum are supplied separately and privately to the
RESTUD replicator. This workflow is optional: use it to regenerate the
artifact before selecting `"cluster"` in the Stata workflow. The reduced local
route requires no precomputed artifact and is documented in the root
`README.md`.

## 1. Prepare the input locally

From the replication-package root, run:

```stata
do "DoFiles/master_cleaning.do"
```

This creates `_aux/main_figure_04_bootstrap_input.csv`. Copy the repository
code and that ignored CSV to persistent shared cluster storage. The raw and
cleaned datasets are not needed by the cluster job.

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


## 2. Submit one multi-core job

From the cluster copy's repository root:

```sh
sbatch cluster/main_figure_04_bootstrap.slurm
```

The production job computes 5,000 replications. This count is fixed because
`master.do cluster` validates the resulting artifact against that public
specification.

The template is configured for Harvard FASRC's `sapphire` partition: one node,
one task, 110 CPUs, 900,000 MB of memory, and an eight-hour wall-time. FASRC's
Sapphire Rapids nodes have two 56-core Intel Xeon CPUs, 112 cores total, and
990 GB of RAM.

The production run completed on 2 September 2026. Its end-to-end scheduler
time was 05:57:31. The R computation itself wrote the expected 105,000 rows in
05:56:46.5. The completed-run log records successful completion and the final
artifact checksum; the root README records the completed benchmark.

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

## Adapting the template to another cluster

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

Keep the project and `_aux` directory on writable persistent storage so that
the checkpoint survives the end of an allocation. Ensure `_aux` exists before
submission because Slurm opens the configured log path when the job starts.
FASRC's `jobstats` helper may not exist elsewhere; use the site's equivalent,
such as Slurm `sacct` or `seff`, to measure elapsed time, CPU use, and memory.

The script creates its transfer-integrity sidecar with GNU `sha256sum`. On a
system that provides only `shasum`, replace that final command with
`shasum -a 256`.

If the scheduler is PBS, LSF, or another system rather than Slurm, translate
the resource directives,
submission command, job-ID/log variables, and allocated-CPU variable; the
underlying R command can still be run with an explicit `--workers=N` value.

## 3. Return the result and finish in Stata

After a successful job, copy these files back to the same paths locally:

- `_aux/choose_wrong_tot_tut_btsp.rds`
- `_aux/choose_wrong_tot_tut_btsp.rds.sha256`

Verify the transfer from the local repository root:

```sh
shasum -a 256 -c _aux/choose_wrong_tot_tut_btsp.rds.sha256
```

Set `figure4_bootstrap_mode` to `"cluster"` in `DoFiles/run_all.do`, then run:

```stata
do "DoFiles/run_all.do"
```

The driver deterministically rebuilds the cleaning outputs, then the main
master validates the returned RDS against the regenerated input and current
environment. It requires the 5,000-replication production count, creates the
inexpensive summary, plots Main Figure 4, and then runs the appendix. Keep
`appendix_replications` at the package's production setting of `500` unless a
different shared count is intentionally desired for OA Figure 15 and SA-1.

The fixed seeds make results independent of worker count within the pinned
environment. Exact byte identity between Linux and macOS is not guaranteed
because compiled numerical libraries can differ; compare substantive results
numerically if the cluster and local computer use different platforms.
