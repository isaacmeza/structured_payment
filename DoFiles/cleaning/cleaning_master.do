version 17.0

* Clean the baseline survey, merge it with the pawn-level administrative data,
* and build the analysis dataset used by the main paper and appendices.
*
* Inputs:
*   Raw/Base_Encuestas_Basales_24_05_2013.dta
*   DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta
*
* Output:
*   DB/Master.dta

use "$directorio/Raw/Base_Encuestas_Basales_24_05_2013.dta", clear

* Retain the survey responses that enter a reported variable or imputation.
keep prenda f_encuesta prenda_tipo pr_recup val_pren genero edad educacion ///
    fam_pide t_consis1 f_estres razon pres_antes plan_gasto ahorros ///
    cta_tanda fam_comun c_trans t_llegar tempt renta comida medicina luz ///
    gas telefono agua t_consis2 rec_cel

* Harmonize repeated survey records at the pawn level, then retain one row.
foreach variable of varlist _all {
    if "`variable'" != "prenda" {
        bysort prenda: egen auxiliary = max(`variable')
        replace `variable' = auxiliary
        drop auxiliary
    }
}
bysort prenda: keep if _n == 1
drop if missing(prenda)
isid prenda

* Attach the administrative outcomes. Survey fields remain missing for pawns
* without a matched baseline interview.
merge 1:1 prenda using ///
    "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2", ///
    keep(2 3) nogen

* Recover selected survey answers across pawns belonging to the same borrower.
foreach variable of varlist genero edad educacion fam_pide f_estres ///
        pres_antes plan_gasto c_trans t_llegar tempt {
    bysort NombrePignorante: egen auxiliary = max(`variable')
    replace `variable' = auxiliary
    drop auxiliary
}

********************************************************************************
* Subjective pawn value
********************************************************************************

* Enforce the loan-implied lower bound and winsorize at the 99th percentile.
replace val_pren = prestamo_i / 0.7 ///
    if val_pren < prestamo_i / 0.7 & !missing(val_pren)
egen val_pren99 = pctile(val_pren), p(99)
replace val_pren = val_pren99 if val_pren > val_pren99 & !missing(val_pren)
drop val_pren99

* First impute with pawn type and stated reason; use loan amount alone for
* observations whose categorical predictors remain missing.
reg val_pren prestamo_i i.prenda_tipo i.razon, r
predict val_pren_pr
replace val_pren = val_pren_pr if missing(val_pren)
replace val_pren = prestamo_i / 0.7 ///
    if val_pren < prestamo_i / 0.7 & !missing(val_pren)

gen val_pren_orig = val_pren
* 2.14489 is the upper 95% CI bound for prestamo_i in the robust regression below.
replace val_pren_orig = 2.14489 * prestamo_i ///
    if val_pren_orig > 2.14489 * prestamo_i & !missing(val_pren_orig)

reg val_pren prestamo_i, r
drop val_pren_pr
predict val_pren_pr
replace val_pren = val_pren_pr if missing(val_pren)
replace val_pren = 2.14489 * prestamo_i ///
    if val_pren > 2.14489 * prestamo_i & !missing(val_pren)
drop val_pren_pr

********************************************************************************
* Alternative financial-cost measures
********************************************************************************

* Subjective-value financial cost.
gen double fc_survey = .
replace fc_survey = sum_int_c + sum_pay_fee_c if des_i_c == 1
replace fc_survey = sum_p_c + val_pren - prestamo_i if def_i_c == 1
replace fc_survey = sum_int_c + sum_pay_fee_c ///
    if def_i_c == 0 & des_i_c == 0
gen double cr_survey = fc_survey / prestamo_i

* Table OA-4 construction: impute missing transport cost
* with the pooled mean over nonmissing pawn rows after borrower-wide recovery.
summarize c_trans
replace c_trans = r(mean) if missing(c_trans)

* Add one full 2012 Mexico City minimum daily wage (MXN 62.33, geographic
* area A) to the transport cost for each branch visit.
gen trans_cost = (c_trans + 62.33) * num_v

gen double fc_tc = .
replace fc_tc = sum_int_c + sum_pay_fee_c + trans_cost if des_i_c == 1
replace fc_tc = sum_p_c + prestamo_i * (0.3 / 0.7) + trans_cost ///
    if def_i_c == 1
replace fc_tc = sum_int_c + sum_pay_fee_c + trans_cost ///
    if def_i_c == 0 & des_i_c == 0
gen double cr_tc = fc_tc / prestamo_i

* Financial cost excluding interest.
gen double fc_int = .
replace fc_int = sum_pay_fee_c if des_i_c == 1
replace fc_int = sum_p_c + prestamo_i * (0.3 / 0.7) if def_i_c == 1
replace fc_int = sum_pay_fee_c if def_i_c == 0 & des_i_c == 0
gen double cr_int = fc_int / prestamo_i

* Fully adjusted cost: subjective value plus transaction costs, net of interest.
gen double fc_fa = .
replace fc_fa = sum_pay_fee_c + trans_cost if des_i_c == 1
replace fc_fa = sum_p_c + val_pren - prestamo_i + trans_cost - sum_int_c ///
    if def_i_c == 1
replace fc_fa = sum_pay_fee_c + trans_cost if def_i_c == 0 & des_i_c == 0
gen double cr_fa = fc_fa / prestamo_i

********************************************************************************
* Survey covariates and fixed effects
********************************************************************************

gen masqueprepa = educacion >= 3 if !missing(educacion)
gen estresado_seguido = f_estres < 3 if !missing(f_estres)
gen hace_presupuesto = plan_gasto == 2 if !missing(plan_gasto)

gen pb = t_consis1 == 0 & t_consis2 == 1 ///
    if !missing(t_consis1, t_consis2)
replace pb = 0 if t_consis2 == 0 & missing(pb)
replace pb = 0 if t_consis1 == 1 & missing(pb)

egen faltas = rowtotal(renta comida medicina luz gas telefono agua)
egen answered_expenses = rownonmiss(renta comida medicina luz gas telefono agua)
replace faltas = faltas / answered_expenses
drop answered_expenses

gen tentado = tempt >= 2 if !missing(tempt)

summarize c_trans, detail
gen low_cost = c_trans <= r(p50) if !missing(c_trans)
summarize t_llegar, detail
gen low_time = t_llegar <= r(p50) if !missing(t_llegar)

* Branch and origination-day fixed effects used by $C0.
foreach variable of varlist dow suc {
    tab `variable', gen(dummy_`variable')
}
drop dummy_dow1 dummy_suc1

gen confidence_100 = pr_recup == 100 if !missing(pr_recup)

********************************************************************************
* Reported outcomes and compact analysis dataset
********************************************************************************

* Reduce dataset size without changing values before creating final variables.
compress

* Define main outcomes
gen des_c = des_i_c
label var des_c "Recovery"
gen def_c = def_i_c
label var def_c "Default"
gen double fc_admin = fc_i_admin
label var fc_admin "Financial cost (appraised value)"
gen double cr = cr_i
label var cr "CR (appraised value)"
gen double prestamo = prestamo_i
label var prestamo "Loan"

label var fc_survey "Financial cost (subj. value)"
label var cr_survey "CR (subj. value)"
label var fc_tc "Financial cost + trans. cost"
label var cr_tc "CR + trans. cost"
label var fc_int "Financial cost - interest"
label var cr_int "CR - interest"
label var fc_fa "Financial cost (appraised value)"
label var cr_fa "CR (fully adjusted)"

* The analysis sample is the borrower's first pawnshop visit. A visit may
* contain multiple pawns; reported inference clusters at the branch-day level.
keep if visit_number == 1
keep prenda NombrePignorante f_encuesta fecha_inicial suc suc_x_dia ///
    t_producto producto pro_2 pro_6 pro_7 choose_commitment concluyo_c ///
    ref_c sum_inc_int first_pawn first_dias_des days_second_pawns ///
    reincidence reincidence_other first_pay sum_p_c sum_int_c ///
    sum_pay_fee_c pays_c mn_p105_c mn_p210_c sum_porcp_c ///
    sum_porcp30_c sum_porcp60_c sum_porcp90_c sum_porcp105_c ///
    sum_porcp150_c sum_porcp180_c sum_porcp210_c sum_porc105_int_c ///
    sum_porc210_int_c num_p num_v dias_primer_pago dias_ultimo_mov ///
    dias_al_desempenyo dias_al_default zero_pay_default ///
    cost_losing_pawn downpayment_capital prestamo_i pr_recup genero edad ///
    fam_pide pres_antes ahorros cta_tanda fam_comun c_trans t_llegar ///
    t_consis1 t_consis2 rec_cel val_pren_orig estresado_seguido ///
    masqueprepa hace_presupuesto pb faltas tentado low_cost low_time ///
    confidence_100 des_c def_c fc_admin cr prestamo fc_survey cr_survey ///
    fc_tc cr_tc fc_int cr_int fc_fa cr_fa dummy_dow2-dummy_dow6 ///
    dummy_suc2-dummy_suc6

isid prenda
sort prenda
save "$directorio/DB/Master.dta", replace
