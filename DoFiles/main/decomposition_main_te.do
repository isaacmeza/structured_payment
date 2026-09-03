version 17.0

* Table 1: Effects on Financial Cost.
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod, 1, 2, 4)
keep t_prod suc_x_dia fc_admin sum_int_c sum_pay_fee_c ///
    downpayment_capital cost_losing_pawn def_c cr

eststo clear
foreach outcome of varlist fc_admin sum_int_c sum_pay_fee_c ///
        downpayment_capital cost_losing_pawn def_c cr {
    eststo: regress `outcome' i.t_prod, vce(cluster suc_x_dia)
    quietly summarize `outcome' if e(sample) & t_prod == 1
    estadd scalar ContrMean = r(mean)
}

esttab using "$directorio/Tables/reg_results/Table1.csv", ///
    se r2 ${star} b(a2) scalars("ContrMean Control Mean") ///
    coeflabels(2.t_producto "Mandatory structured" ///
        4.t_producto "Choice") ///
    keep(2.t_producto 4.t_producto) replace

do "$directorio/DoFiles/render_table.do" Table1
