version 17.0

* Figure 1: Experiment description.
* This script writes the values used by the manually rendered CONSORT figure.

* Experiment and administrative-follow-up dates.
use ///
    "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2fv.dta", ///
    clear
keep if !missing(producto) & clave_movimiento == 4
collapse (min) min_fecha=fecha_inicial (max) max_fecha=fecha_inicial, ///
    by(suc)
merge 1:1 suc using "$directorio/_aux/time_line_aux.dta", ///
    nogen keepusing(min_fecha_suc max_fecha_suc)
gsort -max_fecha -max_fecha_suc
keep in 1
keep min_fecha max_fecha min_fecha_suc max_fecha_suc
gen byte record_type = 2
tempfile timeline
save `timeline'

* Number of randomized branch-days. This is rebuilt here so Figure 1 does not
* depend on either appendix balance-table script having run first.
import excel ///
    "$directorio/Raw/Muestra Aleatoria en Excel con nombres de sucursales.xlsx", ///
    sheet("Muestra Aleatoria2") cellrange(A2:G93) firstrow clear
reshape long t_prod, i(fecha) j(sucursal)
rename fecha f_encuesta
tempfile randomization
save `randomization'

use "$directorio/Raw/Base_Encuestas_Basales_24_05_2013.dta", clear
keep prenda sucursal f_encuesta
foreach variable of varlist sucursal f_encuesta {
    bysort prenda: egen auxiliary = max(`variable')
    replace `variable' = auxiliary
    drop auxiliary
}
bysort prenda: keep if _n == 1
merge m:1 sucursal f_encuesta using `randomization', nogen keep(1 3)
merge 1:1 prenda using ///
    "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta"
replace t_producto = t_prod if _merge == 1
replace t_producto = 6 if f_encuesta < date("9/6/2012", "MDY")
replace fecha_inicial = f_encuesta if _merge == 1
replace suc = sucursal if _merge == 1
keep if inlist(t_producto, 1, 2, 4)
keep suc fecha_inicial t_producto
bysort suc fecha_inicial t_producto: keep if _n == 1
collapse (count) branch_days=suc, by(t_producto)
rename t_producto arm
tempfile branch_days
save `branch_days'

* Loan- and borrower-level survey counts.
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod, 1, 2, 4)
gen byte has_loan_survey = !missing(f_encuesta)
collapse (count) loans=prenda (sum) loan_surveys=has_loan_survey, ///
    by(t_producto)
rename t_producto arm
tempfile loan_counts
save `loan_counts'

use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod, 1, 2, 4)
gen byte num_surveys = !missing(f_encuesta)
collapse (sum) num_surveys, by(NombrePignorante t_producto)
duplicates drop NombrePignorante, force
gen byte has_borrower_survey = num_surveys > 0
collapse (count) borrowers=NombrePignorante ///
    (sum) borrower_surveys=has_borrower_survey, by(t_producto)
rename t_producto arm
merge 1:1 arm using `loan_counts', nogen
merge 1:1 arm using `branch_days', nogen
gen byte record_type = 1
tempfile consort_counts
save `consort_counts'

* Combine the two record types and write the Excel source.
use `timeline', clear
append using `consort_counts'
order record_type arm branch_days loans loan_surveys borrowers ///
    borrower_surveys min_fecha max_fecha min_fecha_suc max_fecha_suc

preserve
keep if record_type == 2
mkmat min_fecha max_fecha min_fecha_suc max_fecha_suc, matrix(timeline_values)
putexcel set "$directorio/Figures/Figure1.xlsx", sheet("exp_arms") modify
putexcel B23 = matrix(timeline_values)
restore

preserve
keep if record_type == 1
sort arm
mkmat branch_days loans loan_surveys, matrix(consort_top)
matrix consort_top = consort_top'
mkmat borrowers borrower_surveys, matrix(consort_bottom)
matrix consort_bottom = consort_bottom'
putexcel set "$directorio/Figures/Figure1.xlsx", sheet("exp_arms") modify
putexcel B15 = matrix(consort_top)
putexcel B19 = matrix(consort_bottom)
restore

confirm file "$directorio/Figures/Figure1.pdf"
