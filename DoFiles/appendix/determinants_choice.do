version 17.0

* Figure OA-4: Determinants of choice.
use "$directorio/DB/Master.dta", clear
keep if inlist(t_producto, 1, 2, 4)
keep choose_commitment edad pr_recup t_consis1 fam_pide fam_comun ///
    faltas ahorros hace_presupuesto tentado rec_cel pb confidence_100 ///
    pres_antes cta_tanda genero masqueprepa estresado_seguido ///
    low_cost low_time

* Standardize the two continuous covariates so their coefficients are measured
* per standard deviation; all remaining covariates are indicators.
foreach variable of varlist edad pr_recup {
    quietly summarize `variable'
    replace `variable' = (`variable' - r(mean)) / r(sd)
}
gen impatience = 1 - t_consis1

local familia fam_pide fam_comun
local ingreso faltas ahorros
local self_control impatience hace_presupuesto tentado rec_cel
local behavioral pb confidence_100
local experiencia pres_antes cta_tanda pr_recup
local otros edad genero masqueprepa estresado_seguido low_cost low_time
local alpha = 0.05

quietly regress choose_commitment `familia' `ingreso' `self_control' ///
    `behavioral' `experiencia' `otros', vce(robust)
local df = e(df_r)

* Store only the coefficient and confidence limits displayed by coefplot.
matrix blp = J(19, 3, .)
local row = 1
foreach variable of varlist `familia' `ingreso' `self_control' `behavioral' ///
        `experiencia' `otros' {
    matrix blp[`row', 1] = _b[`variable']
    matrix blp[`row', 2] = ///
        _b[`variable'] - invttail(`df', `alpha' / 2) * _se[`variable']
    matrix blp[`row', 3] = ///
        _b[`variable'] + invttail(`df', `alpha' / 2) * _se[`variable']
    local ++row
}

matrix colnames blp = beta lo hi
matrix rownames blp = "Fam asks money" "Common asks money" ///
    "Trouble paying bills" "Savings" "Impatience" "Makes budget" ///
    "Tempted" "Want SMS Reminder" "Present bias" "Sure confident" ///
    "Pawn before" "Rosca participant" "Prob recovery" "Age" "Female" ///
    "More high school" "Stressed" "< med transport time" ///
    "< med transport cost"

coefplot (matrix(blp[, 1]), offset(0.06) ci((blp[, 2] blp[, 3])) ///
    ciopts(lcolor(gs4))), ///
    headings("Fam asks money" = "{bf:Family}" ///
        "Trouble paying bills" = "{bf:Income}" ///
        "Pawn before" = "{bf:Experience}" ///
        "Present bias" = "{bf:Behavioral}" ///
        "Age" = "{bf:Other}", labsize(medium)) ///
    xline(0) graphregion(color(white))
graph export "$directorio/Figures/FigureOA4.pdf", replace
