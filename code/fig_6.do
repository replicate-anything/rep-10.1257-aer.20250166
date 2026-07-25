* Step: fig_6 - Figure 6: Long-run gas tax waterfall (small_gas_lr)
* Light figure (parents: macros). Single-policy recompute, same pattern as fig_1.
do "code/helpers/init_study_paths.do"
do "code/helpers/require_wolframscript.do"
do "code/helpers/warm_session.do"

run_program small_gas_lr
do "${github}/figtab/waterfalls_rep.do" "small_gas_lr" "current" "full_current_193"

cap mkdir "outputs"
cap copy "${dropbox}/5_graphs/figures_main/waterfall_small_gas_lr_current.png" ///
    "outputs/waterfall_small_gas_lr_current.png", replace
