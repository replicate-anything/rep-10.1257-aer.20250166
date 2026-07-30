library(haven)
path <- "c:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/rep-10.1257-aer.20250166/data/1_assumptions/user_specific_assumptions/files_vreplicateEverything/Gasoline Externalities/gasoline_vehicle_externalities_scc193_dr2.dta"
d <- read_dta(path)
cat("nrow:", nrow(d), " ncols:", ncol(d), "\n")
cat("years:", paste(sort(unique(d$year)), collapse = " "), "\n")
print(table(d$year))

agg <- aggregate(cbind(wtp_total, wtp_local, wtp_global) ~ year, data = d, FUN = mean)
agg$sum_lg <- agg$wtp_local + agg$wtp_global
agg$diff <- agg$wtp_total - agg$sum_lg
agg$round_total <- round(agg$wtp_total, 3)
agg$round_sum <- round(agg$sum_lg, 3)
agg$assert_fail <- agg$round_total != agg$round_sum

# Stata float globals: store as float then round
stata_float <- function(x) {
  # approximate Stata float (IEEE single) then use as double
  as.numeric(as.single(x))
}
agg$g_total <- stata_float(agg$wtp_total)
agg$g_local <- stata_float(agg$wtp_local)
agg$g_global <- stata_float(agg$wtp_global)
agg$sum_float <- agg$g_local + agg$g_global
agg$stata_round_total <- round(agg$g_total, 3)
agg$stata_round_sum <- round(agg$sum_float, 3)
agg$stata_assert_fail <- agg$stata_round_total != agg$stata_round_sum

cat("\nMax abs mean-diff:", max(abs(agg$diff)), "\n")
cat("Years failing R round(0.001):", sum(agg$assert_fail), "\n")
cat("Years failing float-approx assert:", sum(agg$stata_assert_fail), "\n")

fail <- agg[agg$assert_fail | agg$stata_assert_fail | abs(agg$diff) > 5e-4, ]
print(fail[, c("year", "wtp_total", "wtp_local", "wtp_global", "sum_lg", "diff",
               "round_total", "round_sum", "assert_fail",
               "stata_round_total", "stata_round_sum", "stata_assert_fail")])

ord <- order(-abs(agg$diff))
cat("\nTop |diff| years:\n")
print(agg[ord[1:15], c("year", "wtp_total", "sum_lg", "diff",
                       "round_total", "round_sum", "assert_fail",
                       "stata_round_total", "stata_round_sum", "stata_assert_fail")])

d$row_diff <- d$wtp_total - (d$wtp_local + d$wtp_global)
cat("\nRow-level max|diff|:", max(abs(d$row_diff), na.rm = TRUE), "\n")
cat("Years with >1 row:", sum(table(d$year) > 1), "\n")

# near-boundary cases: fractional part near *.xxx5 relative to 0.001
agg$frac_total <- abs(agg$wtp_total * 1000 - round(agg$wtp_total * 1000))
agg$frac_sum <- abs(agg$sum_lg * 1000 - round(agg$sum_lg * 1000))
# distance to rounding boundary for each side
boundary_dist <- function(x) {
  r <- x * 1000
  abs(r - round(r))
}
agg$bd_t <- boundary_dist(agg$wtp_total)
agg$bd_s <- boundary_dist(agg$sum_lg)
# cases where round sides differ after float store
cat("\nNear half-ulp / boundary (bd < 1e-6 or float fail):\n")
print(agg[agg$stata_assert_fail | agg$bd_t < 1e-4 | agg$bd_s < 1e-4,
          c("year", "diff", "bd_t", "bd_s", "round_total", "round_sum",
            "stata_round_total", "stata_round_sum", "stata_assert_fail")])
