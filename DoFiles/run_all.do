version 17.0

* Full replication driver.
* This is the only do-file most users need to edit: choose how Main Figure 4's
* bootstrap is supplied below, then run this file from the repository root.

******************************* User settings *********************************

* The manuscript's Figure 4 uses a 5,000-replication artifact generated through
* the optional cluster workflow. It is not in the public replication package;
* the RESTUD replicator receives it privately under _aux/. Choose "cluster" to
* consume that artifact, or "local" to recompute a smaller bootstrap here.
local figure4_bootstrap_mode "local"

* These settings are used only when figure4_bootstrap_mode is "local".
* One worker is one independent R process; keep this within available CPU and
* memory capacity. The replication package's local defaults are 50 and 12.
local local_bootstrap_replications 50
local local_bootstrap_workers 12

* Shared appendix count. OA Figure 15 resamples randomized branch-days; SA-1
* draws CATEs and refits the targeting classifiers the same number of times.
local appendix_replications 500

******************************* Cluster input *********************************

if "`figure4_bootstrap_mode'" == "cluster" {
    * Cluster mode consumes this artifact; it does not submit a job.
    confirm file "./_aux/choose_wrong_tot_tut_btsp.rds"
}
display as text ///
    "Main Figure 4 bootstrap mode: `figure4_bootstrap_mode'."
if "`figure4_bootstrap_mode'" == "local" {
    display as text ///
        "Local bootstrap: `local_bootstrap_replications' replications, `local_bootstrap_workers' workers."
}
display as text ///
    "Appendix simulations: `appendix_replications' replications for OA-15 and SA-1."

******************************* Run pipeline **********************************

* Step 1: build the shared cleaned datasets and forest inputs.
display as text "Stage 1 of 3: cleaning data and preparing forest inputs."
do "./DoFiles/master_cleaning.do"

* Step 2: reproduce the main manuscript. This creates the forest summaries
* consumed by the supplementary appendix.
display as text ///
    "Stage 2 of 3: reproducing main-manuscript tables and figures."
if "`figure4_bootstrap_mode'" == "local" {
    do "./DoFiles/master.do" local ///
        `local_bootstrap_replications' `local_bootstrap_workers'
}
else {
    do "./DoFiles/master.do" cluster
}

* Step 3: reproduce all online- and supplementary-appendix exhibits.
display as text ///
    "Stage 3 of 3: reproducing online and supplementary appendices."
do "./DoFiles/master_appendix.do" ///
    `appendix_replications'
display as result "Full replication pipeline completed."
