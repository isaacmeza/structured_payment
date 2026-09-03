version 17.0

* Figure OA-2: Weekly default rates experimental branches and all branches
use "$directorio/DB/Master.dta", clear
keep fecha_inicial def_c
gen weekly = yw(year(fecha_inicial), week(fecha_inicial))
format weekly %tw
collapse (mean) def_c, by(weekly)
tempfile experimental
save `experimental'

* Confidentiality-reduced observational extract supplied for this figure.
use "$directorio/Raw/base_expansion.dta", clear
keep fechaaltadelprestamo def_vta
gen weekly = yw(year(fechaaltadelprestamo), week(fechaaltadelprestamo))
format weekly %tw
collapse (mean) def_vta, by(weekly)
rename def_vta def_c
append using `experimental'

* Retain the experimental and observational windows displayed in the figure.
keep if weekly < yw(2013, 12) | inrange(weekly, yw(2016, 1), yw(2020, 12))
sort weekly
tsset weekly

twoway ///
    (tsline def_c if weekly < yw(2013, 12), ///
        lwidth(medthick) ylabel(.30(.05).60)) ///
    (tsline def_c if inrange(weekly, yw(2016, 1), yw(2020, 12)), ///
        xtitle("Date") ytitle("Default rate (weekly)") ///
        lwidth(medthick) ylabel(.30(.05).60)), ///
    legend(order(1 "Experimental" 2 "Observational") pos(6) cols(2))

graph export "$directorio/Figures/FigureOA2.pdf", replace
