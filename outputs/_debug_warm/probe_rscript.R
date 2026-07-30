# Smoke: require_cost_curve_engine finds Rscript (not wolfram) with R forced.
suppressPackageStartupMessages(
  pkgload::load_all("replicateEverything", quiet = TRUE)
)
Sys.unsetenv("REPLICATE_COST_CURVE_ENGINE")
Sys.unsetenv("REPLICATE_MVPF_LBD_PATH")
options(replicateEverything.stata_timeout = 120)

study <- normalizePath("rep-10.1257-aer.20250166", winslash = "/")
logdir <- file.path(study, "outputs", "_debug_warm")
dir.create(logdir, recursive = TRUE, showWarnings = FALSE)
probe <- file.path(logdir, "probe_rscript.do")
study_fwd <- gsub("\\\\", "/", study)
writeLines(
  c(
    "set more off, permanently",
    "pause off",
    "cap log close _all",
    paste0("log using \"", study_fwd, "/outputs/_debug_warm/probe_rscript.log\", text replace"),
    paste0("cd \"", study_fwd, "\""),
    "do \"code/helpers/init_study_paths.do\"",
    "global REPLICATE_COST_CURVE_ENGINE \"r\"",
    "do \"code/helpers/require_cost_curve_engine.do\"",
    "di as txt \"PROBE_ENGINE=${REPLICATE_COST_CURVE_ENGINE}\"",
    "di as txt \"PROBE_RSCRIPT=${REPLICATE_RSCRIPT}\"",
    "log close"
  ),
  probe
)

res <- tryCatch(
  replicateEverything:::run_stata_do(probe, study, timeout = 120L),
  error = function(e) e
)
if (inherits(res, "condition")) {
  cat("SMOKE ERROR:", conditionMessage(res), "\n")
  quit(status = 1)
}
logf <- file.path(logdir, "probe_rscript.log")
# Also keep package batch log if present
if (!is.null(res$log_path) && file.exists(res$log_path)) {
  file.copy(res$log_path, file.path(logdir, "probe_rscript_batch.log"), overwrite = TRUE)
}
lines <- if (file.exists(logf)) readLines(logf, warn = FALSE) else character(0)
hits <- grep("Rscript found|wolframscript|PROBE_|require_cost_curve|r\\([0-9]+\\)", lines, value = TRUE, ignore.case = TRUE)
cat("--- smoke hits ---\n")
writeLines(hits)
ok <- any(grepl("Rscript found", lines, ignore.case = TRUE)) &&
  !any(grepl("wolframscript not found|require_wolframscript", lines, ignore.case = TRUE))
cat("SMOKE_OK=", ok, " exit=", res$exit_status %||% NA, "\n", sep = "")
if (!isTRUE(ok)) quit(status = 1)
