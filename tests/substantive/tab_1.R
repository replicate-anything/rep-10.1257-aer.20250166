# Substantive (published-value) checks for Table 1 — Hahn et al. (AER)
#
# Benchmarks: Table 1, "Wind Production Credits" headline row (Panel A),
# rounded published components vs baked outputs/Table1_scc193_main.xlsx
# (TABLE sheet). Profits is blank in the display row and is omitted.

tab_1_wind_credits_benchmark <- function() {
  # Transfer, Env. Benefits, LBD Env., Price, WTP, Fiscal Externality, Total, MVPF
  c(1.000, 4.248, 1.900, 0.645, 7.793, 0.328, 1.328, 5.870)
}

resolve_tab_1_xlsx <- function(object = NULL) {
  `%||%` <- function(a, b) if (is.null(a)) b else a
  candidates <- character(0)

  if (is.character(object) && length(object) == 1L && nzchar(object)) {
    candidates <- c(candidates, object)
  } else if (is.list(object) && !is.data.frame(object)) {
    path <- object$output_path %||% object$smcl_path %||% NULL
    if (!is.null(path) && length(path) >= 1L) {
      candidates <- c(candidates, as.character(path[[1L]]))
    }
  }

  roots <- unique(c(
    Sys.getenv("REPLICATE_STUDY_ROOT", unset = ""),
    Sys.getenv("REPLICATE_STUDY_DIR", unset = ""),
    getwd()
  ))
  roots <- roots[nzchar(roots)]
  for (root in roots) {
    candidates <- c(
      candidates,
      file.path(root, "outputs", "Table1_scc193_main.xlsx"),
      file.path(root, "data", "6_tables", "tables_main", "Table1_scc193_main.xlsx")
    )
  }

  for (path in unique(candidates)) {
    if (nzchar(path) && file.exists(path)) {
      return(normalizePath(path, winslash = "/", mustWork = FALSE))
    }
  }
  stop(
    "Could not locate Table1_scc193_main.xlsx for substantive check.",
    call. = FALSE
  )
}

extract_tab_1_wind_credits_row <- function(path) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Package 'readxl' is required to check Table 1 xlsx output.", call. = FALSE)
  }
  sheets <- readxl::excel_sheets(path)
  sheet <- if ("TABLE" %in% sheets) "TABLE" else sheets[[1L]]
  df <- as.data.frame(
    readxl::read_excel(path, sheet = sheet, col_names = FALSE),
    stringsAsFactors = FALSE
  )
  label_re <- "wind production credits"
  idx <- which(vapply(seq_len(nrow(df)), function(i) {
    any(grepl(label_re, as.character(unlist(df[i, , drop = TRUE])), ignore.case = TRUE))
  }, logical(1)))
  if (!length(idx)) {
    stop(
      "Could not find 'Wind Production Credits' row in ", basename(path),
      " sheet ", sheet, ".",
      call. = FALSE
    )
  }
  # First match is the Panel A headline category row (before PTC variants).
  row <- unlist(df[idx[[1L]], , drop = TRUE], use.names = FALSE)
  nums <- suppressWarnings(as.numeric(row))
  nums <- nums[is.finite(nums)]
  if (length(nums) < 8L) {
    stop(
      "Expected at least 8 numeric cells in Wind Production Credits row; got ",
      length(nums), ".",
      call. = FALSE
    )
  }
  # Drop trailing extras if present; keep the eight published components.
  nums[seq_len(8L)]
}

#' @param object Stata replication result, xlsx path, or NULL (use baked outputs/).
#' @param tolerance Absolute tolerance for MVPF-style decimals (default 0.01).
substantive_check_tab_1 <- function(object = NULL, tolerance = 0.01) {
  path <- resolve_tab_1_xlsx(object)
  got <- extract_tab_1_wind_credits_row(path)
  expected <- tab_1_wind_credits_benchmark()
  deltas <- abs(got - expected)
  bad <- which(deltas > tolerance)
  if (length(bad)) {
    stop(
      "Published Table 1 Wind Production Credits check failed (",
      basename(path), "):\n",
      paste0(
        sprintf(
          " - col %d: expected %.3f, got %.6f (abs diff %.6f)",
          bad, expected[bad], got[bad], deltas[bad]
        ),
        collapse = "\n"
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}
