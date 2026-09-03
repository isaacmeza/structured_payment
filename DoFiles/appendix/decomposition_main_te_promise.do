version 17.0

* Table OA-5: Effects of Promise on Financial Cost
use "$directorio/DB/Master.dta", clear
keep t_producto suc_x_dia fc_admin sum_int_c sum_pay_fee_c ///
    downpayment_capital cost_losing_pawn def_c cr

* Estimate each outcome for the control, mandatory-promise, and
* choice-of-promise arms; inference clusters by randomized branch-day.
eststo clear
foreach outcome of varlist fc_admin sum_int_c sum_pay_fee_c ///
        downpayment_capital cost_losing_pawn def_c cr {
    quietly eststo: regress `outcome' i.t_producto ///
        if inlist(t_producto, 1, 3, 5), vce(cluster suc_x_dia)
    quietly summarize `outcome' if e(sample) & t_producto == 1
    estadd scalar ContrMean = r(mean)
}
esttab using "$directorio/Tables/reg_results/TableOA5.csv", ///
    se r2 ${star} b(a2) scalars("ContrMean Control Mean") ///
    coeflabels(3.t_producto "Promise Mandate" ///
        5.t_producto "Promise Choice") ///
    keep(3.t_producto 5.t_producto) replace

do "$directorio/DoFiles/render_table.do" TableOA5
