version 17.0

* Figure 4: Fraction of Sample Foregoing Financial Savings.
* The R scripts called by DoFiles/master.do generate and summarize the requested
* deterministic Bayesian-bootstrap replications before this file plots them.

import delimited ///
    "$directorio/_aux/main_figure_04_bootstrap_summary.csv", clear

replace mean_value = 100 - mean_value if variable == "cwf_nonchoose"
replace lower_ci = 100 - lower_ci if variable == "cwf_nonchoose"
replace upper_ci = 100 - upper_ci if variable == "cwf_nonchoose"
replace threshold = -threshold if variable == "cwf_choose"

twoway ///
    (rarea upper_ci lower_ci threshold if variable == "cwf_nonchoose" & ///
        inrange(threshold, -15, 15), lcolor(dkgreen%5) ///
        fcolor(dkgreen%60) fintensity(40)) ///
    (line mean_value threshold if variable == "cwf_nonchoose" & ///
        inrange(threshold, -15, 15), lpattern(dash) lwidth(medthick) ///
        lcolor(dkgreen%80)) ///
    (scatter mean_value threshold if variable == "cwf_nonchoose" & ///
        inrange(threshold, -15, 15), connect(l) msymbol(x) ///
        color(dkgreen%80)), ///
    legend(off) graphregion(color(white)) ///
    xtitle("CR threshold (percentage points)") xlabel(-15(5)15) ///
    ytitle("CDF") ylabel(0(10)100) ///
    xline(0, lcolor(black) lwidth(medthick) lpattern(dash))
graph export "$directorio/Figures/Figure4a.pdf", replace

twoway ///
    (rarea lower_ci upper_ci threshold if variable == "cwf_choose" & ///
        inrange(threshold, -30, 30), lcolor(maroon%5) ///
        fcolor(maroon%70) fintensity(40)) ///
    (line mean_value threshold if variable == "cwf_choose" & ///
        inrange(threshold, -30, 30), lpattern(dot) lwidth(medthick) ///
        lcolor(maroon%70)) ///
    (scatter mean_value threshold if variable == "cwf_choose" & ///
        inrange(threshold, -30, 30), connect(l) msymbol(x) ///
        color(maroon%70)), ///
    legend(off) graphregion(color(white)) ///
    xtitle("CR threshold (percentage points)") xlabel(-30(10)30) ///
    ytitle("CDF") ylabel(0(10)100) ///
    xline(0, lcolor(black) lwidth(medthick) lpattern(dash))
graph export "$directorio/Figures/Figure4b.pdf", replace
