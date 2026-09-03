version 17.0

* Table 2: Effects on intermediate outcomes.
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod, 1, 2, 4)
keep t_prod suc_x_dia pays_c def_c first_pay prestamo num_v ///
    sum_porcp_c zero_pay_default des_c dias_primer_pago ///
    dias_ultimo_mov dias_al_desempenyo

gen pay_default = pays_c == 1 & def_c == 1
gen first_pay_porc = first_pay / prestamo
gen num_v_d = num_v if def_c == 1
gen sum_porcp_c_d = sum_porcp_c if def_c == 1
gen zero_pay_default_d = zero_pay_default if def_c == 1
gen rec_fd = des_c == 1 & num_v == 1
foreach variable of varlist first_pay_porc sum_porcp_c_d {
    replace `variable' = 100 * `variable'
}
keep t_prod suc_x_dia dias_primer_pago first_pay_porc rec_fd ///
    dias_ultimo_mov dias_al_desempenyo pay_default sum_porcp_c_d ///
    zero_pay_default_d zero_pay_default num_v num_v_d

local speed dias_primer_pago first_pay_porc rec_fd dias_ultimo_mov ///
    dias_al_desempenyo
local default pay_default sum_porcp_c_d zero_pay_default_d zero_pay_default
local visits num_v num_v_d

eststo clear
foreach outcome of varlist `speed' `default' `visits' {
    eststo: regress `outcome' i.t_prod, vce(cluster suc_x_dia)
    quietly summarize `outcome' if e(sample) & t_prod == 1
    estadd scalar ContrMean = r(mean)
}

esttab using "$directorio/Tables/reg_results/Table2.csv", ///
    se r2 ${star} b(a2) scalars("ContrMean Control Mean") ///
    coeflabels(2.t_producto "Mandatory structured" ///
        4.t_producto "Choice") ///
    keep(2.t_producto 4.t_producto) replace

do "$directorio/DoFiles/render_table.do" Table2
