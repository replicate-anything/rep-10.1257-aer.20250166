* Step: fig_7 - Figure 7: MVPF plot of revenue raisers
* Aggregate figure (parents: compute_mvpf_main).
* Needs data/policy_details_v3.xlsx for labels/categories.
do "code/helpers/init_study_paths.do"

do "${github}/figtab/mvpf_plots.do" "taxes" "full_current_193" "Fig7_scc193" "193" "yes_cis"

cap mkdir "outputs"
cap copy "${dropbox}/5_graphs/figures_main/mvpf_taxes_Fig7_scc193_with_CIs.png" ///
    "outputs/mvpf_taxes_Fig7_scc193_with_CIs.png", replace
