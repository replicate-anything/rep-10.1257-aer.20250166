#!/usr/bin/env Rscript
# replicateEverything provenance: translation (Mathematica -> R)
# R reimplementation of cost_curve_simple(_mac).wls
# Args (22): price eps theta X0 rho x0 enviro_* (7) subsidy markup gamma
#            graph tmax start_year_offset cutoff graphfilename filename
# Writes <filename>.csv with rows DP, Dpi, DE (no header), in getwd().

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 22L) {
  stop("cost_curve_simple.R expects 22 arguments; got ", length(args))
}

file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = FALSE))
} else {
  getwd()
}
source(file.path(script_dir, "cost_curve_common.R"), local = TRUE)

price <- parse_num(args[[1]])
eps <- parse_num(args[[2]])
theta <- parse_num(args[[3]])
X0 <- parse_num(args[[4]])
rho <- parse_num(args[[5]])
x0 <- parse_num(args[[6]])
enviro_cons_early <- parse_num(args[[7]])
enviro_cons_late <- parse_num(args[[8]])
enviro_slope_early <- parse_num(args[[9]])
enviro_slope_late <- parse_num(args[[10]])
enviro_extra <- parse_num(args[[11]])
enviro_end <- parse_num(args[[12]])
enviro_cap <- parse_num(args[[13]])
baseline_subsidy <- parse_num(args[[14]])
mu <- parse_num(args[[15]])
gamma <- parse_num(args[[16]])
graph <- parse_num(args[[17]])
tmax <- parse_num(args[[18]])
start_year_offset <- parse_num(args[[19]])
cutoff <- parse_num(args[[20]])
filename <- gsub("\"", "", args[[22]], fixed = TRUE)

den <- 1 - eps * theta
C2 <- X0 / (x0 * den)
C1 <- X0 / (C2^(1 / den))

X_t <- function(t) C1 * (t + C2)^(1 / den)
x_t <- function(t) C1 / den * (t + C2)^(eps * theta / den)
xprime_t <- function(t) {
  C1 * (eps * theta) / (den^2) * (t + C2)^((2 * eps * theta - 1) / den)
}

enviro_at <- function(t) {
  enviroext(
    t,
    enviro_cons_early, enviro_cons_late,
    enviro_slope_early, enviro_slope_late,
    enviro_extra, enviro_end, enviro_cap,
    start_year_offset, cutoff
  )
}

pref_dp <- (-gamma * eps) / (x0 * X0^theta)
integrand_dp <- function(t) {
  theta * (mu + 1) * x_t(t)^2 * X_t(t)^(theta - 1) * exp(-rho * t)
}
DP <- pref_dp * safe_integrate(integrand_dp, 0, Inf)

integrand_dpi <- function(t) {
  exp(-rho * t) * xprime_t(t) * (X_t(t)^theta)
}
Dpi <- (-mu / (mu + 1)) * DP +
  ((-gamma * mu * eps) / (x0 * X0^theta)) * safe_integrate(integrand_dpi, 0, Inf)

pref_de <- (gamma * eps) / (x0 * price)
integrand_de <- function(t) {
  exp(-rho * t) * xprime_t(t) * enviro_at(t)
}
DE <- pref_de * safe_integrate(integrand_de, 0, tmax)

invisible(list(baseline_subsidy = baseline_subsidy, graph = graph))

write_cost_curve_csv(c(DP, Dpi, DE), filename)
cat("Wrote ", filename, ".csv DP=", DP, " Dpi=", Dpi, " DE=", DE, "\n", sep = "")
