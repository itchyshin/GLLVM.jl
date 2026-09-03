# Retained-evidence batch for the fit-input manifest area's EXECUTABLE_NOW
# case_ids (docs/dev-log/core070/fit-input-batch-contract.json). Consolidates,
# without changing the numerics, the already-verified fixed-point mappings
# from tools/core070_gaussian_fixed_point.R (GAUSS-DEFAULT/COMMON/LOADINGS)
# and tools/core070_source_fixed_point.R (ANIMAL-LATENT, KERNEL-ONE,
# KERNEL-TWO) into one script producing one JSON receipt that also names the
# PLANNED_UNPAID and SPEC_DEFECT status of every other case in the area, so
# nothing in the manifest draft is silently skipped.
#
# This is a fixed-outer-parameter density check, not an outer optimizer run
# and not the R-MLE-vs-Julia-optimized-fit comparison (that stays owned by B1
# per fit-input-subset.json). See the contract's scope_note.
#
# Usage:
# Rscript --vanilla tools/core070_fit_input_batch.R <frozen-library> <inputs-dir> <fresh-outdir>

main <- function() {
  args <- commandArgs(TRUE)
  stopifnot(length(args) == 3L)
  lib <- normalizePath(args[[1]], mustWork = TRUE)
  inputs <- normalizePath(args[[2]], mustWork = TRUE)
  out <- args[[3]]
  stopifnot(!dir.exists(out))
  dir.create(out, recursive = TRUE)

  root <- normalizePath(".")
  sha256_file <- function(path) {
    command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
    argv <- if (identical(command, "sha256sum")) path else c("-a", "256", path)
    line <- system2(command, argv, stdout = TRUE, stderr = TRUE)
    stopifnot(is.null(attr(line, "status")), length(line) >= 1L)
    sub("[[:space:]].*$", "", line[[1L]])
  }

  .libPaths(c(lib, .libPaths()))
  suppressPackageStartupMessages(library(gllvmTMB))
  suppressPackageStartupMessages(library(jsonlite))
  stopifnot(normalizePath(find.package("gllvmTMB")) == normalizePath(file.path(lib, "gllvmTMB")))

  contract <- jsonlite::read_json(
    file.path(root, "docs/dev-log/core070/fit-input-batch-contract.json"),
    simplifyVector = FALSE
  )
  stopifnot(identical(contract$reference_commit, "b4d5fee64def88bc768dda1f1f77c29b295edd86"))

  write_tsv <- function(x, path) write.table(x, path, sep = "\t", row.names = FALSE, quote = FALSE)

  gauss_points <- list(
    list(beta = c(.2, -.1, .3), lambda = c(.4, -.2, .3), sd = c(.5, .6, .7), common = .45, sigma = .8),
    list(beta = c(-.1, .25, .05), lambda = c(.7, .1, -.4), sd = c(.4, .8, .6), common = .65, sigma = .55)
  )
  source_points <- list(
    list(beta = c(.2, -.1, .3), lambda = c(.4, -.2, .3, -.15, .5, .25), sigma = .8),
    list(beta = c(-.1, .25, .05), lambda = c(.7, .1, -.4, .2, -.3, .5), sigma = .55)
  )

  rows <- list()
  input_sha <- list()

  ## --- Gaussian family (GAUSS-DEFAULT / GAUSS-COMMON / GAUSS-LOADINGS) -----
  for (model in c("DEFAULT", "COMMON", "LOADINGS")) for (i in seq_along(gauss_points)) {
    id <- paste0("GAUSS-", model, "-P", i)
    dir <- file.path(out, id)
    dir.create(dir)
    input_path <- file.path(inputs, paste0("INPUT-GAUSS-", model, "-input.rds"))
    input_sha[[paste0("INPUT-GAUSS-", model)]] <- sha256_file(input_path)
    x <- readRDS(input_path)
    pt <- gauss_points[[i]]
    stopifnot(
      x$DLL == "gllvmTMB", x$data$n_traits == 3L, x$data$n_sites == 18L,
      x$data$d_B == 1L, all(x$data$family_id_vec == 0L), x$data$use_aghq == 0L
    )
    x$parameters$b_fix <- pt$beta
    x$parameters$theta_rr_B <- pt$lambda
    psi <- model != "LOADINGS"
    common <- model == "COMMON"
    if (psi) x$parameters$theta_diag_B <- log(if (common) rep(pt$common, 3) else pt$sd)
    if (!psi) x$parameters$log_sigma_eps <- log(pt$sigma)
    sigma <- exp(x$parameters$log_sigma_eps)
    obj <- TMB::MakeADFun(data = x$data, parameters = x$parameters, map = x$map, random = x$random, DLL = x$DLL, silent = TRUE)
    par <- obj$par
    value <- obj$fn(par)
    gradient <- obj$gr(par)
    stopifnot(is.finite(value), all(is.finite(gradient)))
    X <- as.matrix(x$data$X_fix)
    expected <- diag(3)[x$data$trait_id + 1L, , drop = FALSE]
    stopifnot(identical(dim(X), dim(expected)), identical(colnames(X), paste0("traitt", 1:3)), identical(as.vector(X), as.vector(expected)))
    Y <- matrix(NA_real_, 3, 18)
    Y[cbind(x$data$trait_id + 1L, x$data$site_id + 1L)] <- x$data$y
    stopifnot(!anyNA(Y))
    variance <- rep(sigma^2, 3) + if (psi) exp(2 * x$parameters$theta_diag_B) else 0
    V <- tcrossprod(pt$lambda) + diag(variance, 3)
    resid <- Y - pt$beta
    dense <- (54 * log(2 * pi) + 18 * as.numeric(determinant(V, logarithm = TRUE)$modulus) + sum(resid * solve(V, resid))) / 2
    write_tsv(data.frame(trait = x$data$trait_id + 1L, site = x$data$site_id + 1L, y = x$data$y), file.path(dir, "data.tsv"))
    write_tsv(data.frame(name = names(par), value = unname(par), gradient = as.numeric(gradient)), file.path(dir, "parameters.tsv"))
    write_tsv(data.frame(
      family = "gaussian", model = model, point = i, sigma = sigma, has_psi = as.integer(psi),
      common = as.integer(common), r_nll = value, dense_nll = dense
    ), file.path(dir, "contract.tsv"))
    saveRDS(list(input = x, par = par, nll = value, gradient = gradient), file.path(dir, "reference.rds"))
    rows[[length(rows) + 1L]] <- data.frame(id = id, family = "gaussian", model = model, point = i, r_nll = value, dense_nll = dense, absolute_delta = abs(value - dense))
    cat(id, "R_DENSE_DELTA", format(abs(value - dense), digits = 17), "\n")
  }

  ## --- Source family (ANIMAL-LATENT / KERNEL-ONE / KERNEL-TWO) -------------
  for (model in c("ANIMAL-LATENT", "KERNEL-ONE", "KERNEL-TWO")) for (i in seq_along(source_points)) {
    id <- paste0(model, "-P", i)
    dir <- file.path(out, id)
    dir.create(dir)
    input_path <- file.path(inputs, paste0("INPUT-", model, "-input.rds"))
    input_sha[[paste0("INPUT-", model)]] <- sha256_file(input_path)
    x <- readRDS(input_path)
    pt <- source_points[[i]]
    stopifnot(x$DLL == "gllvmTMB", x$data$n_traits == 3L, x$data$n_sites == 18L, all(x$data$family_id_vec == 0L), x$data$use_aghq == 0L)
    multi <- x$data$n_kernel_tiers == 2L
    nr <- if (multi) 2L else 1L
    if (multi) stopifnot(identical(dim(x$data$Ainv_kernel), c(2L, 6L, 6L)))
    cs <- if (multi) lapply(1:2, function(r) solve(x$data$Ainv_kernel[r, , ])) else list(solve(as.matrix(x$data$Ainv_phy_rr)))
    group <- if (multi) x$data$kernel_group_id + 1L else x$data$species_aug_id + 1L
    stopifnot(all(vapply(cs, function(C) identical(dim(C), c(6L, 6L)), logical(1))))
    x$parameters$b_fix <- pt$beta
    x$parameters$log_sigma_eps <- log(pt$sigma)
    if (multi) x$parameters$theta_rr_kernel <- pt$lambda else x$parameters$theta_rr_phy <- pt$lambda[1:3]
    obj <- TMB::MakeADFun(data = x$data, parameters = x$parameters, map = x$map, random = x$random, DLL = x$DLL, silent = TRUE)
    par <- obj$par
    value <- obj$fn(par)
    gradient <- obj$gr(par)
    stopifnot(is.finite(value), all(is.finite(gradient)))
    X <- as.matrix(x$data$X_fix)
    E <- diag(3)[x$data$trait_id + 1L, , drop = FALSE]
    stopifnot(identical(dim(X), dim(E)), identical(colnames(X), paste0("traitt", 1:3)), identical(as.vector(X), as.vector(E)))
    ti <- x$data$trait_id + 1L
    V <- diag(pt$sigma^2, length(ti))
    for (r in seq_len(nr)) {
      lambda <- pt$lambda[(3 * r - 2):(3 * r)]
      V <- V + outer(lambda[ti], lambda[ti]) * cs[[r]][group, group]
      write_tsv(data.frame(cs[[r]]), file.path(dir, paste0("source-", r, ".tsv")))
    }
    resid <- x$data$y - as.vector(X %*% pt$beta)
    dense <- (length(resid) * log(2 * pi) + as.numeric(determinant(V, logarithm = TRUE)$modulus) + sum(resid * solve(V, resid))) / 2
    write_tsv(data.frame(trait = ti, site = x$data$site_id + 1L, group = group, y = x$data$y), file.path(dir, "data.tsv"))
    write_tsv(data.frame(name = names(par), value = unname(par), gradient = as.numeric(gradient)), file.path(dir, "parameters.tsv"))
    write_tsv(data.frame(family = "source", model = model, point = i, sources = nr, r_nll = value, dense_nll = dense), file.path(dir, "contract.tsv"))
    saveRDS(list(input = x, par = par, nll = value, gradient = gradient, covariance = V), file.path(dir, "reference.rds"))
    rows[[length(rows) + 1L]] <- data.frame(id = id, family = "source", model = model, point = i, r_nll = value, dense_nll = dense, absolute_delta = abs(value - dense))
    cat(id, "R_DENSE_DELTA", format(abs(value - dense), digits = 17), "\n")
  }

  summary_df <- do.call(rbind, rows)
  write_tsv(summary_df, file.path(out, "summary.tsv"))
  stopifnot(all(summary_df$absolute_delta <= contract$tolerances$native_vs_dense_abs_loglik))
  cat("CORE070_FIT_INPUT_BATCH_R_PASS_NO_OUTER_OPTIMIZATION\n")

  ## --- Negative control 2: cross_point_swap_mismatch (no new TMB calls) ----
  neg_cross_point <- lapply(split(summary_df, summary_df$model), function(rows_for_model) {
    stopifnot(nrow(rows_for_model) == 2L)
    delta <- abs(rows_for_model$r_nll[[1L]] - rows_for_model$r_nll[[2L]])
    list(model = rows_for_model$model[[1L]], delta = delta, mismatch = isTRUE(delta > 1e-6))
  })
  names(neg_cross_point) <- vapply(neg_cross_point, function(z) z$model, character(1))
  cross_point_pass <- all(vapply(neg_cross_point, function(z) z$mismatch, logical(1)))

  ## --- Julia side: native + dense (ForwardDiff) verification --------------
  parent_preload <- Sys.getenv("LD_PRELOAD")
  Sys.unsetenv("LD_PRELOAD")
  julia_bin <- Sys.which("julia")
  if (!nzchar(julia_bin) && nzchar(Sys.getenv("JULIA_HOME"))) {
    julia_bin <- file.path(Sys.getenv("JULIA_HOME"), "julia")
  }
  if (!nzchar(julia_bin)) julia_bin <- "julia"
  julia_log <- tryCatch(
    system2(julia_bin, c("--startup-file=no", "--project=.", "tools/core070_fit_input_batch.jl", out),
      stdout = TRUE, stderr = TRUE
    ),
    error = function(e) paste("JULIA_LAUNCH_ERROR:", conditionMessage(e))
  )
  Sys.setenv(LD_PRELOAD = parent_preload)
  julia_status <- attr(julia_log, "status")
  julia_ok <- is.null(julia_status) || identical(julia_status, 0L)
  julia_text <- paste(julia_log, collapse = "\n")

  parse_points <- function(text) {
    m <- regmatches(text, gregexpr("([A-Z-]+-P[0-9]+) abs_delta=(\\S+) scaled_gradient_error=(\\S+)", text))[[1]]
    if (!length(m)) {
      return(list())
    }
    lapply(m, function(line) {
      parts <- regmatches(line, regexec("([A-Z-]+-P[0-9]+) abs_delta=(\\S+) scaled_gradient_error=(\\S+)", line))[[1]]
      list(id = parts[[2]], abs_delta = as.numeric(parts[[3]]), scaled_gradient_error = as.numeric(parts[[4]]))
    })
  }
  parse_negctrl <- function(text) {
    pattern <- "NEGCTRL ([A-Z-]+-P[0-9]+) shifted_intercept_mismatch delta=(\\S+) mismatch=(true|false)"
    m <- regmatches(text, gregexpr(pattern, text))[[1]]
    if (!length(m)) {
      return(list())
    }
    lapply(m, function(line) {
      parts <- regmatches(line, regexec(pattern, line))[[1]]
      list(id = parts[[2]], delta = as.numeric(parts[[3]]), mismatch = identical(parts[[4]], "true"))
    })
  }
  julia_points <- parse_points(julia_text)
  julia_negctrl <- parse_negctrl(julia_text)
  julia_tally_ok <- grepl("CORE070_FIT_INPUT_BATCH_JULIA_PASS", julia_text, fixed = TRUE)

  expected_ids <- c(
    paste0("GAUSS-", rep(c("DEFAULT", "COMMON", "LOADINGS"), each = 2), "-P", rep(1:2, 3)),
    paste0(rep(c("ANIMAL-LATENT", "KERNEL-ONE", "KERNEL-TWO"), each = 2), "-P", rep(1:2, 3))
  )

  point_records <- lapply(expected_ids, function(id) {
    r <- summary_df[summary_df$id == id, , drop = FALSE]
    j <- Filter(function(z) identical(z$id, id), julia_points)
    n <- Filter(function(z) identical(z$id, id), julia_negctrl)
    ok <- nrow(r) == 1L && length(j) == 1L &&
      is.finite(j[[1]]$abs_delta) && j[[1]]$abs_delta <= contract$tolerances$r_vs_native_abs_loglik &&
      is.finite(j[[1]]$scaled_gradient_error) && j[[1]]$scaled_gradient_error <= contract$tolerances$scaled_gradient_error &&
      length(n) == 1L && isTRUE(n[[1]]$mismatch)
    list(
      id = id,
      r_nll = if (nrow(r) == 1L) r$r_nll[[1L]] else NA_real_,
      dense_nll = if (nrow(r) == 1L) r$dense_nll[[1L]] else NA_real_,
      r_vs_dense_abs_delta = if (nrow(r) == 1L) r$absolute_delta[[1L]] else NA_real_,
      julia_abs_delta = if (length(j) == 1L) j[[1]]$abs_delta else NA_real_,
      julia_scaled_gradient_error = if (length(j) == 1L) j[[1]]$scaled_gradient_error else NA_real_,
      shifted_intercept_mismatch_delta = if (length(n) == 1L) n[[1]]$delta else NA_real_,
      shifted_intercept_mismatch = length(n) == 1L && isTRUE(n[[1]]$mismatch),
      pass = ok
    )
  })
  names(point_records) <- expected_ids
  points_ok <- all(vapply(point_records, function(z) isTRUE(z$pass), logical(1)))

  case_results <- list()
  for (row in contract$rows) {
    for (case_spec in row$cases) {
      if (identical(case_spec$status, "EXECUTABLE_NOW")) {
        ids <- unlist(case_spec$fixed_point_ids, use.names = FALSE)
        case_pass <- all(vapply(ids, function(id) isTRUE(point_records[[id]]$pass), logical(1)))
        case_results[[case_spec$case_id]] <- list(
          case_id = case_spec$case_id, status = if (case_pass) "PASS" else "FAIL",
          fixed_point_ids = ids
        )
      } else {
        case_results[[case_spec$case_id]] <- list(
          case_id = case_spec$case_id, status = case_spec$status, reason = case_spec$reason
        )
      }
    }
  }
  all_case_ids_present <- length(case_results) == 33L

  result <- list(
    status = if (points_ok && cross_point_pass && julia_ok && julia_tally_ok && all_case_ids_present) {
      "FIT_INPUT_BATCH_NATIVE_FIXED_POINT_PASS_OPTIMIZED_FIT_UNPAID"
    } else {
      "FIT_INPUT_BATCH_FAIL"
    },
    area = "fit-input",
    reference_commit = contract$reference_commit,
    contract = "docs/dev-log/core070/fit-input-batch-contract.json",
    contract_sha256 = sha256_file(file.path(root, "docs/dev-log/core070/fit-input-batch-contract.json")),
    input_sha256 = input_sha,
    tolerances = contract$tolerances,
    points = point_records,
    negative_controls = list(
      shifted_intercept_mismatch = list(
        kind = "per_point",
        all_mismatch = all(vapply(point_records, function(z) isTRUE(z$shifted_intercept_mismatch), logical(1)))
      ),
      cross_point_swap_mismatch = list(kind = "per_model", details = neg_cross_point, all_mismatch = cross_point_pass)
    ),
    case_results = case_results,
    process_receipt = list(
      r_version = R.version.string,
      gllvmTMB_version = as.character(utils::packageVersion("gllvmTMB")),
      gllvmTMB_path = find.package("gllvmTMB"),
      frozen_library = lib,
      inputs_dir = inputs,
      julia_bin = julia_bin,
      julia_exit_status = if (is.null(julia_status)) 0L else julia_status,
      julia_log_sha256 = {
        p <- file.path(out, "julia.log")
        writeLines(julia_log, p)
        sha256_file(p)
      }
    ),
    checks = list(
      points_ok = points_ok,
      cross_point_swap_negative_control = cross_point_pass,
      julia_process_ok = julia_ok,
      julia_tally_ok = julia_tally_ok,
      all_33_case_ids_present = all_case_ids_present
    ),
    all_checks = points_ok && cross_point_pass && julia_ok && julia_tally_ok && all_case_ids_present
  )

  results_path <- file.path(out, "fit-input-batch-results.json")
  jsonlite::write_json(result, results_path, auto_unbox = TRUE, pretty = TRUE, digits = NA, null = "null")
  cat("CORE070_FIT_INPUT_BATCH_RESULTS_SHA256", sha256_file(results_path), "\n")
  if (!isTRUE(result$all_checks)) quit(status = 1L)
}

main()
