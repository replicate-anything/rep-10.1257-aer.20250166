* Step: clean_data
* Root transform. Thin wrapper around the author's wrapper/clean_data.do, which
* builds the battery/EV/CPI/population inputs used by every downstream policy
* do-file from data/1_assumptions. No changes to author logic.
do "code/helpers/init_study_paths.do"

do "${github}/wrapper/clean_data.do"

* Marker output for the replicateEverything DAG contract - the real products are
* the many small .dta files the data_cleaning do-files write under data/1_assumptions.
cap mkdir "outputs/clean_data"
file open marker using "outputs/clean_data/.done", write replace
file write marker "clean_data completed $S_DATE $S_TIME" _n
file close marker
