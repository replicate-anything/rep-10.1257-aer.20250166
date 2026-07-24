* Step: compute_mvpf_no_lbd
* Heavy transform (parents: macros). Same full-sample run as compute_mvpf_main but
* with learning-by-doing turned off (lbd=no) - masterfile.do's "full_current_no_lbd"
* specification. This is the one full-sample run that does NOT need Mathematica.
* Needed only because tab_2 (cost_per_ton.do) compares MVPF/cost-per-ton with and
* without learning-by-doing.
do "code/helpers/init_study_paths.do"

local do_files : dir "${github}/policies/harmonized" files "*.do"
local all_programs ""
foreach f of local do_files {
    local prog = substr("`f'", 1, strlen("`f'") - 3)
    local all_programs "`all_programs' `prog'"
}

do "${github}/wrapper/metafile.do" ///
    "current" ///
    "193" ///
    "no" /// learning-by-doing OFF
    "no" ///
    "yes" ///
    "`all_programs'" ///
    0 ///
    "full_current_no_lbd" // nrun

local folders : dir "${dropbox}/4_results" dirs "*full_current_no_lbd_uncorrected_vJK"
local latest : word `:list sizeof folders' of `folders'
cap mkdir "${dropbox}/4_results/full_current_no_lbd"
cap copy "${dropbox}/4_results/`latest'/compiled_results_all_uncorrected_vJK.dta" ///
    "${dropbox}/4_results/full_current_no_lbd/compiled_results_all_uncorrected_vJK.dta", replace
cap mkdir "outputs/compute_mvpf_no_lbd"
cap copy "${dropbox}/4_results/full_current_no_lbd/compiled_results_all_uncorrected_vJK.dta" ///
    "outputs/compute_mvpf_no_lbd/compiled_results_all_uncorrected_vJK.dta", replace
