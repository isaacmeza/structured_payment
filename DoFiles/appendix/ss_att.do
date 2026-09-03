version 17.0

* OA Table 1: attrition and administrative balance data.
import excel "$directorio/Raw/Muestra Aleatoria en Excel con nombres de sucursales.xlsx", ///
    sheet("Muestra Aleatoria2") cellrange(A2:G93) firstrow clear
reshape long t_prod, i(fecha) j(sucursal)
rename fecha f_encuesta
tempfile randomization
save `randomization'

use "$directorio/Raw/Base_Encuestas_Basales_24_05_2013.dta", clear
keep Enc f_encuesta prenda sucursal
destring Enc, replace force
* Consolidate repeated survey rows to one record per pawn before matching.
foreach variable of varlist Enc f_encuesta sucursal {
    bysort prenda: egen auxiliary = max(`variable')
    replace `variable' = auxiliary
    drop auxiliary
}
bysort prenda: keep if _n == 1
merge m:1 sucursal f_encuesta using `randomization', nogen keep(1 3)
merge 1:1 prenda using ///
    "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta", ///
    keepusing(suc prestamo_i fecha_inicial fecha_movimiento HoraMovimiento ///
        NombrePignorante t_producto)

replace t_producto = t_prod if _merge == 1
replace t_producto = 6 if f_encuesta < date("9/6/2012", "MDY")
drop t_prod
replace fecha_inicial = f_encuesta if _merge == 1
replace suc = sucursal if _merge == 1

* A borrower can have several matched pawn records. Count take-up only once per
* borrower, using the unique pawn identifier as a deterministic tie-breaker.
gen byte takeup = (_merge == 3) if inlist(_merge, 1, 3)
sort NombrePignorante takeup prenda
by NombrePignorante: gen long takeup_record = _n
replace takeup = . if takeup_record > 1 & takeup == 1
drop takeup_record

* Build the final table data directly. Each posted row corresponds to one row
* in OA Table 1; the renderer owns labels, rounding, and presentation.
tempname table_post takeup_stats
tempfile table_data
postfile `table_post' str32 statistic double control double mandatory ///
    double choice double p_value using `table_data', replace

quietly orth_out takeup if inlist(t_producto, 1, 2, 4), ///
    by(t_producto) overall se vce(cluster suc) count
