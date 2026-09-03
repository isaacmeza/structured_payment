version 17.0

* Prepare the causal-forest input used by Main Figure 3 and SA Figure/Table 1.

local behavioral_vars fam_pide ahorros t_consis1 t_consis2 ///
    confidence_100 hace_presupuesto tentado rec_cel pres_antes ///
    cta_tanda genero masqueprepa estresado_seguido
local imputed_vars edad faltas c_trans t_llegar `behavioral_vars'

use "$directorio/DB/Master.dta", clear
keep if inlist(t_producto, 1, 2, 4)

gen byte fee_arms = inlist(producto, 2, 4, 5) & !missing(producto)
gen byte insample = !missing(pro_2)
replace cr = -cr

* Require at least one reported behavioral survey response.
egen byte survey_answers = rownonmiss(`behavioral_vars')
drop if survey_answers == 0
drop survey_answers

* Retain missingness indicators and median-impute the forest covariates.
local missing_indicators
foreach variable of local imputed_vars {
    gen byte na_`variable' = missing(`variable')
    quietly summarize `variable', detail
    replace `variable' = r(p50) if missing(`variable')
    local missing_indicators `missing_indicators' na_`variable'
}

local covariates $C0 prestamo `imputed_vars' `missing_indicators'
keep cr fee_arms `covariates' prenda insample
order cr fee_arms `covariates' prenda insample

isid prenda
sort prenda
export delimited "$directorio/_aux/main_figure_03_cate.csv", ///
    replace nolabel
