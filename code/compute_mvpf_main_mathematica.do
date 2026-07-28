* replicateEverything provenance: connector
* Step: compute_mvpf_main_mathematica
* Stata + Mathematica LBD path for the compute_mvpf_main group.
* Sets REPLICATE_MVPF_LBD_PATH so compute_mvpf_main.do forces the original
* wolframscript cost-curve kernel, then runs the same full-sample batch.
* Greyed in Shiny when wolframscript is missing; Code tab still shows this path.
global REPLICATE_MVPF_LBD_PATH "mathematica"
do "code/compute_mvpf_main.do"
macro drop REPLICATE_MVPF_LBD_PATH
