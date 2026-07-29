* replicateEverything provenance: connector
* Step: tab_2 - Table 2: MVPF vs. cost-per-ton, with and without learning-by-doing
* Aggregate table (parents: compute_mvpf_main, compute_mvpf_no_lbd) - the only
* step that needs both full-sample runs.
* Needs data/policy_details_v3.xlsx for labels/categories.
do "code/helpers/init_study_paths.do"
do "code/helpers/warm_session.do"

do "${github}/figtab/cost_per_ton.do" "full_current_193" "yes"
do "${github}/figtab/cost_per_ton.do" "full_current_no_lbd" "no"
do "${github}/figtab/excel_ce_lbd_tables.do" "scc193"

* Absolute path (via ${user}) - see fig_1.do for why "outputs/..." relative
* to cwd is unsafe here. Do not silently cap the copy: a failed stage into
* outputs/ is what previously made the package report a missing sink even
* when tables_main already held the workbook (Dropbox lag / file lock).
cap mkdir "${user}/outputs"
local _src "${dropbox}/6_tables/tables_main/Table2_CE_Table_Avg_scc193.xlsx"
local _dst "${user}/outputs/Table2_CE_Table_Avg_scc193.xlsx"
copy "`_src'" "`_dst'", replace
if _rc {
    sleep 1500
    copy "`_src'" "`_dst'", replace
}
if _rc {
    di as err "tab_2: failed to stage Table2 into outputs/ (r(" _rc "))"
    exit _rc
}
