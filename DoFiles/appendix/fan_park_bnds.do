version 17.0

* Figure OA-9: Fan & Park bounds for benefit in CR%.
use "$directorio/DB/Master.dta", clear
keep if inlist(t_producto, 1, 2)
keep t_producto cr dummy_*
gen byte treat = t_producto == 2
* CR is recorded as a cost; reverse its sign so positive effects are benefits.
replace cr = -cr

* Branch and weekday indicators tighten the nonparametric bounds. The fixed
* k-medians seed makes the seven-cell covariate partition reproducible.
fan_park cr treat dummy_*, delta_partition(100) ///
    cov_partition(7) seed(321)
graph export "$directorio/Figures/FigureOA9.pdf", replace
