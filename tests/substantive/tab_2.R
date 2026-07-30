# Substantive (published-value) checks for Table 2 — Hahn et al. (AER)
#
# Benchmarks: Table 2, "Wind Production Credits" Panel A (with LBD) vs
# baked outputs/Table2_CE_Table_Avg_scc193.xlsx sheet data_export.
# Read data_export (not TABLE): Stata only overwrites data_export;
# TABLE is copied from TEMPLATE_ce_averages.xlsx with formulas into
# data_export, so without Excel recalc readers see a stale template cache.

tab_2_wind_credits_lbd_benchmark <- function() {
  # mvpf, resource_cost_table, govt_cost_table, net_social_cost_table
  c(5.870, -103, 46, -32)
}

resolve_tab_2_xlsx <- function(object = NULL) {
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
      file.path(root, "outputs", "Table2_CE_Table_Avg_scc193.xlsx"),
      file.path(root, "data", "6_tables", "tables_main", "Table2_CE_Table_Avg_scc193.xlsx")
    )
  }

  for (path in unique(candidates)) {
    if (nzchar(path) && file.exists(path)) {
      return(normalizePath(path, winslash = "/", mustWork = FALSE))
    }
  }
  stop(
    "Could not locate Table2_CE_Table_Avg_scc193.xlsx for substantive check.",
    call. = FALSE
  )
}

extract_tab_2_wind_credits_lbd_row <- function(path) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Package 'readxl' is required to check Table 2 xlsx output.", call. = FALSE)
  }
  sheets <- readxl::excel_sheets(path)
  # Prefer data_export: TABLE holds unrecalculated template formulas.
  sheet <- if ("data_export" %in% sheets) "data_export" else sheets[[1L]]
  df <- as.data.frame(
    readxl::read_excel(path, sheet = sheet, col_names = TRUE),
    stringsAsFactors = FALSE
  )
  label_re <- "wind production credits"
  label_col <- names(df)[[1L]]
  idx <- which(grepl(label_re, as.character(df[[label_col]]), ignore.case = TRUE))
  if (!length(idx)) {
    stop(
      "Could not find 'Wind Production Credits' row in ", basename(path),
      " sheet ", sheet, ".",
      call. = FALSE
    )
  }
  # First match is Panel A (with LBD); Panel B repeats the label later.
  row <- df[idx[[1L]], , drop = FALSE]
  nums <- suppressWarnings(as.numeric(unlist(row[, -1L, drop = TRUE], use.names = FALSE)))
  nums <- nums[is.finite(nums)]
  if (length(nums) < 4L) {
    stop(
      "Expected at least 4 numeric cells in Wind Production Credits (LBD) row; got ",
      length(nums), ".",
      call. = FALSE
    )
  }
  nums[seq_len(4L)]
}

#' @param object Stata replication result, xlsx path, or NULL (use baked outputs/).
#' @param mvpf_tolerance Absolute tolerance for MVPF (default 0.01).
#' @param cost_tolerance Absolute tolerance for cost-per-ton columns rounded
#'   to published integers (default 0.6).
substantive_check_tab_2 <- function(object = NULL,
                                    mvpf_tolerance = 0.01,
                                    cost_tolerance = 0.6) {
  path <- resolve_tab_2_xlsx(object)
  got <- extract_tab_2_wind_credits_lbd_row(path)
  expected <- tab_2_wind_credits_lbd_benchmark()
  tols <- c(mvpf_tolerance, rep(cost_tolerance, 3L))
  deltas <- abs(got - expected)
  bad <- which(deltas > tols)
  if (length(bad)) {
    stop(
      "Published Table 2 Wind Production Credits (Panel A / with LBD) check failed (",
      basename(path), "):\n",
      paste0(
        sprintf(
          " - col %d: expected %.3f, got %.6f (abs diff %.6f, tol %.3f)",
          bad, expected[bad], got[bad], deltas[bad], tols[bad]
        ),
        collapse = "\n"
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}
