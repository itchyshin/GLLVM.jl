# M3 performance pre-run (D-139): small paired timing probe, frozen R side.
# NOT a campaign — 3 sizes x 2 families x 3 reps, single thread, to ground the
# full benchmark estimate. Comparison harness lives in tools/, outside tests.
#
# argv: <frozen-library> <output-dir>
args <- commandArgs(TRUE)
stopifnot(length(args) == 2L)
frozen_library <- normalizePath(args[[1]], mustWork = TRUE)
out_dir <- args[[2]]
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(frozen_library, .libPaths()))
suppressMessages(library(gllvmTMB))

grid <- expand.grid(p = c(5L, 20L, 50L), n = c(200L, 500L), family = c("gaussian", "poisson"),
                    stringsAsFactors = FALSE)
grid <- grid[!(grid$p == 50L & grid$n == 200L), ]  # keep the probe small
reps <- 3L
rows <- list()
for (g in seq_len(nrow(grid))) {
  p <- grid$p[g]; n <- grid$n[g]; fam <- grid$family[g]
  set.seed(90000 + g)
  K <- 2L
  Lambda <- matrix(rnorm(p * K, 0, 0.5), p, K)
  eta <- Lambda %*% matrix(rnorm(K * n), K, n)
  Y <- if (fam == "gaussian") eta + 0.7 * matrix(rnorm(p * n), p, n) else
       matrix(rpois(p * n, exp(pmin(eta, 4))), p, n)
  tn <- paste0("t", seq_len(p))
  df <- data.frame(site = factor(rep(seq_len(n), each = p)),
                   trait = factor(rep(tn, n), levels = tn),
                   value = as.vector(Y))
  fam_obj <- if (fam == "gaussian") gaussian() else poisson()
  times <- numeric(reps); ll <- NA_real_
  for (r in seq_len(reps)) {
    t0 <- proc.time()[["elapsed"]]
    fit <- gllvmTMB(value ~ 0 + trait + latent(0 + trait | site, d = 2, unique = FALSE),
                    data = df, unit = "site", trait = "trait", family = fam_obj,
                    control = gllvmTMBcontrol(n_init = 1L, se = FALSE))
    times[r] <- proc.time()[["elapsed"]] - t0
    ll <- as.numeric(logLik(fit))
  }
  rows[[length(rows) + 1L]] <- data.frame(p = p, n = n, family = fam,
    median_s = median(times), min_s = min(times), loglik = ll)
  # persist the data for the Julia side to fit the identical matrix
  saveRDS(list(Y = Y, p = p, n = n, family = fam),
          file.path(out_dir, sprintf("bench-data-%02d.rds", g)))
  write.csv(Y, file.path(out_dir, sprintf("bench-Y-%02d.csv", g)), row.names = FALSE)
}
res <- do.call(rbind, rows)
res$engine <- "gllvmTMB-frozen"
write.csv(res, file.path(out_dir, "r-timings.csv"), row.names = FALSE)
manifest <- data.frame(case = seq_len(nrow(grid)), p = grid$p, n = grid$n,
                       family = grid$family)
write.csv(manifest, file.path(out_dir, "bench-manifest.csv"), row.names = FALSE)
print(res)
