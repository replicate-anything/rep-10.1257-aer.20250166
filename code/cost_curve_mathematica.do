* Optional Mathematica LBD path (greyed when wolframscript is missing).
* Live default uses R via cost_curve_masterfile.ado; set
* REPLICATE_COST_CURVE_ENGINE=mathematica to force original .wls scripts under
* code/original/cost_curve.
do "code/helpers/init_study_paths.do"
global REPLICATE_COST_CURVE_ENGINE "mathematica"
do "code/helpers/require_wolframscript.do"
di in green "Mathematica LBD path available (REPLICATE_COST_CURVE_ENGINE=mathematica)."
