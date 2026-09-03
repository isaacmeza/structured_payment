{smcl}
{* *!version 1.0.3  2023-01-19}{...}
{viewerjumpto "Syntax" "tot_tut##syntax"}{...}
{viewerjumpto "Description" "tot_tut##description"}{...}
{viewerjumpto "Options" "tot_tut##options"}{...}
{viewerjumpto "Examples" "tot_tut##examples"}{...}
{viewerjumpto "Stored results" "tot_tut##stored_results"}{...}
{viewerjumpto "References" "tot_tut##references"}{...}
{viewerjumpto "Authors" "tot_tut##authors"}{...}

{title:Title}

{p 4 8}{cmd:tot_tut} {hline 2} Implementation for the estimation of treatment on the treated (ToT), treatment on the untreated (TuT) and the average treatment effect (ATE) jointly using the design introduced in "Structured Payment in Pawnshop Borrowing: Mandates vs. Choice". Other causal statistics of interest like the average selection bias and the average selection on the level are also provided. {p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:tot_tut} {it:depvar} {it:treatvar} {it:choicevar} {ifin} 
[{cmd:,} 
{cmd:vce(robust | cluster {it:clustvar}{cmd:)}}
{cmd:pvals} 
{cmd:b_rep1(}{it:#}{cmd:)}  
{cmd:b_rep2(}{it:#}{cmd:)}  
]{p_end}

{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{p 4 8}{cmd:tot_tut} estimates jointly the treatment on the treated (ToT), treatment on the untreated (TuT), the average treatment effect, selection on gains, selection bias, and selection on the level, exploiting a design with three arms: a control arm, a forced arm and a choice arm. The specification strategy involves estimating two iv regressions per each selection estimand, and jointly obtaining errors. Moreover, the command displays bounds for the ToT and TuT without imposing exclusion restriction (only for continuously supported dependent variables), and where indicated, also p-values for the violation of the IV validity. Details on the implementation can be found in the paper "Structured Payment in Pawnshop Borrowing: Mandates vs. Choice" and its accompanying appendix.

Note : Jointly inference for selection on gains, selection bias, and selection on the level is not provided. 


{marker arguments}{...}
{title:Arguments}
{dlgtab:Arguments}

{p 8 8} {it:depvar}, this is the outcome of interest.{p_end}

{p 8 8} {it:treatvar}, categorical variable indicating treatment status: control arm (0), forced arm (1), choice arm (2). {p_end}

{p 8 8} {it:choicevar}, binary variable indicating choice.{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Options}

{p 4 8}{cmd:vce(robust | cluster {it:clustvar}{cmd:)}} specifies the type of standard error reported, which includes types that are robust to some kinds of misspecification (robust - the default), and that allow for intragroup correlation (cluster {it:clustvar}).{p_end}

{p 4 8}{cmd:pvals}, if specified presents p-values for the violation of the IV validity. For details see Huber & Mellace (2015).{p_end}

{p 4 8}{cmd:b_rep1(}{it:#}{cmd:)} Indicates the number of bootstrap replications for the first boostrap in the computation of the p-value for the IV validity. Default is {cmd:b_rep1(50)}{p_end}

{p 4 8}{cmd:b_rep2(}{it:#}{cmd:)} Indicates the number of bootstrap replications for the second boostrap in the computation of the p-value for the IV validity. Default is {cmd:b_rep1(50)}{p_end}

{hline}


{marker examples}{...}
{title: Examples}

{title: "Structured Payment in Pawnshop Borrowing: Mandates vs. Choice"}

{p 4 8}Setup{p_end}
{p 8 8}{stata "use tot_tut_commitment.dta, clear"}{p_end}
{p 8 8}{stata "gen x0 = -(Z==2)*(choose==0)"}{p_end}
{p 8 8}{stata "gen x1 = (Z==2)*(choose==1)"}{p_end}
{p 8 8}{stata "gen z0_ = -(Z==0)"}{p_end}
{p 8 8}{stata "gen z0 = (Z==0)"}{p_end}
{p 8 8}{stata "gen z1 = (Z==1)"}{p_end}
{p 8 8}{stata "gen z2 = (Z==2)"}{p_end}

{p 4 8}ToT & ATE using ivregress {p_end}
{p 8 8}{stata "ivregress 2sls apr z1 (x1 = z2), vce(cluster clustvar)"}{p_end}

{p 4 8}TuT & ATE using ivregress {p_end}
{p 8 8}{stata "ivregress 2sls apr z0_ (x0 = z2), vce(cluster clustvar)"}{p_end}

{p 4 8}Simultaneous inference for ToT & TuT - selection on gains{p_end}
{p 8 8}{stata "tot_tut apr Z choose, vce(cluster clustvar)"}{p_end}

{p 4 8}Simultaneous inference for ToT & TuT, and p-values for IV validity{p_end}
{p 8 8}{stata "tot_tut apr Z choose, vce(cluster clustvar) pvals b_rep1(50) b_rep2(50)"}{p_end}


{marker stored_results}{...}
{title:Stored results}

{p 4 8}{cmd:tot_tut} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}

{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations.{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom.{p_end} 
{synopt:{cmd:e(pval_tot)}}p-value for the violation of the exclusion restriction for the treated.{p_end}
{synopt:{cmd:e(pval_tut)}}p-value for the violation of the exclusion restriction for the un-treated.{p_end}
{synopt:{cmd:e(pval_tot_tut)}}p-value for the simultaneous violation of the exclusion restriction.{p_end}


{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient fector.{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators.{p_end}

{p 4 8}{cmd:tot_tut} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}

{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(ub_tut)}}Upper bound for the TuT without exclusion.{p_end}
{synopt:{cmd:r(lb_tut)}}Lower bound for the TuT without exclusion.{p_end}
{synopt:{cmd:r(ub_tot)}}Upper bound for the ToT without exclusion.{p_end}
{synopt:{cmd:r(lb_tot)}}Lower bound for the ToT without exclusion.{p_end}


{marker references}{...}
{title:References}

{p 4 8}{browse "https://doi.org/10.48550/arXiv.2608.13775": DiTraglia, McIntosh, Meza, Sadka, Seira.} "Structured Payment in Pawnshop Borrowing: Mandates vs. Choice". arXiv:2608.13775. {p_end}

{p 4 8} Huber, M., & Mellace, G. (2015). TESTING INSTRUMENT VALIDITY FOR LATE IDENTIFICATION BASED ON INEQUALITY MOMENT CONSTRAINTS. The Review of Economics and Statistics, 97(2), 398–411. {p_end}



{marker authors}{...}
{title:Authors}

{p 4 8}Meza Lopez Isaac; Harvard, Economics.
{browse "mailto:isaacmezalopez@g.harvard.edu": isaacmezalopez@g.harvard.edu}.{p_end}