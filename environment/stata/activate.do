********************
version 17.0
********************

* Activate the project-local Stata environment for the current session.
* Run Stata from the repository root, or pass the repository root as arg 1.

args project_root
if `"`project_root'"' == "" {
    local project_root `"`c(pwd)'"'
}
local project_root : subinstr local project_root "\" "/", all

capture confirm file `"`project_root'/DoFiles/master.do"'
if _rc {
    display as error "Could not find DoFiles/master.do under: `project_root'"
    display as error "Change directory to the replication-package root and activate again."
    exit 601
}

global directorio `"`project_root'"'
cd "$directorio"
set more off

* Fix both random-number and tied-sort engines so results do not inherit a
* user's session settings. Individual stochastic analyses set their own seeds.
set rng mt64
set sortseed 20260819

* Keep all nonofficial ado locations inside this project.
capture mkdir "$directorio/environment/stata/ado"
capture mkdir "$directorio/environment/stata/ado/site"
capture mkdir "$directorio/environment/stata/ado/plus"
capture mkdir "$directorio/environment/stata/ado/personal"
capture mkdir "$directorio/environment/stata/ado/oldplace"

sysdir set SITE     "$directorio/environment/stata/ado/site"
sysdir set PLUS     "$directorio/environment/stata/ado/plus"
sysdir set PERSONAL "$directorio/environment/stata/ado/personal"
sysdir set OLDPLACE "$directorio/environment/stata/ado/oldplace"

* Give this project's PLUS directory precedence over custom profile paths.
capture adopath - PLUS
adopath ++ PLUS

* The scheme is bundled under PLUS/s. Do not change the user's permanent default.
set scheme white_tableau1

display as result "Project Stata environment active: $directorio"
display as text   "Community ado directory: $directorio/environment/stata/ado/plus"
