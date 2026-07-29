study <- normalizePath(
  "c:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/rep-10.1257-aer.20250166"
)
logdir <- file.path(study, "outputs", "_debug_warm")
dir.create(logdir, recursive = TRUE, showWarnings = FALSE)

probe <- file.path(logdir, "probe_warm.do")
study_fwd <- gsub("\\\\", "/", study)
writeLines(
  c(
    "set more off, permanently",
    "pause off",
    "cap log close _all",
    paste0("log using \"", study_fwd, "/outputs/_debug_warm/probe_warm_stata.log\", text replace"),
    paste0("cd \"", study_fwd, "\""),
    "do \"code/helpers/init_study_paths.do\"",
    "di as txt \"PROBE: after init at \" c(current_time)",
    "do \"code/helpers/warm_session.do\"",
    "di as txt \"PROBE: after warm at \" c(current_time)",
    "di as txt \"PROBE: scc=${scc}\"",
    "log close"
  ),
  probe
)

exe <- "C:/Program Files/Stata17/StataMP-64.exe"
t0 <- Sys.time()
px <- processx::run(
  exe,
  c("/e", "/i", "/q", "do", gsub("/", "\\\\", probe)),
  wd = study,
  timeout = 600,
  error_on_status = FALSE,
  spinner = FALSE
)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
cat("elapsed_sec:", elapsed, "\n")
cat("status:", px$status, " timeout:", isTRUE(px$timeout), "\n")
logf <- file.path(logdir, "probe_warm_stata.log")
cat("log exists:", file.exists(logf), " size:", if (file.exists(logf)) file.info(logf)$size else NA, "\n")
if (file.exists(logf)) {
  lines <- readLines(logf, warn = FALSE)
  cat("--- last 50 ---\n")
  writeLines(utils::tail(lines, 50))
  cat("--- markers ---\n")
  hits <- grep("PROBE:|Early exit|SECTION 0|warm_session|macros|r\\([0-9]+\\)|error", lines, value = TRUE, ignore.case = TRUE)
  writeLines(utils::head(hits, 80))
}
