#!/usr/bin/env Rscript
# Append-only frozen-R B1 optimizer probes.  This sources the retained
# diagnostic runner to reconstruct the exact fixture, then records only
# model-preserving changes to initialization or optimizer controls.

runner_arg <- commandArgs()[grepl("^--file=", commandArgs())]
length(runner_arg) == 1L || stop("Could not identify probe runner path.")
probe_runner_path <- normalizePath(sub("^--file=", "", runner_arg), mustWork = TRUE)
base_runner_path <- file.path(dirname(probe_runner_path), "b1_joint_gaussian_reference.R")
file.exists(base_runner_path) || stop("Missing retained B1 diagnostic runner.")
common_module_path <- file.path(dirname(probe_runner_path), "b1_joint_gaussian_common.R")
file.exists(common_module_path) || stop("Missing shared B1 fixture/attestation module.")

parse_probe_args <- function(args) {
  out <- list()
  length(args) %% 2L == 0L || stop("Arguments must be --name PATH pairs.")
  for (i in seq.int(1L, length(args), by = 2L)) {
    key <- args[[i]]; value <- args[[i + 1L]]
    key %in% c("--source", "--library", "--output") || stop("Unknown argument: ", key)
    out[[substring(key, 3L)]] <- value
  }
  missing <- setdiff(c("source", "library", "output"), names(out))
  !length(missing) || stop("Missing: ", paste(missing, collapse = ", "))
  out
}
probe_args <- parse_probe_args(commandArgs(trailingOnly = TRUE))
output_path <- normalizePath(probe_args$output, mustWork = FALSE)
dir.exists(dirname(output_path)) || stop("Output parent does not exist.")
source(common_module_path)
ctx <- b1_joint_prepare(probe_args$source, probe_args$library)
run_fit <- ctx$run_fit
fit_record <- ctx$fit_record
fit_seed <- ctx$fit_seed
as_value <- b1_joint_as_value
field <- b1_joint_field
sha256_file <- b1_joint_sha256_file

probe_control_specs <- list(
  nlminb_multistart_10 = list(
    control = gllvmTMB::gllvmTMBcontrol(n_init = 10L, init_jitter = 0.3, se = FALSE),
    metadata = list(optimizer = "nlminb", n_init = 10L, init_jitter = 0.3,
      start_method = "default")
  ),
  optim_bfgs_multistart_5 = list(
    control = gllvmTMB::gllvmTMBcontrol(n_init = 5L, init_jitter = 0.3, se = FALSE,
      optimizer = "optim", optArgs = list(method = "BFGS",
        control = list(maxit = 10000L, reltol = 1e-12))),
    metadata = list(optimizer = "optim(BFGS)", n_init = 5L, init_jitter = 0.3,
      maxit = 10000L, reltol = 1e-12, start_method = "default")
  ),
  nlminb_indep_multistart_5 = list(
    control = gllvmTMB::gllvmTMBcontrol(n_init = 5L, init_jitter = 0.3, se = FALSE,
      start_method = list(method = "indep")),
    metadata = list(optimizer = "nlminb", n_init = 5L, init_jitter = 0.3,
      start_method = "indep")
  ),
  optim_bfgs_indep_multistart_5 = list(
    control = gllvmTMB::gllvmTMBcontrol(n_init = 5L, init_jitter = 0.3, se = FALSE,
      start_method = list(method = "indep"), optimizer = "optim",
      optArgs = list(method = "BFGS", control = list(maxit = 10000L, reltol = 1e-12))),
    metadata = list(optimizer = "optim(BFGS)", n_init = 5L, init_jitter = 0.3,
      maxit = 10000L, reltol = 1e-12, start_method = "indep")
  )
)

record_attempt <- function(spec) {
  warnings <- character()
  attempt <- withCallingHandlers(
    run_fit(spec$control, fit_seed),
    warning = function(condition) {
      warnings <<- c(warnings, conditionMessage(condition))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(attempt$fit, "error")) {
    return(list(
      status = "failure",
      failure = list(class = class(attempt$fit), message = conditionMessage(attempt$fit)),
      fit_seconds = attempt$fit_seconds,
      control = spec$metadata,
      warnings = warnings,
      warm_start_applied = FALSE
    ))
  }
  record <- fit_record(attempt$fit, attempt$fit_seconds)
  record$status <- "success"
  record$mapping <- NULL
  record$restart_history <- as_value(field(attempt$fit, "restart_history"))
  record$start_provenance <- as_value(field(attempt$fit, "start_provenance"))
  record$control <- spec$metadata
  record$warnings <- warnings
  record$warm_start_applied <- isTRUE(record$start_provenance$auto_indep_fit)
  record
}

attempts <- lapply(probe_control_specs, record_attempt)
threshold <- 1e-6
eligible <- vapply(attempts, function(attempt) {
  identical(attempt$status, "success") && is.null(attempt$failure) && isTRUE(attempt$convergence == 0L) &&
    is.finite(attempt$gradient_max_abs) && attempt$gradient_max_abs <= threshold
}, logical(1))

probe_receipt <- list(
  receipt_kind = "frozen_R_joint_gaussian_optimizer_probe",
  source = ctx$source,
  installed = ctx$installed,
  r_runner = list(
    path = "tools/destination_b/b1_joint_gaussian_optimizer_probes.R",
    sha256 = sha256_file(probe_runner_path),
    fixture_attestation_module = "tools/destination_b/b1_joint_gaussian_common.R",
    fixture_attestation_module_sha256 = sha256_file(common_module_path),
    R_version = as.character(getRversion())
  ),
  specification = list(
    formula = ctx$specification$formula,
    family = ctx$specification$family,
    trait = ctx$specification$trait,
    unit = ctx$specification$unit,
    unit_obs = ctx$specification$unit_obs,
    cluster = ctx$specification$cluster,
    cluster2 = ctx$specification$cluster2,
    REML = FALSE,
    seed = ctx$specification$seed,
    data_md5 = ctx$specification$data_md5,
    invariant = "Only optimizer and initialization controls vary across attempts."
  ),
  acceptance = list(
    source_gradient_threshold = threshold,
    eligible_stationary_attempts = names(attempts)[eligible],
    matched_parameter = FALSE,
    reason = "A stationary frozen-R point requires a fresh Julia paired comparison before B1 acceptance."
  ),
  attempts = attempts
)

b1_joint_publish_json_new(probe_receipt, output_path)
message("Frozen-R joint B1 optimizer-probe receipt written: ", output_path)
