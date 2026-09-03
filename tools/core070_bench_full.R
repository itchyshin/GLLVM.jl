# M3 full benchmark campaign, R side (maintainer-approved 2026-09-01).
# Families: gaussian, poisson, nbinom2, binomial(logit; Bernoulli cells).
# Grid: p in {5,10,20,50} x n in {200,500,1000} plus (100,200) and (100,500);
# 5 reps, median wall time, single thread. Paired canonical model
# (0 + trait means, d=2 latent, unique=FALSE; n_init=1, se off).
# argv: <frozen-library> <output-dir>
args <- commandArgs(TRUE)
stopifnot(length(args) == 2L)
frozen_library <- normalizePath(args[[1]], mustWork = TRUE)
out_dir <- args[[2]]
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(frozen_library, .libPaths()))
suppressMessages(library(gllvmTMB))

cells <- rbind(expand.grid(p = c(5L, 10L, 20L, 50L), n = c(200L, 500L, 1000L)),
               data.frame(p = 100L, n = c(200L, 500L)))
fams <- c("gaussian", "poisson", "nbinom2", "binomial")
grid <- merge(cells, data.frame(family = fams))
reps <- 5L
rows <- list()
for (g in seq_len(nrow(grid))) {
  p <- grid$p[g]; n <- grid$n[g]; fam <- grid$family[g]
  set.seed(91000 + g)
  K <- 2L
  Lambda <- matrix(rnorm(p * K, 0, 0.5), p, K)
  eta <- Lambda %*% matrix(rnorm(K * n), K, n)
  Y <- switch(fam,
    gaussian = eta + 0.7 * matrix(rnorm(p * n), p, n),
    poisson  = matrix(rpois(p * n, exp(pmin(eta, 4))), p, n),
    nbinom2  = matrix(rnbinom(p * n, mu = exp(pmin(eta, 4)), size = 2), p, n),
    binomial = matrix(rbinom(p * n, 1L, plogis(eta)), p, n))
  tn <- paste0("t", seq_len(p))
  df <- data.frame(site = factor(rep(seq_len(n), each = p)),
                   trait = factor(rep(tn, n), levels = tn),
                   value = as.vector(Y))
  fam_obj <- switch(fam, gaussian = gaussian(), poisson = poisson(),
                    nbinom2 = nbinom2(), binomial = binomial())
  times <- rep(NA_real_, reps); ll <- NA_real_; ok <- TRUE
  for (r in seq_len(reps)) {
    t0 <- proc.time()[["elapsed"]]
    fit <- try(gllvmTMB(value ~ 0 + trait + latent(0 + trait | site, d = 2, unique = FALSE),
                        data = df, unit = "site", trait = "trait", family = fam_obj,
                        control = gllvmTMBcontrol(n_init = 1L, se = FALSE)), silent = TRUE)
    times[r] <- proc.time()[["elapsed"]] - t0
    if (inherits(fit, "try-error")) { ok <- FALSE; break }
    ll <- as.numeric(logLik(fit))
  }
  rows[[length(rows) + 1L]] <- data.frame(case = g, p = p, n = n, family = fam,
    median_s = median(times, na.rm = TRUE), min_s = min(times, na.rm = TRUE),
    loglik = ll, ok = ok)
  write.csv(Y, file.path(out_dir, sprintf("bench-Y-%03d.csv", g)), row.names = FALSE)
  cat(sprintf("R done %d/%d %s p=%d n=%d median=%.2fs ok=%s\n",
              g, nrow(grid), fam, p, n, median(times, na.rm = TRUE), ok))
}
res <- do.call(rbind, rows)
res$engine <- "gllvmTMB-frozen"
write.csv(res, file.path(out_dir, "r-timings.csv"), row.names = FALSE)
write.csv(data.frame(case = seq_len(nrow(grid)), p = grid$p, n = grid$n,
                     family = grid$family),
          file.path(out_dir, "bench-manifest.csv"), row.names = FALSE)
