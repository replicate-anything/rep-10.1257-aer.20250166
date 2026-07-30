set more off, permanently
pause off
cap log close _all
log using "C:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/rep-10.1257-aer.20250166/outputs/_debug_warm/probe_rscript.log", text replace
cd "C:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/rep-10.1257-aer.20250166"
do "code/helpers/init_study_paths.do"
global REPLICATE_COST_CURVE_ENGINE "r"
do "code/helpers/require_cost_curve_engine.do"
di as txt "PROBE_ENGINE=${REPLICATE_COST_CURVE_ENGINE}"
di as txt "PROBE_RSCRIPT=${REPLICATE_RSCRIPT}"
log close
