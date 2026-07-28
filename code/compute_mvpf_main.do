* Step: compute_mvpf_main
* Heavy transform (parents: macros). Reproduces masterfile.do's headline run:
*   metafile.do "current" scc=193 lbd=yes savings=no profits=yes <all policies> reps=0 "full_current_193"
* over every policy in policies/harmonized (the full MVPF main sample), producing
* data/4_results/<timestamp>__full_current_193_uncorrected_vJK/compiled_results_all_uncorrected_vJK.dta,
* which tab_1, fig_4, fig_7, and fig_8 read.
*
* WARNING: With lbd=yes, ~40 of ~100 policies hit cost_curve_masterfile.
* Default engine is R (code/cost_curve); set REPLICATE_COST_CURVE_ENGINE=
* mathematica for original .wls. Full batch is long; lbd=no is the separate
* robustness run (compute_mvpf_no_lbd).
do "code/helpers/init_study_paths.do"
do "code/helpers/require_cost_curve_engine.do"

* Reproduce masterfile.do's "Create list of all programs to run" (avoids depending on
* the ssc "filelist" package purely for this).
local do_files : dir "${github}/policies/harmonized" files "*.do"
local all_programs ""
foreach f of local do_files {
    local prog = substr("`f'", 1, strlen("`f'") - 3)
    local all_programs "`all_programs' `prog'"
}

do "${github}/wrapper/metafile.do" ///
    "current" /// 2020
    "193" /// SCC
    "yes" /// learning-by-doing
    "no" /// savings
    "yes" /// profits
    "`all_programs'" /// every policy in policies/harmonized
    0 /// reps (point estimates only - bootstrapping is a separate Phase 2 step)
    "full_current_193" // nrun

* metafile.do writes into a timestamped data/4_results/<ts>__full_current_193_uncorrected_vJK
* folder (author convention - keeps run history). Copy the compiled cross-policy
* results into outputs/ under the replicateEverything DAG contract; downstream
* table/figure runners still read the author-native data/4_results/full_current_193/
* copy below (a fixed, non-timestamped alias) so they do not need to re-discover it.
local folders : dir "${dropbox}/4_results" dirs "*full_current_193_uncorrected_vJK"
local latest : word `:list sizeof folders' of `folders'
cap mkdir "${dropbox}/4_results/full_current_193"
cap copy "${dropbox}/4_results/`latest'/compiled_results_all_uncorrected_vJK.dta" ///
    "${dropbox}/4_results/full_current_193/compiled_results_all_uncorrected_vJK.dta", replace
cap mkdir "outputs/compute_mvpf_main"
cap copy "${dropbox}/4_results/full_current_193/compiled_results_all_uncorrected_vJK.dta" ///
    "outputs/compute_mvpf_main/compiled_results_all_uncorrected_vJK.dta", replace
