#!/usr/bin/env Rscript
# R reimplementation of cost_curve_masterfile(_mac).wls
# Args (24): price fcr eps theta X0 rho x0 tmax enviro_* (7) subsidy subsidy_end
#            markup gamma graph start_year_offset cutoff graphfilename filename
# Writes <filename>.csv with rows DP, Dpi, DE, DFE (no header), in getwd().
#
# Numerical notes: Mathematica uses WorkingPrecision->100 / StiffnessSwitching.
# This port uses deSolve::ode in double precision. Spot-check against .wls when
# wolframscript is available; do not treat bit-identical match as guaranteed.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 24L) {
  stop("cost_curve_masterfile.R expects 24 arguments; got ", length(args))
}

file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = FALSE))
} else {
  getwd()
}
source(file.path(script_dir, "cost_curve_common.R"), local = TRUE)

if (!requireNamespace("deSolve", quietly = TRUE)) {
  stop("Package 'deSolve' is required for cost_curve_masterfile.R (install.packages('deSolve')).")
}

price <- parse_num(args[[1]])
fcr <- parse_num(args[[2]])
eps <- parse_num(args[[3]])
theta <- parse_num(args[[4]])
X0 <- parse_num(args[[5]])
rho <- parse_num(args[[6]])
x0 <- parse_num(args[[7]])
tmax <- parse_num(args[[8]])
enviro_cons_early <- parse_num(args[[9]])
enviro_cons_late <- parse_num(args[[10]])
enviro_slope_early <- parse_num(args[[11]])
enviro_slope_late <- parse_num(args[[12]])
enviro_extra <- parse_num(args[[13]])
enviro_end <- parse_num(args[[14]])
enviro_cap <- parse_num(args[[15]])
baseline_subsidy <- parse_num(args[[16]])
subsidy_end <- parse_num(args[[17]])
mu <- parse_num(args[[18]])
gamma <- parse_num(args[[19]])
graph <- parse_num(args[[20]])
start_year_offset <- parse_num(args[[21]])
cutoff <- parse_num(args[[22]])
filename <- gsub("\"", "", args[[24]], fixed = TRUE)

rdirect <- if (abs(fcr) > .Machine$double.eps) 1 / ((1 / fcr) - 1) else 0
cost <- (price - gamma * baseline_subsidy) / (mu + 1)
kappa <- cost / ((1 + rdirect) * X0^theta)
K <- (cost * rdirect) / (1 + rdirect)

# State y = c(X, Xp) with Xp = X'
ode_fun <- function(t, y, parms) {
  X <- y[[1]]
  Xp <- y[[2]]
  tau <- tau_subsidy(t, baseline_subsidy, subsidy_end)
  taup <- tau_prime_subsidy(t, baseline_subsidy, subsidy_end)
  Xpow <- max(X, .Machine$double.eps)^theta
  Xpowm1 <- max(X, .Machine$double.eps)^(theta - 1)
  numer <- (mu + 1) * theta * kappa * Xpowm1 * Xp + rho * taup
  denom <- (mu + 1) * (K + kappa * Xpow) + rho * tau
  # Avoid blow-up if denom ~ 0 (tau~0 and K~0 early); match WLS by clamping.
  if (!is.finite(denom) || abs(denom) < 1e-300) {
    ratio <- 0
  } else {
    ratio <- numer / denom
  }
  # X''/X' == eps * ratio  =>  X'' == Xp * eps * ratio
  list(c(Xp, Xp * eps * ratio))
}

times <- seq(0, tmax, length.out = max(2001L, as.integer(ceiling(tmax)) + 1L))
sol <- deSolve::ode(
  y = c(X = X0, Xp = x0),
  times = times,
  func = ode_fun,
  parms = NULL,
  method = "lsoda",
  rtol = 1e-8,
  atol = 1e-8
)

t_grid <- sol[, 1]
X_grid <- sol[, 2]
Xp_grid <- sol[, 3]

# Second derivative via finite difference of Xp (smooth enough for quadrature).
Xpp_grid <- rep(NA_real_, length(t_grid))
if (length(t_grid) >= 3L) {
  Xpp_grid[1] <- (Xp_grid[2] - Xp_grid[1]) / (t_grid[2] - t_grid[1])
  Xpp_grid[length(t_grid)] <- (Xp_grid[length(t_grid)] - Xp_grid[length(t_grid) - 1L]) /
    (t_grid[length(t_grid)] - t_grid[length(t_grid) - 1L])
  Xpp_grid[2:(length(t_grid) - 1L)] <- (Xp_grid[3:length(t_grid)] - Xp_grid[1:(length(t_grid) - 2L)]) /
    (t_grid[3:length(t_grid)] - t_grid[1:(length(t_grid) - 2L)])
}

interp <- function(grid_y, t) {
  stats::approx(t_grid, grid_y, xout = t, rule = 2)$y
}

Xnum <- function(t) interp(X_grid, t)
xnum <- function(t) interp(Xp_grid, t)
xprimenum <- function(t) interp(Xpp_grid, t)

enviro_at <- function(t) {
  enviroext(
    t,
    enviro_cons_early, enviro_cons_late,
    enviro_slope_early, enviro_slope_late,
    enviro_extra, enviro_end, enviro_cap,
    start_year_offset, cutoff
  )
}

pref <- (-gamma * eps) / (x0 * price)
pref_pos <- (gamma * eps) / (x0 * price)

integrand_dp <- function(t) {
  Xv <- pmax(Xnum(t), .Machine$double.eps)
  xv <- xnum(t)
  theta * kappa * (mu + 1) * xv^2 * Xv^(theta - 1) * exp(-rho * t)
}
DP <- pref * safe_integrate(integrand_dp, 0, tmax)

integrand_dpi <- function(t) {
  Xv <- pmax(Xnum(t), .Machine$double.eps)
  exp(-rho * t) * xprimenum(t) * (K + kappa * Xv^theta)
}
Dpi <- (-mu / (mu + 1)) * DP +
  ((-gamma * mu * eps) / (x0 * price)) * safe_integrate(integrand_dpi, 0, tmax)

integrand_de <- function(t) {
  exp(-rho * t) * xprimenum(t) * enviro_at(t)
}
DE <- pref_pos * safe_integrate(integrand_de, 0, tmax)

integrand_dfe <- function(t) {
  exp(-rho * t) * xprimenum(t) * tau_subsidy(t, baseline_subsidy, subsidy_end)
}
DFE <- pref_pos * safe_integrate(integrand_dfe, 0, tmax)

invisible(graph)

write_cost_curve_csv(c(DP, Dpi, DE, DFE), filename)
cat(
  "Wrote ", filename, ".csv DP=", DP, " Dpi=", Dpi, " DE=", DE, " DFE=", DFE, "\n",
  sep = ""
)
