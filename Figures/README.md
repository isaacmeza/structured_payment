# Figure outputs

This folder contains the 34 graphics included by the main manuscript and its
appendices. Filenames match the exhibit numbers in the paper; lowercase panel
letters follow the order in which panels appear in the corresponding TeX
figure environment.

| Exhibit | Graphic file(s) | Direct source(s) |
|---|---|---|
| Figure 1 | `Figure1.pdf` | `DoFiles/main/consort_dates.do` updates `Figures/Figure1.xlsx`; manual PDF export |
| Figure 2 | `Figure2.pdf` | Static `Figures/ToT-TUT graph.xlsx`; manual PDF export |
| Figure 3 | `Figure3a.pdf`, `Figure3b.pdf`, `Figure3c.pdf` | `DoFiles/cleaning/prepare_data_te.do`, `DoFiles/cleaning/prepare_data_inst_forest.do`; `RScripts/te_grf.R`, `RScripts/tot_tut_instr_forest.R`; `DoFiles/main/cate_dist.do` |
| Figure 4 | `Figure4a.pdf`, `Figure4b.pdf` | `DoFiles/cleaning/prepare_data_inst_forest_btsp.do`; `RScripts/btsp_tot_tut_instr.R`, `RScripts/summarize_btsp_tot_tut_instr.R`; `DoFiles/main/plot_btsp_choose_wrong_tot_tut.do` |
| Figure 5 | `Figure5.pdf` | `DoFiles/main/partition_tut.do` |
| Figure OA-1 | `FigureOA1.png` | Supplied static asset `Figures/FigureOA1.png` |
| Figure OA-2 | `FigureOA2.pdf` | `DoFiles/appendix/weekly_def_rates.do` |
| Figure OA-3 | `FigureOA3a.pdf`--`FigureOA3d.pdf` | `DoFiles/appendix/hist_den_default.do` |
| Figure OA-4 | `FigureOA4.pdf` | `DoFiles/appendix/determinants_choice.do` |
| Figure OA-5 | `FigureOA5a.pdf`, `FigureOA5b.pdf` | `DoFiles/appendix/survival_graph.do` |
| Figure OA-6 | `FigureOA6a.pdf`, `FigureOA6b.pdf` | `DoFiles/appendix/cumulative_porc_pay_time.do` |
| Figure OA-7 | `FigureOA7.pdf` | `DoFiles/appendix/profit_difference.do` |
| Figure OA-8 | `FigureOA8a.pdf`--`FigureOA8d.pdf` | `DoFiles/appendix/profit_difference_robust.do`, `DoFiles/appendix/copula_functions.do` |
| Figure OA-9 | `FigureOA9.pdf` | `DoFiles/appendix/fan_park_bnds.do` |
| Figure OA-10 | `FigureOA10.pdf` | `DoFiles/appendix/te_rankinvariance.do` |
| Figure OA-11 | `FigureOA11.pdf` | `DoFiles/appendix/discounted_noeffect.do` |
| Figure OA-12 | `FigureOA12.pdf` | `DoFiles/appendix/determinants_sure_confidence.do` |
| Figure OA-13 | `FigureOA13a.pdf`, `FigureOA13b.pdf` | `DoFiles/appendix/po_decomposition.do` |
| Figure OA-14 | `FigureOA14.pdf` | `DoFiles/appendix/partition_tut_promise.do` |
| Figure OA-15 | `FigureOA15a.pdf`, `FigureOA15b.pdf` | `DoFiles/appendix/SC_prepayment.do` |
| Figure SA-1 | `FigureSA1.pdf` | `DoFiles/cleaning/prepare_data_te.do`; `RScripts/sa_wide_narrow_grf.R`; `DoFiles/appendix/wide_narrow_forests.do` |

Most graphics are exported directly by the analysis files listed above. Three
graphics require a manual or static step:

- `Figure1.pdf`: `DoFiles/main/consort_dates.do` updates `Figure1.xlsx` in this
  folder; export the workbook's `consort` sheet to PDF manually.
- `Figure2.pdf`: update and export `ToT-TUT graph.xlsx` manually.
- `FigureOA1.png`: static manuscript input; no editable source or generating
  script is currently included.

The analysis scripts do not generate unreported diagnostic graphs.

`FigureOA2.pdf` combines the experimental sample with the supplied
confidentiality-reduced `Raw/base_expansion.dta` observational extract.
