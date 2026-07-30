* replicateEverything provenance: connector
* Stage an author tables_main xlsx into study outputs/.
*
* Usage:
*   do "code/helpers/stage_xlsx_to_outputs.do" "`src'" "`dst'" "tab_1"
* Args (locals do NOT cross `do` boundaries in this Stata):
*   1  absolute path to source workbook
*   2  absolute path under ${user}/outputs/
*   3  short label for error messages (optional)
*
* Dropbox-paused trees still hit Stata r(693) when the destination xlsx is
* locked or marked read-only. Clear attrib, erase dest, stage via a temp
* name, fall back to Windows copy /Y if Stata copy keeps failing. Hard
* fail with a distinct message for missing source vs locked destination.
*
* Avoid slash-star sequences in comments (Stata block-comment trap).

local _src `"`1'"'
local _dst `"`2'"'
local _label `"`3'"'
if "`_label'" == "" local _label "stage_xlsx"

if `"`_src'"' == "" | `"`_dst'"' == "" {
    di as err "stage_xlsx_to_outputs: need args src dst [label]"
    exit 198
}

cap mkdir "${user}/outputs"

cap confirm file `"`_src'"'
if _rc {
    di as err "`_label': source workbook missing: `_src'"
    di as err "  Author excel writer did not produce the tables_main file."
    exit 601
}

* Clear read-only on an existing destination (Dropbox / prior bake).
if "`c(os)'" == "Windows" {
    local _dst_win = subinstr("`_dst'", "/", "\", .)
    quietly shell attrib -R "`_dst_win'" > nul 2>&1
}
cap erase `"`_dst'"'

local _tmp `"`_dst'.staging.xlsx"'
if "`c(os)'" == "Windows" {
    local _tmp_win = subinstr("`_tmp'", "/", "\", .)
    quietly shell attrib -R "`_tmp_win'" > nul 2>&1
}
cap erase `"`_tmp'"'

* Prefer Stata copy into temp, then promote.
copy `"`_src'"' `"`_tmp'"', replace
local _rc = _rc
if `_rc' {
    sleep 2000
    copy `"`_src'"' `"`_tmp'"', replace
    local _rc = _rc
}
if `_rc' & "`c(os)'" == "Windows" {
    local _src_win = subinstr("`_src'", "/", "\", .)
    quietly shell copy /Y "`_src_win'" "`_tmp_win'"
    sleep 500
    cap confirm file `"`_tmp'"'
    local _rc = _rc
}
if `_rc' {
    di as err "`_label': could not write staging temp `_tmp' (r(`_rc'))"
    di as err "  source ok: `_src'"
    exit `_rc'
}

* Promote temp to destination.
if "`c(os)'" == "Windows" {
    quietly shell attrib -R "`_dst_win'" > nul 2>&1
}
cap erase `"`_dst'"'
copy `"`_tmp'"' `"`_dst'"', replace
local _rc = _rc
if `_rc' {
    sleep 1500
    if "`c(os)'" == "Windows" {
        quietly shell copy /Y "`_tmp_win'" "`_dst_win'"
        sleep 500
        cap confirm file `"`_dst'"'
        local _rc = _rc
    }
    else {
        copy `"`_tmp'"' `"`_dst'"', replace
        local _rc = _rc
    }
}
cap erase `"`_tmp'"'

cap confirm file `"`_dst'"'
if _rc {
    di as err "`_label': failed to stage into outputs/ (dest locked or unwritable)"
    di as err "  source: `_src'"
    di as err "  dest:   `_dst'"
    di as err "  Clear read-only / close the xlsx if open, then re-run."
    exit 693
}

di in green "`_label': staged `_dst'"
