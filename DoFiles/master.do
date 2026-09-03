version 17.0

* Replicate the numbered tables and figures in the main manuscript.
* Run DoFiles/master_cleaning.do first in a new or clean workspace.
* Required mode "cluster" uses a production Figure 4 bootstrap placed in
* _aux/ after the optional cluster workflow;
* mode "local" rebuilds a reduced bootstrap using the supplied argument counts.

args run_mode requested_reps requested_workers extra_argument
if !inlist("`run_mode'", "cluster", "local") {
    display as error ///
        "Usage: do DoFiles/master.do {cluster|local reps workers}"
    exit 198
}
if "`extra_argument'" != "" {
    display as error "Too many master.do arguments."
    exit 198
}

local production_bootstrap_reps 5000
local bootstrap_reps `production_bootstrap_reps'
if "`run_mode'" == "local" {
    if "`requested_reps'" == "" | "`requested_workers'" == "" {
        display as error ///
            "Local mode requires replication and worker counts."
        exit 198
    }

    if !regexm("`requested_reps'", "^[1-9][0-9]*$") {
        display as error "The replication count must be a positive integer."
        exit 198
    }
    if !regexm("`requested_workers'", "^[1-9][0-9]*$") {
        display as error "The worker count must be a positive integer."
        exit 198
    }
    capture confirm integer number `requested_reps'
    if _rc {
        display as error "The replication count must be a positive integer."
        exit 198
    }
    capture confirm integer number `requested_workers'
    if _rc {
        display as error "The worker count must be a positive integer."
        exit 198
    }
    local bootstrap_reps `requested_reps'
    local bootstrap_workers `requested_workers'
}
else if "`requested_reps'`requested_workers'" != "" {
    display as error "Replication and worker counts require local mode."
    exit 198
}
do "./DoFiles/set_environment.do"

* Fail before running any exhibit if the production artifact is not in place.
if "`run_mode'" == "cluster" {
    confirm file "$directorio/_aux/choose_wrong_tot_tut_btsp.rds"
}

capture mkdir "$directorio/Results"
capture mkdir "$directorio/Results/forest"
capture mkdir "$directorio/Figures"
capture mkdir "$directorio/Tables"
capture mkdir "$directorio/Tables/reg_results"

************************************ Tables ************************************

* Table 1: Effects on Financial Cost
do "$directorio/DoFiles/main/decomposition_main_te.do"

* Table 2: Effects on intermediate outcomes
do "$directorio/DoFiles/main/mechanisms.do"

* Table 3: TOT, TUT, ASG, ASB, and ASL Estimates
do "$directorio/DoFiles/main/tot_tut.do"

*********************************** Figures ************************************

* Figure 1: Experiment description
do "$directorio/DoFiles/main/consort_dates.do"

* Figure 2: Graphical Intuition for the Mandates vs. Choice Design.
do "$directorio/DoFiles/main/check_static_main.do"

* Figure 3: Heterogeneous Treatment Effects.
capture erase "$directorio/Results/forest/main_figure_03_cate.csv"
capture erase "$directorio/Results/forest/main_figure_03_instr.csv"
rscript using "$directorio/RScripts/te_grf.R", rversion(4.5.3 4.5.3)
rscript using "$directorio/RScripts/tot_tut_instr_forest.R", ///
    rversion(4.5.3 4.5.3)
confirm file "$directorio/Results/forest/main_figure_03_cate.csv"
confirm file "$directorio/Results/forest/main_figure_03_instr.csv"
do "$directorio/DoFiles/main/cate_dist.do"

* Figure 4: Fraction of Sample Foregoing Financial Savings
if "`run_mode'" == "local" {
    capture erase "$directorio/_aux/choose_wrong_tot_tut_btsp.local.rds"
    rscript using "$directorio/RScripts/btsp_tot_tut_instr.R", ///
        args("--reps=`bootstrap_reps'" ///
            "--workers=`bootstrap_workers'" "--local-artifact") ///
        rversion(4.5.3 4.5.3)
    confirm file "$directorio/_aux/choose_wrong_tot_tut_btsp.local.rds"
}
else {
    display as text "Using the production Figure 4 bootstrap in _aux/."
}

capture erase "$directorio/_aux/main_figure_04_bootstrap_summary.csv"
capture erase "$directorio/_aux/cw_cr_tot_tut.csv"
if "`run_mode'" == "local" {
    rscript using "$directorio/RScripts/summarize_btsp_tot_tut_instr.R", ///
        args("--expected-reps=`bootstrap_reps'" "--local-artifact") ///
        rversion(4.5.3 4.5.3)
}
else {
    rscript using "$directorio/RScripts/summarize_btsp_tot_tut_instr.R", ///
        args("--expected-reps=`bootstrap_reps'") ///
        rversion(4.5.3 4.5.3)
}
confirm file "$directorio/_aux/main_figure_04_bootstrap_summary.csv"
confirm file "$directorio/_aux/cw_cr_tot_tut.csv"
do "$directorio/DoFiles/main/plot_btsp_choose_wrong_tot_tut.do"

* Figure 5: Differences in TUT Effects by behavioral variables (Financial Cost Outcome).
do "$directorio/DoFiles/main/partition_tut.do"
