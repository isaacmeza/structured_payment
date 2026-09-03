version 17.0

* Clean the administrative transaction records and build the compact panel-
* and pawn-level datasets used by the main paper and appendices.
*
* Input:
*   Raw/20131014Consilidacion_Agosto_2013.dta
*   Raw/db_product.dta
*
* Outputs:
*   _aux/time_line_aux.dta                            (Main Figure 1)
*   _aux/pre_admin.dta                                (OA Figure 11)
*   DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2fv.dta
*                                                      (OA Figures 6 and 15)
*   DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta
*                                                      (Master and OA Table 1)
*   DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2fv.dta
*                                                      (Main Figure 1)

use "$directorio/Raw/20131014Consilidacion_Agosto_2013.dta", clear

* Establish a canonical order before dropping unused raw fields. The source
* contains no exact duplicate rows, so indice_sort is a unique tie-breaker.
sort *, stable
gen indice_sort = _n

keep Sucursal ClaveMovimiento FechaMovimiento FechaIngreso NúmPrenda ///
    MontoPréstamo ImporteMovimiento HoraMovimiento NombrePignorante ///
    indice_sort

* Standardize variable names and encode movement types.
rename Sucursal suc
rename ClaveMovimiento clave_movimiento
rename FechaMovimiento fecha_movimiento
rename FechaIngreso fecha_inicial
rename NúmPrenda prenda
rename MontoPréstamo prestamo_i
rename ImporteMovimiento importe

encode clave_movimiento, gen(clave_movimiento_num)
drop clave_movimiento
rename clave_movimiento_num clave_movimiento

* Reduce memory size.
qui compress


* Branch and movement labels.

label define lab_suc ///
	3 "Calzada"      ///
	5 "Congreso"     ///
	42 "Insurgentes"  ///
	78 "Jose Marti"   ///
	80 "San Cosme"    ///
	104 "San Simon"


label define lab_mov      ///
	1 "Abono a Capital"   ///
	2 "Venta con Billete" ///
	3 "Desempeno"         ///
	4 "Empeno"            ///
	5 "Refrendo"          ///
	6 "Pase al Moneda"


label var suc "Branch"
label var clave_movimiento "Movement type"

label values suc lab_suc
label values clave_movimiento lab_mov


* Attach the experimental product assignment.
merge m:1 prenda using "$directorio/Raw/db_product.dta", ///
	keepusing(producto t_producto) nogen keep(3)

* Label assignment arms with the nomenclature used in the paper. producto
* retains the separate labels for the contract each borrower received.
label define lab_t_prod 1 "Control" 2 "Mandatory structured" ///
    3 "Promise Mandate" 4 "Choice" 5 "Promise Choice", modify
label values t_producto lab_t_prod
label variable t_producto "Treatment assignment arm"

* Treatment indicators used by the forest analyses. pro_2 contrasts the
* mandatory structure arm with the status quo; pro_6 and pro_7 identify the
* two choice-arm product variants used in the supplementary forest.
gen pro_2 = (t_producto == 2)
replace pro_2 = . if !inlist(t_producto, 1, 2)
label var pro_2 "NC-Fee"

gen pro_6 = (producto == 4)
replace pro_6 = . if !inlist(producto, 1, 4)
label var pro_6 "C-Fee-SQ"

gen pro_7 = (producto == 5)
replace pro_7 = . if !inlist(producto, 1, 5)
label var pro_7 "C-Fee-NSQ"

* Elapsed days from loan origination.
gen dias_inicio = fecha_movimiento - fecha_inicial
drop if dias_inicio < 0 | missing(dias_inicio)
label var dias_inicio  "Days passed between movement date and initial date"

* Days of first payment.
gen dpp = dias_inicio if inlist(clave_movimiento, 1,3,5)


* Drop negative duplicate transaction and loan records.
drop if importe<0
drop if prestamo_i<0

* For duplicated recovery records, keep the last record.
sort prenda fecha_movimiento HoraMovimiento clave_movimiento, stable
by prenda : gen uno = clave_movimiento==3
by prenda : egen dup = sum(uno)
by prenda : gen pd = sum(uno)
drop if pd==uno & pd==1 & dup==2
drop uno dup pd


