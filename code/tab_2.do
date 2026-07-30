* replicateEverything provenance: connector
* Step: tab_2 - Table 2: MVPF vs. cost-per-ton, with and without learning-by-doing
* Aggregate table (parents: compute_mvpf_main, compute_mvpf_no_lbd) - the only
* step that needs both full-sample runs.
* Needs data/policy_details_v3.xlsx for labels/categories.
do "code/helpers/init_study_paths.do"
do "code/helpers/warm_session.do"

do "${github}/figtab/cost_per_ton.do" "full_current_193" "yes"
do "${github}/figtab/cost_per_ton.do" "full_current_no_lbd" "no"

* excel_ce_lbd_tables.do writes Table2 (tables_main) first, then appendix
* Table12/13/14. Appendix template copies can fail under Dropbox-paused
* trees (r(603)) after Table2 is already saved - do not abort staging.
cap mkdir "${dropbox}/6_tables/tables_appendix"
capture noisily do "${github}/figtab/excel_ce_lbd_tables.do" "scc193"
local _excel_rc = _rc

* Pass paths as do-file args - locals do not cross `do` boundaries here.
do "code/helpers/stage_xlsx_to_outputs.do" ///
    "${dropbox}/6_tables/tables_main/Table2_CE_Table_Avg_scc193.xlsx" ///
    "${user}/outputs/Table2_CE_Table_Avg_scc193.xlsx" ///
    "tab_2"

if `_excel_rc' {
    di in yellow "tab_2: excel_ce_lbd_tables ended with r(`_excel_rc') (appendix may be incomplete); Table2 staged OK"
}
