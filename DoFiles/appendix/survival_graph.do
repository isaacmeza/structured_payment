version 17.0

* Figure OA-5: Survival graph.
use "$directorio/DB/Master.dta", clear
keep if inlist(t_producto, 1, 2, 3, 4, 5)
keep t_producto dias_ultimo_mov concluyo_c dias_al_desempenyo des_c

* Retain all five arms while constructing the empirical CDFs: cumul's handling
* of tied event times depends on observation order, including the unplotted arms.
* Scaling by the completion rate converts the conditional CDF into the
* cumulative percentage of all loans completed by each day.
forvalues arm = 1/5 {
    cumul dias_ultimo_mov if concluyo_c == 1 & t_producto == `arm', ///
        gen(ecd_t`arm')
    quietly summarize concluyo_c if t_producto == `arm'
    replace ecd_t`arm' = ecd_t`arm' * r(mean) * 100
}

sort t_producto dias_ultimo_mov
twoway ///
    (line ecd_t1 dias_ultimo_mov, lwidth(medthick) lpattern(solid) ///
        lcolor(black) xline(105, lpattern(dot) lcolor(gs10))) ///
    (line ecd_t2 dias_ultimo_mov, lwidth(medthick) lpattern(dash) ///
        lcolor(navy%90) xline(30 60 90, lcolor(gs12))) ///
    (line ecd_t4 dias_ultimo_mov, lwidth(medthick) lpattern(shortdash) ///
        lcolor(maroon%90)), ///
    graphregion(color(white)) xtitle("Elapsed days") ///
    ytitle("Percentage (%)") ///
    legend(order(1 "Status-quo" 2 "Mandatory structured" 3 "Choice") ///
        size(medium) pos(6) rows(1)) ///
    xlabel(0 30 60 90 180 270 320)
graph export "$directorio/Figures/FigureOA5a.pdf", replace

* Repeat for recoveries; missing recovery times exclude defaulted loans from
* the conditional CDF before scaling by the arm's overall recovery rate.
forvalues arm = 1/5 {
    cumul dias_al_desempenyo if t_producto == `arm', gen(ecdf_t`arm')
    quietly summarize des_c if t_producto == `arm'
    replace ecdf_t`arm' = ecdf_t`arm' * r(mean) * 100
}

sort t_producto dias_al_desempenyo
twoway ///
    (line ecdf_t1 dias_al_desempenyo, lwidth(medthick) lpattern(solid) ///
        lcolor(black) xline(105, lpattern(dot) lcolor(gs10))) ///
    (line ecdf_t2 dias_al_desempenyo, lwidth(medthick) lpattern(dash) ///
        lcolor(navy%90) xline(30 60 90, lcolor(gs12))) ///
    (line ecdf_t4 dias_al_desempenyo, lwidth(medthick) ///
        lpattern(shortdash) lcolor(maroon%90)), ///
    graphregion(color(white)) xtitle("Elapsed days to recovery") ///
    ytitle("Percentage %") ///
    legend(order(1 "Status-quo" 2 "Mandatory structured" 3 "Choice") ///
        size(medium) pos(6) rows(1)) ///
    xlabel(0 30 60 90 180 270 320)
graph export "$directorio/Figures/FigureOA5b.pdf", replace