* Branch dates used in the experiment timeline.
preserve
collapse (min) min_fecha_suc = fecha_inicial ///
    (max) max_fecha_suc = fecha_movimiento, by(suc)
save "$directorio/_aux/time_line_aux.dta", replace
restore


* Restrict to the randomization period.
keep if fecha_inicial>=date("06/09/2012","DMY")

* Indicator for choosing the commitment product.
gen choose_commitment =  (producto==5 | producto==7) if inlist(producto, 4, 5, 6, 7)


*Variable creation

sort prenda fecha_movimiento HoraMovimiento, stable
*'pagos' indicate deposits from the customers, i.e. refrendo, desempeno, abono al capital.
*Filter those that indicate payments
gen pagos = importe if inlist(clave_movimiento, 1,3,5)
replace pagos = 0 if pagos==.
label var pagos "Client deposits"

* Paid interest.
gen intereses = importe if inlist(clave_movimiento, 5)
sort prenda fecha_movimiento, stable
by prenda : egen spagos = sum(pagos)
by prenda : egen sint = sum(intereses)
replace intereses = spagos-sint-prestamo_i if clave_movimiento==3
drop spagos sint
label var intereses "Interests"


* A loan has certainly ended after recovery, default, or sale.
gsort prenda dias_inicio fecha_movimiento HoraMovimiento -clave_movimiento indice_sort
by prenda : gen ultimo_mov = _n==_N


*Tag as ended if either recovery, default, or vbi
gen concluyo = inlist(clave_movimiento,2,3,6)
*Add those that sell pawn (these default)
replace concluyo = 1 if ultimo_mov==1 & clave_movimiento==4
*Add those that didnt rollover pawn (these default)
replace concluyo = 1 if ultimo_mov==1 & clave_movimiento==1


*Add those that did rollover but then didnt pay in observation window - and didnt rollover for a further period (these default)
su fecha_movimiento
gen dias_quedan = `r(max)' - fecha_movimiento
replace concluyo = 1 if ultimo_mov==1 & clave_movimiento==5 & dias_quedan>=90
*Identify ended loans
sort prenda, stable
by prenda : egen concluyo_c = max(concluyo)

*Drop when pawn was sell, since this is not of interest, and moves the last day in the admin data.
drop if clave_movimiento==2


* Incurred interest and fees. These contractual rate and fee formulas are
* retained exactly because they feed the reported financial-cost outcomes.
preserve
collapse (mean) prestamo_i (sum) importe (mean) dias_inicio ///
    (mean) concluyo_c (mean) fecha_inicial, by(prenda fecha_movimiento)
sort prenda fecha_movimiento dias_inicio, stable

gen double incurred_int = .
gen double fee_strong = .
gen capital = prestamo_i
bysort prenda : gen num_mov = _N
su num_mov
forvalues i = 2/`r(max)' {
	*Interests (7%)
	bysort prenda : replace incurred_int = capital[_n-1]*((1+0.002257833358012379025857)^(dias_inicio-dias_inicio[_n-1])-1) if _n==`i'
	*Fee
	bysort prenda : replace fee_strong = .02*capital[_n-1]/3*(ceil(dias_inicio/30)-ceil(dias_inicio[_n-1]/30)-1+(importe<=capital/3)) if _n==`i'
	bysort prenda : replace capital = capital[_n-1] - (importe-incurred_int-fee_strong) if _n==`i'
	}

su fecha_movimiento
bysort prenda : replace incurred_int = incurred_int + capital*((1+0.002257833358012379025857)^((`r(max)'-fecha_inicial)-dias_inicio)-1) if concluyo_c==0 & _n==_N

