* Step: fig_4 - Figure 4: Baseline MVPFs for subsidies
* Aggregate figure (parents: compute_mvpf_main). Reads the full compiled MVPF sample.
*
* KNOWN GAP: figtab/mvpf_plots.do imports "${code_files}/policy_details_v3.xlsx" (policy
* labels/categories) via a hard "merge ..., keep(3)". This file is referenced repeatedly
* by the author README (and listed as "Appendix Table 1") but is NOT present anywhere in
* the OpenICPSR 239169-V1 deposit - see onboarding_notes/openicpsr-aer-239169.md. This
* step will fail at that import until the file is sourced from the authors/OpenICPSR.
do "code/helpers/init_study_paths.do"

do "${github}/figtab/mvpf_plots.do" "subsidies" "full_current_193" "Fig4_scc193" "193" "yes_cis"

cap mkdir "outputs"
cap copy "${dropbox}/5_graphs/figures_main/mvpf_subsidies_Fig4_scc193.png" ///
    "outputs/mvpf_subsidies_Fig4_scc193.png", replace
