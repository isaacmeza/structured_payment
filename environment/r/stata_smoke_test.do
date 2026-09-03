********************
version 17.0
********************

* Verify that Stata's rscript bridge launches the project-local renv library.
args project_root
if `"`project_root'"' == "" {
    local project_root `"`c(pwd)'"'
}

do `"`project_root'/environment/stata/activate.do"' `"`project_root'"'
rscript using "$directorio/environment/r/verify.R", rversion(4.5.3 4.5.3)
rscript using "$directorio/environment/r/smoke_test.R", rversion(4.5.3 4.5.3)

display as result "Stata-to-renv integration test passed."
