#!/usr/bin/env Rscript
# Frozen-R source-alignment receipt for one crossed, replicated Gaussian cluster2-tier fit.
# It does not edit, rebuild, or otherwise alter the gllvmTMB reference source.

usage <- function(status = 0L) {
  cat("Usage: b1_cluster2_gaussian_reference.R --source PATH --library PATH --output PATH\n")
  quit(status = status)
}

parse_args <- function(args) {
  out <- list()
  if (length(args) %% 2L != 0L) stop("Arguments must be --name PATH pairs.")
  for (i in seq.int(1L, length(args), by = 2L)) {
    key <- args[[i]]; value <- args[[i + 1L]]
    key %in% c("--source", "--library", "--output") || stop("Unknown argument: ", key)
    nzchar(value) || stop("Empty value for ", key)
    out[[substring(key, 3L)]] <- value
  }
  missing <- setdiff(c("source", "library", "output"), names(out))
  length(missing) == 0L || stop("Missing: ", paste0("--", missing, collapse = ", "))
  out
}

args <- tryCatch(parse_args(commandArgs(trailingOnly = TRUE)), error = function(e) {
  message("ERROR: ", conditionMessage(e)); usage(2L)
})
source_dir <- normalizePath(args$source, mustWork = TRUE)
library_dir <- normalizePath(args$library, mustWork = TRUE)
output_path <- normalizePath(args$output, mustWork = FALSE)
dir.exists(dirname(output_path)) || stop("Output parent does not exist: ", dirname(output_path))
expected_sha <- "b4d5fee64def88bc768dda1f1f77c29b295edd86"
expected_version <- "0.7.0"

run_git <- function(...) {
  result <- suppressWarnings(system2("git", c("-C", source_dir, ...), stdout = TRUE, stderr = TRUE))
  status <- attr(result, "status")
  if (!is.null(status) && status != 0L) stop("git validation failed: ", paste(result, collapse = "\n"))
  trimws(paste(result, collapse = "\n"))
}
sha256_file <- function(path) {
  result <- suppressWarnings(system2("shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE))
  status <- attr(result, "status")
  if (!is.null(status) && status != 0L) stop("SHA-256 failed: ", paste(result, collapse = "\n"))
  hash <- strsplit(trimws(paste(result, collapse = "\n")), "[[:space:]]+")[[1L]][1L]
  grepl("^[0-9a-f]{64}$", hash) || stop("SHA-256 output was malformed for: ", path)
  hash
}
runner_arg <- commandArgs()[grepl("^--file=", commandArgs())]
length(runner_arg) == 1L || stop("Could not identify the receipt runner path.")
runner_path <- normalizePath(sub("^--file=", "", runner_arg), mustWork = TRUE)

identical(run_git("rev-parse", "HEAD"), expected_sha) || stop("Frozen source SHA mismatch.")
source_desc <- read.dcf(file.path(source_dir, "DESCRIPTION"))
identical(unname(source_desc[1L, "Version"]), expected_version) || stop("Frozen source Version mismatch.")
archive <- tempfile("gllvmTMB-frozen-r070-cluster2-", fileext = ".tar")
archive_result <- suppressWarnings(system2("git", c("-C", source_dir, "archive", "--format=tar",
    paste0("--output=", archive), expected_sha), stdout = TRUE, stderr = TRUE))
if (!is.null(attr(archive_result, "status")) && attr(archive_result, "status") != 0L) {
  stop("Frozen source archive failed: ", paste(archive_result, collapse = "\n"))
}
archive_sha256 <- sha256_file(archive)
unlink(archive)

requireNamespace("jsonlite", quietly = TRUE) || stop("jsonlite is required for the receipt.")
marker_path <- file.path(library_dir, "gllvmTMB-frozen-source-identity.json")
file.exists(marker_path) || stop("Frozen-library identity marker is absent: ", marker_path)
marker <- jsonlite::fromJSON(marker_path, simplifyVector = FALSE)
shared <- list.files(file.path(library_dir, "gllvmTMB", "libs"),
  pattern = "^gllvmTMB\\.(so|dylib)$", full.names = TRUE)
length(shared) == 1L || stop("Expected exactly one installed gllvmTMB shared library.")
shared <- normalizePath(shared[[1L]], mustWork = TRUE)
shared_sha256 <- sha256_file(shared)
identical(marker$source_sha, expected_sha) || stop("Frozen-library source SHA marker mismatch.")
identical(marker$source_version, expected_version) || stop("Frozen-library Version marker mismatch.")
identical(marker$source_archive_sha256, archive_sha256) || stop("Frozen-library archive marker mismatch.")
identical(marker$installed_shared_library_sha256, shared_sha256) || stop("Frozen-library shared-library marker mismatch.")

.libPaths(c(library_dir, .libPaths()))
library("gllvmTMB", lib.loc = library_dir, character.only = TRUE)
loaded_path <- normalizePath(find.package("gllvmTMB"), mustWork = TRUE)
identical(loaded_path, normalizePath(file.path(library_dir, "gllvmTMB"), mustWork = TRUE)) ||
  stop("Loaded gllvmTMB is not in --library.")
identical(as.character(utils::packageVersion("gllvmTMB")), expected_version) ||
  stop("Loaded gllvmTMB Version mismatch.")

as_receipt_value <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.matrix(x)) { dimnames(x) <- NULL; return(x) }
  if (is.atomic(x)) return(unname(x))
  x
}
field <- function(x, name) if (is.list(x) && name %in% names(x)) as_receipt_value(x[[name]]) else NULL

