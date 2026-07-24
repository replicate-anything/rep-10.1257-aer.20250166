* Step: tab_1 - Table 1: Baseline MVPF components
* Aggregate table (parents: compute_mvpf_main).
* KNOWN GAP: figtab/excel_MVPF_tables_condensed.do imports
* "${code_files}/policy_details_v3.xlsx" (policy labels + broad_category + extended
* flags) and inner-joins ("merge", keep(3)) it onto the compiled results, then asserts the merged
* sample size - the file is not present anywhere in the OpenICPSR 239169-V1 deposit.
* This step cannot run until that file is sourced from the authors/OpenICPSR - see
* onboarding_notes/openicpsr-aer-239169.md. Uses tables_templates/TEMPLATE_condensed.xlsx
* (present in data/6_tables/tables_templates/) for the output formatting.
do "code/helpers/init_study_paths.do"

do "${github}/figtab/excel_MVPF_tables_condensed.do" "full_current_193" "Table1_scc193_main" "no" "yes"

cap mkdir "outputs"
cap copy "${dropbox}/6_tables/tables_main/Table1_scc193_main.xlsx" ///
    "outputs/Table1_scc193_main.xlsx", replace
