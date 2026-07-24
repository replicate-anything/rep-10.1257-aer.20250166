* Step: tab_2 - Table 2: MVPF vs. cost-per-ton, with and without learning-by-doing
* Aggregate table (parents: compute_mvpf_main, compute_mvpf_no_lbd) - the only
* step that needs both full-sample runs.
* KNOWN GAP: figtab/cost_per_ton.do also imports the missing policy_details_v3.xlsx
* (see tab_1.do header) - same blocker applies here.
do "code/helpers/init_study_paths.do"

do "${github}/figtab/cost_per_ton.do" "full_current_193" "yes"
do "${github}/figtab/cost_per_ton.do" "full_current_no_lbd" "no"
do "${github}/figtab/excel_ce_lbd_tables.do" "scc193"

cap mkdir "outputs"
cap copy "${dropbox}/6_tables/tables_main/Table2_CE_Table_Avg_scc193.xlsx" ///
    "outputs/Table2_CE_Table_Avg_scc193.xlsx", replace
