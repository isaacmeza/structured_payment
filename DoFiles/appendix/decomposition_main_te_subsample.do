version 17.0

* Table OA-8: Effects on Financial Cost by selected subsample of survey respondents
use "$directorio/DB/Master.dta", clear
* The top panel retains borrowers observed on at least one covariate used by the
* CATE analysis; the bottom panel retains anyone linked to a survey interview.
gen cate_subsample = !(missing(fam_pide) & missing(ahorros) & ///
    missing(t_consis1) & missing(t_consis2) & missing(confidence_100) & ///
    missing(hace_presupuesto) & missing(tentado) & missing(rec_cel) & ///
    missing(pres_antes) & missing(cta_tanda) & missing(genero) & ///
    missing(masqueprepa) & missing(estresado_seguido))
gen survey_subsample = !missing(f_encuesta)
keep t_producto suc_x_dia cate_subsample survey_subsample fc_admin sum_int_c ///
    sum_pay_fee_c downpayment_capital cost_losing_pawn def_c cr

eststo clear
foreach sample in cate_subsample survey_subsample {
    foreach outcome of varlist fc_admin sum_int_c sum_pay_fee_c ///
            downpayment_capital cost_losing_pawn def_c cr {
        quietly eststo: regress `outcome' i.t_producto ///
            if inlist(t_producto, 1, 2, 4) & `sample' == 1, ///
            vce(cluster suc_x_dia)
        quietly summarize `outcome' if e(sample) & t_producto == 1
        estadd scalar ContrMean = r(mean)
    }
}
esttab using "$directorio/Tables/reg_results/TableOA8.csv", ///
    se r2 ${star} b(a2) scalars("ContrMean Control Mean") ///
    coeflabels(2.t_producto "Mandatory structured" ///
        4.t_producto "Choice") ///
    keep(2.t_producto 4.t_producto) replace

do "$directorio/DoFiles/render_table.do" TableOA8
