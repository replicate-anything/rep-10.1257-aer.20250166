# Direct Stata smoke: force R engine, confirm Rscript found (not wolfram).
study <- normalizePath(
  "c:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/rep-10.1257-aer.20250166",
  winslash = "/"
)
Sys.unsetenv("REPLICATE_COST_CURVE_ENGINE")
Sys.unsetenv("REPLICATE_MVPF_LBD_PATH")
# Intentionally set env to mathematica to prove Stata global wins.
Sys.setenv(REPLICATE_COST_CURVE_ENGINE = "mathematica")

logdir <- file.path(study, "outputs", "_debug_warm")
dir.create(logdir, recursive = TRUE, showWarnings = FALSE)
probe <- file.path(logdir, "probe_rscript2.do")
marker <- file.path(logdir, "probe_rscript2_ok.txt")
if (file.exists(marker)) unlink(marker)

writeLines(
  c(
    "set more off, permanently",
    "pause off",
    paste0("cd \"", study, "\""),
    "do \"code/helpers/init_study_paths.do\"",
    "global REPLICATE_COST_CURVE_ENGINE \"r\"",
    "do \"code/helpers/require_cost_curve_engine.do\"",
    paste0("file open mh using \"", study, "/outputs/_debug_warm/probe_rscript2_ok.txt\", write replace"),
    "file write mh \"engine=${REPLICATE_COST_CURVE_ENGINE}\" _n",
    "file write mh \"rscript=${REPLICATE_RSCRIPT}\" _n",
    "file close mh",
    "di as txt \"SMOKE_DONE engine=${REPLICATE_COST_CURVE_ENGINE} rscript=${REPLICATE_RSCRIPT}\"",
    "exit 0"
  ),
  probe
)

exe <- "C:/Program Files/Stata17/StataMP-64.exe"
t0 <- Sys.time()
px <- processx::run(
  exe,
  c("/e", "/i", "/q", "do", gsub("/", "\\\\", probe)),
  wd = study,
  timeout = 180,
  error_on_status = FALSE,
  spinner = FALSE,
  env = c(Sys.getenv(), REPLICATE_COST_CURVE_ENGINE = "mathematica")
)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
cat("elapsed_sec:", elapsed, " status:", px$status, " timeout:", isTRUE(px$timeout), "\n")
if (file.exists(marker)) {
  cat("--- marker ---\n")
  writeLines(readLines(marker, warn = FALSE))
  txt <- paste(readLines(marker, warn = FALSE), collapse = "\n")
  ok <- grepl("engine=r", txt) && grepl("rscript=", txt) && !grepl("wolfram", txt, ignore.case = TRUE)
  cat("SMOKE_OK=", ok, "\n", sep = "")
  if (!ok) quit(status = 1)
} else {
  cat("SMOKE ERROR: marker missing\n")
  cat(px$stdout, "\n")
  cat(px$stderr, "\n")
  quit(status = 1)
}
Sys.unsetenv("REPLICATE_COST_CURVE_ENGINE")
Sys.unsetenv("REPLICATE_MVPF_LBD_PATH")
