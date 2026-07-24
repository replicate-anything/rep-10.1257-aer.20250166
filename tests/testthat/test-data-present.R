test_that("root data inputs are present", {
  study_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = FALSE)

  testthat::expect_true(dir.exists(file.path(study_root, "data", "1_assumptions")))
  testthat::expect_true(dir.exists(file.path(study_root, "data", "2a_causal_estimates_papers")))
  testthat::expect_true(file.exists(file.path(
    study_root, "data", "1_assumptions", "policy_category_assumptions_MASTER.xlsx"
  )))
  testthat::expect_true(file.exists(file.path(
    study_root, "data", "5_graphs", "figures_data", "Nudge Estimates.xlsx"
  )))
})

test_that("known missing input is documented, not fabricated", {
  study_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = FALSE)

  # policy_details_v3.xlsx genuinely does not exist in OpenICPSR 239169-V1 (see
  # data/README.md). This test intentionally asserts its ABSENCE so nobody
  # accidentally "fixes" this by fabricating the file instead of sourcing it.
  testthat::expect_false(file.exists(file.path(study_root, "data", "policy_details_v3.xlsx")))
  testthat::expect_true(file.exists(file.path(study_root, "data", "README.md")))
})

test_that("original author code needed by in-scope steps is present", {
  study_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = FALSE)
  original <- file.path(study_root, "code", "original")

  for (d in c("ado", "calculations", "cost_curve", "data_cleaning", "figtab", "wrapper",
              "policies/harmonized")) {
    testthat::expect_true(dir.exists(file.path(original, d)), info = d)
  }
  testthat::expect_true(file.exists(file.path(original, "wrapper", "metafile.do")))
  testthat::expect_true(file.exists(file.path(original, "ado", "run_program.ado")))
})
