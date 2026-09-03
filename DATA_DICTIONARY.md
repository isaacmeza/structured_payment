# Data guide and processed-data dictionary

This guide describes the files supplied under `Raw/` and the four datasets
created under `DB/` by `DoFiles/master_cleaning.do`. The generated `DB/` files
are not distributed in the clean replication archive; they are rebuilt from
the supplied inputs.

## Supplied files

| File | Description and role |
|---|---|
| `20131014Consilidacion_Agosto_2013.dta` | Administrative pawn-loan ledger. Each row is a movement on a pawn ticket, such as origination, payment, renewal, recovery, or sale/default. This is the main source for the cleaned administrative outcomes and transaction panels. |
| `Base_Encuestas_Basales_24_05_2013.dta` | Baseline intake-survey responses collected around loan origination. Raw responses may contain more than one row for a pawn ticket; `cleaning_master.do` harmonizes them to one pawn-level record and links them to administrative outcomes. |
| `Muestra Aleatoria en Excel con nombres de sucursales.xlsx` | Branch-by-date randomization calendar. Each row is a date and the columns record the assigned experimental arm at each of the six branches. It is used to reconstruct the experiment timeline and take-up statistics. |
| `db_product.dta` | Pawn-level product crosswalk. It contains one row per experimental pawn ticket and supplies the randomized arm and realized contract/product. |
| `base_expansion.dta` | Confidentiality-reduced observational extract used only for OA Figure 2. Each row is an eligible observational loan and retains only its origination date (`fechaaltadelprestamo`) and a sale/default proxy (`def_vta`, equal to 1 when the restricted source recorded a sale date). No loan identifier is retained, so repeated date/outcome rows represent loan multiplicity. It was derived from a restricted transaction database whose raw-to-extract construction is outside the portable package. |
| `Diccionario_base_Seira.xlsx` | Spanish variable dictionary for the omitted restricted parent transaction database. It is provenance documentation, not the dictionary for the two-variable `base_expansion.dta`, and is not read by the code. |

## Generated DB datasets

The row counts below are from the clean replication run. `prenda` is a pawn
ticket/loan identifier and `NombrePignorante` is the numeric borrower linkage
identifier retained in the source data.

| Code | Dataset | Unit of observation | Rows | Key and purpose |
|---|---|---:|---:|---|
| `M` | `Master.dta` | First-visit pawn ticket | 16,676 | `prenda` is unique. Main analysis file combining administrative outcomes, treatment assignment, and baseline-survey covariates. |
| `A` | `Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta` | Pawn ticket across all retained borrower visits | 26,180 | `prenda` is unique. Administrative pawn-level cross-section used to construct `Master.dta` and OA Table 1. |
| `P` | `Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2fv.dta` | Movement on a first-visit pawn ticket | 48,606 | Multiple rows per `prenda`; no unique row key is retained, and exact duplicate retained rows can represent separate source movements. Compact transaction panel used by OA Figures 6 and 15. |
| `F` | `Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2fv.dta` | First-visit pawn ticket | 16,676 | The pawn identifier is intentionally omitted, so no unique row key is retained and repeated branch/date/product rows represent different pawns. Minimal file used by Main Figure 1. |

The `Datasets` column below uses these four codes. Monetary amounts are Mexican
pesos. Dates are Stata daily dates. Variables described as ratios are stored as
fractions (for example, `0.25`, not 25). Unless stated otherwise, indicators are
`1=yes`, `0=no`, and missing when the underlying response or comparison sample
is unavailable.

## Common categorical codes

