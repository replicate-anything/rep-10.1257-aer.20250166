# Full Hahn bake with fresh timings. Safe to re-run with only_missing=TRUE.
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
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
summary_path <- file.path(outdir, "_debug_warm", "bake_summary.txt")
dir.create(dirname(summary_path), recursive = TRUE, showWarnings = FALSE)

cat("=== bake start", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "===\n")
cat("stata_timeout=", getOption("replicateEverything.stata_timeout"), "\n")
cat("env COST_CURVE=", Sys.getenv("REPLICATE_COST_CURVE_ENGINE", ""), "\n")
cat("env MVPF_LBD=", Sys.getenv("REPLICATE_MVPF_LBD_PATH", ""), "\n")

t0 <- Sys.time()
err <- NULL
result <- tryCatch(
  build_study_outputs(study, install_deps = TRUE, only_missing = FALSE),
  error = function(e) {
    err <<- conditionMessage(e)
    message("BAKE ERROR: ", err)
    NULL
  }
)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

# Collect status
timings_path <- file.path(outdir, "replication_timings.json")
timings <- if (file.exists(timings_path)) {
  tryCatch(jsonlite::fromJSON(timings_path, simplifyVector = FALSE), error = function(e) NULL)
} else {
  NULL
}

tables <- c(
  Table1 = file.path(outdir, "Table1_scc193_main.xlsx"),
  Table2 = file.path(outdir, "Table2_CE_Table_Avg_scc193.xlsx")
)

manifest_path <- file.path(outdir, "manifest.json")
manifest <- if (file.exists(manifest_path)) {
  tryCatch(jsonlite::fromJSON(manifest_path, simplifyVector = FALSE), error = function(e) NULL)
} else {
  NULL
}

lines <- c(
  paste0("finished_at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste0("elapsed_sec: ", round(elapsed, 1)),
  paste0("error: ", if (is.null(err)) "" else err),
  paste0("Table1_exists: ", file.exists(tables[["Table1"]]), " size=", if (file.exists(tables[["Table1"]])) file.info(tables[["Table1"]])$size else NA),
  paste0("Table2_exists: ", file.exists(tables[["Table2"]]), " size=", if (file.exists(tables[["Table2"]])) file.info(tables[["Table2"]])$size else NA)
)

if (!is.null(manifest$prep)) {
  lines <- c(lines, "--- prep ---")
  for (nm in names(manifest$prep)) {
    st <- manifest$prep[[nm]]$status %||% "?"
    lines <- c(lines, paste0(nm, ": ", st))
  }
}
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
    sec <- timings$steps[[nm]]$seconds %||% timings$steps[[nm]]$elapsed %||% timings$steps[[nm]]
    lines <- c(lines, paste0(nm, ": ", sec))
  }
}

writeLines(lines, summary_path)
cat(paste(lines, collapse = "\n"), "\n")
cat("Wrote ", summary_path, "\n", sep = "")
if (!is.null(err)) quit(status = 1)
