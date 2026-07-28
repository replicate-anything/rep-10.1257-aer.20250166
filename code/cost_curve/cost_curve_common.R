# replicateEverything provenance: translation (Mathematica -> R)
# Shared LBD cost-curve helpers (R port of code/original/cost_curve/*.wls).
# CLI args match the Mac wolframscript Part[args, i] contract used by
# cost_curve_masterfile.ado after the enviro-fit locals are computed in Stata.

parse_num <- function(x) {
  as.numeric(as.character(x))
}

enviroext <- function(
    t,
    enviro_cons_early,
    enviro_cons_late,
    enviro_slope_early,
    enviro_slope_late,
    enviro_extra,
    enviro_end,
    enviro_cap,
    start_year_offset,
    cutoff
) {
  y <- t + start_year_offset
  if (abs(enviro_extra) < .Machine$double.eps) {
    early <- y < cutoff
    ifelse(
      early,
      enviro_cons_early + enviro_slope_early * log(pmax(y, .Machine$double.eps)),
      enviro_cons_late + enviro_slope_late * log(pmax(y, .Machine$double.eps))
    )
  } else {
    early <- y < cutoff
    mid <- (y >= cutoff) & (y < enviro_end)
    late <- y >= enviro_end
    out <- numeric(length(t))
    out[early] <- enviro_cons_early +
      enviro_slope_early * y[early] +
      enviro_extra * y[early]^2
    out[mid] <- enviro_cons_late + enviro_slope_late * y[mid]
    out[late] <- enviro_cap
    out
  }
}

tau_subsidy <- function(t, baseline_subsidy, subsidy_end) {
  baseline_subsidy * (0.5 + atan(1e6 * (t - subsidy_end)) / (-pi))
}

tau_prime_subsidy <- function(t, baseline_subsidy, subsidy_end) {
  # d/dt arctan(a*(t-s)) = a / (1 + (a*(t-s))^2)
  a <- 1e6
  u <- a * (t - subsidy_end)
  baseline_subsidy * (a / (1 + u^2)) / (-pi)
}

write_cost_curve_csv <- function(values, filename) {
  # Match Mathematica Export of a column vector: one value per row, no header.
  out <- file.path(getwd(), paste0(filename, ".csv"))
  write.table(
    matrix(as.numeric(values), ncol = 1L),
    file = out,
    sep = ",",
    row.names = FALSE,
    col.names = FALSE
  )
  invisible(out)
}

safe_integrate <- function(f, lower, upper, rel.tol = 1e-8, subdivisions = 2000L) {
  res <- tryCatch(
    stats::integrate(
      f,
      lower = lower,
      upper = upper,
      rel.tol = rel.tol,
      subdivisions = subdivisions,
      stop.on.error = FALSE
    ),
    error = function(e) NULL
  )
  if (is.null(res) || !is.finite(res$value)) {
    # Fallback: trapezoid on a dense grid (handles Inf upper via large cutoff).
    if (!is.finite(upper)) upper <- 1e4
    grid <- seq(lower, upper, length.out = max(2001L, subdivisions))
    vals <- f(grid)
    vals[!is.finite(vals)] <- 0
    return(sum(diff(grid) * (vals[-length(vals)] + vals[-1L]) / 2))
  }
  res$value
}