| Variable | Codes |
|---|---|
| `suc` | `3` Calzada; `5` Congreso; `42` Insurgentes; `78` Jose Marti; `80` San Cosme; `104` San Simon. |
| `t_producto` | `1` Control; `2` Mandatory structured; `3` Promise Mandate; `4` Choice; `5` Promise Choice. |
| `producto` | `1` Control; `2` No Choice/Fee; `3` No Choice/Promise; `4` Choice/Fee-SQ; `5` Choice/Fee-NSQ; `6` Choice/Promise-SQ; `7` Choice/Promise-NSQ. |
| `clave_movimiento` | `1` Abono a Capital; `2` Venta con Billete; `3` Desempeno; `4` Empeno; `5` Refrendo; `6` Pase al Moneda. |
| `genero` | `0` Hombre; `1` Mujer. |
| Survey yes/no fields | `0` No; `1` Si. This label applies to `fam_pide`, `pres_antes`, `ahorros`, `cta_tanda`, `fam_comun`, and `rec_cel`. |
| `t_consis1` | `0` chooses 100 tomorrow; `1` chooses 150 in one month. |
| `t_consis2` | `0` chooses 100 in three months; `1` chooses 150 in four months. |

## Processed variable dictionary

### Identifiers, assignment, and timing

| Variable | Datasets | Definition |
|---|---|---|
| `prenda` | `M A P` | Pawn ticket/loan identifier; unique only in `M` and `A`. |
| `NombrePignorante` | `M A` | Numeric borrower/pledgor linkage identifier used to connect multiple pawn tickets. |
| `suc` | `M A F` | Branch code; see the common codes above. |
| `suc_x_dia` | `M A P` | Sequential cluster identifier for the branch-by-origination-date combination. |
| `fecha_inicial` | `M A F` | Loan origination/admission date. |
| `fecha_movimiento` | `A P` | Administrative movement date; in `A`, the date of the selected last movement. |
| `HoraMovimiento` | `A P` | Administrative movement time stored as an eight-character string; in `A`, the time of the selected last movement. |
| `clave_movimiento` | `A P F` | Administrative movement type; see the common codes above. In `A` and `F`, this is the selected last movement. |
| `dias_inicio` | `P` | Elapsed days from loan origination to the movement date. |
| `dow` | `A` | Stata day of week for loan origination (`0` Sunday through `6` Saturday). |
| `producto` | `M A F` | Realized contract/product; see the common codes above. |
| `t_producto` | `M A P` | Randomized treatment arm; see the common codes above. |
| `pro_2` | `M A` | Mandatory-structured comparison: 1 for treatment arm 2, 0 for control, missing for all other arms. |
| `pro_6` | `M A` | Choice/Fee-SQ comparison: 1 for product 4, 0 for control product 1, missing for other products. |
| `pro_7` | `M A` | Choice/Fee-NSQ comparison: 1 for product 5, 0 for control product 1, missing for other products. |
| `choose_commitment` | `M A` | Choice-arm take-up indicator: 1 for structured variants 5 or 7 and 0 for status-quo variants 4 or 6; missing outside the choice arms. |
| `visit_number` | `A` | Borrower's chronological pawnshop-visit number, capped at the sample 99th percentile (7). |
| `first_pawn` | `M A` | Indicator for the borrower's first observed distinct pawnshop visit/date. |
| `concluyo_c` | `M A` | Indicator that the loan is classified as ended during the observation window through recovery, default, sale, or a final unpaid condition. |

### Payments, outcomes, and financial costs