set.seed(20260912L)
n_trait <- 2L; n_cluster2 <- 6L; n_unit_per_cluster2 <- 4L; n_replicate <- 2L
trait_levels <- paste0("trait_", seq_len(n_trait))
cluster2_levels <- paste0("cluster2_", seq_len(n_cluster2))
rows <- do.call(rbind, lapply(cluster2_levels, function(cluster2_value) {
  do.call(rbind, lapply(seq_len(n_unit_per_cluster2), function(unit_index) {
    data.frame(cluster2_id = cluster2_value,
      unit = paste0("unit_", unit_index),
      replicate = seq_len(n_replicate), stringsAsFactors = FALSE)
  }))
}))
rows <- rows[rep(seq_len(nrow(rows)), each = n_trait), , drop = FALSE]
rows$trait <- rep(trait_levels, times = nrow(rows) %/% n_trait)
trait_mean <- c(-0.22, 0.25)
trait_sd_cluster2 <- c(0.52, 0.31)
r_c2 <- rbind(rnorm(n_cluster2, sd = trait_sd_cluster2[1L]),
              rnorm(n_cluster2, sd = trait_sd_cluster2[2L]))
rows$value <- trait_mean[match(rows$trait, trait_levels)] +
  r_c2[cbind(match(rows$trait, trait_levels), match(rows$cluster2_id, cluster2_levels))] +
  rnorm(nrow(rows), sd = 0.19)
data <- data.frame(value = rows$value,
  trait = factor(rows$trait, levels = trait_levels),
  unit = factor(rows$unit),
  cluster2_id = factor(rows$cluster2_id, levels = cluster2_levels),
  replicate = rows$replicate)
data_csv <- tempfile("b1-cluster2-gaussian-data-", fileext = ".csv")
utils::write.csv(data, data_csv, row.names = FALSE)
data_md5 <- unname(tools::md5sum(data_csv)); unlink(data_csv)

formula_text <- "value ~ 0 + trait + indep(0 + trait | cluster2_id)"
receipt <- list(
  receipt_kind = "frozen_R_source_alignment_only",
  limitations = c("Not Julia parity until independently checked by Julia.",
    "Not recovery evidence.", "Not interval validation.", "Not B1 qualification.",
    "Crossed diagonal cluster2 only; latent and full forms are excluded."),
  source = list(path = source_dir, git_sha = expected_sha, description_version = expected_version,
    archive_sha256 = archive_sha256),
  installed = list(library = library_dir, loaded_path = loaded_path, loaded_version = expected_version,
    marker_path = marker_path, shared_library = shared, shared_library_sha256 = shared_sha256),
  r_runner = list(path = "tools/destination_b/b1_cluster2_gaussian_reference.R",
    sha256 = sha256_file(runner_path), R_version = as.character(getRversion())),
  specification = list(formula = formula_text, family = "gaussian()", trait = "trait",
    unit = "unit", cluster2 = "cluster2_id", REML = FALSE, control = list(n_init = 1L, se = FALSE),
    n_trait = n_trait, n_cluster2 = n_cluster2, n_unit_per_cluster2 = n_unit_per_cluster2,
    n_replicate = n_replicate, n_observation = n_cluster2 * n_unit_per_cluster2 * n_replicate,
    row_order = "cluster2, unit, replicate, trait", seed = 20260912L, data_md5 = data_md5),
  response_long = list(value = as_receipt_value(data$value), trait = as.character(data$trait),
    unit = as.character(data$unit), cluster2_id = as.character(data$cluster2_id), replicate = data$replicate),
  mapping = NULL, fit = NULL, failure = list(present = FALSE)
)

