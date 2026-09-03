version 17.0

* Figure SA-1 and Table SA-1: seeded sensitivity analysis.
* The required argument is the number of threshold-zero CATE draws to average.
args replications extra_argument
if "`replications'" == "" | "`extra_argument'" != "" {
    display as error ///
        "Usage: do DoFiles/appendix/wide_narrow_forests.do replications"
    exit 198
}
capture confirm integer number `replications'
if _rc {
    display as error "The replication count must be a positive integer."
    exit 198
}
if `replications' < 1 {
    display as error "The replication count must be a positive integer."
    exit 198
}

local forest_file "$directorio/_aux/sa_wide_narrow_grf.csv"
local choice_file "$directorio/_aux/cw_cr_tot_tut.csv"
confirm file "`forest_file'"
confirm file "`choice_file'"

import delimited "`forest_file'", clear
isid prenda
* The R handoff contains each pawn's wide/narrow CATE and variance estimates.
* Merge the four predictors used by the targeting classifiers, then restrict
* the comparison to borrowers assigned to the choice arm. Desired loan size
* enters the upstream narrow CATE forest but not these classifier fits.
merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3) ///
    keepusing(t_producto genero pres_antes masqueprepa edad)
keep if t_producto == 4
keep prenda tau_hat_eff var_hat_eff tau_hat_eff_narrow ///
    var_hat_eff_narrow genero pres_antes masqueprepa edad

gen double tau_sim = .
gen double tau_sim_narrow = .
gen byte bfa = .

tempname simulation_post
tempfile simulation_results scatter_draws
postfile `simulation_post' int replication ///
    double better_forceall type_i type_ii type_i_lg type_ii_lg ///
    using `simulation_results', replace

