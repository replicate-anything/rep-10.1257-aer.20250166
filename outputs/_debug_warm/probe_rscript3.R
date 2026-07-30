suppressPackageStartupMessages(
  pkgload::load_all(
    "c:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/replicateEverything",
    quiet = TRUE
  )
)
Sys.unsetenv("REPLICATE_COST_CURVE_ENGINE")
Sys.unsetenv("REPLICATE_MVPF_LBD_PATH")
# Prove Stata global beats a hostile env var.
Sys.setenv(REPLICATE_COST_CURVE_ENGINE = "mathematica")
options(replicateEverything.stata_timeout = 300)

study <- normalizePath(
  "c:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/rep-10.1257-aer.20250166",
  winslash = "/"
)
logdir <- file.path(study, "outputs", "_debug_warm")
dir.create(logdir, recursive = TRUE, showWarnings = FALSE)
probe <- file.path(logdir, "probe_rscript3.do")
marker <- file.path(logdir, "probe_rscript3_ok.txt")
if (file.exists(marker)) unlink(marker)

writeLines(
  c(
    "set more off, permanently",
    "pause off",
    paste0("cd \"", study, "\""),
    "do \"code/helpers/init_study_paths.do\"",
    "global REPLICATE_COST_CURVE_ENGINE \"r\"",
    "do \"code/helpers/require_cost_curve_engine.do\"",
    paste0("file open mh using \"", study, "/outputs/_debug_warm/probe_rscript3_ok.txt\", write replace"),
    "file write mh \"engine=${REPLICATE_COST_CURVE_ENGINE}\" _n",
    "file write mh \"rscript=${REPLICATE_RSCRIPT}\" _n",
    "file close mh",
    "exit 0"
  ),
  probe
)

t0 <- Sys.time()
res <- tryCatch(
  replicateEverything:::run_stata_do(probe, study, timeout = 300L),
  error = function(e) e
)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
cat("elapsed_sec:", elapsed, "\n")
if (inherits(res, "condition")) {
  cat("SMOKE ERROR:", conditionMessage(res), "\n")
  quit(status = 1)
}
cat("exit_status:", res$exit_status %||% NA, "\n")
if (!file.exists(marker)) {
  cat("SMOKE ERROR: marker missing\n")
  if (!is.null(res$log_tail)) writeLines(utils::tail(res$log_tail, 40))
  quit(status = 1)
}
txt <- paste(readLines(marker, warn = FALSE), collapse = "\n")
cat("--- marker ---\n", txt, "\n", sep = "")
ok <- grepl("engine=r", txt, fixed = TRUE) &&
  grepl("rscript=", txt, fixed = TRUE) &&
  nzchar(sub(".*rscript=", "", txt)) &&
  !grepl("wolfram", txt, ignore.case = TRUE)
cat("SMOKE_OK=", ok, "\n", sep = "")
Sys.unsetenv("REPLICATE_COST_CURVE_ENGINE")
Sys.unsetenv("REPLICATE_MVPF_LBD_PATH")
if (!ok) quit(status = 1)
