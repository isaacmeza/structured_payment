version 17.0

* Clean the shared administrative and survey data, then prepare the small CSV
* inputs that feed the forests used in Main Figures 3 and 4.

do "./DoFiles/set_environment.do"

capture mkdir "$directorio/DB"
capture mkdir "$directorio/_aux"

* Shared cleaned datasets.
do "$directorio/DoFiles/cleaning/cleaning_admin.do"
do "$directorio/DoFiles/cleaning/cleaning_master.do"

* Feed the causal and instrumental forests used in Main Figure 3.
do "$directorio/DoFiles/cleaning/prepare_data_te.do"
do "$directorio/DoFiles/cleaning/prepare_data_inst_forest.do"

* Feed the deterministic Bayesian-bootstrap forests used in Main Figure 4.
do "$directorio/DoFiles/cleaning/prepare_data_inst_forest_btsp.do"