matrix `takeup_stats' = r(matrix)

quietly regress takeup ibn.t_producto if inlist(t_producto, 1, 2, 4), ///
    nocons r cluster(suc)
quietly test 1.t_producto == 2.t_producto == 4.t_producto
local takeup_joint_p = r(p)

post `table_post' ("takeup_mean") ///
    (el(`takeup_stats', 1, 1)) (el(`takeup_stats', 1, 2)) ///
    (el(`takeup_stats', 1, 3)) (`takeup_joint_p')
post `table_post' ("takeup_se") ///
    (el(`takeup_stats', 2, 1)) (el(`takeup_stats', 2, 2)) ///
    (el(`takeup_stats', 2, 3)) (.)

drop if missing(t_producto)

preserve
sort suc fecha_movimiento HoraMovimiento NombrePignorante prenda, stable
duplicates drop NombrePignorante prenda suc fecha_inicial, force
collapse (count) num_pawns = prenda, by(suc fecha_inicial t_producto)
tempfile num_pawns
save `num_pawns'
restore

sort NombrePignorante suc fecha_inicial
by NombrePignorante suc fecha_inicial: gen num_pawns_borr = _N ///
    if !missing(NombrePignorante)

sort suc fecha_movimiento HoraMovimiento NombrePignorante prenda, stable
duplicates drop NombrePignorante prenda suc fecha_inicial ///
    if !missing(NombrePignorante), force
duplicates drop Enc f_encuesta if missing(NombrePignorante), force
duplicates drop NombrePignorante suc fecha_inicial ///
    if !missing(NombrePignorante), force
collapse (count) num_borrowers = NombrePignorante ///
    (mean) num_pawns_borr prestamo_i ///
    (sum) total_borrowed = prestamo_i, ///
    by(suc fecha_inicial t_producto)
merge 1:1 suc fecha_inicial t_producto using `num_pawns', nogen

foreach variable of varlist num_borrowers num_pawns_borr num_pawns {
    * Remove the upper one-percent tail defined within the choice arm.
    quietly summarize `variable' if t_producto == 4, detail
    replace `variable' = . if `variable' > r(p99)
}

keep t_producto suc num_borrowers num_pawns_borr num_pawns prestamo_i ///
    total_borrowed
order t_producto suc num_borrowers num_pawns_borr ///
    num_pawns prestamo_i total_borrowed

* The output names are stable table identifiers rather than internal variable
* names. Mean and standard-error rows come from the clustered orth_out results;
* median rows reproduce the reported quantile regressions.
local outcomes num_borrowers num_pawns_borr num_pawns prestamo_i total_borrowed
local table_names num_borrowers num_pawns_borrower num_pawns average_loan ///
    total_borrowed
local number_outcomes : word count `outcomes'
tempname summary_stats
forvalues index = 1/`number_outcomes' {
    local outcome : word `index' of `outcomes'
    local table_name : word `index' of `table_names'

    quietly orth_out `outcome' if inlist(t_producto, 1, 2, 4), by(t_producto) ///
        overall se vce(cluster suc) bdec(2) count
    matrix `summary_stats' = r(matrix)

    quietly regress `outcome' ibn.t_producto ///
        if inlist(t_producto, 1, 2, 4), nocons r cluster(suc)
    quietly test 1.t_producto == 2.t_producto == 4.t_producto
    local p_value = r(p)

    post `table_post' ("`table_name'_mean") ///
        (el(`summary_stats', 1, 1)) (el(`summary_stats', 1, 2)) ///
        (el(`summary_stats', 1, 3)) (`p_value')
    post `table_post' ("`table_name'_se") ///
        (el(`summary_stats', 2, 1)) (el(`summary_stats', 2, 2)) ///
        (el(`summary_stats', 2, 3)) (.)

    quietly qreg `outcome' i.t_producto if inlist(t_producto, 1, 2, 4), ///
        q(0.5) vce(robust)
    local median_control = _b[_cons]
    local median_mandatory = _b[_cons] + _b[2.t_producto]
    local median_choice = _b[_cons] + _b[4.t_producto]
    quietly test 1.t_producto == 2.t_producto == 4.t_producto
    local median_p_value = r(p)

    post `table_post' ("`table_name'_median") ///
        (`median_control') (`median_mandatory') (`median_choice') ///
        (`median_p_value')
}

* The table's observation counts are randomized branch-days remaining after the
* reported upper-tail exclusions, not the loan-level take-up sample size.
quietly count if t_producto == 1 & !missing(num_borrowers)
local observations_control = r(N)
quietly count if t_producto == 2 & !missing(num_borrowers)
local observations_mandatory = r(N)
quietly count if t_producto == 4 & !missing(num_borrowers)
local observations_choice = r(N)
post `table_post' ("observations") (`observations_control') ///
    (`observations_mandatory') (`observations_choice') (.)
postclose `table_post'

* Enforce the renderer's fixed row contract before replacing the final CSV.
use `table_data', clear
local expected_rows takeup_mean takeup_se num_borrowers_mean ///
    num_borrowers_se num_borrowers_median num_pawns_borrower_mean ///
    num_pawns_borrower_se num_pawns_borrower_median num_pawns_mean ///
    num_pawns_se num_pawns_median average_loan_mean average_loan_se ///
    average_loan_median total_borrowed_mean total_borrowed_se ///
    total_borrowed_median observations
assert _N == 18
forvalues row = 1/18 {
    local expected : word `row' of `expected_rows'
    assert statistic == "`expected'" in `row'
}
isid statistic
order statistic control mandatory choice p_value
format control mandatory choice p_value %24.17g

capture mkdir "$directorio/Tables"
capture mkdir "$directorio/Tables/reg_results"
export delimited using "$directorio/Tables/reg_results/TableOA1.csv", ///
    replace datafmt

do "$directorio/DoFiles/render_table.do" TableOA1
