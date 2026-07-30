suppressPackageStartupMessages(
  pkgload::load_all("replicateEverything", quiet = TRUE)
)
root <- "rep-10.1257-aer.20250166"
meta <- read_study_replication_yaml(root)
display <- replicateEverything:::folder_display_replications(meta)
ids <- vapply(display, function(x) as.character(x$id[[1]] %||% x$id), character(1))
cat("display:", paste(ids, collapse = ", "), "\n")
prep <- replicateEverything:::prep_steps_for_build(meta, display)
pids <- vapply(prep, function(x) as.character(x$id[[1]] %||% x$id), character(1))
inc <- vapply(prep, function(x) isTRUE(x$incomplete %||% FALSE), logical(1))
cat("prep:", paste(pids, collapse = ", "), "\n")
cat("incomplete among prep:", paste(pids[inc], collapse = ", "), "\n")
entry <- replicateEverything:::find_replication_entry(meta, "compute_mvpf_main")
cat(
  "lookup compute_mvpf_main ->",
  as.character(entry$id),
  " incomplete=",
  isTRUE(entry$incomplete),
  " code=",
  as.character(entry$code[[1]] %||% entry$code),
  "\n"
)
entry2 <- tryCatch(
  replicateEverything:::find_replication_entry(meta, "compute_mvpf_main", language = "mathematica"),
  error = function(e) e
)
if (inherits(entry2, "error")) {
  cat("lookup language=mathematica: ", conditionMessage(entry2), "\n")
} else {
  cat(
    "lookup language=mathematica ->",
    as.character(entry2$id),
    " code=",
    as.character(entry2$code[[1]] %||% entry2$code),
    "\n"
  )
}
