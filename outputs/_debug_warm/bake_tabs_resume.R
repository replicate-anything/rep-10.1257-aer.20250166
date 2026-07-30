# Force tab_1/tab_2 with fixed staging + timings package; then only_missing.
# Also backfill overnight fig wall-clock timings into replication_timings.json
# (build_study_outputs previously never called record_study_replication_timing).
suppressPackageStartupMessages(
  pkgload::load_all(
    "c:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/replicateEverything",
    quiet = TRUE
  )
)

Sys.unsetenv("REPLICATE_COST_CURVE_ENGINE")
Sys.unsetenv("REPLICATE_MVPF_LBD_PATH")
options(replicateEverything.stata_timeout = 3600)

study <- "c:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/rep-10.1257-aer.20250166"
outdir <- file.path(study, "outputs")
summary_path <- file.path(outdir, "_debug_warm", "bake_summary_tabs.txt")
dir.create(dirname(summary_path), recursive = TRUE, showWarnings = FALSE)

`%||%` <- function(x, y) if (is.null(x)) y else x

# Overnight fig wall-clock (end mtimes Jul 30 01:27–02:04; start ≈ prior end).
# Real bake durations from the successful overnight rewrite.
fig_secs <- list(
  fig_1 = 320,
  fig_2 = 1012,
  fig_3 = 322,
  fig_4 = 9,
  fig_5 = 509,
  fig_6 = 322,
  fig_7 = 6,
  fig_8 = 5
)
for (nm in names(fig_secs)) {
  record_study_replication_timing(study, nm, fig_secs[[nm]], engine = "stata")
}
cat("Backfilled overnight fig timings into replication_timings.json\n")
cat("timings mtime=", format(file.info(file.path(outdir, "replication_timings.json"))$mtime), "\n")

cat("=== tab force + resume", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "===\n")
cat("package=", as.character(packageVersion("replicateEverything")), "\n")
cat("stata_timeout=", getOption("replicateEverything.stata_timeout"), "\n")

t0 <- Sys.time()
err <- NULL

cat("--- forcing tab_1, tab_2 ---\n")
tryCatch(
  build_study_outputs(
    study,
    ids = c("tab_1", "tab_2"),
    install_deps = TRUE,
    only_missing = FALSE
  ),
  error = function(e) {
    err <<- paste0("tabs: ", conditionMessage(e))
    message("TAB BAKE ERROR: ", err)
  }
)

if (is.null(err)) {
  cat("--- only_missing resume ---\n")
  tryCatch(
    build_study_outputs(study, install_deps = TRUE, only_missing = TRUE),
    error = function(e) {
      err <<- paste0("resume: ", conditionMessage(e))
      message("RESUME ERROR: ", err)
    }
  )
}

elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
timings <- tryCatch(
  jsonlite::fromJSON(file.path(outdir, "replication_timings.json"), simplifyVector = FALSE),
  error = function(e) NULL
)
manifest <- tryCatch(
  jsonlite::fromJSON(file.path(outdir, "manifest.json"), simplifyVector = FALSE),
  error = function(e) NULL
)

tables <- c(
  Table1 = file.path(outdir, "Table1_scc193_main.xlsx"),
  Table2 = file.path(outdir, "Table2_CE_Table_Avg_scc193.xlsx")
)

lines <- c(
  paste0("finished_at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste0("elapsed_sec: ", round(elapsed, 1)),
  paste0("error: ", if (is.null(err)) "" else err),
  paste0("timings_generated_at: ", timings$generated_at %||% NA),
  paste0(
    "Table1_exists: ", file.exists(tables[["Table1"]]),
    " size=", if (file.exists(tables[["Table1"]])) file.info(tables[["Table1"]])$size else NA,
    " mtime=", if (file.exists(tables[["Table1"]])) format(file.info(tables[["Table1"]])$mtime) else NA
  ),
  paste0(
    "Table2_exists: ", file.exists(tables[["Table2"]]),
    " size=", if (file.exists(tables[["Table2"]])) file.info(tables[["Table2"]])$size else NA,
    " mtime=", if (file.exists(tables[["Table2"]])) format(file.info(tables[["Table2"]])$mtime) else NA
  )
)

if (!is.null(manifest$replications)) {
  lines <- c(lines, "--- display ---")
  for (nm in names(manifest$replications)) {
    st <- manifest$replications[[nm]]$status %||% "?"
    msg <- manifest$replications[[nm]]$message %||% ""
    lines <- c(lines, paste0(nm, ": ", st, if (nzchar(msg)) paste0(" | ", msg) else ""))
  }
}
if (!is.null(timings$steps)) {
  lines <- c(lines, "--- timings (sec) ---")
  for (nm in names(timings$steps)) {
    step <- timings$steps[[nm]]
    lines <- c(lines, paste0(nm, ": ", step$seconds %||% step, " @ ", step$recorded_at %||% ""))
  }
}

writeLines(lines, summary_path)
cat(paste(lines, collapse = "\n"), "\n")
cat("Wrote ", summary_path, "\n", sep = "")
if (!is.null(err)) quit(status = 1)
