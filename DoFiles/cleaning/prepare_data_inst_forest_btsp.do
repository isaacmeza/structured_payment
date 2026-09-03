version 17.0

* Prepare the instrumental-forest input used by Main Figure 4.

local behavioral_vars fam_pide ahorros t_consis1 t_consis2 ///
    confidence_100 hace_presupuesto tentado rec_cel pres_antes ///
    cta_tanda genero masqueprepa estresado_seguido
local imputed_vars edad faltas c_trans t_llegar `behavioral_vars'

use "$directorio/DB/Master.dta", clear
keep if inlist(t_producto, 1, 2, 4)

replace cr = -cr
gen byte forced = choose_commitment == 1 | t_producto == 2

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

* Preserve the covariate order used by the verified Figure 4 forest.
local covariates $C0 prestamo `imputed_vars' `missing_indicators'

* The former IV regressions were used only to identify complete observations.
egen byte incomplete = rowmiss(cr forced t_producto suc_x_dia `covariates')
drop if incomplete > 0
drop incomplete

keep cr `covariates' forced prenda t_producto suc_x_dia
order cr `covariates' forced prenda t_producto suc_x_dia

isid prenda
sort prenda
export delimited using ///
    "$directorio/_aux/main_figure_04_bootstrap_input.csv", ///
    replace nolabel