| Variable | Datasets | Definition |
|---|---|---|
| `prestamo_i` | `M A` | Original loan principal in pesos; the cleaning excludes the five loans above 57,000 pesos. |
| `porc_pagos` | `P` | Movement-level customer payment, including any applicable paid fee, divided by loan principal. |
| `first_pay` | `M A` | Total positive payment amount on the pawn's first payment date; 0 if no payment is observed. |
| `sum_p_c` | `M A` | Final cumulative customer payments, including applicable paid fees. |
| `sum_int_c` | `M A` | Final cumulative paid interest. |
| `sum_pay_fee_c` | `M A` | Final cumulative paid structured-payment fees. |
| `sum_inc_int` | `M A` | Cumulative interest incurred under the contractual formula, including accrual through the observation end for unresolved loans. |
| `pays_c` | `M A` | Indicator that cumulative payments are positive. |
| `mn_p105_c` | `M A` | Mean nonzero payment through elapsed day 110, excluding origination and `Pase al Moneda` records; 0 if none. |
| `mn_p210_c` | `M A` | Mean nonzero payment during elapsed days 111--220, excluding origination and `Pase al Moneda` records; 0 if none. |
| `sum_porcp_c` | `M A` | Final cumulative payments divided by principal. |
| `sum_porcp30_c` | `M A` | Cumulative payments divided by principal through day 35 (the named 30-day horizon plus grace period). |
| `sum_porcp60_c` | `M A` | Cumulative payments divided by principal through day 65. |
| `sum_porcp90_c` | `M A` | Cumulative payments divided by principal through day 95. |
| `sum_porcp105_c` | `M A` | Cumulative payments divided by principal through day 110. |
| `sum_porcp150_c` | `M A` | Cumulative payments divided by principal through day 155. |
| `sum_porcp180_c` | `M A` | Cumulative payments divided by principal through day 185. |
| `sum_porcp210_c` | `M A` | Cumulative payments divided by principal through day 220. |
| `sum_porc105_int_c` | `M A` | Maximum cumulative paid interest divided by principal through day 110. |
| `sum_porc210_int_c` | `M A` | Maximum cumulative paid interest divided by principal through day 220. |
| `num_p` | `M A` | Number of nonzero payment transaction rows. |
| `num_v` | `M A` | Number of distinct dates with a nonzero payment (customer payment visits). |
| `des_i_c` | `A` | Recovery indicator: 1 if any recovery movement is observed. |
| `def_i_c` | `A` | Default indicator: ended loan not recovered. Unresolved/censored loans also equal 0 and are distinguished using `concluyo_c`. |
| `ref_c` | `M A` | Indicator that any renewal (`Refrendo`) is observed. |
| `dias_primer_pago` | `M A` | Minimum elapsed day of a principal payment, recovery, or renewal; missing if none is observed. |
| `dias_ultimo_mov` | `M A` | Elapsed days from origination to the last retained movement. |
| `dias_al_desempenyo` | `M A` | Elapsed days to recovery for recovered pawns; same-day recovery is recorded as day 1. |
| `dias_al_default` | `M A` | Default timing based on the last movement, with selected cases assigned to contract-cycle endpoints 105, 210, or 315. |
| `zero_pay_default` | `M A` | Indicator for a classified default with no cumulative payment. |
| `first_dias_des` | `M A` | Recovery timing for the borrower's first observed visit, when recovered. |
| `days_second_pawns` | `M A` | Calendar days from the borrower's first to second observed pawn date; missing if no second date exists. |
| `reincidence` | `M A` | Indicator that the borrower has more than one distinct observed pawn date. |
| `reincidence_other` | `M A` | Repeat-pawn indicator whose second principal is outside plus/minus 2.5% of the first, used as a proxy for different collateral. |
| `fc_i_admin` | `A` | Administrative financial cost in pesos. For recovered/unresolved loans it is interest plus fees; for defaults it is payments plus `(0.3/0.7) * principal`. |
| `cr_i` | `A` | `fc_i_admin / prestamo_i`. |
| `cost_losing_pawn` | `M A` | For defaults, payments minus interest and fees plus `(0.3/0.7) * principal`; 0 otherwise. |
| `downpayment_capital` | `M A` | For defaults, payments minus interest and fees; 0 otherwise. |

### Baseline survey and Master-only constructed variables

