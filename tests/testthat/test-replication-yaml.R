# Smoke tests only - no Stata in this environment yet (see
# onboarding_notes/openicpsr-aer-239169.md). These tests validate the yaml
# contract and file layout, not live execution. LBD default engine is R.

DOI <- "10.1257/aer.20250166"
FOLDER <- "10.1257_aer.20250166"
STUDY_REPO <- "replicate-anything/rep-10.1257-aer.20250166"

study_test_context <- function() {
  study_root <- normalizePath(
    testthat::test_path("..", ".."),
    winslash = "/",
    mustWork = FALSE
  )
  registry_root <- normalizePath(
    file.path(study_root, "..", "registry"),
    winslash = "/",
    mustWork = FALSE
  )
  monorepo_root <- normalizePath(
    file.path(study_root, ".."),
    winslash = "/",
    mustWork = FALSE
  )

  local_index <- data.frame(
    folder = FOLDER,
    handle = "mvpf-climate-policy",
    doi = paste0("https://doi.org/", DOI),
    title = "A Welfare Analysis of Policies Impacting Climate Change",
    journal = "American Economic Review",
    year = 2026,
    authors = "Hahn, Hendren, Metcalfe, Sprung-Keyser",
    repo = STUDY_REPO,
    stringsAsFactors = FALSE
  )

  list(
    study_root = study_root,
    registry_root = registry_root,
    monorepo_root = monorepo_root,
    local_index = local_index
  )
}

with_study_options <- function(ctx, expr) {
  withr::with_options(
    list(
      replicateEverything.registry_root = ctx$registry_root,
      replicateEverything.index = ctx$local_index,
      replicateEverything.use_sibling_packages = TRUE,
      replicateEverything.study_folders_root = ctx$monorepo_root
    ),
    expr
  )
}

test_that("no committed .do file has a stray backtick or embedded block-comment-open in a comment", {
  # Our own code/*.do runners (NOT code/original/**, which is unmodified author
  # code) use single-line "*" comments only. Two Stata lexer gotchas turned real
  # code into a silently-swallowed comment during scaffolding - see
  # onboarding_notes/openicpsr-aer-239169.md:
  #  1. A lone backtick opens a `macro' reference and scans forward (through
  #     comments, across lines) for the closing apostrophe - a markdown-style
  #     `word` in a comment swallows everything after it with NO error.
  #  2. A forward-slash immediately followed by an asterisk opens a block
  #     comment REGARDLESS of surrounding comment context; with no matching
  #     closing asterisk-slash anywhere later in the file, it silently
  #     swallows every remaining line (including real code) to end-of-file,
  #     again with NO error. This was the actual root cause of ${github}
  #     staying empty and clean_data.do failing with r(601).
  ctx_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = FALSE)
  do_files <- list.files(
    file.path(ctx_root, "code"),
    pattern = "\\.do$", recursive = TRUE, full.names = TRUE
  )
  do_files <- do_files[!grepl("/original/", do_files, fixed = TRUE)]
  testthat::expect_true(length(do_files) > 0)

  for (f in do_files) {
    lines <- readLines(f, warn = FALSE)
    comment_lines <- grep("^\\s*\\*", lines, value = TRUE)
    bad_backtick <- grep("`[A-Za-z][^`']*`", comment_lines, value = TRUE)
    testthat::expect_length(bad_backtick, 0)
    bad_slash_star <- grep("/\\*", comment_lines, value = TRUE, fixed = FALSE)
    testthat::expect_length(bad_slash_star, 0)
  }
})

test_that("replication.yml parses and declares the expected v1 steps", {
  ctx <- study_test_context()
  yml <- yaml::read_yaml(file.path(ctx$study_root, "replication.yml"))

  testthat::expect_true(!is.null(yml$steps))
  ids <- vapply(yml$steps, function(s) s$id, character(1))

  expected <- c(
    "cost_curve_data_r",
    "clean_data", "macros", "compute_mvpf_main", "compute_mvpf_main_mathematica",
    "compute_mvpf_no_lbd",
    "fig_1", "fig_2", "fig_3", "fig_5", "fig_6",
    "fig_4", "fig_7", "fig_8", "tab_1", "tab_2"
  )
  testthat::expect_true(all(expected %in% ids))
  testthat::expect_false("cost_curve_mathematica" %in% ids)

  # Sidebar / DAG order: prep before MVPF path group
  testthat::expect_lt(
    match("clean_data", ids),
    match("compute_mvpf_main", ids)
  )
  testthat::expect_lt(
    match("macros", ids),
    match("compute_mvpf_main", ids)
  )
  testthat::expect_lt(
    match("cost_curve_data_r", ids),
    match("compute_mvpf_main", ids)
  )

  mvpf <- yml$steps[vapply(yml$steps, function(s) {
    identical(s$id, "compute_mvpf_main")
  }, logical(1))][[1]]
  mvpf_m <- yml$steps[vapply(yml$steps, function(s) {
    identical(s$id, "compute_mvpf_main_mathematica")
  }, logical(1))][[1]]
  testthat::expect_identical(mvpf$group, "compute_mvpf_main")
  testthat::expect_identical(mvpf_m$group, "compute_mvpf_main")

  # No legacy fields (hard error under replicateEverything 0.7)
  testthat::expect_null(yml$prep)
  testthat::expect_null(yml$replications)
})

test_that("every declared code: path exists", {
  ctx <- study_test_context()
  yml <- yaml::read_yaml(file.path(ctx$study_root, "replication.yml"))
  for (step in yml$steps) {
    if (!is.null(step$code)) {
      testthat::expect_true(
        file.exists(file.path(ctx$study_root, step$code)),
        info = sprintf("%s: %s", step$id, step$code)
      )
    }
  }
})

test_that("list_replications() sees the declared steps", {
  testthat::skip_if_not_installed("replicateEverything")
  ctx <- study_test_context()
  testthat::skip_if_not(dir.exists(ctx$registry_root), "registry checkout missing")

  with_study_options(ctx, {
    reps <- replicateEverything::list_replications(DOI, folder = FOLDER)
    ids <- vapply(reps, function(x) x$id, character(1))
    testthat::expect_true(all(c("tab_1", "tab_2", "fig_1") %in% ids))
  })
})

test_that("check_study_compatibility reports stata as unavailable here", {
  # Documents the environment this scaffold was built in (see onboarding_notes) -
  # not a pass/fail assertion on the study itself.
  testthat::skip_if_not_installed("replicateEverything")
  ctx <- study_test_context()
  testthat::skip_if_not(dir.exists(ctx$registry_root), "registry checkout missing")

  with_study_options(ctx, {
    result <- tryCatch(
      replicateEverything::check_study_compatibility(DOI),
      error = function(e) e
    )
    # Just confirm it runs without erroring on yaml parsing; do not assert on
    # stata/mathematica availability, which is machine-specific.
    testthat::expect_false(inherits(result, "error"))
  })
})
