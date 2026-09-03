version 17.0

* Helper functions for Figure OA-8; this file creates no exhibit by itself.
mata: mata clear
mata:
/* Numerically stable inverse-logit evaluation for the dependence bounds. */
real colvector s_logit(real colvector x)
{
    real colvector y, high, low, middle, ihigh, ilow, imiddle;
    y = J(rows(x), 1, .);
    high = (x :>= 30);
    low = (x :<= -30);
    middle = !(high :| low);
    ihigh = selectindex(high);
    ilow = selectindex(low);
    imiddle = selectindex(middle);
    if (rows(ihigh)) y[ihigh] = J(rows(ihigh), 1, 1);
    if (rows(ilow)) y[ilow] = J(rows(ilow), 1, 0);
    if (rows(imiddle)) y[imiddle] = 1 :/ (1 :+ exp(-x[imiddle]));
    return(y);
}

real scalar mean_logitnorm_on_grid(
    real scalar mu, real scalar sigma, real colvector z)
{
    return(mean(s_logit(mu :+ sigma :* z)));
}

real scalar calibrate_mu_logitnorm(
    real colvector z, real scalar sigma, real scalar pbar)
{
    real scalar lo, hi, mid, mu0, iteration;
    /* Choose the logit-normal location that reproduces the arm's mean
       repeat-borrowing probability on the empirical quantile grid. */
    mu0 = -sigma * invnormal(1 - pbar);
    lo = mu0 - 10 * sigma;
    hi = mu0 + 10 * sigma;
    for (iteration = 1; iteration <= 80; iteration++) {
        mid = (lo + hi) / 2;
        if (mean_logitnorm_on_grid(mid, sigma, z) > pbar) hi = mid;
        else lo = mid;
    }
    return(mid);
}

void ltv_logitnorm_frechet_arm(
    real scalar armval, real scalar delta, real scalar Thor, real scalar sigma)
{
    real colvector armv, index, X, R, Xs, u, z, P_como, P_cntr;
    real colvector gT_como, gT_cntr;
    real scalar n, pbar, mu;

    st_view(armv = ., ., "arm");
    index = selectindex(armv :== armval);
    if (rows(index) == 0) _error(3499, "No obs match this arm.");
    st_view(X = ., index, "fc_admin");
    st_view(R = ., index, "reincidence");
    X = select(X, X :< .);
    if (rows(X) == 0) _error(3497, "All fc_admin missing in this arm.");
    if (rows(select(R, R :< .)) == 0) _error(3497, "No nonmissing reincidence in this arm.");

    pbar = mean(select(R, R :< .));
    if (pbar <= 1e-12) pbar = 1e-12;
    if (pbar >= 1 - 1e-12) pbar = 1 - 1e-12;
    n = rows(X);
    /* Pair ordered profit with increasing and decreasing recurrence risk to
       obtain the comonotone and countermonotone Fréchet envelopes. */
    Xs = sort(X, 1);
    u = ((1::n) :- 0.5) :/ n;
    z = invnormal(u);
    mu = calibrate_mu_logitnorm(z, sigma, pbar);
    P_como = s_logit(mu :+ sigma :* z);
    P_cntr = s_logit(mu :- sigma :* z);
    gT_como = (1 :- (delta :* P_como):^(Thor + 1)) :/ (1 :- delta :* P_como);
    gT_cntr = (1 :- (delta :* P_cntr):^(Thor + 1)) :/ (1 :- delta :* P_cntr);
    st_numscalar("LTVtmp_como", mean(Xs :* gT_como));
    st_numscalar("LTVtmp_cntr", mean(Xs :* gT_cntr));
}
end

