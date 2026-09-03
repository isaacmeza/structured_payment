version 17.0

* Figure OA-7: Profit difference, mandatory structure versus control.
use "$directorio/DB/Master.dta", clear
keep if inlist(t_producto, 1, 2)
keep t_producto suc_x_dia fc_admin reincidence

* Recover arm-specific mean current profit and repeat-borrowing probabilities.
quietly regress fc_admin i.t_producto, vce(cluster suc_x_dia)
quietly summarize fc_admin if e(sample) & t_producto == 1
scalar FC1 = r(mean)
scalar FC2 = FC1 + _b[2.t_producto]

quietly regress reincidence i.t_producto, vce(cluster suc_x_dia)
quietly summarize reincidence if e(sample) & t_producto == 1
scalar Pr1 = r(mean)
scalar Pr2 = Pr1 + _b[2.t_producto]

clear
set obs 90
gen Delta = .
gen T = .
gen Difference = .
local delta_values 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9
local T_values 0 1 2 3 4 5 6 7 8 9
local observation = 0

* Sum expected discounted profit through each horizon for discount factors
* from 0.1 to 0.9, then express the mandatory-control gap relative to control.
foreach delta of local delta_values {
    foreach horizon of local T_values {
        scalar control = 0
        scalar mandatory = 0
        forvalues period = 0/`horizon' {
            scalar control = control + (`delta'^`period') * (Pr1^`period') * FC1
            scalar mandatory = mandatory + (`delta'^`period') * (Pr2^`period') * FC2
        }
        scalar difference = (mandatory - control) / control
        local ++observation
        replace Delta = `delta' in `observation'
        replace T = `horizon' in `observation'
        replace Difference = difference in `observation'
    }
}
replace T = T + 1

twoway ///
    (line Difference T if inrange(Delta, 0.05, 0.15), lcolor(gs15)) ///
    (line Difference T if inrange(Delta, 0.15, 0.25), lcolor(gs14)) ///
    (line Difference T if inrange(Delta, 0.25, 0.35), lcolor(gs12)) ///
    (line Difference T if inrange(Delta, 0.35, 0.45), lcolor(gs10)) ///
    (line Difference T if inrange(Delta, 0.45, 0.55), lcolor(gs8)) ///
    (line Difference T if inrange(Delta, 0.55, 0.65), lcolor(gs6)) ///
    (line Difference T if inrange(Delta, 0.65, 0.75), lcolor(gs4)) ///
    (line Difference T if inrange(Delta, 0.75, 0.85), lcolor(gs2)) ///
    (line Difference T if inrange(Delta, 0.85, 0.95), lcolor(gs1)), ///
    title("") ytitle("Profit difference %") xlabel(0(1)10) ///
    ylabel(, angle(horizontal)) ///
    legend(order(1 "{&delta} = 0.1" 2 "{&delta} = 0.2" ///
        3 "{&delta} = 0.3" 4 "{&delta} = 0.4" 5 "{&delta} = 0.5" ///
        6 "{&delta} = 0.6" 7 "{&delta} = 0.7" 8 "{&delta} = 0.8" ///
        9 "{&delta} = 0.9"))
graph export "$directorio/Figures/FigureOA7.pdf", replace
