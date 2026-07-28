* replicateEverything provenance: connector
* Step: fig_4 - Figure 4: Baseline MVPFs for subsidies
* Aggregate figure (parents: compute_mvpf_main). Reads the full compiled MVPF sample.
* Needs data/policy_details_v3.xlsx (${code_files}/policy_details_v3.xlsx) for labels.
do "code/helpers/init_study_paths.do"

do "${github}/figtab/mvpf_plots.do" "subsidies" "full_current_193" "Fig4_scc193" "193" "yes_cis"

* Absolute path (via ${user}) - see fig_1.do for why "outputs/..." relative
* to cwd is unsafe here.
cap mkdir "${user}/outputs"
cap copy "${dropbox}/5_graphs/figures_main/mvpf_subsidies_Fig4_scc193.png" ///
    "${user}/outputs/mvpf_subsidies_Fig4_scc193.png", replace
