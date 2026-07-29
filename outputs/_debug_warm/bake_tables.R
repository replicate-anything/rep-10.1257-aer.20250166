suppressPackageStartupMessages(
  pkgload::load_all(
    "c:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/replicateEverything",
    quiet = TRUE
  )
)
options(replicateEverything.stata_timeout = 3600)
study <- "c:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/rep-10.1257-aer.20250166"

bake_one <- function(step) {
  message("=== baking ", step, " ===")
  t0 <- Sys.time()
  err <- NULL
  tryCatch(
    withr::with_dir(study, {
      run_replication("local", step, install_deps = TRUE, format = FALSE, force = FALSE)
    }),
    error = function(e) {
      err <<- conditionMessage(e)
      message("ERROR: ", err)
    }
  )
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  timing <- tryCatch(
    lookup_study_replication_timing("rep-10.1257-aer.20250166", step),
    error = function(e) NULL
  )
  list(step = step, elapsed_sec = elapsed, error = err, timing = timing)
}

r1 <- bake_one("tab_1")
r2 <- bake_one("tab_2")

outs <- c(
  file.path(study, "outputs/Table1_scc193_main.xlsx"),
  file.path(study, "outputs/Table2_CE_Table_Avg_scc193.xlsx")
)
cat("\n=== summary ===\n")
str(list(tab_1 = r1, tab_2 = r2), max.level = 3)
cat("files exist:\n")
print(file.exists(outs))
cat("sizes:\n")
print(file.info(outs)$size)
