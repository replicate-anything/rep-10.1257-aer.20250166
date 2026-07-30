library(haven)
path <- "c:/WZB Dropbox/Macartan Humphreys/5_github/replicate_everything/rep-10.1257-aer.20250166/data/1_assumptions/user_specific_assumptions/files_vreplicateEverything/Gasoline Externalities/gasoline_vehicle_externalities_scc193_dr2.dta"
d <- read_dta(path)
wtp <- grep("^wtp_", names(d), value = TRUE)
cat("wtp cols:\n"); print(wtp)

# residual vs local+global
d$resid <- d$wtp_total - d$wtp_local - d$wtp_global
cat("\nresid summary:\n"); print(summary(d$resid))
cat("max|resid|:", max(abs(d$resid)), " year(s):", paste(d$year[which.max(abs(d$resid))], collapse=","), "\n")

# Stata %9.0g simulation (digits 6 width 9)
store9g <- function(x, digits = 6) {
  as.numeric(trimws(formatC(x, format = "g", digits = digits, width = 9)))
}

check <- function(digits) {
  gt <- vapply(d$wtp_total, store9g, numeric(1), digits = digits)
  gl <- vapply(d$wtp_local, store9g, numeric(1), digits = digits)
  gg <- vapply(d$wtp_global, store9g, numeric(1), digits = digits)
  fail <- round(gt, 3) != round(gl + gg, 3)
  data.frame(digits = digits, nfail = sum(fail), years = paste(d$year[fail], collapse = ","))
}
print(do.call(rbind, lapply(5:9, check)))

# For each year print exact values and distance to milli boundary
bd <- function(x) {
  # distance of x to nearest (k+0.5)/1000 midpoint
  r <- x * 1000
  abs(r - (floor(r) + 0.5))
}
out <- data.frame(
  year = d$year,
  total = d$wtp_total,
  local = d$wtp_local,
  global = d$wtp_global,
  sumlg = d$wtp_local + d$wtp_global,
  resid = d$resid,
  bd_t = bd(d$wtp_total),
  bd_s = bd(d$wtp_local + d$wtp_global)
)
# after %9.0g digits=6
out$gt <- vapply(d$wtp_total, store9g, numeric(1), digits = 6)
out$gs <- vapply(d$wtp_local, store9g, numeric(1), digits = 6) +
  vapply(d$wtp_global, store9g, numeric(1), digits = 6)
out$fail6 <- round(out$gt, 3) != round(out$gs, 3)
out$bd_gt <- bd(out$gt)
out$bd_gs <- bd(out$gs)

cat("\nClosest to milli half-boundaries (raw):\n")
print(out[order(pmin(out$bd_t, out$bd_s))[1:10],
          c("year", "total", "sumlg", "resid", "bd_t", "bd_s")])

cat("\nAny fail digits=6:\n")
print(out[out$fail6, c("year", "total", "sumlg", "gt", "gs", "fail6")])

# Also: Stata round(x,0.001) is round(x/0.001)*0.001
# Check if comparing with absolute abs(total-sum)>0.0005 would fail
out$absdiff <- abs(out$total - out$sumlg)
cat("\nmax absdiff:", max(out$absdiff), "\n")
cat("any absdiff > 0.0005:", any(out$absdiff > 0.0005), "\n")

# print full table of year, total, sum, resid, round sides
out$rt <- round(out$total, 3)
out$rs <- round(out$sumlg, 3)
out$fail_raw <- out$rt != out$rs
cat("raw round fail years:", paste(out$year[out$fail_raw], collapse=","), "\n")
