version 17.0

* Figure OA-10: Distribution of treatment effects for CR benefit under rank invariance.
use "$directorio/DB/Master.dta", clear
keep if inlist(t_producto, 1, 2)
keep t_producto cr

* CR is recorded as a cost; reverse its sign so positive effects are benefits.
replace cr = -cr
* Match treated and control quantiles under rank invariance. The construction
* excludes the lowest pooled percentile before interpolating both quantile grids.
xtile percentile = cr, nq(100)
keep if percentile > 1
xtile percentile_control = cr if t_producto == 1, nq(1000)
xtile percentile_treated = cr if t_producto == 2, nq(1000)
sort percentile* cr
duplicates drop percentile*, force
egen percentile_combined = rowtotal(percentile percentile_control percentile_treated)
gen treated = t_producto == 2
keep cr percentile_combined treated
reshape wide cr, i(percentile_combined) j(treated)
ipolate cr0 percentile_combined, gen(cr_control)
ipolate cr1 percentile_combined, gen(cr_treated)
gen difference = cr_treated - cr_control
* Evaluate the empirical CDF of the matched quantile differences on 101 evenly
* spaced treatment-effect thresholds.
quietly summarize difference
local lower = r(min)
local upper = r(max)
local step = (`upper' - `lower') / 100
gen indicator = .
gen cdf = .
gen delta = .
local row = 1
forvalues threshold = `lower'(`step')`upper' {
    quietly replace indicator = difference <= `threshold'
    quietly summarize indicator
    quietly replace cdf = r(mean) in `row'
    quietly replace delta = `threshold' in `row'
    local ++row
}
keep if !missing(delta)
keep delta cdf
twoway (line cdf delta, lwidth(medthick)), ///
    xtitle("{&delta}") ///
    ytitle("{&int}1(F{sub:1}{sup:-1}(u)-F{sub:0}{sup:-1}(u){&le}{&delta})du")
graph export "$directorio/Figures/FigureOA10.pdf", replace