keep prenda fecha_movimiento incurred_int fee_strong
tempfile temp_int
save `temp_int'
restore

merge m:1 prenda fecha_movimiento using `temp_int', nogen
*Drop duplicates by prenda-date
sort prenda fecha_movimiento HoraMovimiento indice_sort, stable
foreach var of varlist incurred_int fee_strong {
	by prenda fecha_movimiento : replace `var' = . if _n!=1
	}

* Paid fees.
gen payed_fees = fee_strong if pagos>0 & inlist(producto,2,5)

label var incurred_int "Incurred interests"
label var fee_strong "Incurred fees"
label var payed_fees "Payed fees"


*'sum_p' is the cumulative sum of payments
sort prenda fecha_movimiento HoraMovimiento, stable
*Add fees
replace pagos = pagos + payed_fees if !missing(payed_fees)
by prenda: gen sum_p=sum(pagos)
label var sum_p "Cumulative sum of payments"

*'sum_int' is the cumulative sum of interest
sort prenda fecha_movimiento HoraMovimiento, stable
by prenda: gen sum_int=sum(intereses)
label var sum_int "Cumulative sum of interests"

*'sum_incurred_int' is the cumulative sum of incurred interest
sort prenda fecha_movimiento HoraMovimiento, stable
by prenda: gen sum_inc_int=sum(incurred_int)
label var sum_inc_int "Cumulative sum of incurred interests"

* 'sum_pay_fee' is the cumulative sum of paid fees.
sort prenda fecha_movimiento HoraMovimiento, stable
by prenda: gen sum_pay_fee=sum(payed_fees)
label var sum_pay_fee "Cumulative sum of payed fees"

*Var correction (desempeno)
bysort prenda: replace clave_movimiento=5 if clave_movimiento==3 & sum_p < prestamo_i - 1

*'porc_pagos' is the percentage of payments wrt the loan
gen porc_pagos=pagos/prestamo_i
label var porc_pagos "Payment percentage wrt to loan"

*'sum_porc_p' is the percentage of the cumulative sum of the payments wrt to the loan
sort prenda fecha_movimiento HoraMovimiento, stable
by prenda: gen sum_porc_p=sum_p/prestamo_i
label var sum_porc_p "Percentage of the cumulative sum of payments"

* Percentage of cumulative interest, used by the censoring analysis.
sort prenda fecha_movimiento HoraMovimiento, stable
by prenda: gen sum_porc_int=sum_int/prestamo_i
label var sum_porc_int "Percentage of the cumulative sum of interest"

*Number of payments at current date
gen dum_pago=(pagos!=0 & pagos!=.)
sort prenda fecha_movimiento HoraMovimiento, stable
by prenda: gen sum_np= sum(dum_pago)
by prenda : replace dum_pago = . if fecha_movimiento[_n]==fecha_movimiento[_n-1]
by prenda: gen sum_visit= sum(dum_pago)

drop dum_pago

label var sum_np "Number of payments at current date"
label var sum_visit "Number of visits at current date"


* Movement indicators used in reported outcomes.
gen desempeno=(clave_movimiento==3)
gen refrendo=(clave_movimiento==5)

* Number of borrower visits, capped at the 99th percentile.
preserve
duplicates drop NombrePignorante fecha_inicial, force

sort NombrePignorante fecha_inicial, stable
*Number of visits to pawnshop
bysort NombrePignorante: gen visit_number = _n
qui su visit_number, d
local tr99 = `r(p99)'
replace visit_number = `tr99' if visit_number>=`tr99'

keep NombrePignorante fecha_inicial visit_number
tempfile temp_varsC0
save  `temp_varsC0'
restore

*Recidivism
preserve
sort prenda fecha_movimiento HoraMovimiento dias_inicio indice_sort, stable
	*Desempeno
by prenda: egen des_i_c=max(desempeno)
gen dias_inicio_d=dias_inicio if des_i_c==1
by prenda: gen dias_al_desempenyo=dias_inicio_d[_N]
replace dias_al_desempenyo = 1 if dias_al_desempenyo==0

sort NombrePignorante fecha_inicial suc indice_sort, stable
*Identify borrowers with multiple branches in their first loan
bysort NombrePignorante fecha_inicial suc: gen mb_fl = _n ==1
bysort NombrePignorante fecha_inicial : replace mb_fl = sum(mb_fl)
bysort NombrePignorante fecha_inicial : replace mb_fl = mb_fl[_N]
bysort NombrePignorante : egen b_mb = max(mb_fl)
drop if b_mb>1

*Identify borrowers with multiple treatments in their first loan
bysort NombrePignorante fecha_inicial t_producto: gen mt_fl = _n ==1
bysort NombrePignorante fecha_inicial : replace mt_fl = sum(mt_fl)
bysort NombrePignorante fecha_inicial : replace mt_fl = mt_fl[_N]
bysort NombrePignorante : egen b_mt = max(mt_fl)
drop if b_mt>1

* Complete missing product assignments within a borrower-date group.
sort NombrePignorante fecha_inicial producto t_producto, stable
by NombrePignorante fecha_inicial : replace producto = producto[_n-1] ///
    if missing(producto) & !missing(producto[_n-1])
by NombrePignorante fecha_inicial : replace t_producto = t_producto[_n-1] ///
    if missing(t_producto) & !missing(t_producto[_n-1])
duplicates drop NombrePignorante fecha_inicial, force

*Dummy indicating if customer returned after first visit (WHEN FIRST TREATED)
sort NombrePignorante fecha_inicial indice_sort, stable
by NombrePignorante: gen first_pawn = _n==1

by NombrePignorante: gen first_visit = fecha_inicial[1]
by NombrePignorante: gen first_loan_value = prestamo_i[1]
by NombrePignorante: gen first_dias_des = dias_al_desempenyo[1] if !missing(des_i_c)

*days from first to *second pawn*
sort NombrePignorante fecha_inicial, stable
by NombrePignorante: gen days_second_pawns = fecha_inicial[2] - first_visit if _n==1

*Ever repeat pawns
bysort NombrePignorante : gen reincidence = (_N>1)

* Proxy different collateral when the second loan differs by more than +/-2.5%
* from the first loan amount.
by NombrePignorante: gen reincidence_other = reincidence==1 & !inrange(prestamo_i[2],first_loan_value*0.975,first_loan_value*1.025) if _n==1

keep if first_pawn==1
keep NombrePignorante fecha_inicial first_pawn first_dias_des ///
    days_second_pawns reincidence reincidence_other
tempfile temp_rec
save  `temp_rec'
restore

merge m:1 NombrePignorante fecha_inicial using `temp_varsC0', nogen
merge m:1 NombrePignorante fecha_inicial using `temp_rec', nogen

* Compact transaction panel used by the discounted-cost analysis.
preserve
keep prenda fecha_inicial fecha_movimiento HoraMovimiento dias_inicio ///
    clave_movimiento pagos intereses prestamo_i desempeno concluyo_c ///
    sum_pay_fee visit_number t_producto choose_commitment suc
compress
save "$directorio/_aux/pre_admin.dta", replace
restore


********************************************************************************
*							Measures of recovery/default					   *
********************************************************************************

*The next variables indicate if the movement exists in the voucher.
*e.g.
*'sum_p_c' is the maximum/last cumulative payment
*'sum_porcp_c'is the maximum/last percentage of payment
*'num_p' is the number of payments
preserve
sort prenda fecha_movimiento HoraMovimiento, stable
keep if (pagos>0)
by prenda fecha_movimiento : egen sum_pay_day = sum(pagos)
by prenda : gen first_pay = sum_pay_day[1]

duplicates drop prenda first_pay, force
keep prenda first_pay
tempfile temp_fp
save `temp_fp'
restore
merge m:1 prenda using `temp_fp', nogen
replace first_pay = 0 if missing(first_pay)


sort prenda fecha_movimiento HoraMovimiento, stable

	*Desempeno - defined as ever recovered in observation window
by prenda: egen des_i_c=max(desempeno)
	*Default - defined as losing the piece - note that it is not symmetrical with recovered
gen def_i_c = concluyo_c
replace def_i_c = 0 if des_i_c==1

by prenda: egen ref_c=max(refrendo)
by prenda: egen sum_p_c=max(sum_p)
by prenda: egen sum_int_c=max(sum_int)
by prenda: egen sum_pay_fee_c=max(sum_pay_fee)
by prenda: gen pays_c=(sum_p_c>0) if !missing(sum_p_c)
by prenda: egen mn_p105_=mean(pagos) if !inlist(clave_movimiento,4,6) & pagos!=0 & dias_inicio<=110
by prenda: egen mn_p105_c=max(mn_p105_)
replace mn_p105_c = 0 if missing(mn_p105_c)
by prenda: egen mn_p210_=mean(pagos) if !inlist(clave_movimiento,4,6) & pagos!=0 & inrange(dias_inicio,111,220)
by prenda: egen mn_p210_c=max(mn_p210_)
replace mn_p210_c = 0 if missing(mn_p210_c)

by prenda: egen sum_porcp_c=max(sum_porc_p)
* The named payment horizons include the five-day grace windows used in the
* analysis (35, 65, 95, 110, 155, 185, and 220 elapsed days).
by prenda: egen sum_porcp30_c_aux=sum(porc_pagos) if dias_inicio<=35
by prenda: egen sum_porcp30_c=max(sum_porcp30_c_aux)
by prenda: egen sum_porcp60_c_aux=sum(porc_pagos) if dias_inicio<=65
by prenda: egen sum_porcp60_c=max(sum_porcp60_c_aux)
by prenda: egen sum_porcp90_c_aux=sum(porc_pagos) if dias_inicio<=95
by prenda: egen sum_porcp90_c=max(sum_porcp90_c_aux)
by prenda: egen sum_porcp105_c_aux=sum(porc_pagos) if dias_inicio<=110
by prenda: egen sum_porcp105_c=max(sum_porcp105_c_aux)
by prenda: egen sum_porcp150_c_aux=sum(porc_pagos) if dias_inicio<=155
by prenda: egen sum_porcp150_c=max(sum_porcp150_c_aux)
by prenda: egen sum_porcp180_c_aux=sum(porc_pagos) if dias_inicio<=185
by prenda: egen sum_porcp180_c=max(sum_porcp180_c_aux)
by prenda: egen sum_porcp210_c_aux=sum(porc_pagos) if dias_inicio<=220
by prenda: egen sum_porcp210_c=max(sum_porcp210_c_aux)

cap drop sum_porcp30_c_aux sum_porcp60_c_aux sum_porcp90_c_aux sum_porcp105_c_aux sum_porcp150_c_aux sum_porcp180_c_aux sum_porcp210_c_aux

by prenda: egen sum_porc105_int_c_aux=max(sum_porc_int) if dias_inicio<=110
by prenda: egen sum_porc105_int_c=max(sum_porc105_int_c_aux)
by prenda: egen sum_porc210_int_c_aux=max(sum_porc_int) if dias_inicio<=220
by prenda: egen sum_porc210_int_c=max(sum_porc210_int_c_aux)

cap drop sum_porc105_int_c_aux sum_porc210_int_c_aux

by prenda: egen num_p=max(sum_np)
by prenda: gen num_v=sum_visit[_N]

by prenda: egen dias_primer_pago = min(dpp)
by prenda: gen dias_ultimo_mov = dias_inicio[_N]
gen dias_inicio_d=dias_inicio if des_i_c==1
*Days towards recovery
by prenda: gen dias_al_desempenyo=dias_inicio_d[_N]
replace dias_al_desempenyo = 1 if dias_al_desempenyo==0
replace dias_inicio = 1 if dias_inicio==0 & des_i_c==1
*Days towards default
gen dias_al_default = dias_ultimo_mov if def_i_c==1
* Assign defaults to the end of successive 105-day contract cycles
* (90-day term plus 15-day grace period).
replace dias_al_default = 105 if dias_al_default<90 & def_i_c==1
replace dias_al_default = 210 if inrange(dias_ultimo_mov, 110, 180) & def_i_c==1
replace dias_al_default = 315 if inrange(dias_ultimo_mov, 220, 270) & def_i_c==1

cap drop dias_inicio_d

* Indicator for borrowers who defaulted without making a payment.
bysort prenda: gen zero_pay_default = def_i_c*(sum_porcp_c==0) if !missing(sum_porcp_c)

label var des_i_c "Recovery"
label var def_i_c "Default"
label var ref_c "Refrendum"
label var sum_p_c "Cum (total) payments"
label var sum_int_c "Cum (total) interest"
label var sum_pay_fee_c "Cum (total) payed fees"
label var pays_c "Dummy of payment>0"
label var sum_porcp_c "Percentage of payment (total)"
label var sum_porcp30_c "Percentage of payment (at 30 days)"
label var sum_porcp60_c "Percentage of payment (at 60 days)"
label var sum_porcp90_c "Percentage of payment (at 90 days)"
label var sum_porcp105_c "Percentage of payment (at 105 days)"
label var sum_porcp150_c "Percentage of payment (at 150 days)"
label var sum_porcp180_c "Percentage of payment (at 180 days)"
label var sum_porcp210_c "Percentage of payment (at 210 days)"
label var sum_porc105_int_c "Percentage of interest (at 105 days)"
label var sum_porc210_int_c "Percentage of interest (at 210 days)"
label var num_p "Number of payments"
label var zero_pay_default "Selled pawn"


********************************************************************************
*							Measures of cost								   *
********************************************************************************

* Financial cost. For defaulted pawns, 0.3/0.7 implements the paper's
* collateral-value assumption.
gen double fc_i_admin = .
	*Only fees and interest for recovered pawns
replace fc_i_admin = sum_int_c + sum_pay_fee_c if des_i_c==1
	*All payments + appraised value net of loan amount when default
replace fc_i_admin = sum_p_c + prestamo_i*(0.3/0.7) if def_i_c==1
	*Not ended at the end of observation period - only fees and interest
replace fc_i_admin = sum_int_c + sum_pay_fee_c if def_i_c==0 & des_i_c==0

label var fc_i_admin "Financial cost (appraised value)"

	*cost of losing pawn
gen double cost_losing_pawn = 0
replace cost_losing_pawn = sum_p_c - sum_int_c - sum_pay_fee_c + prestamo_i*(0.3/0.7) if def_i_c==1

gen double downpayment_capital = 0
replace downpayment_capital = sum_p_c - sum_int_c - sum_pay_fee_c if def_i_c==1

*CR
gen double cr_i  = fc_i_admin/prestamo_i
label var cr_i "CR (appraised value)"


********************************************************************************

*Suc by day
egen suc_x_dia=group(suc fecha_inicial)

*Day of week
gen dow=dow(fecha_inicial)

* Compact first-visit transaction panel used by OA Figures 6 and 15.
preserve
keep if visit_number==1
keep suc_x_dia clave_movimiento t_producto prenda fecha_movimiento ///
    HoraMovimiento porc_pagos dias_inicio
compress
save "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2fv", replace
restore

* Select the last transaction for each pawn.
gsort prenda fecha_inicial -fecha_movimiento clave_movimiento t_producto indice_sort
by prenda fecha_inicial : keep if _n==1
* Exclude the five loan-size outliers above MXN 57,000.
drop if prestamo_i>57000

* Pawn-level cross-section used to build Master.dta and OA Table 1.
keep prenda t_producto fecha_inicial suc producto clave_movimiento ///
    fecha_movimiento HoraMovimiento NombrePignorante prestamo_i ///
    choose_commitment concluyo_c cost_losing_pawn days_second_pawns ///
    dias_al_default dias_al_desempenyo dias_primer_pago dias_ultimo_mov ///
    downpayment_capital first_dias_des first_pawn first_pay mn_p105_c ///
    mn_p210_c num_p num_v pays_c pro_2 pro_6 pro_7 ref_c ///
    reincidence reincidence_other suc_x_dia sum_inc_int sum_int_c ///
    sum_p_c sum_pay_fee_c sum_porc105_int_c sum_porc210_int_c ///
    sum_porcp_c sum_porcp105_c sum_porcp150_c sum_porcp180_c ///
    sum_porcp210_c sum_porcp30_c sum_porcp60_c sum_porcp90_c ///
    zero_pay_default des_i_c def_i_c fc_i_admin cr_i dow visit_number
isid prenda
sort prenda
compress
save "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta", replace

* Minimal first-visit dates used by Main Figure 1.
keep if visit_number==1
keep producto clave_movimiento fecha_inicial suc
save "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2fv.dta", replace
