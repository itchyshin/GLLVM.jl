#!/usr/bin/env Rscript
# Frozen-R receipt for one joint, replicated Gaussian B1 grouping fit.
# It only reads the supplied frozen source/build.

parse_args <- function(args) {
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
args <- parse_args(commandArgs(trailingOnly = TRUE))
output_path <- normalizePath(args$output, mustWork = FALSE)
runner_arg <- commandArgs()[grepl("^--file=", commandArgs())]
length(runner_arg) == 1L || stop("Could not identify runner path.")
runner_path <- normalizePath(sub("^--file=", "", runner_arg), mustWork = TRUE)
source(file.path(dirname(runner_path), "b1_joint_gaussian_common.R"))
ctx <- b1_joint_prepare(args$source, args$library)

receipt <- list(
  receipt_kind = "frozen_R_to_Julia_joint_gaussian_optimizer_diagnostic",
  limitations = c("The frozen R reference point is not stationary enough for matched-parameter acceptance on this fixture.", "Direct-coordinate likelihood identity is not independently-refitted parameter parity.", "Not interval validation.", "Not recovery evidence.", "Not B1 qualification."),
  source = ctx$source, installed = ctx$installed,
  r_runner = list(path = "tools/destination_b/b1_joint_gaussian_reference.R", sha256 = b1_joint_sha256_file(runner_path), fixture_attestation_module = "tools/destination_b/b1_joint_gaussian_common.R", fixture_attestation_module_sha256 = b1_joint_sha256_file(file.path(dirname(runner_path), "b1_joint_gaussian_common.R")), R_version = as.character(getRversion())),
  specification = c(ctx$specification, list(control = list(n_init = 1L, se = FALSE), optimizer_attempts = list(default = "nlminb", nlminb_tight_same_start = list(eval_max = 10000L, iter_max = 10000L, rel_tol = 1e-12, x_tol = 1e-12, xf_tol = 1e-12), optim_bfgs_same_start = "BFGS", nlminb_multistart_5 = list(n_init = 5L, init_jitter = 0.3)))),
  response_long = ctx$response_long, mapping = NULL, fit = NULL,
  acceptance = list(matched_parameter = FALSE, source_gradient_threshold = 1e-6, reason = "Default, tight-control, BFGS, and documented five-start frozen-R attempts do not establish a stationary reference."),
  failure = list(present = FALSE)
)
default_control <- gllvmTMB::gllvmTMBcontrol(n_init = 1L, se = FALSE)
default_attempt <- ctx$run_fit(default_control, ctx$fit_seed)
fit <- default_attempt$fit
if (inherits(fit, "error")) {
  receipt$failure <- list(present = TRUE, class = class(fit), message = conditionMessage(fit), fit_seconds = default_attempt$fit_seconds)
} else {
  default_record <- ctx$fit_record(fit, default_attempt$fit_seconds)
  receipt$mapping <- default_record$mapping; default_record$mapping <- NULL
  tight_control <- gllvmTMB::gllvmTMBcontrol(n_init = 1L, se = FALSE, optArgs = list(control = list(eval.max = 10000L, iter.max = 10000L, rel.tol = 1e-12, x.tol = 1e-12, xf.tol = 1e-12)))
  bfgs_control <- gllvmTMB::gllvmTMBcontrol(n_init = 1L, se = FALSE, optimizer = "optim", optArgs = list(method = "BFGS"))
  multistart_control <- gllvmTMB::gllvmTMBcontrol(n_init = 5L, se = FALSE)
  record_or_failure <- function(attempt) {
    if (inherits(attempt$fit, "error")) return(list(failure = TRUE, class = class(attempt$fit), message = conditionMessage(attempt$fit), fit_seconds = attempt$fit_seconds))
    record <- ctx$fit_record(attempt$fit, attempt$fit_seconds); record$mapping <- NULL; record
  }
  receipt$fit <- c(default_record, list(nlminb_tight_same_start = record_or_failure(ctx$run_fit(tight_control, ctx$fit_seed)), optim_bfgs_same_start = record_or_failure(ctx$run_fit(bfgs_control, ctx$fit_seed)), nlminb_multistart_5 = record_or_failure(ctx$run_fit(multistart_control, ctx$fit_seed))))
}
b1_joint_publish_json_new(receipt, output_path)
if (isTRUE(receipt$failure$present)) quit(status = 1L)
message("Frozen-R joint B1 optimizer-diagnostic receipt written: ", output_path)
