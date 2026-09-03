********************
version 17.0
********************

* One-time installer. Start Stata in the repository root, or pass it as arg 1.
args project_root
if `"`project_root'"' == "" {
    local project_root `"`c(pwd)'"'
}
do `"`project_root'/environment/stata/activate.do"' `"`project_root'"'

capture log close stata_env
log using "$directorio/environment/stata/install.log", text replace name(stata_env)

display as text "Installing into the project-local PLUS directory..."
local install_failed = 0

* Packages used by the analysis, appendix, and table/figure code.
* catplot 2.0.2 and rforest 2.0.3 are already bundled. The former preserves
* the syntax used by appendix/hist_den_default.do; the latter includes the
* exact Weka/RandomForest Java payload used by the supplementary analysis.
local ssc_packages "estout coefplot orth_out"
foreach package of local ssc_packages {
    display as text "Installing SSC package: `package'"
    capture noisily ssc install `package', replace
    if _rc {
        local install_failed = 1
        display as error "Installation failed for SSC package: `package'"
    }
}

* GitHub packages are pinned to immutable commits for this project environment.
display as text "Installing fan_park"
capture noisily net install fan_park, from("https://raw.githubusercontent.com/isaacmeza/fan_park/c2c6e83bca25ef3013c73b34c0c67502d78af72f") replace
if _rc {
    local install_failed = 1
    display as error "Installation failed for fan_park"
}

display as text "Installing tot_tut"
capture noisily net install tot_tut, from("https://raw.githubusercontent.com/isaacmeza/tot_tut/04f3a69700f9c4aab5991da27934ce79679103d0") replace
if _rc {
    local install_failed = 1
    display as error "Installation failed for tot_tut"
}

* R-backed analysis scripts invoke this third-party bridge.
display as text "Installing rscript"
capture noisily net install rscript, from("https://raw.githubusercontent.com/reifjulian/rscript/ef486af760dd44673682fe1fccfd326454bb5ea0") replace
if _rc {
    local install_failed = 1
    display as error "Installation failed for rscript"
}

capture noisily do "$directorio/environment/stata/verify.do" "$directorio"
local verify_failed = _rc

ado dir
log close stata_env

if `install_failed' | `verify_failed' {
    display as error "The local Stata environment is incomplete; inspect environment/stata/install.log."
    exit 499
}

display as result "Local Stata environment installed and verified."
