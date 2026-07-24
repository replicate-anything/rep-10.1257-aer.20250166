library(testthat)

test_check <- function(...) {
  if (requireNamespace("replicateEverything", quietly = TRUE)) {
    library(replicateEverything)
  }
  testthat::test_dir("testthat", ...)
}

test_check()
