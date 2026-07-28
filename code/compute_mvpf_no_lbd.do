* replicateEverything provenance: connector
* Step: compute_mvpf_no_lbd
* Heavy transform (parents: macros). Same full-sample run as compute_mvpf_main but
* with learning-by-doing turned off (lbd=no) - masterfile.do's "full_current_no_lbd"
* specification. This is the one full-sample run that does NOT need Mathematica.
* Needed only because tab_2 (cost_per_ton.do) compares MVPF/cost-per-ton with and
* without learning-by-doing.
do "code/helpers/init_study_paths.do"

* Case-preserving program list - see compute_mvpf_main.do for the full
* rationale (this must stay inlined per-file; locals set inside a
* `do "other_file.do"' do not propagate back to the caller's scope).
local __outfile "__harmonized_programs.txt"
cap erase "`__outfile'"
if "`c(os)'" == "Windows" {
    local __glob = subinstr(`"${program_folder}/*.do"', "/", "\", .)
    shell dir /b "`__glob'" > "`__outfile'"
}
if "`c(os)'" != "Windows" {
    di as error "compute_mvpf_no_lbd.do: non-Windows OS - falling back to case-folding dir(); mixed-case policy names (bolk_France/Germany/Spain/UK, CPP_aj/CPP_pj, PER) may break."
    local __do_files : dir "${program_folder}" files "*.do"
    local __fh = fopen("`__outfile'", "w")
    foreach __f of local __do_files {
        fput `__fh' "`__f'"
    }
    fclose `__fh'
}
local all_programs ""
file open __progfile using "`__outfile'", read text
file read __progfile __line
while r(eof) == 0 {
    local __base `"`__line'"'
    if strpos(`"`__base'"', ".do") > 0 & `"`__base'"' != "" {
        local __prog = substr(`"`__base'"', 1, strlen(`"`__base'"') - 3)
        local all_programs "`all_programs' `__prog'"
    }
    file read __progfile __line
}
file close __progfile
cap erase "`__outfile'"
local all_programs = trim("`all_programs'")

do "${github}/wrapper/metafile.do" ///
    "current" ///
    "193" ///
    "no" /// learning-by-doing OFF
    "no" ///
    "yes" ///
    "`all_programs'" ///
    0 ///
    "full_current_no_lbd" // nrun

local folders : dir "${dropbox}/4_results" dirs "*full_current_no_lbd*"
local n_folders : list sizeof folders
local latest : word `n_folders' of `folders'
cap mkdir "${dropbox}/4_results/full_current_no_lbd"
cap copy "${dropbox}/4_results/`latest'/compiled_results_all_uncorrected_vJK.dta" ///
    "${dropbox}/4_results/full_current_no_lbd/compiled_results_all_uncorrected_vJK.dta", replace
* Absolute path (via ${user}) - see compute_mvpf_main.do for why "outputs/..."
* relative to cwd is unsafe here (wrapper chain never restores Stata's cwd).
cap mkdir "${user}/outputs/compute_mvpf_no_lbd"
cap copy "${dropbox}/4_results/full_current_no_lbd/compiled_results_all_uncorrected_vJK.dta" ///
    "${user}/outputs/compute_mvpf_no_lbd/compiled_results_all_uncorrected_vJK.dta", replace
