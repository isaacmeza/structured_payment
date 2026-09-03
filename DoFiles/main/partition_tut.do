version 17.0

* Figure 5: Differences in TUT Effects by behavioral variables.
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod, 1, 2, 4)
keep fc_admin pb confidence_100 choose_commitment t_prod suc_x_dia
replace fc_admin = -fc_admin
gen byte Z = 0 if t_prod == 1
replace Z = 1 if t_prod == 2
replace Z = 2 if t_prod == 4

matrix behavioral_te = J(4, 4, .)
matrix tut = J(2, 2, .)
local row = 1
local variable_index = 1

foreach variable of varlist pb confidence_100 {
    tot_tut fc_admin Z choose_commitment if !missing(`variable'), ///
        vce(cluster suc_x_dia)
    matrix tut[`variable_index', 1] = _b[TuT]
    matrix tut[`variable_index', 2] = _se[TuT]

    forvalues group = 0/1 {
        tot_tut fc_admin Z choose_commitment if `variable' == `group', ///
            vce(cluster suc_x_dia)
        matrix behavioral_te[`row', 1] = _b[TuT]
        matrix behavioral_te[`row', 2] = _se[TuT]
        matrix behavioral_te[`row', 3] = `group'
        matrix behavioral_te[`row', 4] = `variable_index'
        local ++row
    }
    local ++variable_index
}

clear
svmat behavioral_te
rename behavioral_te2 behavioral_te1_se
label define behavioral_var 1 "Present Bias" 2 "Sure-confidence"
label values behavioral_te4 behavioral_var

* The full fee-arm frame contains 257 branch-day clusters before the behavioral-
* variable and subgroup restrictions. Preserve the reported figure's fixed
* t(257) critical-value convention for all displayed intervals.
local critical_value = invttail(257, 0.025)
gen behavioral_te1_lo = behavioral_te1 - `critical_value' * behavioral_te1_se
gen behavioral_te1_hi = behavioral_te1 + `critical_value' * behavioral_te1_se
reshape wide behavioral_te1 behavioral_te1_se behavioral_te1_lo ///
    behavioral_te1_hi, i(behavioral_te4) j(behavioral_te3)

svmat tut
rename tut2 tut1_se
gen tut1_lo = tut1 - `critical_value' * tut1_se
gen tut1_hi = tut1 + `critical_value' * tut1_se
gen ind0 = behavioral_te4 - 0.1
gen ind1 = behavioral_te4 + 0.1

twoway ///
    (rcap tut1_lo tut1_hi behavioral_te4, msize(large) color(navy)) ///
    (scatter tut1 behavioral_te4, msymbol(square) msize(medium) color(navy)) ///
    (rcap behavioral_te1_lo0 behavioral_te1_hi0 ind0, ///
        msize(large) color(maroon)) ///
    (scatter behavioral_te10 ind0, msymbol(diamond) ///
        msize(medium) color(maroon)) ///
    (rcap behavioral_te1_lo1 behavioral_te1_hi1 ind1, ///
        msize(large) color(dkgreen)) ///
    (scatter behavioral_te11 ind1, msize(large) color(dkgreen)), ///
    yline(0) xline(1.5, lpattern(solid)) ///
    legend(order(4 "TuT | X=0" 2 "TuT" 6 "TuT | X=1") ///
        pos(6) rows(1)) ///
    xlabel(0.5 " " 1 2 2.5 " ", valuelabel)

graph export "$directorio/Figures/Figure5.pdf", replace
