version 17.0

* Figure OA-8: Bounding lender's profit.
use "$directorio/DB/Master.dta", clear
keep t_producto fc_admin reincidence suc_x_dia
rename t_producto t_prod
gen byte arm = t_prod == 2 if inlist(t_prod, 1, 2)
do "$directorio/DoFiles/appendix/copula_functions.do"

* Compare Fréchet dependence envelopes with a joint-latent benchmark over
* the discount factors and ten horizons displayed in the four panels.
local delta_values 0.4 0.6 0.8 0.9
local horizon_values 1 2 3 4 5 6 7 8 9 10
copula_grid, deltas(`delta_values') thors(`horizon_values') ///
    sigma(0.15) cluster(suc_x_dia) ///
    latintp(12) latmethod(ghermite) latarmvar(t_prod) ///
    lattreat(2) latcontrol(1) latamt(fc_admin) latret(reincidence)

foreach discount of numlist 0.4 0.6 0.8 0.9 {
    local panel a
    if `discount' == 0.6 local panel b
    if `discount' == 0.8 local panel c
    if `discount' == 0.9 local panel d
    twoway ///
        (line estimate Thor if delta == `discount' & ///
            series == "logitnorm_struct", lpattern(dash) lwidth(medthick) ///
            color(green)) ///
        (line estimate Thor if delta == `discount' & ///
            series == "logitnorm_status", lpattern(dash) lwidth(medthick) ///
            color(green)) ///
        (line estimate Thor if delta == `discount' & ///
            series == "latent_benchmark", lwidth(medthick) color(black%60)) ///
        (scatter estimate Thor if delta == `discount' & ///
            series == "latent_benchmark", msymbol(x) msize(medlarge) ///
            lwidth(medthick) color(black)), ///
        yline(0) legend(order(1 "Envelopes UB/LB" ///
            3 "Joint-latent model") size(medium) col(1) pos(11) ring(0)) ///
        ytitle("Profit difference in %") ///
        xtitle("Time horizon (δ = `discount')") ///
        ylabel(-0.3(0.2)0.1)
    graph export ///
        "$directorio/Figures/FigureOA8`panel'.pdf", replace
}
