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

test_that("policy_details_v3.xlsx is present at data root", {
  study_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = FALSE)

  # Deposit path is data/policy_details_v3.xlsx (= ${code_files}/...), not under
  # 1_assumptions/. Early onboarding missed it; keep this assert so it stays committed.
  testthat::expect_true(file.exists(file.path(study_root, "data", "policy_details_v3.xlsx")))
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
