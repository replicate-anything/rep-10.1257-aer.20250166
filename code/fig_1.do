* replicateEverything provenance: connector
* Step: fig_1 - Figure 1: EV subsidy waterfall (Muehlegger & Rapson EV FMP)
* Light figure (parents: macros). Only recomputes the ONE policy this figure needs,
* not the full 100-policy sample - matches masterfile.do wrapper/figures.do section 1.
do "code/helpers/init_study_paths.do"
do "code/helpers/require_cost_curve_engine.do"
do "code/helpers/warm_session.do"

run_program muehl_efmp, scc(193)
do "${github}/figtab/waterfalls_rep.do" "muehl_efmp" "current" "full_current_193"

* Absolute path (via ${user}) - run_program/waterfalls_rep.do "cd" through
* subdirectories and never restore Stata's cwd, so "outputs/..." relative to
* cwd here can silently resolve (and cap-swallow an error) elsewhere.
cap mkdir "${user}/outputs"
cap copy "${dropbox}/5_graphs/figures_main/waterfall_muehl_efmp_current.png" ///
    "${user}/outputs/waterfall_muehl_efmp_current.png", replace
