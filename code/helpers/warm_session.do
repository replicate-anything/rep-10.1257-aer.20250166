* replicateEverything provenance: connector
* Warm a fresh Stata session with the path globals + externality caches that
* wrapper/metafile.do normally leaves behind after SECTION 0.
*
* replicateEverything runs each step in a new Stata process, so the macros step's
* .done marker does not leave ${scc} / ${assumptions} / loaded externality
* globals in memory for fig_* / tab_* runners. Author figures.do assumes it is
* called inside an already-warmed metafile session.
*
* Same throwaway metafile call as code/macros.do / ado/reset_globals.ado:
* early-exits after macros with macros_rerun=no when caches exist (fast).
* Requires init_study_paths.do first.
*
* Avoid slash-star sequences in comments (Stata block-comment trap).

set more off, permanently
pause off

if "${github}" == "" | "${dropbox}" == "" {
    di as err "warm_session: call code/helpers/init_study_paths.do first"
    exit 198
}

capture noisily do "${github}/wrapper/metafile.do" ///
    "current" ///
    "193" /// SCC
    "yes" /// learning-by-doing
    "no" /// savings
    "yes" /// profits
    "retrofit_res" /// throwaway single policy
    0 /// reps
    "resetting_globals" // nrun: early exit after macros
if _rc {
    di as err "warm_session: metafile.do failed with r(" _rc ")"
    exit _rc
}

di in green "warm_session: macros caches loaded (scc=${scc})"
