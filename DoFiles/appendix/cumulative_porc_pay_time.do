version 17.0

* Figure OA-6: Percentage of the loan paid over time, by experimental arm.
use "$directorio/DB/Master.dta", clear
keep if inlist(t_producto, 1, 2, 3, 4, 5)
keep t_producto suc_x_dia sum_porcp30_c sum_porcp60_c ///
    sum_porcp90_c sum_porcp105_c
rename t_producto t_prod

* Estimate the arm differences printed at the four payment checkpoints.
foreach day in 30 60 90 105 {
    local variable sum_porcp`day'_c
    replace `variable' = `variable' * 100

    quietly regress `variable' i.t_prod if inlist(t_prod, 1, 2, 4), ///
        vce(cluster suc_x_dia)
    local beta_fee`day' = round(_b[2.t_prod], 0.01)
    local se_fee`day' = round(_se[2.t_prod], 0.01)

    quietly regress `variable' i.t_prod if inlist(t_prod, 1, 3, 5), ///
        vce(cluster suc_x_dia)
    local beta_promise`day' = round(_b[3.t_prod], 0.01)
    local se_promise`day' = round(_se[3.t_prod], 0.01)
}

* Insert zero-payment days into each pawn's history, cumulate payments within
* pawn, and then average the cumulative share by arm and elapsed day.
use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2fv.dta", clear
keep if inlist(clave_movimiento, 1, 3, 4, 5) & !missing(t_producto)
sort prenda fecha_movimiento HoraMovimiento
replace porc_pagos = porc_pagos * 100
collapse (sum) porc_pagos (mean) t_producto, by(prenda dias_inicio)
xtset prenda dias_inicio
tsfill, full
replace porc_pagos = 0 if missing(porc_pagos)
by prenda: gen sum_porc_p = sum(porc_pagos)
by prenda: egen t_prod = mean(t_producto)
collapse (mean) sum_porc_p, by(t_prod dias_inicio)

twoway ///
    (line sum_porc_p dias_inicio if t_prod == 1, lwidth(medthick) ///
        lcolor(black) lpattern(solid) ///
        xline(110, lpattern(dot) lcolor(gs10))) ///
    (line sum_porc_p dias_inicio if t_prod == 2, lwidth(medthick) ///
        lcolor(navy%90) lpattern(dash) xline(35 65 95, lcolor(gs12))) ///
    (line sum_porc_p dias_inicio if t_prod == 4, lwidth(thick) ///
        lcolor(maroon%90) lpattern(shortdash)) ///
    (scatteri 15 29 (9) "{&beta}{subscript:35} = `=round(`beta_fee30',.01)'" ///
        25 59 (9) "{&beta}{subscript:65} = `=round(`beta_fee60',.01)'" ///
        45 89 (9) "{&beta}{subscript:95} = `=round(`beta_fee90',.01)'" ///
        70 105 (3) "{&beta}{subscript:110} = `=round(`beta_fee105',.01)'", ///
        msymbol(i) mlabcolor(black) mlabsize(4)) ///
    (scatteri 12 29 (9) "{&sigma}{subscript:35} = `=round(`se_fee30',.1)'" ///
        22 59 (9) "{&sigma}{subscript:65} = `=round(`se_fee60',.2)'" ///
        42 89 (9) "{&sigma}{subscript:95} = `=round(`se_fee90',.1)'" ///
        67 105 (3) "{&sigma}{subscript:110} = `=round(`se_fee105',.1)'", ///
        msymbol(i) mlabcolor(black) mlabsize(3)), ///
    graphregion(color(white)) xtitle("Elapsed days") ytitle("% of payment") ///
    legend(order(1 "Status-quo" 2 "Mandatory structured" 3 "Choice") ///
        size(small) pos(6) rows(1)) xlabel(0 35 65 95 180 270 320)
graph export "$directorio/Figures/FigureOA6a.pdf", replace

twoway ///
    (line sum_porc_p dias_inicio if t_prod == 1, lwidth(medthick) ///
        lcolor(black) lpattern(solid) ///
        xline(110, lpattern(dot) lcolor(gs10))) ///
    (line sum_porc_p dias_inicio if t_prod == 3, lwidth(medthick) ///
        lcolor(navy%90) lpattern(dash) xline(35 65 95, lcolor(gs12))) ///
    (line sum_porc_p dias_inicio if t_prod == 5, lwidth(thick) ///
        lcolor(maroon%90) lpattern(shortdash)) ///
    (scatteri 15 29 (9) "{&beta}{subscript:35} = `=round(`beta_promise30',.01)'" ///
        25 59 (9) "{&beta}{subscript:65} = `=round(`beta_promise60',.01)'" ///
        45 89 (9) "{&beta}{subscript:95} = `=round(`beta_promise90',.01)'" ///
        70 105 (3) "{&beta}{subscript:110} = `=round(`beta_promise105',.01)'", ///
        msymbol(i) mlabcolor(black) mlabsize(4)) ///
    (scatteri 12 29 (9) "{&sigma}{subscript:35} = `=round(`se_promise30',.1)'" ///
        22 59 (9) "{&sigma}{subscript:65} = `=round(`se_promise60',.2)'" ///
        42 89 (9) "{&sigma}{subscript:95} = `=round(`se_promise90',.1)'" ///
        67 105 (3) "{&sigma}{subscript:110} = `=round(`se_promise105',.1)'", ///
        msymbol(i) mlabcolor(black) mlabsize(3)), ///
    graphregion(color(white)) xtitle("Elapsed days") ytitle("% of payment") ///
    legend(order(1 "Status-quo" 2 "Mandatory promise" 3 "Choice promise") ///
        size(small) pos(6) rows(1)) xlabel(0 35 65 95 180 270 320)
graph export "$directorio/Figures/FigureOA6b.pdf", replace
