#!/usr/bin/env Rscript
# Frozen-R feasibility/timing probe for the single authorised S4 public formula.
#
# Usage:
#   Rscript --vanilla run_a4_s4_public_r_formula_probe.R <frozen-library> <output-json>
#
# This runner deliberately calls only the native frozen gllvmTMB constructor.
# It does not call Julia, extract intervals, compare endpoints, or create an
# admission result.  A successful JSON record is a public-formula feasibility
# observation, not an S3b/S4 parity receipt.

probe_stop <- function(message) stop(message, call. = FALSE)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  probe_stop(paste(
    "usage: Rscript --vanilla run_a4_s4_public_r_formula_probe.R",
    "<frozen-library> <output-json>"
  ))
}

frozen_library <- normalizePath(args[[1L]], mustWork = TRUE)
output <- normalizePath(args[[2L]], mustWork = FALSE)
file_argument <- grep("^--file=", commandArgs(), value = TRUE)
if (length(file_argument) != 1L) {
  probe_stop("runner path is not available from Rscript invocation")
}
runner_path <- normalizePath(sub("^--file=", "", file_argument), mustWork = TRUE)
link_target <- Sys.readlink(output)
if (file.exists(output) ||
    (length(link_target) == 1L && !is.na(link_target) && nzchar(link_target))) {
  probe_stop("refusing to overwrite a public-formula probe receipt")
}
if (!dir.exists(dirname(output))) {
  probe_stop("output-json parent directory does not exist")
}

package_path <- file.path(frozen_library, "gllvmTMB")
dll_path <- file.path(package_path, "libs", "gllvmTMB.so")
identity_path <- file.path(frozen_library, "gllvmTMB-frozen-source-identity.json")
if (!file.exists(dll_path) || !file.exists(identity_path)) {
  probe_stop("frozen gllvmTMB library lacks the required DLL or source identity record")
}
if (!requireNamespace("ape", quietly = TRUE) ||
    !requireNamespace("digest", quietly = TRUE) ||
    !requireNamespace("jsonlite", quietly = TRUE)) {
  probe_stop("ape, digest, and jsonlite are required for the public-formula probe")
}
identity <- tryCatch(jsonlite::fromJSON(identity_path), error = function(error) NULL)
dll_sha256 <- unname(tools::sha256sum(dll_path))
source_pin <- if (is.list(identity) && !is.null(identity$source_sha)) identity$source_sha else ""
if (!is.list(identity) || !is.character(source_pin) || length(source_pin) != 1L ||
    !identical(source_pin, "b4d5fee64def88bc768dda1f1f77c29b295edd86") ||
    !identical(identity$source_version, "0.7.0") ||
    !identical(identity$installed_shared_library_sha256, dll_sha256)) {
  probe_stop("frozen source identity does not attest the requested R 0.7.0 DLL")
}

.libPaths(c(frozen_library, .libPaths()))
suppressPackageStartupMessages(library("gllvmTMB", lib.loc = frozen_library,
  character.only = TRUE))
loaded_package_path <- find.package("gllvmTMB", lib.loc = frozen_library)
if (!identical(normalizePath(loaded_package_path), normalizePath(package_path)) ||
    !identical(as.character(utils::packageVersion("gllvmTMB")), identity$source_version)) {
  probe_stop("loaded gllvmTMB package is not the attested frozen 0.7.0 install")
}

# Three tips, two trait columns, and three individuals per tip provide the
# smallest intended public wide-data shape with residual replication.  Every
# root-to-tip distance is two, deliberately exercising the non-unit native
# tree scale while remaining ultrametric.
tree <- ape::read.tree(text = "(sp1:2,(sp2:1,sp3:1):1);")
d_wide <- data.frame(
  individual = factor(paste0("i", seq_len(9L))),
  species = factor(rep(c("sp1", "sp2", "sp3"), each = 3L),
                   levels = c("sp1", "sp2", "sp3")),
  trait_1 = c(-0.6, -0.2, 0.1, 0.4, 0.8, 1.1, 1.3, 1.7, 2.0),
  trait_2 = c(0.5, 0.2, 0.7, 0.1, -0.3, 0.4, -0.6, -0.2, -0.9)
)
formula_text <- "traits(trait_1, trait_2) ~ 1 + phylo_dep(1 | species, tree = tree)"
fixture_sha256 <- digest::digest(list(
  tree_newick = "(sp1:2,(sp2:1,sp3:1):1);",
  data = d_wide,
  formula = formula_text
), algo = "sha256")
started <- Sys.time()
fit_or_error <- tryCatch(
  gllvmTMB::gllvmTMB(
    traits(trait_1, trait_2) ~ 1 + phylo_dep(1 | species, tree = tree),
    data = d_wide,
    unit = "individual",
    cluster = "species",
    family = stats::gaussian(),
    control = gllvmTMB::gllvmTMBcontrol(se = FALSE),
    silent = TRUE
  ),
  error = function(error) error
)
elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))

record <- list(
  schema_version = "destination-b-a4-s4-public-r-formula-probe-1",
  status = if (inherits(fit_or_error, "error")) "formula_rejected_or_fit_failed" else "formula_evaluated_native_only",
  claim_status = "feasibility_probe_not_a_paired_receipt",
  source_pin = source_pin,
  source_archive_sha256 = identity$source_archive_sha256,
  frozen_identity_sha256 = unname(tools::sha256sum(identity_path)),
  dll_sha256 = dll_sha256,
  runner_path = runner_path,
  runner_sha256 = unname(tools::sha256sum(runner_path)),
  invocation = list(command = "Rscript --vanilla", frozen_library = frozen_library,
    output = output),
  captured_at_utc = format(Sys.time(), tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ"),
  r_version = R.version.string,
  package_version = as.character(utils::packageVersion("gllvmTMB")),
  loaded_package_path = normalizePath(loaded_package_path),
  formula = formula_text,
  resolved_long_formula = "value ~ 0 + trait + phylo_dep(0 + trait | species, tree = tree)",
  data_layout = "wide_traits",
  n_tips = 3L,
  ultrametric = isTRUE(ape::is.ultrametric(tree)),
  root_to_tip_height = 2,
  fixture_sha256 = fixture_sha256,
  elapsed_seconds = elapsed,
  native_only = TRUE,
  julia_called = FALSE,
  intervals_extracted = FALSE
)
if (inherits(fit_or_error, "error")) {
  record$error <- conditionMessage(fit_or_error)
} else {
  record$native_convergence <- fit_or_error$opt$convergence
  record$native_loglik <- as.numeric(stats::logLik(fit_or_error))
  record$use_phylo_rr <- isTRUE(fit_or_error$use$phylo_rr)
  record$use_phylo_dep <- isTRUE(fit_or_error$use$phylo_dep)
}

jsonlite::write_json(record, output, auto_unbox = TRUE, pretty = TRUE)
cat(jsonlite::toJSON(record, auto_unbox = TRUE), "\n")
