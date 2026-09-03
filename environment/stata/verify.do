********************
version 17.0
********************

args project_root
if `"`project_root'"' == "" {
    local project_root `"`c(pwd)'"'
}
do `"`project_root'/environment/stata/activate.do"' `"`project_root'"'

local verify_failed = 0
local required_commands "estadd eststo esttab coefplot catplot orth_out rforest fan_park tot_tut rscript"

foreach command of local required_commands {
    capture findfile `command'.ado
    if _rc {
        local verify_failed = 1
        display as error "Missing required command: `command'"
    }
    else {
        local command_path `"`r(fn)'"'
        if strpos(`"`command_path'"', "$directorio/environment/stata/ado/") != 1 {
            local verify_failed = 1
            display as error "`command' resolved outside the project: `command_path'"
        }
        else {
            display as result "`command': `command_path'"
        }
    }
}

capture findfile scheme-white_tableau1.scheme
if _rc {
    local verify_failed = 1
    display as error "Missing graph scheme: white_tableau1"
}
else {
    local scheme_path `"`r(fn)'"'
    if strpos(`"`scheme_path'"', "$directorio/environment/stata/ado/") != 1 {
        local verify_failed = 1
        display as error "white_tableau1 resolved outside the project: `scheme_path'"
    }
    else {
        display as result "white_tableau1: `scheme_path'"
    }
}

display as text "Stata version: `c(stata_version)'"
sysdir

if `verify_failed' {
    exit 499
}
display as result "All required Stata commands and the graph scheme were found."
