version 17.0

* Replicate the numbered exhibits in the online and supplementary appendices.
* run_all.do passes the common OA-15 and SA-1 replication count.
args appendix_replications extra_argument
if "`appendix_replications'" == "" | "`extra_argument'" != "" {
    display as error ///
        "Usage: do DoFiles/master_appendix.do replications"
    exit 198
}
if !regexm("`appendix_replications'", "^[1-9][0-9]*$") {
    display as error "The replication count must be a positive integer."
    exit 198
}
capture confirm integer number `appendix_replications'
if _rc {
    display as error "The replication count must be a positive integer."
    exit 198
}

do "./DoFiles/set_environment.do"

capture mkdir "$directorio/Results"
capture mkdir "$directorio/Figures"
capture mkdir "$directorio/Tables"
capture mkdir "$directorio/Tables/reg_results"

* Figure OA-1: Contract Terms Summary, and Promise Slip
* Table OA-7: Baseline survey questions (translated to English)
do "$directorio/DoFiles/appendix/check_static_appendix.do"

* Figure OA-2: Weekly default rates experimental branches and all branches
do "$directorio/DoFiles/appendix/weekly_def_rates.do"

* Figure OA-3: Behavior of borrowers who lost their pawn.
do "$directorio/DoFiles/appendix/hist_den_default.do"

* Figure OA-4: Determinants of choice.
do "$directorio/DoFiles/appendix/determinants_choice.do"

* Table OA-1: No selection across arms
do "$directorio/DoFiles/appendix/ss_att.do"

* Table OA-2: Borrowers' characteristics are balanced
do "$directorio/DoFiles/appendix/ss_balance.do"

* Table OA-3: Bounding censoring
do "$directorio/DoFiles/appendix/censoring_imp.do"

* Figure OA-5: Survival graph.
do "$directorio/DoFiles/appendix/survival_graph.do"

* Figure OA-6: Percentage of the loan paid over time, by experimental arm
do "$directorio/DoFiles/appendix/cumulative_porc_pay_time.do"

* Table OA-4: Effects on more comprehensive cost measures
do "$directorio/DoFiles/appendix/fc_robustness.do"

* Figure OA-7: Profit difference, mandatory structure versus control
do "$directorio/DoFiles/appendix/profit_difference.do"

* Figure OA-8: Bounding lender's profit.
do "$directorio/DoFiles/appendix/profit_difference_robust.do"

* Table OA-5: Effects of Promise on Financial Cost
do "$directorio/DoFiles/appendix/decomposition_main_te_promise.do"

* Table OA-6: Effects on Repeat Pawning
do "$directorio/DoFiles/appendix/repeat_loans.do"

* Table OA-7 is the static TEX transcription checked above.

* Figure OA-9: Fan & Park bounds for benefit in CR%.
do "$directorio/DoFiles/appendix/fan_park_bnds.do"

* Figure OA-10: Distribution of treatment effects for CR benefit under rank invariance.
do "$directorio/DoFiles/appendix/te_rankinvariance.do"

* Table OA-8: Effects on Financial Cost by selected subsample of survey respondents
do "$directorio/DoFiles/appendix/decomposition_main_te_subsample.do"

* Table OA-9: Effect of Prior Assignment on Subsequent Choice
do "$directorio/DoFiles/appendix/learning_exp.do"

* Figure OA-11: Financial benefit TUT effect for different discount rates.
do "$directorio/DoFiles/appendix/discounted_noeffect.do"

* Figure OA-12: Determinants of sure confidence
do "$directorio/DoFiles/appendix/determinants_sure_confidence.do"

* Figure OA-13: Estimating counterfactual outcomes for non-choosers, by overconfidence
do "$directorio/DoFiles/appendix/po_decomposition.do"

* Figure OA-14: Differences in TUT estimates by behavioral variables, promise arms
do "$directorio/DoFiles/appendix/partition_tut_promise.do"

* Figure OA-15: Comparing the Effect of Structure on Prepayment
* Each replication resamples randomized branch-day clusters and recomputes
* both prepayment difference-in-difference paths. Their pointwise 5th and 95th
* percentiles form the figure's 90% confidence intervals.
do "$directorio/DoFiles/appendix/SC_prepayment.do" ///
    `appendix_replications'

* Figure SA-1: Conditional ATEs from “wide” and “narrow” covariate sets.
* Table SA-1: Type I & II errors using targeting narrow rules
* Main Figure 4 supplies the observed choice-rule error rates used in SA
* Table 1; the R step below constructs the wide/narrow CATE handoff.
confirm file "$directorio/_aux/main_figure_03_cate.csv"
confirm file "$directorio/_aux/cw_cr_tot_tut.csv"
capture erase "$directorio/_aux/sa_wide_narrow_grf.csv"
rscript using "$directorio/RScripts/sa_wide_narrow_grf.R", ///
    rversion(4.5.3 4.5.3)
confirm file "$directorio/_aux/sa_wide_narrow_grf.csv"
* Each replication draws individual CATEs using the forest estimates and
* their variances, refits the random-forest and logit targeting rules, and
* contributes one set of classification errors to the Table SA-1 averages.
do "$directorio/DoFiles/appendix/wide_narrow_forests.do" ///
    `appendix_replications'
