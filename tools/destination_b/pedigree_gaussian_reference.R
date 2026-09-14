#!/usr/bin/env Rscript
# Exact frozen-R Gaussian animal_latent pilot. No R package source is edited.
args <- commandArgs(trailingOnly = TRUE)
if (!(length(args) %in% c(3L, 4L))) stop("usage: pedigree_gaussian_reference.R PRIVATE_LIBRARY PRECISION_JSON OUTPUT_JSON [nlminb|bfgs]")
policy <- if (length(args) == 4L) args[[4L]] else "nlminb"
if (!policy %in% c("nlminb", "bfgs")) stop("unknown sealed optimizer policy")
lib <- normalizePath(args[[1L]], mustWork = TRUE)
precision_path <- normalizePath(args[[2L]], mustWork = TRUE)
output <- args[[3L]]
attempt <- paste0(output, ".attempt.rds")
if (any(file.exists(c(output, attempt)))) stop("use a fresh output path; attempts are immutable")
expected_dll <- "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"
expected_precision <- "c428e369e6fb554cc4b9bb03f250418d0d51474ba86e01d1be9c7c7301e615ee"
sha <- function(path) unname(tools::sha256sum(path))[[1L]]
stopifnot(sha(precision_path) == expected_precision)
if ("gllvmTMB" %in% loadedNamespaces()) stop("start a fresh R process")
library("gllvmTMB", lib.loc = lib, character.only = TRUE)
package_path <- normalizePath(find.package("gllvmTMB"), mustWork = TRUE)
dll_path <- normalizePath(getLoadedDLLs()[["gllvmTMB"]][["path"]], mustWork = TRUE)
stopifnot(as.character(packageVersion("gllvmTMB")) == "0.7.0",
          startsWith(package_path, paste0(lib, "/")),
          startsWith(dll_path, paste0(lib, "/")), sha(dll_path) == expected_dll)
precision <- jsonlite::fromJSON(precision_path)
Q <- Matrix::Matrix(precision$Q_canonical, sparse = TRUE)
dimnames(Q) <- list(precision$pedigree$node_labels, precision$pedigree$node_labels)
observed <- precision$observed_node_one_based
tips <- precision$observed_labels
parent_labels <- function(index) ifelse(index == 0L, NA_character_,
    precision$pedigree$node_labels[pmax(index, 1L)])
ped <- data.frame(id = precision$pedigree$node_labels,
    sire = parent_labels(precision$pedigree$sire_one_based_zero_unknown),
    dam = parent_labels(precision$pedigree$dam_one_based_zero_unknown))
traits <- c("a", "b", "c")
seed <- 20260907L
set.seed(seed)
# This draw is a functional fixture, not independent recovery certification.
# R-only covariance solve generates data; Julia will consume canonical Q.
genetic <- as.numeric(t(chol(solve(as.matrix(Q)))) %*% rnorm(12L))
beta <- c(.4, -.2, .3)
loading <- c(.9, .5, -.6)
df <- expand.grid(replicate = 1:2, trait_id = 1:3, species_id = 1:8)
df$species <- factor(tips[df$species_id], levels = tips)
df$trait <- factor(traits[df$trait_id], levels = traits)
df$value <- beta[df$trait_id] + loading[df$trait_id] * genetic[observed[df$species_id]] +
  rnorm(nrow(df), sd = .25)
observation <- (df$species_id - 1L) * 2L + df$replicate
Y <- matrix(NA_real_, 3L, 16L)
Y[cbind(df$trait_id, observation)] <- df$value
rows <- function(x) unname(lapply(seq_len(nrow(x)), function(i) unname(as.numeric(x[i, ]))))
yhash <- function(x) digest::digest(writeBin(as.double(c(x)), raw(), size = 8L,
                                          endian = "little"), algo = "sha256", serialize = FALSE)
