version 17.0

capture program drop oa_censoring_outcomes
program define oa_censoring_outcomes
    version 17.0

    * Reconstruct the administrative outcomes under an assigned final status
    * for loans that had not ended by the close of observation.
    gen des_imp = 1 - def_imp

    * For a censored default within a contractual cycle, assign the endpoint
    * of that 90-day cycle plus the 15-day grace period.
    replace dias_al_default = dias_ultimo_mov ///
        if concluyo_c == 0 & def_imp == 1
    replace dias_al_default = 105 ///
        if dias_ultimo_mov < 90 & concluyo_c == 0 & def_imp == 1
    replace dias_al_default = 210 ///
        if inrange(dias_ultimo_mov, 110, 180) & concluyo_c == 0 & def_imp == 1
    replace dias_al_default = 315 ///
        if inrange(dias_ultimo_mov, 220, 270) & concluyo_c == 0 & def_imp == 1
    replace dias_al_default = 420 ///
        if dias_ultimo_mov > 315 & concluyo_c == 0 & def_imp == 1
    replace dias_al_desempenyo = dias_ultimo_mov ///
        if concluyo_c == 0 & des_imp == 1

    replace sum_p_c = prestamo + sum_inc_int ///
        if concluyo_c == 0 & des_imp == 1
    replace sum_int_c = sum_inc_int if concluyo_c == 0 & des_imp == 1

    * Financial cost equals paid interest and fees after recovery, or total
    * payments plus the lender's implied 30/70 resale margin after default.
    gen double fc_admin = .
    replace fc_admin = sum_int_c + sum_pay_fee_c if des_imp == 1
    replace fc_admin = sum_p_c + prestamo_i * (0.3 / 0.7) if def_imp == 1

    gen double cost_losing_pawn = 0
    replace cost_losing_pawn = sum_p_c - sum_int_c - sum_pay_fee_c ///
        + prestamo_i * (0.3 / 0.7) if def_imp == 1

    gen double downpayment_capital = 0
    replace downpayment_capital = sum_p_c - sum_int_c - sum_pay_fee_c ///
        if def_imp == 1

    gen double cr = fc_admin / prestamo
end

* OA Table 3: censoring-imputation data in canonical pawn order.
use "$directorio/DB/Master.dta", clear
keep prenda t_producto suc_x_dia suc def_c concluyo_c dias_ultimo_mov ///
    dias_al_default dias_al_desempenyo first_pay prestamo mn_p105_c ///
    mn_p210_c dias_primer_pago sum_porcp30_c sum_porcp60_c ///
    sum_porcp90_c sum_porcp105_c sum_porc105_int_c sum_porcp150_c ///
    sum_porcp180_c sum_porcp210_c sum_porc210_int_c sum_p_c ///
    sum_inc_int sum_int_c sum_pay_fee_c prestamo_i

* prenda is unique and fixes the row order independently of how Master.dta was
* last written. Each lasso below also receives its own explicit CV seed.
isid prenda
sort prenda

forvalues control_imputation = 0/1 {
    forvalues mandatory_imputation = 0/1 {
        local panel = cond(`control_imputation' == 0, ///
            cond(`mandatory_imputation' == 0, "a", "b"), ///
            cond(`mandatory_imputation' == 0, "c", "d"))
        preserve
        * Panels a--d apply every combination of recovery/default to censored
        * loans in the status-quo and mandatory-structure arms.
        gen def_imp = def_c
        replace def_imp = `control_imputation' ///
            if t_producto == 1 & concluyo_c == 0
        replace def_imp = `mandatory_imputation' ///
            if t_producto == 2 & concluyo_c == 0
        oa_censoring_outcomes

        eststo clear
        foreach outcome of varlist fc_admin sum_int_c downpayment_capital ///
                cost_losing_pawn def_imp cr {
            quietly eststo: regress `outcome' i.t_producto ///
                if inlist(t_producto, 1, 2), vce(cluster suc_x_dia)
            quietly summarize `outcome' if e(sample) & t_producto == 1
            estadd scalar ContrMean = r(mean)
        }
        esttab using ///
            "$directorio/Tables/reg_results/TableOA3`panel'.csv", ///
            se r2 ${star} b(a2) scalars("ContrMean Control Mean") ///
            coeflabels(2.t_producto "Mandatory structured") ///
            keep(2.t_producto) replace
        restore
    }
}

gen first_pay_porc = first_pay / prestamo
gen mn_porc_p105_c = mn_p105_c / prestamo
gen mn_porc_p210_c = mn_p210_c / prestamo
gen slice = 1 if inrange(dias_ultimo_mov, 0, 220)
replace slice = 2 if dias_ultimo_mov > 220
gen def_pr = .

* Fit separate prediction models before and after day 220 because later loans
* have longer payment histories available. Explicit seeds fix CV selection.
forvalues slice_number = 1/2 {
    if `slice_number' == 1 {
        quietly lasso logit def_c dias_ultimo_mov dias_primer_pago first_pay_porc ///
            sum_porcp30_c sum_porcp60_c sum_porcp90_c sum_porcp105_c ///
            sum_porc105_int_c mn_porc_p105_c prestamo i.suc ///
            if concluyo_c == 1 & slice == `slice_number', rseed(130301)
        quietly predict predf_`slice_number'
    }
    else {
        quietly lasso logit def_c dias_ultimo_mov dias_primer_pago first_pay_porc ///
            sum_porcp30_c sum_porcp60_c sum_porcp90_c sum_porcp105_c ///
            sum_porcp150_c sum_porcp180_c sum_porcp210_c ///
            sum_porc105_int_c sum_porc210_int_c mn_porc_p105_c ///
            mn_porc_p210_c prestamo i.suc ///
            if concluyo_c == 1 & slice == `slice_number', rseed(130302)
        quietly predict predf_`slice_number'
    }
}
forvalues slice_number = 1/2 {
    * Panel e classifies a censored loan as default when its fitted probability
    * is at least one half.
    quietly replace def_pr = (predf_`slice_number' >= 0.5) ///
        if slice == `slice_number'
}

gen def_imp = def_c
replace def_imp = def_pr if concluyo_c == 0
oa_censoring_outcomes

eststo clear
foreach outcome of varlist fc_admin sum_int_c downpayment_capital ///
        cost_losing_pawn def_imp cr {
    quietly eststo: regress `outcome' i.t_producto if inlist(t_producto, 1, 2, 4), ///
        vce(cluster suc_x_dia)
    quietly summarize `outcome' if e(sample) & t_producto == 1
    estadd scalar ContrMean = r(mean)
}
esttab using "$directorio/Tables/reg_results/TableOA3e.csv", ///
    se r2 ${star} b(a2) scalars("ContrMean Control Mean") ///
    coeflabels(2.t_producto "Mandatory structured" ///
        4.t_producto "Choice") ///
    keep(2.t_producto 4.t_producto) replace

do "$directorio/DoFiles/render_table.do" TableOA3
