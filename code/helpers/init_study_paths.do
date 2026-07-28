* replicateEverything provenance: connector
* Locate study root and set the author's original path globals.
* Call at the top of every Stata runner (before "do"-ing anything under code/original/).
* NOTE: comments in every code do-file in this repo must never contain a
* forward-slash immediately followed by an asterisk - not even inside a
* single-line star comment, and not even as an innocuous glob such as a
* folder path ending in "do" files or a double-star suffix. Stata's lexer
* opens a block comment on that two-character sequence REGARDLESS of
* surrounding comment context, and since no closing asterisk-slash appears
* anywhere later in these files, it silently swallows every remaining line
* (including real code) to end-of-file with NO error message. This is the
* actual root cause of an early scaffolding bug where the github global
* stayed empty and "do" of the original clean_data script failed with
* r(601) file-not-found - see onboarding_notes/openicpsr-aer-239169.md.
*
* The author code under code/original is unmodified from the OpenICPSR deposit and refers
* throughout to ${github} (code root) and ${dropbox} (data root) - see original
* masterfile.do "I.1. User-Specific File Paths". We set those two globals (plus the
* small number of other top-level globals masterfile.do would normally ask a user to
* fill in) to point at this repo instead of a real Dropbox/GitHub checkout. Everything
* else (${assumptions}, ${code_files}, ${results}, ...) is derived by the author's own
* wrapper/metafile.do / wrapper/macros.do - we do not re-derive it here.

version 17
cap log close
* Non-interactive: never page, never pause during batch.
set more off, permanently
pause off
set linesize 255

local root "`c(pwd)'"
local root : subinstr local root "\" "/", all
while !fileexists("`root'/replication.yml") & "`root'" != "" {
    local parent = substr("`root'", 1, strrpos("`root'", "/") - 1)
    if "`parent'" == "`root'" | !nzchar("`parent'") continue, break
    local root "`parent'"
}

global github    "`root'/code/original"
global dropbox   "`root'/data"
global user      "`root'"
global user_name "replicateEverything"

* Derived paths + defaults that wrapper/metafile.do normally sets before any
* run_program / macros.do call. Fresh per-step Stata sessions otherwise leave
* ${scc} empty, and run_program.ado's scc-mismatch guard comparing the local
* scc to the global scc becomes invalid syntax.
global code_files                = "${dropbox}"
global assumptions               = "${code_files}/1_assumptions"
global user_specific_assumptions = "${assumptions}/user_specific_assumptions"
global bootstrap_folder          = "${code_files}/3_bootstrap_draws"
global output_tab                = "${code_files}/6_tables"
global output_fig                = "${code_files}/5_graphs"
global program_folder            = "${github}/policies/harmonized"
global calculation_files         = "${github}/calculations"
global ado_files                 = "${github}/ado"
global default_assumptions       = "${assumptions}/default_assumptions_toggles_vMAIN.xlsx"
global policy_assumptions        = "${assumptions}/policy_category_assumptions_MASTER.xlsx"
if "${scc}" == "" global scc = 193
if "${EV_VMT_car_adjustment}" == "" global EV_VMT_car_adjustment = 0.61544408
if "${ev_grid}" == "" global ev_grid = "US"
if "${hev_cf}" == "" global hev_cf = "muehl"
if "${bev_cf}" == "" global bev_cf = "clean_car"

* Custom commands (run_program, reset_globals, check_timepaths, dynamic_split_grid,
* rebound, cost_curve_masterfile, ...) live as .ado files under code/original/ado and
* code/original/cost_curve rather than a real Stata ado path - add both explicitly so
* every runner can call them regardless of which script does the first "do".
adopath + "${github}/ado"
adopath + "${github}/cost_curve"

* Mathematica (learning-by-doing cost curves) is invoked via "wolframscript" on the
* PATH on Windows/Linux; masterfile.do only needs this global set on macOS
* (see masterfile.do line 46: "which wolframscript" for the path).
global mac_wolfram_path ""

* Make sure the writable staging folders the author code expects already exist
* (author scripts "cap mkdir" most of these themselves, but do it defensively here too).
foreach d in "0_log" "2b_causal_estimates_draws" "3_bootstrap_draws" "4_results" ///
             "5_graphs/figures_main" "5_graphs/figures_data" "6_tables/tables_main" ///
             "6_tables/tables_templates" "1_assumptions/user_specific_assumptions" {
    cap mkdir "${dropbox}/`d'"
}

di in green "Study root:   ${user}"
di in green "Code root:    ${github}"
di in green "Data root:    ${dropbox}"