receipt <- list(schema_version = "destination-b-pedigree-gaussian-marginal-1",
  status = "error", source_pin = precision$source_pin,
  package_version = "0.7.0", package_path = package_path,
  dll_path = dll_path, dll_sha256 = expected_dll,
  precision_reference_sha256 = expected_precision, precision = precision,
  seed = seed, trait_names = traits, reps = 2L,
  Y_traits_by_observations = rows(Y), data_sha256 = yhash(Y),
  data_hash_encoding = "Float64 little-endian column-major",
  original_long = df[c("species_id", "trait_id", "replicate", "value")],
  formula = "value ~ 0 + trait + animal_latent(species, d=1, pedigree=ped, unique=FALSE)",
  input_route = "pedigree",
  residual_mode = "shared", rank = 1L, unique = FALSE,
  optimizer_policy = policy,
  warnings = list(), session_info = paste(capture.output(sessionInfo()), collapse = "\n"),
  claim = "R-only functional pilot; no Julia fit, intervals, recovery or admission")
warnings <- list()
tryCatch({
  optimizer_control <- if (policy == "nlminb") {
    gllvmTMBcontrol(n_init = 1L, optimizer = "nlminb",
      optArgs = list(control = list(iter.max = 100L, eval.max = 150L, rel.tol = 1e-12)))
  } else {
    gllvmTMBcontrol(n_init = 1L, optimizer = "optim",
      optArgs = list(method = "BFGS", control = list(maxit = 400L, reltol = 1e-12)))
  }
  started <- proc.time()[["elapsed"]]
  fit <- withCallingHandlers(gllvmTMB(
    value ~ 0 + trait + animal_latent(species, d = 1, pedigree = ped, unique = FALSE),
    data = df, trait = "trait", unit = "species", cluster = "species",
    family = gaussian(), REML = FALSE, engine = "tmb",
    control = optimizer_control),
    warning = function(w) warnings[[length(warnings) + 1L]] <<-
      list(message = conditionMessage(w), class = class(w)))
  receipt$elapsed_seconds <- proc.time()[["elapsed"]] - started
  receipt$warnings <- warnings
  saveRDS(list(status = "fit_returned_before_assertions", receipt = receipt,
              optimizer = fit$opt, tmb_data = fit$tmb_data, tmb_map = fit$tmb_map), attempt)
  obj <- fit$tmb_obj
  # Production marginal covariance, not the conditional random-mode Hessian.
  # Obtain it before later objective cross-evaluations mutate the TMB cache.
  fit <- gllvmTMB::standard_errors(fit)
  sd <- fit$sd_report
  stopifnot(isTRUE(sd$pdHess), all(is.finite(sd$cov.fixed)),
            identical(names(sd$par.fixed), names(fit$opt$par)),
            identical(unname(sd$par.fixed), unname(fit$opt$par)))
  public_vcov <- stats::vcov(fit)
  stopifnot(all(public_vcov == sd$cov.fixed[1:3, 1:3]))
  receipt$uncertainty <- list(method = "frozen production sdreport cov.fixed",
    parameter_names = names(sd$par.fixed), parameter_values = unname(sd$par.fixed),
    covariance = rows(sd$cov.fixed), public_beta_vcov = rows(public_vcov),
    pd_hessian = sd$pdHess, condition_number = kappa(sd$cov.fixed, exact = TRUE))
  expected_names <- c(rep("b_fix", 3L), "log_sigma_eps", rep("theta_rr_phy", 3L))
  stopifnot(identical(names(obj$par), expected_names),
            identical(names(fit$opt$par), expected_names))
  engineQ <- as.matrix(fit$tmb_data$Ainv_phy_rr)
  stopifnot(identical(engineQ, as.matrix(Q)), fit$tmb_data$n_aug_phy == 12L,
            abs(-fit$tmb_data$log_det_A_phy_rr - precision$log_det_Q) <= 1e-12)
  sid <- as.integer(fit$tmb_data$species_id)
  tid <- as.integer(fit$tmb_data$trait_id)
  aug <- as.integer(fit$tmb_data$species_aug_id)
  ey <- as.numeric(fit$tmb_data$y)
  stopifnot(length(sid) == nrow(df), length(tid) == nrow(df), length(aug) == nrow(df))
  permutation <- vapply(seq_len(nrow(df)), function(i) {
    candidate <- which(df$species_id - 1L == sid[i] & df$trait_id - 1L == tid[i] &
                         df$value == ey[i])
    stopifnot(length(candidate) == 1L)
    as.integer(candidate)
  }, integer(1L))
  stopifnot(identical(sort(permutation), seq_len(nrow(df))),
            identical(aug, as.integer(observed[sid + 1L] - 1L)))
  X <- as.matrix(fit$tmb_data$X_fix)
  expected_X <- model.matrix(~ 0 + trait, df)[permutation, , drop = FALSE]
  stopifnot(identical(dim(X), dim(expected_X)), all(X == expected_X))
  receipt$engine_to_original_long_row_one_based <- permutation
  receipt$engine_species_id_zero_based <- sid
  receipt$engine_trait_id_zero_based <- tid
  receipt$engine_augmented_id_zero_based <- aug
  receipt$engine_fixed_design <- rows(X)
  receipt$engine_Q_matches_reference <- TRUE
  receipt$active_parameter_names <- expected_names
  evaluate <- function(theta) {
    nll <- obj$fn(theta)
    gradient <- as.numeric(obj$gr(theta))
    stopifnot(is.finite(nll), all(is.finite(theta)), all(is.finite(gradient)))
    list(values = unname(theta), marginal_nll = nll, gradient = gradient,
         gradient_norm = max(abs(gradient)))
  }
  receipt$matched <- evaluate(c(beta, log(.3), loading))
  stopifnot(identical(receipt$matched$marginal_nll, obj$fn(c(beta, log(.3), loading))))
  receipt$fitted <- evaluate(fit$opt$par)
  receipt$fitted$convergence <- fit$opt$convergence
  receipt$fitted$message <- fit$opt$message
  receipt$fitted$evaluations <- fit$opt$evaluations
  # Diagnostic curvature of the same marginal objective at the returned
  # point. This is not an interval or a replacement convergence flag.
  H <- stats::optimHess(fit$opt$par, fn = obj$fn, gr = obj$gr)
  stopifnot(all(is.finite(H)))
  eig <- eigen((H + t(H)) / 2, symmetric = TRUE, only.values = TRUE)$values
  receipt$fitted$marginal_hessian_diagnostic <- list(
    method = "optimHess on full marginal objective/gradient; default ndeps",
    matrix = rows(H), eigenvalues = unname(eig),
    positive_definite = all(eig > 0),
    condition_number = if (all(eig > 0)) max(eig) / min(eig) else NULL)
  receipt$status <- "recorded"
  jsonlite::write_json(receipt, output, auto_unbox = TRUE, pretty = TRUE,
                       digits = 17L, null = "null", na = "null")
  roundtrip <- jsonlite::fromJSON(output)
  stopifnot(identical(roundtrip$Y_traits_by_observations, Y),
            identical(yhash(roundtrip$Y_traits_by_observations), receipt$data_sha256))
  cat("FROZEN_PEDIGREE_GAUSSIAN_REFERENCE_RECORDED\n")
  cat(sha(output), "\n")
}, error = function(e) {
  receipt$status <- "error"
  receipt$error <- conditionMessage(e)
  receipt$warnings <- warnings
  # Preserve a returned-fit RDS when later assertions fail; otherwise retain
  # the pre-fit data and error. An error JSON cannot be mistaken for success.
  if (!file.exists(attempt)) saveRDS(receipt, attempt)
  jsonlite::write_json(receipt, output, auto_unbox = TRUE, pretty = TRUE,
                       digits = 17L, null = "null", na = "null")
  stop(e)
})
