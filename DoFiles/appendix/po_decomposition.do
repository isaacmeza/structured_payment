version 17.0

* Figure OA-13: Estimating counterfactual outcomes for non-choosers,
* by overconfidence. Both main and promise panels are produced here.
foreach panel in main promise {
    if "`panel'" == "main" {
        local sample_arms 1, 2, 4
        local treated_arm = 2
        local choice_arm = 4
        local panel_seed = 1301301
        local graph_file "$directorio/Figures/FigureOA13a.pdf"
    }
    else {
        local sample_arms 1, 3, 5
        local treated_arm = 3
        local choice_arm = 5
        local panel_seed = 1301302
        local graph_file ///
            "$directorio/Figures/FigureOA13b.pdf"
    }

    use "$directorio/DB/Master.dta", clear
    keep if inlist(t_producto, `sample_arms')
    keep prenda t_producto fc_admin choose_commitment confidence_100
    * Validate and sort the unique pawn key so bsample does not depend on the
    * order in which Master.dta happened to be saved.
    isid prenda, sort
    * Financial cost enters the decomposition as a benefit.
    replace fc_admin = -fc_admin
    gen byte Z = 0 if t_producto == 1
    replace Z = 1 if t_producto == `treated_arm'
    replace Z = 2 if t_producto == `choice_arm'

    * The distinct fixed seeds have no substantive meaning. They make each
    * panel reproducible and independent of preceding commands in the session.
    set seed `panel_seed'

    * The sure-confident bootstrap includes the four summary rows appended after
    * the not-sure-confident group. Their analysis fields are missing, so they
    * only affect the resampling-frame size; retain them for exact replication.
    tempfile accumulated_results
    save `accumulated_results', emptyok replace

    foreach confidence_group in 0 1 {
        * Only E[Y(0)|C=0] and the inferred E[Y(1)|C=0] appear in the figure.
        matrix potential_outcomes = J(100, 2, .)
        forvalues replication = 1/100 {
            preserve
            bsample

            quietly summarize fc_admin if t_producto == `choice_arm' & ///
                choose_commitment == 0 & ///
                confidence_100 == `confidence_group'
            local EY0_0 = r(mean)
            matrix potential_outcomes[`replication', 1] = `EY0_0'

            quietly summarize fc_admin if t_producto == `choice_arm' & ///
                choose_commitment == 1 & ///
                confidence_100 == `confidence_group'
            local EY1_1 = r(mean)

            quietly tot_tut fc_admin Z choose_commitment ///
                if confidence_100 == `confidence_group'
            local EY1_0 = `EY1_1' - _b[ASL]
            matrix potential_outcomes[`replication', 2] = `EY1_0'
            restore
        }

        quietly summarize fc_admin if t_producto == `choice_arm' & ///
            choose_commitment == 0 & ///
            confidence_100 == `confidence_group', meanonly
        local EY00 = r(mean)
        quietly summarize fc_admin if t_producto == `choice_arm' & ///
            choose_commitment == 1 & ///
            confidence_100 == `confidence_group', meanonly
        local EY11 = r(mean)
        quietly tot_tut fc_admin Z choose_commitment ///
            if confidence_100 == `confidence_group'
        local EY10 = `EY11' - _b[ASL]

        matrix colnames potential_outcomes = EY0_0 EY1_0
        svmat potential_outcomes, names(col)
        quietly centile EY0_0, centile(2.5 97.5)
        local lower0 = r(c_1)
        local upper0 = r(c_2)
        quietly centile EY1_0, centile(2.5 97.5)
        local lower1 = r(c_1)
        local upper1 = r(c_2)

        clear
        * Four rows preserve the resampling-frame convention described above;
        * only the first two contain quantities displayed in the figure.
        set obs 4
        gen id = _n
        gen mean = .
        replace mean = `EY00' in 1
        replace mean = `EY10' in 2
        gen lo = .
        gen hi = .
        replace lo = `lower0' in 1
        replace hi = `upper0' in 1
        replace lo = `lower1' in 2
        replace hi = `upper1' in 2
        gen conf = `confidence_group'
        append using `accumulated_results'
        save `accumulated_results', replace
    }

    keep if inlist(id, 1, 2)
    gen id_plot = id
    replace id_plot = id_plot + 0.1 if conf == 1
    replace id_plot = id_plot - 0.1 if conf == 0

    quietly summarize lo, meanonly
    local ymin = floor(r(min))
    local ymax = ceil(r(max))
    quietly summarize hi, meanonly
    local ymin = floor(min(r(min), `ymin')) - 5
    local ymax = ceil(max(r(max), `ymax')) + 5
    local step = (`ymax' - `ymin') / 4

    local xlabels ///
        `"1 "E[Y(0)|C=0]" 2 "E[Y(1)|C=0]""'
    twoway ///
        (rcap lo hi id_plot if conf == 0, ///
            lcolor(teal) lwidth(medium)) ///
        (rcap lo hi id_plot if conf == 1, ///
            lcolor(maroon) lwidth(medium)) ///
        (scatter mean id_plot if conf == 0, msymbol(circle) ///
            mcolor(teal) msize(medium) mlabel(mean) ///
            mlabformat(%12.2fc) mlabposition(6) mlabcolor(teal) ///
            mlabsize(small)) ///
        (scatter mean id_plot if conf == 1, msymbol(circle) ///
            mcolor(maroon) msize(medium) mlabel(mean) ///
            mlabformat(%12.2fc) mlabposition(6) mlabcolor(maroon) ///
            mlabsize(small)), ///
        xlabel(`xlabels', labsize(small) nogrid) ///
        aspectratio(0.85) xscale(range(0.75 2.25) noextend) ///
        ylabel(`ymin'(`step')`ymax', nogrid) ytitle("FC benefit") ///
        xtitle("") legend(order(3 "Not sure-confident" ///
            4 "Sure-confident") cols(2) pos(6))
    graph export "`graph_file'", replace
}
