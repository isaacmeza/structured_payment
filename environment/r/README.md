# Project-local R environment

This repository uses `renv` at the repository root. The standard root files
`.Rprofile`, `renv.lock`, and `renv/activate.R` ensure that both interactive R
and the R processes launched from Stata use the project-local package library.

The validated lockfile records R 4.5.3 and the exact package dependency closure. The
working library is installed locally under `renv/library/`.

The direct project dependencies are `dplyr`, `grf`, `readr`, and `tidyr`; the
lockfile includes their complete recursive dependency closure.
The deterministic Bayesian bootstrap uses base R's `parallel` and `stats`
packages, so it does not require MCMCpack or pbapply.

`packages.tsv` and `sessionInfo.txt` record the validated package and system
environment. The hashes of the lockfile and activation files can be checked
from the repository root with:

```sh
shasum -a 256 -c environment/r/checksums.sha256
```

On macOS, `.Rprofile` disables renv's optional sandbox before activation. This
avoids a verified startup hang in the current renv/R configuration; the project
library remains isolated as the first entry in `.libPaths()`.

## Restore on a new machine

Install R, open a terminal in the repository root, and run:

```sh
Rscript environment/r/restore.R
Rscript environment/r/verify.R
```

The renv bootstrap installs the required renv version automatically if needed.

## Start working

Open R or RStudio with the repository root as the working directory. The root
`.Rprofile` activates renv automatically. Confirm with:

```r
renv::project()
.libPaths()
```

From Stata, first activate the Stata environment as usual:

```stata
cd "/path/to/structured_payment_replication"
do "DoFiles/set_environment.do"
```

All Stata `rscript` calls inherit the repository working directory and activate
renv through `.Rprofile`; no separate R activation is needed.

To test the full Stata-to-R activation path:

```stata
do "environment/r/stata_smoke_test.do"
```

## Maintenance

Run `Rscript environment/r/install.R` only when deliberately rebuilding or
updating the environment. After changing R dependencies, run
`renv::snapshot()` and then rerun the environment check and smoke tests.

This lockfile records a newly validated environment, not the unknown historical
package versions: no previous lockfile or R `sessionInfo()` was supplied.

Do not distribute the machine-specific `renv/library/` directory in the final
replication archive. It is ignored by `renv/.gitignore` and is reconstructed
from `renv.lock` with `restore.R`.
