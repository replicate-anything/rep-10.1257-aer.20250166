* replicateEverything provenance: connector
* Step: fig_8 - Figure 8: MVPF plot of international policies
* Aggregate figure (parents: compute_mvpf_main).
* Needs data/policy_details_v3.xlsx for labels/categories.
do "code/helpers/init_study_paths.do"

do "${github}/figtab/mvpf_plots.do" "intl" "full_current_193" "Fig8_scc193" "split" "no_cis"

* Absolute path (via ${user}) - see fig_1.do for why "outputs/..." relative
* to cwd is unsafe here.
cap mkdir "${user}/outputs"
cap copy "${dropbox}/5_graphs/figures_main/mvpf_intl_Fig8_scc193_with_CIs.png" ///
    "${user}/outputs/mvpf_intl_Fig8_scc193_with_CIs.png", replace
