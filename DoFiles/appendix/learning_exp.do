version 17.0

* Table OA-9: Effect of Prior Assignment on Subsequent Choice
* This table uses the all-visit pawn-level administrative data directly.
use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta", ///
    clear
keep if inlist(t_producto, 1, 2, 4)
duplicates drop NombrePignorante fecha_inicial suc producto t_producto, force
* Fill a missing product or assignment from another pawn recorded on the same
* borrower visit, then remove any duplicates created by that fill.
sort NombrePignorante fecha_inicial producto, stable
by NombrePignorante fecha_inicial: replace producto = producto[_n - 1] ///
    if missing(producto) & !missing(producto[_n - 1])
by NombrePignorante fecha_inicial: replace t_producto = t_producto[_n - 1] ///
    if missing(t_producto) & !missing(t_producto[_n - 1])
duplicates drop NombrePignorante fecha_inicial suc producto t_producto, force

* Exclude borrowers whose same-day records span branches, because their visit
* sequence cannot be assigned unambiguously to one randomized branch-day.
duplicates tag NombrePignorante fecha_inicial, gen(same_visit)
duplicates tag NombrePignorante fecha_inicial suc, gen(same_branch)
gen different_branch = same_visit == 1 & same_branch == 0
bysort NombrePignorante: egen contaminated = max(different_branch)
drop if contaminated == 1
keep if inlist(visit_number, 1, 2)
bysort NombrePignorante fecha_inicial t_producto: gen within_visit = _n
bysort NombrePignorante: egen multiple_second = total(visit_number == 2)
drop if multiple_second == 2 | within_visit == 2

* Link the first visit to the next chronological visit for each borrower.
sort NombrePignorante fecha_inicial, stable
by NombrePignorante: gen next_product = producto[_n + 1] ///
    if visit_number == 1 & visit_number[_n + 1] == 2
by NombrePignorante: gen next_treatment = t_producto[_n + 1] ///
    if visit_number == 1 & visit_number[_n + 1] == 2
gen choose_nsq_fee_exp = next_product == 5 if next_treatment == 4
* This composite outcome codes borrowers without an observed qualifying return
* as zero, avoiding conditioning the second column on the decision to return.
gen choose_nsq_fee = next_product == 5
keep if visit_number == 1
keep t_producto suc_x_dia choose_nsq_fee_exp choose_nsq_fee

eststo clear
foreach outcome of varlist choose_nsq_fee_exp choose_nsq_fee {
    quietly eststo: regress `outcome' i.t_producto ///
        if inlist(t_producto, 1, 2, 4), vce(cluster suc_x_dia)
    quietly summarize `outcome' if e(sample)
    estadd scalar DepVarMean = r(mean)
}
esttab using "$directorio/Tables/reg_results/TableOA9.csv", ///
    se r2 ${star} b(a2) scalars("DepVarMean DepVarMean") ///
    coeflabels(2.t_producto "Mandatory structured" ///
        4.t_producto "Choice") ///
    keep(2.t_producto 4.t_producto) replace

do "$directorio/DoFiles/render_table.do" TableOA9
