version 17.0

* Table OA-4: Effects on more comprehensive cost measures
use "$directorio/DB/Master.dta", clear
keep if inlist(t_producto, 1, 2, 4)
keep t_producto suc_x_dia fc_admin fc_survey fc_tc fc_int fc_fa ///
    cr cr_survey cr_tc cr_int cr_fa

eststo clear
foreach outcome of varlist fc_admin fc_survey fc_tc fc_int fc_fa ///
    cr cr_survey cr_tc cr_int cr_fa {
    quietly eststo: regress `outcome' i.t_producto, vce(cluster suc_x_dia)
    quietly summarize `outcome' if e(sample) & t_producto == 1
    estadd scalar ContrMean = r(mean)
}

esttab using "$directorio/Tables/reg_results/TableOA4.csv", ///
    se r2 ${star} b(a2) scalars("ContrMean Control Mean") replace ///
    coeflabels(2.t_producto "Mandatory structured" ///
        4.t_producto "Choice") ///
    keep(2.t_producto 4.t_producto)

do "$directorio/DoFiles/render_table.do" TableOA4
