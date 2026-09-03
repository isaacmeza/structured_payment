version 17.0

* Table 3: TOT, TUT, ASG, ASB, and ASL Estimates.
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod, 1, 2, 4)
keep cr def_c ref_c fc_admin choose_commitment t_prod suc_x_dia

replace fc_admin = -fc_admin
replace cr = -100 * cr
replace def_c = 100 - 100 * def_c
replace ref_c = 100 - 100 * ref_c
gen byte Z = 0 if t_prod == 1
replace Z = 1 if t_prod == 2
replace Z = 2 if t_prod == 4

eststo clear
foreach outcome of varlist cr fc_admin def_c ref_c {
    eststo: tot_tut `outcome' Z choose_commitment, vce(cluster suc_x_dia)
    * Table 3 reports two tests of the selection-gain estimate ToT - TuT.
    quietly test ToT - TuT = 0
    local p_asg_two = r(p)
    local t_asg = sign(_b[ToT] - _b[TuT]) * sqrt(r(F))
    local df_asg = r(df_r)
    estadd scalar tut_tot = `p_asg_two'
    estadd scalar tut_tot_1 = ttail(`df_asg', `t_asg')
}

esttab using "$directorio/Tables/reg_results/Table3.csv", ///
    se ${star} b(a2) ///
    scalars("tut_tot H_0 : ASG=0" ///
        "tut_tot_1 H_0 : ASG$\leq$ 0") ///
    replace

do "$directorio/DoFiles/render_table.do" Table3
