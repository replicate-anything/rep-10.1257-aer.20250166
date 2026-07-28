# replicateEverything provenance: connector
# Step: cost_curve_data_r - LBD cost-curve data build (R engine)
#
# Builds a real LBD cost-curve dataset by calling the exact R scripts that
# Stata's cost_curve_masterfile.ado shells to for the live-default engine
# (REPLICATE_COST_CURVE_ENGINE unset / "r" - see README "LBD cost-curve
# rewrite"). Downstream Stata steps (compute_mvpf_main, fig_1, fig_2, fig_3,
# fig_6) invoke these SAME two scripts per-policy at runtime with
# policy-specific, Stata-computed parameters; this step is the standalone,
# runnable R-engine build/validation gate for that shared numerical kernel -
# if R/deSolve is broken here, the same failure would recur ~40x inside the
# full compute_mvpf_main batch. The Mathematica original (.wls) path is the
# separate, optional `cost_curve_mathematica` step - the two engines are
# deliberately NOT combined into one multilingual step.
#
# Scenarios below are illustrative calibration points chosen to exercise BOTH
# scripts cost_curve_masterfile.ado dispatches between (cost_curve_simple.R
# when subsidy_end==0 & fcr==0; cost_curve_masterfile.R otherwise) - they are
# not any single paper policy's real assumptions. Numerical fidelity vs
# Mathematica is spot-check status only (see README).

make_cost_curve_data_r <- function() {
  root <- Sys.getenv("REPLICATE_STUDY_ROOT", unset = getwd())
  cc_dir <- file.path(root, "code", "cost_curve")
  out_dir <- file.path(root, "outputs", "cost_curve_data_r")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  rscript_bin <- Sys.which("Rscript")
  if (!nzchar(rscript_bin)) {
    stop(
      "cost_curve_data_r: Rscript not found on PATH (needed to run ",
      "code/cost_curve/*.R the same way cost_curve_masterfile.ado does)."
    )
  }

  run_cc_script <- function(script, args, tag) {
    work_dir <- file.path(tempdir(), paste0("cost_curve_data_r_", tag))
    unlink(work_dir, recursive = TRUE, force = TRUE)
    dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)
    old_wd <- getwd()
    setwd(work_dir)
    on.exit(setwd(old_wd), add = TRUE)

    script_path <- file.path(cc_dir, script)
    log_lines <- system2(
      rscript_bin,
      args = c(shQuote(script_path), args, tag),
      stdout = TRUE, stderr = TRUE
    )
    csv_path <- file.path(work_dir, paste0(tag, ".csv"))
    if (!file.exists(csv_path)) {
      stop(
        "cost_curve_data_r: ", script, " did not produce ", tag, ".csv.\n",
        paste(log_lines, collapse = "\n")
      )
    }
    utils::read.csv(csv_path, header = FALSE)[[1]]
  }

  # Args positional order matches cost_curve_masterfile.ado's shell calls
  # exactly (see code/original/cost_curve/cost_curve_masterfile.ado ~L277-306
  # and code/cost_curve/cost_curve_simple.R / cost_curve_masterfile.R headers).
  simple_args <- c(
    15000,        # price
    -0.4,         # eps (demand elasticity; must be negative)
    -0.25,        # theta (learning-by-doing elasticity; must be negative)
    2000000,      # X0 (cumulative production)
    0.03,         # rho (discount rate)
    200000,       # x0 (current production; must be < X0)
    60, 45, -3, -1.5, 0, 0, 0,  # enviro cons_early/late, slope_early/late, extra, end, cap
    500,          # subsidy (baseline)
    0.1,          # markup (mu)
    0.8,          # gamma (passthrough analog)
    0,            # graph (off)
    30,           # tmax
    1,            # start_year_offset
    10,           # cutoff
    "NA"          # graphfilename (unused when graph == 0)
  )
  simple_vals <- run_cc_script("cost_curve_simple.R", simple_args, "cc_simple_demo")

  master_args <- c(
    15000,        # price
    0.6,          # fcr (fixed-cost ratio; triggers the full ODE path)
    -0.4,         # eps
    -0.25,        # theta
    2000000,      # X0
    0.03,         # rho
    200000,       # x0
    30,           # tmax
    60, 45, -3, -1.5, 0, 0, 0,  # enviro cons_early/late, slope_early/late, extra, end, cap
    500,          # baseline_subsidy
    15,           # subsidy_end (non-zero; also triggers the full ODE path)
    0.1,          # mu (markup)
    0.8,          # gamma (passthrough analog)
    0,            # graph (off)
    1,            # start_year_offset
    10,           # cutoff
    "NA"          # graphfilename (unused when graph == 0)
  )
  master_vals <- run_cc_script("cost_curve_masterfile.R", master_args, "cc_masterfile_demo")

  components_simple <- c("DP", "Dpi", "DE")
  components_master <- c("DP", "Dpi", "DE", "DFE")

  result <- rbind(
    data.frame(
      scenario = "simple", script = "cost_curve_simple.R",
      component = components_simple[seq_along(simple_vals)],
      value = as.numeric(simple_vals), stringsAsFactors = FALSE
    ),
    data.frame(
      scenario = "masterfile", script = "cost_curve_masterfile.R",
      component = components_master[seq_along(master_vals)],
      value = as.numeric(master_vals), stringsAsFactors = FALSE
    )
  )

  if (any(!is.finite(result$value))) {
    stop(
      "cost_curve_data_r: non-finite value(s) in LBD cost-curve output - ",
      "R engine kernel failed:\n",
      paste(utils::capture.output(print(result)), collapse = "\n")
    )
  }

  out_path <- file.path(out_dir, "lbd_cost_curve.csv")
  utils::write.csv(result, out_path, row.names = FALSE)
  message("cost_curve_data_r: wrote ", out_path)
  invisible(result)
}
