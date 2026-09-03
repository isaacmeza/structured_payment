version 17.0

* Figure OA-11: Financial benefit TUT effect for different discount rates.
use "$directorio/_aux/pre_admin.dta", clear
sort prenda fecha_movimiento HoraMovimiento
by prenda: egen des_c = max(desempeno)
gen def_c = concluyo_c
replace def_c = 0 if des_c == 1
by prenda: egen sum_pay_fee_c = max(sum_pay_fee)
egen suc_x_dia = group(suc fecha_inicial)
gen Z = 0 if t_producto == 1
replace Z = 1 if t_producto == 2
replace Z = 2 if t_producto == 4
keep prenda fecha_inicial fecha_movimiento HoraMovimiento dias_inicio ///
    clave_movimiento pagos intereses prestamo_i des_c def_c sum_pay_fee_c ///
    visit_number t_producto Z choose_commitment suc_x_dia

* Re-estimate TuT at annual rates from 0% to 5,000%, in 100-point increments.
* Aggregate each pawn's complete transaction history before restricting to
* first visits: visit and treatment fields are missing on some movement rows.
matrix results = J(51, 4, .)
local row = 1
forvalues discount = 0(100)5000 {
    quietly {
        preserve
        local daily = (1 + `discount' / 100)^(1 / 365) - 1
        gen discounted_payment = pagos / ((1 + `daily')^dias_inicio) ///
            if clave_movimiento <= 3 | clave_movimiento == 5
        replace discounted_payment = 0 if missing(discounted_payment)
        gen discounted_interest = intereses / ((1 + `daily')^dias_inicio)
        sort prenda fecha_movimiento HoraMovimiento, stable
        by prenda: gen cumulative_interest = sum(discounted_interest)
        by prenda: gen cumulative_payment = sum(discounted_payment)
        by prenda: egen total_payment = max(cumulative_payment)
        by prenda: egen total_interest = max(cumulative_interest)
        * Recovered pawns incur discounted interest and fees. For defaults,
        * 0.3/0.7 is the paper's collateral-value loss, discounted to day 90.
        gen double discounted_cost = .
        replace discounted_cost = total_interest + sum_pay_fee_c if des_c == 1
        replace discounted_cost = total_payment + ///
            0.3 * prestamo_i / (0.7 * (1 + `daily')^90) if def_c == 1
        replace discounted_cost = total_interest + sum_pay_fee_c ///
            if def_c == 0 & des_c == 0
        * tot_tut is expressed as a financial benefit rather than a cost.
        replace discounted_cost = -discounted_cost
        keep if visit_number == 1
        gsort prenda fecha_inicial -fecha_movimiento clave_movimiento ///
            t_producto
        by prenda fecha_inicial: keep if _n == 1
        tot_tut discounted_cost Z choose_commitment, vce(cluster suc_x_dia)
        matrix results[`row', 1] = `discount'
        matrix results[`row', 2] = _b[TuT]
        matrix results[`row', 3] = _se[TuT]
        matrix results[`row', 4] = e(df_r)
        local ++row
        restore
    }
}
matrix colnames results = discount estimate se df
clear
svmat double results, names(col)
drop if missing(discount)
gen ci95_low = estimate - invttail(df, 0.025) * se
gen ci95_high = estimate + invttail(df, 0.025) * se
gen ci90_low = estimate - invttail(df, 0.05) * se
gen ci90_high = estimate + invttail(df, 0.05) * se
twoway (rarea ci95_high ci95_low discount, color(navy%15)) ///
    (rarea ci90_high ci90_low discount, color(navy%30)) ///
    (line estimate discount, color(navy) lwidth(thick)), ///
    graphregion(color(white)) xtitle("Annual discount rate %") ///
    ytitle("FC Benefit (TuT)") legend(off) yline(0, lcolor(black))
graph export "$directorio/Figures/FigureOA11.pdf", replace