started <- Sys.time()
fit <- tryCatch(gllvmTMB::gllvmTMB(
  value ~ 0 + trait + indep(0 + trait | cluster2_id), data = data, family = gaussian(),
  trait = "trait", unit = "unit", cluster2 = "cluster2_id", REML = FALSE,
  control = gllvmTMB::gllvmTMBcontrol(n_init = 1L, se = FALSE)
), error = function(e) e)
fit_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
if (inherits(fit, "error")) {
  receipt$failure <- list(present = TRUE, class = class(fit), message = conditionMessage(fit), fit_seconds = fit_seconds)
} else {
  report <- field(fit, "report"); opt <- field(fit, "opt"); tmb_data <- field(fit, "tmb_data")
  opt_par <- if (is.list(opt) && "par" %in% names(opt)) opt$par else NULL
  fitted <- if (!is.null(opt_par)) tryCatch(fit$tmb_obj$env$parList(opt_par), error = function(e) NULL) else NULL
  required <- c("b_fix", "log_sigma_eps", "theta_diag_cluster2")
  if (!is.list(fitted) || any(vapply(required, function(name) is.null(fitted[[name]]), logical(1L)))) {
    stop("Frozen-R fit did not expose required b_fix/log_sigma_eps/theta_diag_cluster2 coordinates.")
  }
  sigma_c2 <- tryCatch(gllvmTMB::extract_Sigma(fit, level = "cluster2", part = "total", link_residual = "none")$Sigma,
    error = function(e) NULL)
  is.null(sigma_c2) && stop("Frozen-R canonical cluster2 Sigma extraction failed.")
  sigma_eps <- field(report, "sigma_eps")
  is.null(sigma_eps) && stop("Frozen-R report did not expose sigma_eps.")
  receipt$mapping <- list(trait_levels = as_receipt_value(levels(data$trait)), x_fix_names = field(fit, "X_fix_names"),
    trait_id = field(tmb_data, "trait_id"), unit_id = field(tmb_data, "site_id"),
    cluster2_id = field(tmb_data, "cluster2_id"), n_units = field(tmb_data, "n_sites"),
    n_cluster2 = field(tmb_data, "n_cluster2"))
  receipt$fit <- list(fit_seconds = fit_seconds, logLik = as.numeric(stats::logLik(fit)),
    convergence = if (is.list(opt) && "convergence" %in% names(opt)) as_receipt_value(opt$convergence) else NULL,
    optimizer_message = if (is.list(opt) && "message" %in% names(opt)) as_receipt_value(opt$message) else NULL,
    raw_opt_par = list(names = unname(names(opt_par)), values = unname(as.numeric(opt_par))),
    report_fields = if (is.list(report)) unname(names(report)) else NULL,
    b_fix = as_receipt_value(fitted$b_fix), log_sigma_eps = as_receipt_value(fitted$log_sigma_eps),
    theta_diag_cluster2 = as_receipt_value(fitted$theta_diag_cluster2),
    log_sd_cluster2 = as_receipt_value(log(field(report, "sd_c2"))), Sigma_cluster2 = as_receipt_value(sigma_c2),
    sigma_eps = sigma_eps)
}

writeLines(jsonlite::toJSON(receipt, auto_unbox = TRUE, pretty = TRUE, digits = 16, na = "null"), output_path)
if (isTRUE(receipt$failure$present)) quit(status = 1L)
message("Frozen-R cluster2 source-alignment receipt written: ", output_path)
