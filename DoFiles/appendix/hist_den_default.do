version 17.0

* Figure OA-3: Behavior of borrowers who lost their pawn.
use "$directorio/DB/Master.dta", clear
keep if t_producto == 1 & def_c == 1
keep dias_primer_pago dias_ultimo_mov sum_porcp_c num_p

* The published panel reports up to five payments; omit the sparse upper tail.
replace num_p = . if num_p > 5

histogram dias_ultimo_mov, percent width(10) graphregion(color(white)) ///
    xtitle("Elapsed days to last payment") title("") note("")
graph export "$directorio/Figures/FigureOA3b.pdf", replace

histogram dias_primer_pago, percent width(10) graphregion(color(white)) ///
    xtitle("Elapsed days") title("") note("")
graph export "$directorio/Figures/FigureOA3a.pdf", replace

histogram sum_porcp_c, percent width(0.1) graphregion(color(white)) ///
    xtitle("% of payment") title("") note("")
graph export "$directorio/Figures/FigureOA3c.pdf", replace

catplot num_p, percent vertical graphregion(color(white)) ///
    ytitle("Percent")
graph export "$directorio/Figures/FigureOA3d.pdf", replace
