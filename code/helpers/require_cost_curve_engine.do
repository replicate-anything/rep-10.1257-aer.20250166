* Fail fast when the selected LBD cost-curve engine is missing.
*
* Avoid slash-star sequences in comments (Stata block-comment trap).
*
* Default engine is R (REPLICATE_COST_CURVE_ENGINE unset or "r"): needs Rscript
* on PATH and deSolve for the masterfile ODE path.
* Mathematica engine: needs wolframscript (same probe as before).

local cc_engine : env REPLICATE_COST_CURVE_ENGINE
if "${REPLICATE_COST_CURVE_ENGINE}" != "" local cc_engine "${REPLICATE_COST_CURVE_ENGINE}"
local cc_engine = lower("`cc_engine'")
local cc_engine = strtrim("`cc_engine'")
if "`cc_engine'" == "" local cc_engine "r"
if inlist("`cc_engine'", "wolfram", "wolframscript", "wls") local cc_engine "mathematica"
if inlist("`cc_engine'", "rscript") local cc_engine "r"

if "`cc_engine'" == "r" {
    local probe "`c(tmpdir)'re_rscript_where.txt"
    capture erase "`probe'"
    if "`c(os)'" == "Windows" {
        quietly shell where Rscript > "`probe'" 2>&1
    }
    else {
        quietly shell which Rscript > "`probe'" 2>&1
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
        di as err "require_cost_curve_engine: Rscript not found on PATH"
        di as err "  Default LBD path shells to R (code/cost_curve)."
        di as err "  Install R and ensure Rscript is on PATH, or set"
        di as err "  REPLICATE_COST_CURVE_ENGINE=mathematica for original .wls."
        exit 601
    }
    di in green "require_cost_curve_engine: Rscript found (`line')"
}
else if "`cc_engine'" == "mathematica" {
    do "code/helpers/require_wolframscript.do"
}
else {
    di as err "require_cost_curve_engine: unknown engine `cc_engine' (use r or mathematica)"
    exit 198
}
