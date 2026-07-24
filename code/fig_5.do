* Step: fig_5 - Figure 5: Home Energy Report (nudges) MVPF correlation plot
* Light figure (parents: macros). Does NOT depend on compute_mvpf_main - reads
* data/5_graphs/figures_data/Nudge Estimates.xlsx (manually compiled HER RCT
* metadata, shipped in the deposit) plus the state/region crosswalk sheet in
* policy_category_assumptions_MASTER.xlsx, and the externality globals macros.do sets.
do "code/helpers/init_study_paths.do"

do "${github}/figtab/mvpf_plots_nudges.do" "yes" "no"

cap mkdir "outputs"
cap copy "${dropbox}/5_graphs/figures_main/corr_plot_nudges.png" ///
    "outputs/corr_plot_nudges.png", replace
