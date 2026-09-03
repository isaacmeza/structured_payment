********************
version 17.0
********************

* Fast functional test of the isolated environment; does not use project data.
args project_root
if `"`project_root'"' == "" {
    local project_root `"`c(pwd)'"'
}
do `"`project_root'/environment/stata/activate.do"' `"`project_root'"'

* estout, coefplot, orth_out, and the legacy catplot syntax used by this project.
sysuse auto, clear
eststo clear
quietly eststo smoke_reg: regress price mpg
esttab smoke_reg, se
coefplot smoke_reg, nodraw name(smoke_coefplot, replace)
orth_out price mpg, by(foreign) overall se count
catplot rep78, percent vertical nodraw name(smoke_catplot, replace)
graph drop _all

* rforest, including its bundled Java payload and prediction command.
rforest foreign mpg weight, type(class) iter(10) seed(1)
predict smoke_pr0 smoke_pr1, pr
assert !missing(smoke_pr0, smoke_pr1)

* fan_park.
clear
set obs 200
set seed 12345
generate treat = mod(_n, 2)
generate outcome = rnormal() + treat
fan_park outcome treat, delta_values(0) nograph

* tot_tut.
clear
set obs 300
set seed 12345
generate Z = mod(_n, 3)
generate choose = mod(_n, 2)
generate outcome = rnormal() + choose
tot_tut outcome Z choose

* Stata-to-R bridge, pinned to the R version recorded in renv.lock.
tempfile r_smoke_base
local r_smoke `"`r_smoke_base'.R"'
tempname r_handle
file open `r_handle' using `"`r_smoke'"', write text replace
file write `r_handle' "cat('rscript bridge ok\n')" _n
file close `r_handle'
rscript using `"`r_smoke'"', rversion(4.5.3 4.5.3)

display as result "Stata environment smoke test passed."
