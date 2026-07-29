set more off, permanently
pause off
cap log close _all
log using "C:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/rep-10.1257-aer.20250166/outputs/_debug_warm/probe_warm_stata.log", text replace
cd "C:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/rep-10.1257-aer.20250166"
do "code/helpers/init_study_paths.do"
di as txt "PROBE: after init at " c(current_time)
do "code/helpers/warm_session.do"
di as txt "PROBE: after warm at " c(current_time)
di as txt "PROBE: scc=${scc}"
log close