capture program drop frechet_logitnorm_once
program define frechet_logitnorm_once, rclass
    version 17.0
    syntax, DELTA(real) THOR(integer) SIGMA(real)

    * arm=1 is mandatory structure and arm=0 is status quo.
    mata: ltv_logitnorm_frechet_arm(1, `delta', `thor', `sigma')
    scalar S_como = scalar(LTVtmp_como)
    scalar S_cntr = scalar(LTVtmp_cntr)
    mata: ltv_logitnorm_frechet_arm(0, `delta', `thor', `sigma')
    scalar Q_como = scalar(LTVtmp_como)
    scalar Q_cntr = scalar(LTVtmp_cntr)
    return scalar diff_struct = (S_como - Q_cntr) / Q_cntr
    return scalar diff_status = (S_cntr - Q_como) / Q_como
end

capture program drop fit_latent_phats
program define fit_latent_phats
    version 17.0
    syntax, ARMVAR(varname) TREAT(integer) CONTROL(integer) AMT(varname) ///
        RET(varname) METHOD(string) INTP(integer)

    * Fit current profit and repeat borrowing jointly through a shared latent
    * factor, then predict each observation's repeat-borrowing probability.
    tempvar fc_std
    quietly summarize `amt' if inlist(`armvar', `control', `treat')
    quietly gen double `fc_std' = ///
        cond(r(sd) > 0, (`amt' - r(mean)) / r(sd), 0)
    quietly gsem (`amt' <- L i.`armvar') ///
        (`ret' <- L i.`armvar' c.`fc_std' ///
            i.`armvar'#c.`fc_std', logit) ///
        if inlist(`armvar', `control', `treat'), ///
        var(L@1) intmethod(`method') intpoints(`intp') nolog
    quietly predict double phat_bench if e(sample), mu eq(`ret')
end

capture program drop copula_grid
program define copula_grid
    version 17.0
    syntax, DELTAS(string) THORS(numlist) SIGMA(real) CLUSTER(name) ///
        LATINTP(integer) LATMETHOD(string) LATARMVAR(name) ///
        LATTREAT(integer) LATCONTROL(integer) LATAMT(name) LATRET(name)

    numlist "`deltas'", ascending
    local delta_values `r(numlist)'
    numlist "`thors'", ascending
    local horizon_values `r(numlist)'

    * Store the two dependence envelopes and the joint-latent benchmark on the
    * requested discount-factor-by-horizon grid.
    tempname output_handle
    tempfile output_data
    postfile `output_handle' str24 series double delta int Thor ///
        double estimate ///
        using `output_data', replace

    fit_latent_phats, armvar(`latarmvar') treat(`lattreat') ///
        control(`latcontrol') amt(`latamt') ret(`latret') ///
        method(`latmethod') intp(`latintp')

    foreach horizon of numlist `horizon_values' {
        foreach discount of numlist `delta_values' {
            quietly frechet_logitnorm_once, ///
                delta(`discount') thor(`horizon') sigma(`sigma')
            post `output_handle' ("logitnorm_struct") (`discount') ///
                (`horizon') (r(diff_struct))
            post `output_handle' ("logitnorm_status") (`discount') ///
                (`horizon') (r(diff_status))

            tempvar probability_clip geometric_sum lifetime_value
            quietly gen double `probability_clip' = cond(!missing(phat_bench), ///
                min(phat_bench, .999 / `discount'), .)
            quietly gen double `geometric_sum' = ///
                (1 - (`discount' * `probability_clip')^(`horizon' + 1)) / ///
                (1 - `discount' * `probability_clip')
            quietly gen double `lifetime_value' = `latamt' * `geometric_sum'
            quietly regress `lifetime_value' ib`latcontrol'.`latarmvar' ///
                if inlist(`latarmvar', `latcontrol', `lattreat') & ///
                    `lifetime_value' < ., ///
                vce(cluster `cluster')
            local coefficient "`lattreat'.`latarmvar'"
            post `output_handle' ("latent_benchmark") (`discount') ///
                (`horizon') (_b[`coefficient'] / _b[_cons])
            quietly drop `probability_clip' `geometric_sum' `lifetime_value'
        }
    }

    postclose `output_handle'
    use `output_data', clear
    order series delta Thor estimate
    sort delta series Thor
end
