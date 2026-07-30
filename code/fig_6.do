* replicateEverything provenance: connector
* Step: fig_6 - Figure 6: Long-run gas tax waterfall (small_gas_lr)
* Light figure (parents: macros). Single-policy recompute, same pattern as fig_1.
do "code/helpers/init_study_paths.do"
* Operable LBD path is R (see fig_1.do).
global REPLICATE_COST_CURVE_ENGINE "r"
do "code/helpers/require_cost_curve_engine.do"
do "code/helpers/warm_session.do"

run_program small_gas_lr
do "${github}/figtab/waterfalls_rep.do" "small_gas_lr" "current" "full_current_193"

* Absolute path (via ${user}) - see fig_1.do for why "outputs/..." relative
* to cwd is unsafe here.
cap mkdir "${user}/outputs"
cap copy "${dropbox}/5_graphs/figures_main/waterfall_small_gas_lr_current.png" ///
    "${user}/outputs/waterfall_small_gas_lr_current.png", replace
