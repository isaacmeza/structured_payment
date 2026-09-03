version 17.0

* Figure OA-14: Differences in TUT estimates by behavioral variables,
* promise arms.
use "$directorio/DB/Master.dta", clear
keep if inlist(t_producto, 1, 3, 5)
keep fc_admin pb confidence_100 choose_commitment t_producto suc_x_dia
* Financial cost enters as a benefit, and Z codes control, mandatory promise,
* and choice of promise as required by tot_tut.
replace fc_admin = -fc_admin
gen Z = 0 if t_producto == 1
replace Z = 1 if t_producto == 3
replace Z = 2 if t_producto == 5

matrix subgroup = J(4, 4, .)
matrix overall = J(2, 2, .)
local row = 1
local variable_index = 1
foreach variable of varlist pb confidence_100 {
    quietly tot_tut fc_admin Z choose_commitment if !missing(`variable'), ///
        vce(cluster suc_x_dia)
    matrix overall[`variable_index', 1] = _b[TuT]
    matrix overall[`variable_index', 2] = _se[TuT]
    forvalues group = 0/1 {
        quietly tot_tut fc_admin Z choose_commitment if `variable' == `group', ///
            vce(cluster suc_x_dia)
        matrix subgroup[`row', 1] = _b[TuT]
        matrix subgroup[`row', 2] = _se[TuT]
        matrix subgroup[`row', 3] = `group'
        matrix subgroup[`row', 4] = `variable_index'
        local ++row
    }
    local ++variable_index
}
clear
svmat subgroup
rename subgroup2 subgroup1_se
label define behavioral_var 1 "Present Bias" 2 "Sure-confidence"
label values subgroup4 behavioral_var
* Preserve the reported figure's fixed t(257) critical-value convention for
* overall and subgroup estimates; standard errors remain branch-day clustered.
local critical_value = invttail(257, 0.025)
gen subgroup1_low = subgroup1 - `critical_value' * subgroup1_se
gen subgroup1_high = subgroup1 + `critical_value' * subgroup1_se
reshape wide subgroup1 subgroup1_se subgroup1_low subgroup1_high, ///
    i(subgroup4) j(subgroup3)
svmat overall
rename overall2 overall1_se
gen overall1_low = overall1 - `critical_value' * overall1_se
gen overall1_high = overall1 + `critical_value' * overall1_se
gen x_group0 = subgroup4 - 0.1
gen x_group1 = subgroup4 + 0.1
twoway ///
    (rcap overall1_low overall1_high subgroup4, msize(large) color(navy)) ///
    (scatter overall1 subgroup4, msymbol(square) msize(medium) color(navy)) ///
    (rcap subgroup1_low0 subgroup1_high0 x_group0, msize(large) color(maroon)) ///
    (scatter subgroup10 x_group0, msymbol(diamond) msize(medium) color(maroon)) ///
    (rcap subgroup1_low1 subgroup1_high1 x_group1, msize(large) color(dkgreen)) ///
    (scatter subgroup11 x_group1, msize(large) color(dkgreen)), ///
    yline(0) xline(1.5, lpattern(solid)) ///
    legend(order(4 "TuT | X=0" 2 "TuT" 6 "TuT | X=1") pos(6) rows(1)) ///
    xlabel(0.5 " " 1 2 2.5 " ", valuelabel)
graph export "$directorio/Figures/FigureOA14.pdf", replace