* Table SA-1 reports targeting errors only for a zero CATE threshold. Disjoint
* numerical ranges give the CATE draw and classifier their own reproducible
* random streams; adding the replication number makes every draw distinct.
local threshold = 0
forvalues replication = 1/`replications' {
    local wide_seed = 110110000 + `replication'
    local rforest_seed = 410110000 + `replication'

    quietly set seed `wide_seed'
    quietly replace tau_sim = ///
        rnormal(tau_hat_eff, sqrt(var_hat_eff))
    quietly replace bfa = tau_sim > `threshold' / 100 ///
        if !missing(tau_sim)

    * SA Table 1 reports this sample fraction, not bootstrap uncertainty.
    quietly summarize bfa, meanonly
    local better_forceall = r(mean) * 100

    preserve
    quietly keep if !missing(bfa, genero, pres_antes, masqueprepa, edad)
    quietly summarize bfa
    if r(sd) == 0 {
        local type_i = 0
        local type_ii = 0
        local type_i_lg = 0
        local type_ii_lg = 0
    }
    else {
        * Fit the table's targeting rule using its four borrower predictors,
        * then target the same share that the simulated wide forest classifies
        * as benefiting from structure.
        quietly rforest bfa genero pres_antes masqueprepa edad, ///
            type(class) iter(1000) seed(`rforest_seed')
        quietly predict fit_rf0 fit_rf1, pr
        quietly xtile percentile_rf = fit_rf1, nq(100)
        quietly summarize bfa, meanonly
        local target_percentile = 100 - ceil(r(mean) * 100)
        * Match the predicted-treatment share to the simulated beneficiary
        * share; adjacent percentile bins handle gaps created by tied scores.
        quietly summarize fit_rf1 if percentile_rf == `target_percentile', ///
            meanonly
        if r(N) == 0 {
            quietly summarize fit_rf1 if inrange( ///
                percentile_rf, `target_percentile' - 1, ///
                `target_percentile' + 1), meanonly
        }
        if r(N) == 0 {
            quietly summarize fit_rf1 if inrange( ///
                percentile_rf, `target_percentile' - 1, ///
                `target_percentile' + 2), meanonly
        }
        local rf_cutoff = r(mean)
        quietly replace fit_rf1 = fit_rf1 >= `rf_cutoff'
        quietly count
        local sample_size = r(N)
        quietly count if fit_rf1 == 0 & bfa == 1
        local type_i = r(N) / `sample_size' * 100
        quietly count if fit_rf1 == 1 & bfa == 0
        local type_ii = r(N) / `sample_size' * 100

        * With perfect prediction, logit can remove every observation and
        * exit with r(2000). Its in-sample classification error is then zero.
        capture quietly logit bfa genero pres_antes masqueprepa edad
        local logit_rc = _rc
        if `logit_rc' == 2000 {
            local type_i_lg = 0
            local type_ii_lg = 0
        }
        else if `logit_rc' != 0 {
            display as error "Unexpected logit failure (r(`logit_rc'))."
            restore
            postclose `simulation_post'
            exit `logit_rc'
        }
        else {
            * Apply the same share-matching rule to logit probabilities.
            quietly predict double fit_lg
            quietly xtile percentile_lg = fit_lg, nq(100)
            quietly summarize bfa, meanonly
            local target_percentile = 100 - ceil(r(mean) * 100)
            quietly summarize fit_lg if ///
                percentile_lg == `target_percentile', meanonly
            if r(N) == 0 {
                quietly summarize fit_lg if inrange( ///
                    percentile_lg, `target_percentile' - 1, ///
                    `target_percentile' + 1), meanonly
            }
            if r(N) == 0 {
                quietly summarize fit_lg if inrange( ///
                    percentile_lg, `target_percentile' - 1, ///
                    `target_percentile' + 2), meanonly
            }
            local logit_cutoff = r(mean)
            quietly replace fit_lg = fit_lg >= `logit_cutoff'
            quietly count
            local sample_size = r(N)
            quietly count if fit_lg == 0 & bfa == 1
            local type_i_lg = r(N) / `sample_size' * 100
            quietly count if fit_lg == 1 & bfa == 0
            local type_ii_lg = r(N) / `sample_size' * 100
        }
    }
    restore

    post `simulation_post' (`replication') (`better_forceall') ///
        (`type_i') (`type_ii') (`type_i_lg') (`type_ii_lg')
}
postclose `simulation_post'

* Figure SA-1 uses one separately seeded paired CATE draw solely to plot the
* wide/narrow comparison. Fixed plot seeds make it independent of the chosen
* Table SA-1 simulation count, and their disjoint ranges keep the two draws
* independent.
local figure_wide_seed = 110210100
local figure_narrow_seed = 210210100
quietly set seed `figure_wide_seed'
quietly replace tau_sim = rnormal(tau_hat_eff, sqrt(var_hat_eff))
quietly set seed `figure_narrow_seed'
quietly replace tau_sim_narrow = ///
    rnormal(tau_hat_eff_narrow, sqrt(var_hat_eff_narrow))

keep prenda tau_sim tau_sim_narrow
save `scatter_draws'

use `simulation_results', clear
collapse (mean) better_forceall type_i type_ii type_i_lg type_ii_lg
local all_status_quo = better_forceall[1]
local all_structure = 100 - `all_status_quo'
local rf_control = type_i[1]
local rf_treatment = type_ii[1]
local logit_control = type_i_lg[1]
local logit_treatment = type_ii_lg[1]

* Main Figure 4's bootstrap summary supplies the observed choice-rule errors.
* SA Table 1 uses its three threshold-zero means.
import delimited "`choice_file'", clear
isid threshold variable
quietly summarize mean_value if threshold == 0 & variable == "cwf_nonchoose", ///
    meanonly
local choice_control = r(mean)
quietly summarize mean_value if threshold == 0 & variable == "cwf_choose", ///
    meanonly
local choice_treatment = r(mean)
quietly summarize mean_value if threshold == 0 & variable == "cwf", meanonly
local choice_overall = r(mean)

* Figure SA-1: Conditional ATEs from wide and narrow covariate sets.
use `scatter_draws', clear
quietly regress tau_sim_narrow tau_sim
local display_r2 = round(e(r2), 0.001)

twoway ///
    (scatter tau_sim_narrow tau_sim, msymbol(smcircle_hollow) ///
        text(0.25 -0.1 "R-squared : `display_r2'")) ///
    (lfitci tau_sim_narrow tau_sim, lcolor(navy)) ///
    (line tau_sim tau_sim, sort lcolor(black) lpattern(dash)), ///
    name(sct, replace) legend(off) xscale(off) yscale(off) ///
    xtitle("") ytitle("") xlabel(-0.1(.1)0.25, nolabel) ///
    ylabel(-0.1(.1)0.25, nolabel)

kdensity tau_sim_narrow, kernel(gaussian) generate(x0 d0)
line x0 d0, xscale(reverse off) yscale(alt) xlabel(, nolabel) ///
    ylabel(-0.1(.1)0.25) xtick(, notick) name(hist0, replace) ///
    fxsize(40) ytitle("Narrow forest")

kdensity tau_sim, kernel(gaussian) generate(x1 d1)
line d1 x1, xscale(alt) yscale(reverse off) ylabel(, nolabel) ///
    xlabel(-0.1(.1)0.25) ytick(, notick) name(hist1, replace) ///
    fysize(35) xtitle("Wide forest")

graph combine hist0 sct hist1, cols(2) holes(3) imargin(0 0 0 0)
graph export "$directorio/Figures/FigureSA1.pdf", replace

* Table SA-1: six targeting rules and their three reported error rates.
clear
set obs 6
gen str24 rule = ""
gen double incorrectly_control = .
gen double incorrectly_treatment = .
gen double overall_error = .
replace rule = "all_to_status_quo" in 1
replace incorrectly_control = `all_status_quo' in 1
replace incorrectly_treatment = 0 in 1
replace overall_error = `all_status_quo' in 1
replace rule = "all_to_structure" in 2
replace incorrectly_control = 0 in 2
replace incorrectly_treatment = `all_structure' in 2
replace overall_error = `all_structure' in 2
replace rule = "optimal" in 3
replace incorrectly_control = 0 in 3
replace incorrectly_treatment = 0 in 3
replace overall_error = 0 in 3
replace rule = "narrow_rf" in 4
replace incorrectly_control = `rf_control' in 4
replace incorrectly_treatment = `rf_treatment' in 4
replace overall_error = `rf_control' + `rf_treatment' in 4
replace rule = "narrow_logit" in 5
replace incorrectly_control = `logit_control' in 5
replace incorrectly_treatment = `logit_treatment' in 5
replace overall_error = `logit_control' + `logit_treatment' in 5
replace rule = "allow_choice" in 6
replace incorrectly_control = `choice_control' in 6
replace incorrectly_treatment = `choice_treatment' in 6
replace overall_error = `choice_overall' in 6

* Keep only the values displayed in the manuscript table. Python reads this
* canonical CSV and applies the table's LaTeX labels and formatting.
keep rule incorrectly_control incorrectly_treatment overall_error
order rule incorrectly_control incorrectly_treatment overall_error
assert _N == 6
isid rule
assert !missing(incorrectly_control, incorrectly_treatment, overall_error)
export delimited "$directorio/Tables/reg_results/TableSA1.csv", replace

do "$directorio/DoFiles/render_table.do" TableSA1
