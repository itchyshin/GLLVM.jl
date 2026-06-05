# Cross-language benchmark harness: GLLVM.jl vs R gllvmTMB (issue #65, item 2).
#
# RUNTIME-SESSION SCRIPT — needs R with {gllvm} (gllvmTMB) installed and a Julia
# with GLLVM.jl available. NOT run/verified in the authoring environment (no R).
# It is a starting point: simulate per family, fit gllvmTMB (timed), export the
# data, fit the same in Julia (gradient=:finite and :analytic), and compare
# per-fit median time and maximised log-likelihood.
#
# Usage:
#   Rscript bench/gllvmTMB_compare.R            # writes data + gllvmTMB timings
#   julia --project=. bench/gllvmTMB_compare.jl # fits in GLLVM.jl, prints comparison
#
# Keep the reporting rule from the phylo handoff note: never mix fixed-dispersion
# "speed isolation" rows with estimated-dispersion "likelihood parity" rows in a
# single "X× faster" claim.

suppressMessages(library(gllvm))
set.seed(20260605)

p <- 12L; n <- 200L; K <- 2L; reps <- 5L
outdir <- "bench/_cmp"; dir.create(outdir, showWarnings = FALSE)

sim_poisson <- function() {
  beta <- rnorm(p, 0, 0.3)
  Lambda <- matrix(rnorm(p * K, 0, 0.4), p, K)
  Z <- matrix(rnorm(n * K), n, K)
  eta <- matrix(beta, p, n) + Lambda %*% t(Z)
  matrix(rpois(p * n, exp(eta)), p, n)
}

bench_gllvmTMB <- function(Y, family) {
  # gllvm expects sites in rows (n x p); we store species x sites, so transpose.
  Yt <- t(Y)
  fit_once <- function() gllvm(Yt, num.lv = K, family = family, seed = 1)
  fit_once()                                  # warm-up / compile TMB
  times <- replicate(reps, system.time(fit_once())[["elapsed"]])
  fit <- fit_once()
  list(time = median(times), loglik = logLik(fit))
}

Y <- sim_poisson()
write.csv(Y, file.path(outdir, "poisson_Y.csv"), row.names = FALSE)
res <- bench_gllvmTMB(Y, "poisson")
cat(sprintf("gllvmTMB Poisson: median %.4fs, logLik %.4f\n", res$time, as.numeric(res$loglik)))
saveRDS(res, file.path(outdir, "poisson_gllvmTMB.rds"))

# Repeat for negative.binomial / binomial / Gamma / beta as needed (gllvm family
# strings: "poisson", "negative.binomial", "binomial", "Gamma", "beta"), exporting
# each Y so the Julia side fits the identical data. The Julia companion reads the
# CSVs, fits with gradient=:finite and :analytic, and tabulates time + |Δloglik|
# against the gllvmTMB rows above.
cat("Data + gllvmTMB timings written to", outdir, "\n")
