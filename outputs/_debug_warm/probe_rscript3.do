set more off, permanently
pause off
cd "C:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/rep-10.1257-aer.20250166"
do "code/helpers/init_study_paths.do"
global REPLICATE_COST_CURVE_ENGINE "r"
do "code/helpers/require_cost_curve_engine.do"
file open mh using "C:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/rep-10.1257-aer.20250166/outputs/_debug_warm/probe_rscript3_ok.txt", write replace
file write mh "engine=${REPLICATE_COST_CURVE_ENGINE}" _n
file write mh "rscript=${REPLICATE_RSCRIPT}" _n
file close mh
exit 0
