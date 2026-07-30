* replicateEverything provenance: connector
* Step: compute_mvpf_main
* Heavy transform (parents: macros). Reproduces masterfile.do's headline run:
*   metafile.do "current" scc=193 lbd=yes savings=no profits=yes <all policies> reps=0 "full_current_193"
* over every policy in policies/harmonized (the full MVPF main sample), producing
* data/4_results/<timestamp>__full_current_193_uncorrected_vJK/compiled_results_all_uncorrected_vJK.dta,
* which tab_1, fig_4, fig_7, and fig_8 read.
*
* WARNING: With lbd=yes, ~40 of ~100 policies hit cost_curve_masterfile.
* Default path is Stata + R LBD (translation of the Mathematica kernel under
* code/cost_curve/). Sibling step compute_mvpf_main_mathematica.do sets
* REPLICATE_MVPF_LBD_PATH=mathematica before calling this file. Full batch
* is long; lbd=no is the separate robustness run (compute_mvpf_no_lbd).
do "code/helpers/init_study_paths.do"
if "${REPLICATE_MVPF_LBD_PATH}" == "mathematica" {
    global REPLICATE_COST_CURVE_ENGINE "mathematica"
}
else {
    global REPLICATE_COST_CURVE_ENGINE "r"
}
do "code/helpers/require_cost_curve_engine.do"

* Reproduce masterfile.do's "Create list of all programs to run" (avoids depending on
* the ssc "filelist" package purely for this). Deliberately NOT `local do_files :
* dir "..." files "*.do"' - that extended macro function lower-cases every
* returned filename on this Stata/Windows install (verified empirically:
* "bolk_France.do" comes back as "bolk_france.do"). Four harmonized files have
* mixed-case names (bolk_France/Germany/Spain/UK.do, CPP_aj/CPP_pj.do, PER.do)
* and their own code hardcodes that exact mixed-case string as a global-macro
* suffix (e.g. wind_ado.ado sets global program_cost_bolk_France). A
* lower-cased loop variable then reads back an unset global (globals are
* case-sensitive in Stata), silently expanding to empty inside
* bootstrap_wrapper.do and breaking a division with a bare "if" token -
* failing with a cryptic r(111) "if not found" deep in the ~100-policy batch.
* Fix: shell out to a case-preserving directory listing (`dir /b' on
* Windows) instead, and read the raw filenames back line by line. This has
* to stay inlined here (not factored into a helper do-file) because locals
* set inside a `do "other_file.do"' do NOT propagate back to the caller's
* scope in this Stata version - only globals do.
local __outfile "__harmonized_programs.txt"
cap erase "`__outfile'"
if "`c(os)'" == "Windows" {
    local __glob = subinstr(`"${program_folder}/*.do"', "/", "\", .)
    shell dir /b "`__glob'" > "`__outfile'"
}
if "`c(os)'" != "Windows" {
    * Prefer shell ls (case-preserving) over Stata's :dir, which lower-cases
    * on some installs. Do NOT use Mata fopen()/fput()/fclose() here — those
    * are Mata-only and yield "unknown function fopen" in ado/do context
    * (seen on Linux Shiny/server hosts).
    cap shell ls -1 "${program_folder}"/*.do > "`__outfile'"
    cap confirm file "`__outfile'"
    if _rc {
        di as error "compute_mvpf_main.do: non-Windows OS - falling back to case-folding dir(); mixed-case policy names (bolk_France/Germany/Spain/UK, CPP_aj/CPP_pj, PER) may break."
        local __do_files : dir "${program_folder}" files "*.do"
        file open __fh using "`__outfile'", write text replace
        foreach __f of local __do_files {
            file write __fh `"`__f'"' _n
        }
        file close __fh
    }
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
    "current" /// 2020
    "193" /// SCC
    "yes" /// learning-by-doing
    "no" /// savings
    "yes" /// profits
    "`all_programs'" /// every policy in policies/harmonized
    0 /// reps (point estimates only - bootstrapping is a separate Phase 2 step)
    "full_current_193" // nrun

* metafile.do writes into a timestamped data/4_results/<ts>__full_current_193_uncorrected_vJK
* folder (author convention - keeps run history). Copy the compiled cross-policy
* results into outputs/ under the replicateEverything DAG contract; downstream
* table/figure runners still read the author-native data/4_results/full_current_193/
* copy below (a fixed, non-timestamped alias) so they do not need to re-discover it.
local folders : dir "${dropbox}/4_results" dirs "*full_current_193*"
local n_folders : list sizeof folders
local latest : word `n_folders' of `folders'
cap mkdir "${dropbox}/4_results/full_current_193"
cap copy "${dropbox}/4_results/`latest'/compiled_results_all_uncorrected_vJK.dta" ///
    "${dropbox}/4_results/full_current_193/compiled_results_all_uncorrected_vJK.dta", replace
* Absolute path (via ${user}, set in init_study_paths.do) - not "outputs/...":
* metafile.do / the wrapper chain "cd"s through several subdirectories and
* never restores Stata's original working directory, so a path relative to
* cwd at this point silently resolves (and cap-swallows an error) somewhere
* other than the study root.
cap mkdir "${user}/outputs/compute_mvpf_main"
cap copy "${dropbox}/4_results/full_current_193/compiled_results_all_uncorrected_vJK.dta" ///
    "${user}/outputs/compute_mvpf_main/compiled_results_all_uncorrected_vJK.dta", replace
