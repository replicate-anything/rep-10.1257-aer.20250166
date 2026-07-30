* replicateEverything provenance: connector
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
    di as err "  This is the optional Mathematica LBD path (incomplete without"
    di as err "  Mathematica). Default live path is Stata + R (REPLICATE_COST_CURVE_ENGINE=r)."
    di as err "  Use the [Stata / R] path, or compute_mvpf_no_lbd for Stata-only robustness."
    exit 601
}

di in green "require_wolframscript: found `line'"
