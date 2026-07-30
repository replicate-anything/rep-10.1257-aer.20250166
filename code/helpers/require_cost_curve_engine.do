* replicateEverything provenance: connector
* Fail fast when the selected LBD cost-curve engine is missing.
*
* Avoid slash-star sequences in comments (Stata block-comment trap).
*
* Default engine is R (REPLICATE_COST_CURVE_ENGINE unset or "r"): needs Rscript
* on PATH and deSolve for the masterfile ODE path.
* Mathematica engine: needs wolframscript (same probe as before).

* Preference: Stata global (set by compute_mvpf_main / fig_*.do) > env >
* default "r". Do not let a leftover REPLICATE_COST_CURVE_ENGINE=mathematica
* in the parent R/.Renviron divert the operable R path.
local cc_engine ""
if "${REPLICATE_COST_CURVE_ENGINE}" != "" {
    local cc_engine "${REPLICATE_COST_CURVE_ENGINE}"
}
if "`cc_engine'" == "" {
    local cc_engine : env REPLICATE_COST_CURVE_ENGINE
}
local cc_engine = lower("`cc_engine'")
local cc_engine = strtrim("`cc_engine'")
if "`cc_engine'" == "" local cc_engine "r"
if inlist("`cc_engine'", "wolfram", "wolframscript", "wls") local cc_engine "mathematica"
if inlist("`cc_engine'", "rscript") local cc_engine "r"

if "`cc_engine'" == "r" {
    local ok = 0
    local line ""
    * Prefer absolute path injected by the package runner (Stata often has a
    * thinner PATH than the parent R / Shiny process on Linux and Windows).
    if `"${REPLICATE_RSCRIPT}"' != "" {
        capture confirm file `"${REPLICATE_RSCRIPT}"'
        if !_rc {
            local line `"${REPLICATE_RSCRIPT}"'
            local ok = 1
        }
    }
    if !`ok' {
        local env_rs : env REPLICATE_RSCRIPT
        if `"`env_rs'"' != "" {
            capture confirm file `"`env_rs'"'
            if !_rc {
                local line `"`env_rs'"'
                local ok = 1
            }
        }
    }
    if !`ok' {
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
        if `"`line'"' != "" {
            if !strpos(lower(`"`line'"'), "could not") & !strpos(lower(`"`line'"'), "not found") {
                local ok = 1
            }
        }
    }
    if !`ok' & "`c(os)'" == "Windows" {
        * Stata batch on Windows often inherits a thin PATH that omits R.
        * Probe common install locations before failing.
        local r_root "C:/Program Files/R"
        capture local r_vers : dir "`r_root'" dirs "R-*", respectcase
        foreach v of local r_vers {
            foreach sub in "bin/x64/Rscript.exe" "bin/Rscript.exe" {
                local cand "`r_root'/`v'/`sub'"
                capture confirm file "`cand'"
                if !_rc {
                    local line "`cand'"
                    local ok = 1
                    continue, break
                }
            }
            if `ok' continue, break
        }
    }
    if !`ok' & "`c(os)'" != "Windows" {
        * Common Unix locations when service PATH omits R (Linux Shiny hosts).
        foreach cand in "/usr/bin/Rscript" "/usr/local/bin/Rscript" "/opt/R/bin/Rscript" {
            capture confirm file "`cand'"
            if !_rc {
                local line "`cand'"
                local ok = 1
                continue, break
            }
        }
    }
    if !`ok' {
        di as err "require_cost_curve_engine: Rscript not found (default LBD path needs R)"
        di as err "  Install R and ensure Rscript is on PATH for the Stata process."
        di as err "  The Mathematica/.wls alternate is incomplete when wolframscript"
        di as err "  is missing; do not set REPLICATE_COST_CURVE_ENGINE=mathematica"
        di as err "  unless wolframscript is available."
        exit 601
    }
    * Prefer bare "Rscript" when where/which found it; otherwise absolute path.
    * On Windows ONLY, convert absolute paths to 8.3 short form when possible so
    * shell quoting survives spaces in "Program Files". Never run CMD `for %I`
    * on Unix/Linux (that probe is Windows-only).
    if "`c(os)'" == "Windows" & `ok' {
        local probe "`c(tmpdir)'re_rscript_where.txt"
        quietly shell for %I in ("`line'") do @echo %~sI > "`probe'" 2>&1
        tempname fh2
        capture file open `fh2' using "`probe'", read text
        if !_rc {
            file read `fh2' shortline
            file close `fh2'
            if `"`shortline'"' != "" & !strpos(lower(`"`shortline'"'), "could not") {
                local line `"`shortline'"'
            }
        }
    }
    global REPLICATE_RSCRIPT `"`line'"'
    di in green "require_cost_curve_engine: Rscript found (`line')"
}
else if "`cc_engine'" == "mathematica" {
    do "code/helpers/require_wolframscript.do"
}
else {
    di as err "require_cost_curve_engine: unknown engine `cc_engine' (use r or mathematica)"
    exit 198
}
