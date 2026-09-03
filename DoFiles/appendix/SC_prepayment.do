version 17.0

* Figure OA-15: Comparing the Effect of Structure on Prepayment
* The required argument is the number of clustered bootstrap draws.
args replications extra_argument
if "`replications'" == "" | "`extra_argument'" != "" {
    display as error ///
        "Usage: do DoFiles/appendix/SC_prepayment.do replications"
    exit 198
}
capture confirm integer number `replications'
if _rc {
    display as error "Bootstrap replications must be a positive integer."
    exit 198
}
if `replications' < 1 {
    display as error "Bootstrap replications must be a positive integer."
    exit 198
}

* Attach the borrower confidence measure once, before repeatedly loading the
* compact transaction panel inside the bootstrap.
use "$directorio/DB/Master.dta", clear
keep prenda confidence_100
isid prenda
tempfile confidence
save `confidence'

use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2fv.dta", clear
keep suc_x_dia clave_movimiento t_producto prenda fecha_movimiento ///
    HoraMovimiento porc_pagos dias_inicio
* Cluster resampling precedes the analysis filters. Retain unmatched raw rows
* and restore their order so pre-merging confidence does not change that frame.
gen long transaction_order = _n
merge m:1 prenda using `confidence', keep(1 3) nogen
sort transaction_order
drop transaction_order
tempfile transactions
save `transactions'

capture program drop oa15_did
program define oa15_did
    version 17.0

    keep if inlist(clave_movimiento, 1, 3, 4, 5) & !missing(t_producto)
    keep if inlist(t_producto, 1, 2)
    sort prenda fecha_movimiento HoraMovimiento
    replace porc_pagos = 100 * porc_pagos
    collapse (sum) porc_pagos (mean) t_producto confidence_100, ///
        by(prenda dias_inicio)
    xtset prenda dias_inicio
    tsfill, full
    replace porc_pagos = 0 if missing(porc_pagos)
    by prenda: gen cumulative_payment = sum(porc_pagos)
    by prenda: egen treatment = mean(t_producto)
    by prenda: egen sure_confident = mean(confidence_100)
    by prenda: gen makes_any_pp = 100 * (cumulative_payment > 0)
    by prenda: gen pays_today = porc_pagos > 0
    * The second outcome flags payment of more than one-third of the loan in a
    * seven-day window centered on each elapsed day.
    by prenda: gen pays_around = pays_today == 1 | ///
        pays_today[_n - 1] == 1 | pays_today[_n - 2] == 1 | ///
        pays_today[_n - 3] == 1 | pays_today[_n + 1] == 1 | ///
        pays_today[_n + 2] == 1 | pays_today[_n + 3] == 1
    by prenda: gen makes_pp_third = 100 * (pays_around == 1 & ///
        (porc_pagos > 33 | porc_pagos[_n - 1] > 33 | ///
        porc_pagos[_n - 2] > 33 | porc_pagos[_n - 3] > 33 | ///
        porc_pagos[_n + 1] > 33 | porc_pagos[_n + 2] > 33 | ///
        porc_pagos[_n + 3] > 33))
    collapse (mean) makes_any_pp makes_pp_third, ///
        by(treatment sure_confident dias_inicio)
    drop if missing(sure_confident)
    keep dias_inicio treatment sure_confident makes_any_pp makes_pp_third

    preserve
    keep if treatment == 1
    reshape wide makes_any_pp makes_pp_third, ///
        i(dias_inicio) j(sure_confident)
    tempfile control
    save `control'
    restore

    keep if treatment == 2
    reshape wide makes_any_pp makes_pp_third, ///
        i(dias_inicio) j(sure_confident)
    append using `control'
    * First difference sure-confident minus other borrowers within each arm;
    * then difference those gaps between mandatory structure and control.
    gen confidence_makes_any_pp = makes_any_pp1 - makes_any_pp0
    gen confidence_makes_pp_third = makes_pp_third1 - makes_pp_third0
    drop makes_any_pp0 makes_any_pp1 makes_pp_third0 makes_pp_third1
    reshape wide confidence_makes_any_pp confidence_makes_pp_third, ///
        i(dias_inicio) j(treatment)
    gen difference_makes_any_pp = ///
        confidence_makes_any_pp2 - confidence_makes_any_pp1
    gen difference_makes_pp_third = ///
        confidence_makes_pp_third2 - confidence_makes_pp_third1
    keep if dias_inicio <= 90
    keep dias_inicio difference_makes_any_pp difference_makes_pp_third
end

* Resample randomized branch-days with replacement. One fixed sequence supplies
* draws for both outcomes, producing reproducible pointwise 90% intervals.
set seed 1
forvalues replication = 1/`replications' {
    quietly {
        use `transactions', clear
        bsample, cluster(suc_x_dia)
        oa15_did
        rename difference_makes_any_pp draw_makes_any_pp_`replication'
        rename difference_makes_pp_third draw_makes_pp_third_`replication'
        tempfile draw_`replication'
        save `draw_`replication''
    }
}

quietly {
    use `transactions', clear
    oa15_did
    forvalues replication = 1/`replications' {
        merge 1:1 dias_inicio using `draw_`replication'', nogen
        erase `draw_`replication''
    }
    foreach outcome in makes_pp_third makes_any_pp {
        egen ci_low_`outcome' = rowpctile(draw_`outcome'_*), p(5)
        egen ci_high_`outcome' = rowpctile(draw_`outcome'_*), p(95)
    }
}

foreach outcome in makes_pp_third makes_any_pp {
    preserve
    keep dias_inicio difference_`outcome' ci_low_`outcome' ci_high_`outcome'
    rename (difference_`outcome' ci_low_`outcome' ci_high_`outcome') ///
        (difference_in_difference ci_low ci_high)
    twoway (rarea ci_low ci_high dias_inicio, color(ltblue%40)) ///
        (line difference_in_difference dias_inicio, ///
            lwidth(medthick) lcolor(navy)), ///
        xlabel(0 30 60 90) yline(0, lwidth(medthick) lcolor(black)) ///
        xtitle("Elapsed days") ytitle("DiD (pp)") legend(off)
    local graph_file "$directorio/Figures/FigureOA15b.pdf"
    if "`outcome'" == "makes_any_pp" {
        local graph_file "$directorio/Figures/FigureOA15a.pdf"
    }
    graph export "`graph_file'", replace
    restore
}
capture program drop oa15_did
