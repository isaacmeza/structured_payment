version 17.0

* Figure 3: Heterogeneous Treatment Effects.
* The two forest files are written by the R calls immediately before this do-file
* in DoFiles/master.do.

import delimited "$directorio/Results/forest/main_figure_03_instr.csv", clear
keep if panel == "tot"
keep prenda estimate
rename estimate tau_hat_tot
tempfile tot
save `tot'

import delimited "$directorio/Results/forest/main_figure_03_instr.csv", clear
keep if panel == "tut"
keep if t_producto == 4
keep prenda estimate
rename estimate tau_hat_tut
tempfile tut
save `tut'

import delimited "$directorio/Results/forest/main_figure_03_cate.csv", clear
merge 1:1 prenda using `tot', nogen
merge 1:1 prenda using `tut', nogen

twoway (kdensity tau_hat_eff, kernel(gaussian) lwidth(thick) color(navy)), ///
    xline(0) legend(off) ytitle(" ") xtitle("CR")
graph export "$directorio/Figures/Figure3c.pdf", replace

xtile perc_tau_hat_tot = tau_hat_tot, nq(100)
twoway (kdensity tau_hat_tot if perc_tau_hat_tot >= 5, ///
    kernel(gaussian) lwidth(thick) color(maroon)), ///
    xline(0) legend(off) ytitle(" ") xtitle("CR")
graph export "$directorio/Figures/Figure3a.pdf", replace

twoway (kdensity tau_hat_tut, kernel(gaussian) lwidth(thick) color(dkgreen)), ///
    xline(0) legend(off) ytitle(" ") xtitle("CR")
graph export "$directorio/Figures/Figure3b.pdf", replace
