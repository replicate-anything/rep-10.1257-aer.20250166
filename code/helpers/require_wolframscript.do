* Fail fast if Mathematica's wolframscript is not available.
*
* Used when REPLICATE_COST_CURVE_ENGINE=mathematica. Default live path is R
* (see require_cost_curve_engine.do). Author .wls scripts remain under
* code/original/cost_curve.
*
* Avoid slash-star sequences in comments (Stata block-comment trap).

local probe "`c(tmpdir)'re_wolfram_where.txt"
capture erase "`probe'"

if "`c(os)'" == "MacOSX" & "${mac_wolfram_path}" != "" {
    quietly shell "${mac_wolfram_path}/wolframscript" -version > "`probe'" 2>&1
}
else if "`c(os)'" == "Windows" {
    quietly shell where wolframscript > "`probe'" 2>&1
}
else {
    quietly shell which wolframscript > "`probe'" 2>&1
}

tempname fh
capture file open `fh' using "`probe'", read text
if _rc {
    local line ""
}
else {
    file read `fh' line
    file close `fh'
}

local ok = 0
if `"`line'"' != "" {
    if !strpos(lower(`"`line'"'), "could not") & !strpos(lower(`"`line'"'), "not found") {
        local ok = 1
    }
}

if !`ok' {
    di as err "require_wolframscript: wolframscript not found on PATH"
    di as err "  Headline MVPF (lbd=yes) and LBD waterfalls need Mathematica."
    di as err "  Without it, cost_curve_masterfile waits 20s then exits r(601)."
    di as err "  Stata-only alternative: compute_mvpf_no_lbd (robustness, not headline)."
    di as err "  First LBD-on policy in the alphabetical batch is typically bento_gas."
    exit 601
}

di in green "require_wolframscript: found `line'"
