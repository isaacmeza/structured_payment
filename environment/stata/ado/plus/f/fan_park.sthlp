{smcl}
{* *! version 1.0.2  10oct2025}{...}
{viewerjumpto "Syntax" "fan_park##syntax"}{...}
{viewerjumpto "Description" "fan_park##description"}{...}
{viewerjumpto "Options" "fan_park##options"}{...}
{viewerjumpto "Examples" "fan_park##examples"}{...}
{viewerjumpto "Stored results" "fan_park##stored_results"}{...}
{viewerjumpto "Remarks" "fan_park##remarks"}{...}
{viewerjumpto "References" "fan_park##references"}{...}
{viewerjumpto "Authors" "fan_park##authors"}{...}

{title:Title}

{p 4 8}{cmd:fan_park} {hline 2} Sharp bounds on the distribution (and quantile function) of treatment effects for a binary treatment, with optional covariate tightening and pointwise inference.{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:fan_park} {it:depvar} {it:treatvar} [{it:indepvars}] {ifin}
[{cmd:,}
{cmd:delta_partition(}{it:#}{cmd:)}
{cmd:delta_values(}{it:numlist}{cmd:)}
{cmd:cov_partition(}{it:#}{cmd:)}
{cmd:level(}{it:#}{cmd:)}
{cmd:nograph}
{cmd:seed(}{it:#}{cmd:)}
{cmd:qbounds}
{cmd:num_quantiles(}{it:#}{cmd:)}
]{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:fan_park} implements the sharp, nonparametric bounds on the distribution of treatment effects for a binary treatment developed by Fan and Park (2010, {it:Econometric Theory}). Let {it:δ = Y1 - Y0}. Given the marginal distributions {it:F1} and {it:F0}, the command estimates pointwise sharp bounds
{it:F_L(δ) <= F_δ(δ) <= F_U(δ)} over a grid of {it:δ} values (the distribution-function branch).

{pstd}
With option {cmd:qbounds}, the command instead computes bounds on the quantile function {it:F^{-1}_δ(q)}:
{it:F^{-1,U}(q) <= F^{-1}_δ(q) <= F^{-1,L}(q)} (the quantile-function branch). No standard errors are reported in this branch.

{pstd}
When {it:indepvars} are provided, the covariate space is partitioned by {cmd:cluster kmedians}. Conditional bounds are computed within each cell using cell-specific supports and then averaged with empirical cell weights. The reported bounds intersect the unconditional and the averaged-conditional bounds, which can tighten the region under heterogeneity and overlapping-support restrictions.

{marker options}{...}
{title:Options}

{synoptset 28 tabbed}{...}
{synopthdr :Options}
{synoptline}
{synopt:{opt delta_partition(#)}}Number of grid points for the support of {it:δ = Y1 - Y0} when computing distribution-function bounds; default {cmd:100}.{p_end}
{synopt:{opt delta_values(numlist)}}Explicit grid of {it:δ} values at which to compute bounds. Values outside the feasible range [{it:a - d}, {it:b - c}] are ignored. Supersedes {cmd:delta_partition()}.{p_end}
{synopt:{opt cov_partition(#)}}If {it:indepvars} are supplied, number of k-medians clusters used to partition covariate space (tightening the bounds); default {cmd:6}.{p_end}
{synopt:{opt level(#)}}Confidence level for pointwise confidence intervals on distribution-function bounds; default {cmd:95}. The graph shows 95% and 90% bands by default.{p_end}
{synopt:{opt nograph}}Suppress the graph.{p_end}
{synopt:{opt seed(#)}}Initialization passed to {cmd:cluster ... start(krandom(#))}. With the default {cmd:seed(1)}, a random integer is drawn internally; set a fixed integer for replication.{p_end}
{synopt:{opt qbounds}}Compute bounds for the quantile function of {it:δ} instead of the CDF (no SEs/CIs reported).{p_end}
{synopt:{opt num_quantiles(#)}}Number of equally spaced quantiles in [0,1] for {cmd:qbounds}; default {cmd:100}.{p_end}
{synoptline}

{marker examples}{...}
{title:Examples}

{title:Baseline usage}
{phang2}{stata "use limits_commitment.dta, clear"}{p_end}
{phang2}{stata "fan_park apr treat"}{p_end}

{title:With covariates (potential tightening)}
{phang2}{stata "fan_park apr treat age educ, cov_partition(6)"}{p_end}

{title:Specify the δ grid explicitly}
{phang2}{stata "fan_park apr treat, delta_values(-10(0.5)10)"}{p_end}

{title:Quantile-function bounds}
{phang2}{stata "fan_park apr treat, qbounds num_quantiles(200)"}{p_end}

{title:Simulation}
{phang2}{stata "do simulation_fan_park.do"}{p_end}

{marker stored_results}{...}
{title:Stored results}

{pstd}{cmd:fan_park} stores the following in {cmd:r()}.

{p2colset 5 24 26 2}{...}
{p2col :{cmd:r(bounds)}}Distribution-function branch: {it:n x 2} matrix with columns {cmd:LB} and {cmd:UB}, evaluated at {cmd:r(delta_val)}.
Quantile-function branch: {it:n x 2} matrix with quantile-function bounds {cmd:UB} and {cmd:LB}, evaluated at {cmd:r(q_val)}.{p_end}
{p2col :{cmd:r(sigma_2)}}Distribution-function branch only. {it:n x 2} matrix of large-sample variances for the active lower and upper bound at each {it:δ} (columns {cmd:Var_L}, {cmd:Var_U}).{p_end}
{p2col :{cmd:r(M_delta)}}Distribution-function branch only. {it:n x 2} matrix; column 1 stores {it:M(δ) = sup over y of [F1(y) - F0(y - δ)]}, column 2 stores {it:m(δ) = inf over y of [F1(y) - F0(y - δ)]}.{p_end}
{p2col :{cmd:r(M_active)}}Distribution-function branch only. {it:n x 2} matrix with the sup/inf values corresponding to the bound that is actually active at each {it:δ} after intersecting unconditional and conditional bounds (columns {cmd:M_L_active}, {cmd:M_U_active}).{p_end}
{p2col :{cmd:r(delta_val)}}Distribution-function branch only. {it:n x 1} grid of {it:δ} values used for {cmd:r(bounds)}.{p_end}
{p2col :{cmd:r(q_val)}}Quantile-function branch only. {it:n x 1} grid of quantiles in [0,1] used for {cmd:r(bounds)}.{p_end}
{p2colreset}{...}

{marker remarks}{...}
{title:Remarks}

{pstd}
{it:Computation.} The command builds empirical CDFs of {it:Y1} and {it:Y0 + δ} via {cmd:cumul}, interpolates with {cmd:ipolate}, and searches the intersection support {it:Y_δ = [a,b] intersect [c + δ, d + δ]}. With covariates, the same is done cell-by-cell using cell-specific supports {[a_c, b_c]} and {[c_c, d_c]}, and then averaged across cells using empirical shares.

{pstd}
{it:Interpretation.} {cmd:r(bounds)} contains the final (possibly tightened) bounds after intersecting unconditional and conditional averages. {cmd:r(M_delta)} reports the raw sup/inf from the unconditional step; {cmd:r(M_active)} reports the sup/inf corresponding to whichever bound is active at each {it:δ} (used for the one-sidedness adjustment in CIs).

{pstd}
{it:Positivity and empty cells.} A cluster with no treated or no controls is skipped; weights are renormalized over remaining cells and a note is displayed. If all cells are dropped at a given {it:δ} (rare), the conditional piece is missing and the unconditional bound is reported.

{pstd}
{it:Inference.} CIs are pointwise (not uniform) and based on large-sample normal approximations. The graph displays 95% and 90% bands by default. For {cmd:qbounds}, CIs are not reported; if needed, consider bootstrap inference away from boundary cases.

{marker references}{...}
{title:References}

{pstd}
Fan, Yanqin, and Sang Soo Park (2010). “Sharp bounds on the distribution of treatment effects and their statistical inference.” {it:Econometric Theory} 26(3): 931–951. DOI: 10.1017/S0266466609990168

{marker authors}{...}
{title:Authors}

{pstd}
Isaac Meza López, Department of Economics, Harvard University.
{browse "mailto:isaacmezalopez@g.harvard.edu":isaacmezalopez@g.harvard.edu}
