version 17.0

* Figure OA-12: Determinants of sure confidence.
use "$directorio/DB/Master.dta", clear
keep if inlist(t_producto, 1, 2, 4)
keep confidence_100 edad fam_pide fam_comun faltas ahorros ///
    pb t_consis1 hace_presupuesto tentado rec_cel pres_antes cta_tanda ///
    genero masqueprepa estresado_seguido low_cost low_time

quietly summarize edad
replace edad = (edad - r(mean)) / r(sd)
* Reverse the time-consistency indicator so higher values denote impatience.
gen impatience = 1 - t_consis1
local family fam_pide fam_comun
local income faltas ahorros
local self_control pb impatience hace_presupuesto tentado rec_cel
local experience pres_antes cta_tanda
local other edad genero masqueprepa estresado_seguido low_cost low_time
local covariates `family' `income' `self_control' `experience' `other'
quietly regress confidence_100 `covariates', vce(robust)
local df = e(df_r)
* Store only the coefficient and robust 95% confidence interval plotted below.
matrix estimates = J(17, 3, .)
local row = 1
foreach variable of varlist `covariates' {
    matrix estimates[`row', 1] = _b[`variable']
    matrix estimates[`row', 2] = ///
        _b[`variable'] - invttail(`df', 0.025) * _se[`variable']
    matrix estimates[`row', 3] = ///
        _b[`variable'] + invttail(`df', 0.025) * _se[`variable']
    local ++row
}
matrix colnames estimates = beta low high
matrix rownames estimates = "Fam asks money" "Common asks money" ///
    "Trouble paying bills" "Savings" "Present bias" "Impatience" ///
    "Makes budget" "Tempted" "Want SMS Reminder" "Pawn before" ///
    "Rosca participant" "Age" "Female" "More high school" "Stressed" ///
    "< med transport time" "< med transport cost"
coefplot (matrix(estimates[, 1]), offset(0.06) ///
    ci((estimates[, 2] estimates[, 3])) ciopts(lcolor(gs4))), ///
    headings("Fam asks money" = "{bf:Family}" ///
        "Trouble paying bills" = "{bf:Income}" ///
        "Present bias" = "{bf:Self Control}" ///
        "Pawn before" = "{bf:Experience}" ///
        "Age" = "{bf:Other}", labsize(medium)) ///
    legend(off) xline(0) graphregion(color(white))
graph export "$directorio/Figures/FigureOA12.pdf", replace
