* Step: macros
* Transform (parents: clean_data). Warms/refreshes the shared externality globals and
* cached datasets (electricity, natural gas, vehicle externalities) that every policy
* do-file reads via Stata globals set by wrapper/macros.do.
*
* macros.do itself expects a large preamble of globals (scc, rebound, EV VMT
* assumptions, ...) that the author only sets inside wrapper/metafile.do before it
* calls macros.do. Rather than re-deriving that preamble here (risk of drift from the
* original), we call metafile.do exactly the way the author's own
* ado/reset_globals.ado does: one cheap throwaway policy, 0 reps, so macros.do runs
* for real but the run finishes in seconds rather than hours. clean_data is a separate
* parent step already, so we skip reset_globals.ado's own redundant clean_data.do call.
* metafile.do early-exits after SECTION 0 when nrun contains resetting_globals, so we
* never reach bootstrap_wrapper (which has a bare pause) or compile.
do "code/helpers/init_study_paths.do"
set more off, permanently
pause off

capture noisily do "${github}/wrapper/metafile.do" ///
    "current" ///
    "193" /// SCC
    "yes" /// learning-by-doing
    "no" /// savings
    "yes" /// profits
    "retrofit_res" /// throwaway single policy, same as ado/reset_globals.ado
    0 /// reps
    "resetting_globals" // nrun
if _rc {
    di as err "macros step: metafile.do failed with r(" _rc ")"
    exit _rc
}

* Marker output for the replicateEverything DAG contract - the real products are the
* cached externality datasets macros.do writes under
* data/1_assumptions/user_specific_assumptions, in a per-user subfolder.
cap mkdir "outputs/macros"
file open marker using "outputs/macros/.done", write replace
file write marker "macros completed $S_DATE $S_TIME" _n
file close marker
