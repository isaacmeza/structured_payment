version 17.0

* OA Table 2: baseline-survey balance data.
use "$directorio/DB/Master.dta", clear
keep t_producto suc_x_dia f_encuesta val_pren_orig faltas pb ///
    hace_presupuesto pr_recup pres_antes edad genero masqueprepa

local survey_variables val_pren_orig faltas pb hace_presupuesto pr_recup ///
    pres_antes edad genero masqueprepa

* Stable row keys let the table renderer apply the manuscript labels and
* display precision without relying on an Excel formatting template.
local statistic_keys appraisal_value trouble_paying_bills present_bias ///
    makes_budget expected_recovery previous_pawn age female ///
    high_school_or_more

tempname table_post
tempfile table_data
postfile `table_post' str40 statistic ///
    double control double mandatory double choice double p_value ///
    using `table_data', replace

local outcome_number = 0
foreach outcome of local survey_variables {
    local ++outcome_number
    local statistic_key : word `outcome_number' of `statistic_keys'

    * The displayed arm means and standard errors come from separate
    * arm-specific intercept-only regressions with branch-day clustering.
    tempname arm_means arm_ses joint_p
    matrix `arm_means' = J(1, 3, .)
    matrix `arm_ses' = J(1, 3, .)
    local arm_number = 0
    foreach treatment in 1 2 4 {
        local ++arm_number
        quietly regress `outcome' if t_producto == `treatment', ///
            vce(cluster suc_x_dia)
        matrix `arm_means'[1, `arm_number'] = _b[_cons]
        matrix `arm_ses'[1, `arm_number'] = _se[_cons]
    }

    * The reported p-value tests equality of all three randomized-arm means.
    quietly regress `outcome' ibn.t_producto ///
        if inlist(t_producto, 1, 2, 4), nocons vce(cluster suc_x_dia)
    quietly test 1.t_producto == 2.t_producto == 4.t_producto
    scalar `joint_p' = r(p)

    post `table_post' ("`statistic_key'_mean") ///
        (`arm_means'[1, 1]) (`arm_means'[1, 2]) (`arm_means'[1, 3]) ///
        (`joint_p')
    post `table_post' ("`statistic_key'_se") ///
        (`arm_ses'[1, 1]) (`arm_ses'[1, 2]) (`arm_ses'[1, 3]) (.)
}

* The final row reports baseline-survey respondents by randomized arm.
local arm_number = 0
foreach treatment in 1 2 4 {
    local ++arm_number
    local arm : word `arm_number' of control mandatory choice
    quietly count if !missing(f_encuesta) & t_producto == `treatment'
    local `arm'_observations = r(N)
}
post `table_post' ("observations") (`control_observations') ///
    (`mandatory_observations') (`choice_observations') (.)
postclose `table_post'

use `table_data', clear
local expected_rows appraisal_value_mean appraisal_value_se ///
    trouble_paying_bills_mean trouble_paying_bills_se ///
    present_bias_mean present_bias_se makes_budget_mean makes_budget_se ///
    expected_recovery_mean expected_recovery_se previous_pawn_mean ///
    previous_pawn_se age_mean age_se female_mean female_se ///
    high_school_or_more_mean high_school_or_more_se observations
assert _N == 19
forvalues row = 1/19 {
    local expected : word `row' of `expected_rows'
    assert statistic == "`expected'" in `row'
}
isid statistic
assert !missing(control, mandatory, choice)
order statistic control mandatory choice p_value
format control mandatory choice p_value %24.17g
capture mkdir "$directorio/Tables"
capture mkdir "$directorio/Tables/reg_results"
export delimited using "$directorio/Tables/reg_results/TableOA2.csv", ///
    datafmt replace

do "$directorio/DoFiles/render_table.do" TableOA2