| Variable | Datasets | Definition |
|---|---|---|
| `f_encuesta` | `M` | Baseline survey date. |
| `pr_recup` | `M` | Elicited subjective probability, from 0 to 100, that the borrower will recover the pawn. |
| `genero` | `M` | Reported gender (`0` man, `1` woman). |
| `edad` | `M` | Borrower age in years. |
| `fam_pide` | `M` | Indicator that family asked the respondent for money during the month. |
| `t_consis1` | `M` | Near-term intertemporal choice; see the common codes above. |
| `pres_antes` | `M` | Indicator that the respondent had pawned before. |
| `ahorros` | `M` | Indicator that the respondent reports savings. |
| `cta_tanda` | `M` | Indicator that the respondent participates in a rotating savings group (`tanda`). |
| `fam_comun` | `M` | Indicator that family asking the respondent for money is common. |
| `c_trans` | `M` | Reported transport cost to the branch, treated as pesos in the analysis. Responses are recovered across all pawns belonging to the same borrower; values that remain missing are replaced with the overall mean across pawn observations with nonmissing transport cost. |
| `t_llegar` | `M` | Reported travel time to the branch; the source dataset does not encode a unit. |
| `t_consis2` | `M` | Later intertemporal choice; see the common codes above. |
| `rec_cel` | `M` | Yes/no baseline-survey response concerning a cellphone reminder; the exact question wording appears in `Tables/TableOA7.tex`. |
| `val_pren_orig` | `M` | Cleaned subjective pawn value in pesos after the loan-implied floor, 99th-percentile winsorization, and first regression-imputation step; capped at 2.14489 times principal. It can remain missing when predictors for that first imputation are unavailable. |
| `fc_survey` | `M` | Financial cost in pesos using the final internally cleaned subjective pawn value for defaults and administrative interest/fees otherwise. That final subjective-value variable is not retained separately in `Master.dta`. |
| `cr_survey` | `M` | `fc_survey / prestamo_i`. |
| `fc_tc` | `M` | Administrative financial cost plus transaction cost, where transaction cost is `(c_trans + 62.33) * num_v`. |
| `cr_tc` | `M` | `fc_tc / prestamo_i`. |
| `fc_int` | `M` | Financial cost excluding paid interest. |
| `cr_int` | `M` | `fc_int / prestamo_i`. |
| `fc_fa` | `M` | Fully adjusted financial cost: the final internally cleaned subjective pawn value and transaction cost are included for defaults, while paid interest is excluded. |
| `cr_fa` | `M` | `fc_fa / prestamo_i`. |
| `masqueprepa` | `M` | Indicator for completed high school or more (`educacion >= 3`). |
| `estresado_seguido` | `M` | Indicator for frequent stress according to the baseline response (`f_estres < 3`). |
| `hace_presupuesto` | `M` | Indicator that the household makes an expense budget (`plan_gasto == 2`). |
| `pb` | `M` | Present-bias indicator constructed from the two intertemporal choices: chooses 100 tomorrow over 150 in one month but chooses 150 in four months over 100 in three months. |
| `faltas` | `M` | Share of seven answered household-expense categories for which the respondent reports payment problems (`renta`, `comida`, `medicina`, `luz`, `gas`, `telefono`, and `agua`). |
| `tentado` | `M` | Temptation/self-control indicator (`tempt >= 2`). |
| `low_cost` | `M` | Indicator that transport cost is at or below the pooled sample median after overall-mean imputation. |
| `low_time` | `M` | Indicator that reported travel time is at or below the pooled sample median. |
| `dummy_dow2` | `M` | Origination-day indicator for Tuesday (`dow == 2`); Monday is the omitted observed category. |
| `dummy_dow3` | `M` | Origination-day indicator for Wednesday (`dow == 3`). |
| `dummy_dow4` | `M` | Origination-day indicator for Thursday (`dow == 4`). |
| `dummy_dow5` | `M` | Origination-day indicator for Friday (`dow == 5`). |
| `dummy_dow6` | `M` | Origination-day indicator for Saturday (`dow == 6`). |
| `dummy_suc2` | `M` | Branch indicator for Congreso; Calzada is the omitted branch. |
| `dummy_suc3` | `M` | Branch indicator for Insurgentes. |
| `dummy_suc4` | `M` | Branch indicator for Jose Marti. |
| `dummy_suc5` | `M` | Branch indicator for San Cosme. |
| `dummy_suc6` | `M` | Branch indicator for San Simon. |
| `confidence_100` | `M` | Indicator that `pr_recup == 100`, i.e. complete stated confidence in recovery. |
| `des_c` | `M` | Analysis alias of the administrative recovery indicator `des_i_c`. |
| `def_c` | `M` | Analysis alias of the administrative default indicator `def_i_c`. |
| `fc_admin` | `M` | Analysis alias of `fc_i_admin`, administrative financial cost in pesos using appraised value. |
| `cr` | `M` | Analysis alias of `cr_i`, administrative financial cost divided by principal. |
| `prestamo` | `M` | Analysis alias of `prestamo_i`, original loan principal in pesos. |
