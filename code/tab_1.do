* replicateEverything provenance: connector
* Step: tab_1 - Table 1: Baseline MVPF components
* Aggregate table (parents: compute_mvpf_main).
* Needs data/policy_details_v3.xlsx for labels/categories; uses
* tables_templates/TEMPLATE_condensed.xlsx for output formatting.
do "code/helpers/init_study_paths.do"
do "code/helpers/warm_session.do"

do "${github}/figtab/excel_MVPF_tables_condensed.do" "full_current_193" "Table1_scc193_main" "no" "yes"

* Absolute path (via ${user}) - see fig_1.do for why "outputs/..." relative
* to cwd is unsafe here.
cap mkdir "${user}/outputs"
cap copy "${dropbox}/6_tables/tables_main/Table1_scc193_main.xlsx" ///
    "${user}/outputs/Table1_scc193_main.xlsx", replace
