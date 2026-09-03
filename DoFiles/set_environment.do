version 17.0

* Locate the replication-package root, activate the project-local Stata
* environment, and define settings shared by the cleaning and analysis files.
*
* Input:
*   environment/stata/activate.do
*
* Session settings:
*   $directorio   replication-package root
*   $star         esttab significance-star convention
*   $C0           branch and origination-day fixed effects

* Project root and isolated ado environment.
* Start Stata in the replication-package root before running this file.
local project_root `"`c(pwd)'"'
capture confirm file `"`project_root'/DoFiles/master.do"'
if _rc {
    display as error "Run this file from the replication-package root."
    exit 601
}
do `"`project_root'/environment/stata/activate.do"' `"`project_root'"'

* Significance-star convention used by esttab.
global star "star(* 0.1 ** 0.05 *** 0.01)"
* global star "nostar"

* Branch and origination-day fixed effects used by the regressions.
global C0 = "dummy_*"

* The project-local scheme is selected by environment/stata/activate.do.
