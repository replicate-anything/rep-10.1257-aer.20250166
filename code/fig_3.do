* replicateEverything provenance: connector
* Step: fig_3 - Figure 3: Solar waterfall (3a, Pless & Van Benthem) + solar
* elasticities (3b, produced by fig_2's wind_solar_paper.do run - see fig_2).
* Light figure (parents: fig_2, macros).
do "code/helpers/init_study_paths.do"
do "code/helpers/require_cost_curve_engine.do"
do "code/helpers/warm_session.do"

run_program pless_ho
do "${github}/figtab/waterfalls_rep.do" "pless_ho" "current" "full_current_193"

* Fig_3b_solar_elasticities.png already produced by fig_2 (wind_solar_paper.do writes
* both panels in one run) - copy it into this step's own outputs/ rather than re-run.
* Absolute path (via ${user}) - see fig_1.do for why "outputs/..." relative
* to cwd is unsafe here.
cap mkdir "${user}/outputs"
cap copy "${dropbox}/5_graphs/figures_main/waterfall_pless_ho_current.png" ///
    "${user}/outputs/waterfall_pless_ho_current.png", replace
cap copy "${dropbox}/5_graphs/figures_main/Fig_3b_solar_elasticities.png" ///
    "${user}/outputs/Fig_3b_solar_elasticities.png", replace
