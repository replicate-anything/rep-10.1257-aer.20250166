* Step: fig_2 - Figure 2: Wind PTC waterfall (2a) + wind/solar elasticities (2b)
* Light figure (parents: macros). wrapper/figtab/wind_solar_paper.do produces BOTH
* Fig_2b_wind_elasticities.png and Fig_3b_solar_elasticities.png in one pass (shared
* author script) - fig_3 depends on fig_2 for the 3b panel instead of re-running this,
* per AI.md "share upstream objects across figures when that is the author structure".
do "code/helpers/init_study_paths.do"

run_program hitaj_ptc, scc(193)
do "${github}/figtab/waterfalls_rep.do" "hitaj_ptc" "current" "full_current_193"

do "${github}/figtab/wind_solar_paper.do"

cap mkdir "outputs"
cap copy "${dropbox}/5_graphs/figures_main/waterfall_hitaj_ptc_current.png" ///
    "outputs/waterfall_hitaj_ptc_current.png", replace
cap copy "${dropbox}/5_graphs/figures_main/Fig_2b_wind_elasticities.png" ///
    "outputs/Fig_2b_wind_elasticities.png", replace
