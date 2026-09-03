version 17.0

* Table OA-6: Effects on Repeat Pawning
use "$directorio/DB/Master.dta", clear
* Repeat-loan outcomes are borrower-level. Keep the lowest pawn identifier when
* a first visit contains more than one pawn so the retained row is deterministic.
sort NombrePignorante prenda
duplicates drop NombrePignorante, force
gen reincidence_des = !missing(days_second_pawns) ///
    if first_pawn == 1 & !missing(first_dias_des)
gen reincidence_ar = !missing(days_second_pawns) & days_second_pawns >= 90 ///
    if first_pawn == 1
gen reincidence_br = !missing(days_second_pawns) & days_second_pawns <= 90 ///
    if first_pawn == 1
keep t_producto suc_x_dia reincidence reincidence_ar reincidence_br ///
    reincidence_other reincidence_des

eststo clear
foreach outcome of varlist reincidence reincidence_ar reincidence_br ///
        reincidence_other reincidence_des {
    quietly eststo: regress `outcome' i.t_producto ///
        if inlist(t_producto, 1, 2, 4), vce(cluster suc_x_dia)
    quietly summarize `outcome' if e(sample) & t_producto == 1
    estadd scalar ContrMean = r(mean)
}
esttab using "$directorio/Tables/reg_results/TableOA6.csv", ///
    se r2 ${star} b(a2) scalars("ContrMean Control Mean") ///
    coeflabels(2.t_producto "Mandatory structured" ///
        4.t_producto "Choice") ///
    keep(2.t_producto 4.t_producto) replace

do "$directorio/DoFiles/render_table.do" TableOA6
