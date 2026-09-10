#!/usr/bin/env Rscript
# Frozen-R source-alignment receipt for one tiny Gaussian unit-latent fit.
# This script is deliberately not a Julia parity or qualification harness.

usage <- function(status = 0L) {
  cat(paste(
    "Usage: b1_unit_gaussian_reference.R --source PATH --library PATH --output PATH",
    "",
    "Create one auditable frozen-R 0.7.0 source-alignment receipt.",
    "",
    "Required arguments:",
    "  --source PATH   Frozen gllvmTMB source checkout; must be git SHA",
    "                  b4d5fee64def88bc768dda1f1f77c29b295edd86 and Version 0.7.0.",
    "  --library PATH  Explicit R library. The script builds the frozen source here",
    "                  when its retained source-identity marker is absent or mismatched.",
    "  --output PATH   JSON receipt path. Its parent directory must already exist.",
    "",
    "The sole fitted specification is:",
    "  value ~ 0 + trait + latent(0 + trait | site, d = 1, unique = FALSE)",
    "  family = gaussian(), trait = 'trait', unit = 'site', REML = FALSE,",
    "  control = gllvmTMBcontrol(n_init = 1L, se = FALSE)",
    "",
    "The receipt is source-alignment evidence only: it is not Julia parity,",
    "recovery, interval validation, B1 qualification, or public bridge admission.",
    sep = "\n"
  ), "\n")
  quit(status = status)
}

parse_args <- function(args) {
  if (length(args) == 1L && args[[1L]] %in% c("--help", "-h")) usage(0L)
  out <- list()
  if (length(args) %% 2L != 0L) stop("Arguments must be supplied as --name PATH pairs.")
  for (i in seq.int(1L, length(args), by = 2L)) {
    key <- args[[i]]
    value <- args[[i + 1L]]
    if (!key %in% c("--source", "--library", "--output")) stop("Unknown argument: ", key)
    if (!nzchar(value)) stop("Empty value for ", key)
    out[[substring(key, 3L)]] <- value
  }
  required <- c("source", "library", "output")
  missing <- setdiff(required, names(out))
  if (length(missing)) stop("Missing required argument(s): ", paste0("--", missing, collapse = ", "))
  out
}

args <- tryCatch(parse_args(commandArgs(trailingOnly = TRUE)), error = function(e) {
  message("ERROR: ", conditionMessage(e))
  usage(2L)
})

source_dir <- normalizePath(args$source, mustWork = TRUE)
library_dir <- normalizePath(args$library, mustWork = FALSE)
output_path <- normalizePath(args$output, mustWork = FALSE)
expected_sha <- "b4d5fee64def88bc768dda1f1f77c29b295edd86"
expected_version <- "0.7.0"

if (!file.exists(file.path(source_dir, "DESCRIPTION"))) stop("--source does not contain DESCRIPTION: ", source_dir)
if (!dir.exists(dirname(output_path))) stop("Parent directory for --output does not exist: ", dirname(output_path))

run_git <- function(...) {
  result <- suppressWarnings(system2("git", c("-C", source_dir, ...), stdout = TRUE, stderr = TRUE))
  status <- attr(result, "status")
  if (!is.null(status) && status != 0L) stop("git validation failed: ", paste(result, collapse = "\n"))
  trimws(paste(result, collapse = "\n"))
}

source_sha <- run_git("rev-parse", "HEAD")
if (!identical(source_sha, expected_sha)) {
  stop("Frozen source SHA mismatch: expected ", expected_sha, ", found ", source_sha)
}
source_desc <- read.dcf(file.path(source_dir, "DESCRIPTION"))
source_version <- unname(source_desc[1L, "Version"])
if (!identical(source_version, expected_version)) {
  stop("Frozen source Version mismatch: expected ", expected_version, ", found ", source_version)
}

sha256_file <- function(path) {
  result <- suppressWarnings(system2("shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE))
  status <- attr(result, "status")
  if (!is.null(status) && status != 0L) stop("SHA-256 calculation failed: ", paste(result, collapse = "\n"))
  hash <- strsplit(trimws(paste(result, collapse = "\n")), "[[:space:]]+")[[1L]][1L]
  if (!grepl("^[0-9a-f]{64}$", hash)) stop("SHA-256 output was not a digest for: ", path)
  hash
}

# Archive the exact Git object. This deliberately excludes ignored/stale source
# build products such as src/gllvmTMB.so before R compiles a new package.
source_archive <- tempfile("gllvmTMB-frozen-r070-b1-", fileext = ".tar")
archive_out <- suppressWarnings(system2(
  "git",
  c("-C", source_dir, "archive", "--format=tar", paste0("--output=", source_archive), expected_sha),
  stdout = TRUE,
  stderr = TRUE
))
archive_status <- attr(archive_out, "status")
if (!is.null(archive_status) && archive_status != 0L) {
  stop("Frozen Git archive failed: ", paste(archive_out, collapse = "\n"))
}
if (!file.exists(source_archive)) stop("Frozen Git archive was not created.")
source_archive_sha256 <- sha256_file(source_archive)

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("jsonlite is required to write the auditable JSON receipt, but is not installed.")
}

marker_path <- file.path(library_dir, "gllvmTMB-frozen-source-identity.json")
read_marker <- function(path) {
  if (!file.exists(path)) return(NULL)
  tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
}
installed_shared_library <- function() {
  candidates <- list.files(
    file.path(library_dir, "gllvmTMB", "libs"),
    pattern = "^gllvmTMB\\.(so|dylib)$",
    full.names = TRUE
  )
  length(candidates) == 1L || return(NA_character_)
  normalizePath(candidates[[1L]], mustWork = TRUE)
}
marker_matches <- function(marker) {
  current_desc <- file.path(library_dir, "gllvmTMB", "DESCRIPTION")
  current_installed_md5 <- if (file.exists(current_desc)) {
    unname(tools::md5sum(current_desc))
  } else {
    NA_character_
  }
  current_shared <- installed_shared_library()
  current_shared_sha256 <- if (is.na(current_shared)) NA_character_ else sha256_file(current_shared)
  is.list(marker) &&
    identical(marker$source_sha, expected_sha) &&
    identical(marker$source_version, expected_version) &&
    identical(normalizePath(marker$source_dir, mustWork = FALSE), source_dir) &&
    identical(marker$source_archive_sha256, source_archive_sha256) &&
    identical(marker$installed_package_description_md5, current_installed_md5) &&
    identical(marker$installed_shared_library_sha256, current_shared_sha256)
}

dir.create(library_dir, recursive = TRUE, showWarnings = FALSE)
marker <- read_marker(marker_path)
installed_desc_path <- file.path(library_dir, "gllvmTMB", "DESCRIPTION")
installed_version <- if (file.exists(installed_desc_path)) unname(read.dcf(installed_desc_path)[1L, "Version"]) else NA_character_
if (!marker_matches(marker) || !identical(installed_version, expected_version)) {
  if (dir.exists(file.path(library_dir, "gllvmTMB")) || file.exists(marker_path)) {
    stop("Frozen build library identity mismatch; refusing to overwrite it. Supply a new empty --library path.")
  }
  build_dir <- tempfile("gllvmTMB-frozen-r070-b1-source-")
  dir.create(build_dir, recursive = TRUE)
  utils::untar(source_archive, exdir = build_dir)
  archive_desc <- file.path(build_dir, "DESCRIPTION")
  if (!file.exists(archive_desc) || !identical(unname(read.dcf(archive_desc)[1L, "Version"]), expected_version)) {
    stop("Frozen Git archive did not contain the expected 0.7.0 DESCRIPTION.")
  }
  install_out <- suppressWarnings(system2(
    file.path(R.home("bin"), "R"),
    c("CMD", "INSTALL", "--preclean", paste0("--library=", library_dir), build_dir),
    stdout = TRUE,
    stderr = TRUE
  ))
  unlink(build_dir, recursive = TRUE, force = TRUE)
  install_status <- attr(install_out, "status")
  if (!is.null(install_status) && install_status != 0L) {
    stop("Frozen source installation failed (no fallback attempted):\n", paste(install_out, collapse = "\n"))
  }
  installed_desc_path <- file.path(library_dir, "gllvmTMB", "DESCRIPTION")
  if (!file.exists(installed_desc_path)) stop("Frozen source installation did not create gllvmTMB/DESCRIPTION.")
  installed_version <- unname(read.dcf(installed_desc_path)[1L, "Version"])
  if (!identical(installed_version, expected_version)) {
    stop("Installed Version mismatch after frozen build: expected ", expected_version, ", found ", installed_version)
  }
  installed_shared_path <- installed_shared_library()
  if (is.na(installed_shared_path)) stop("Frozen source installation did not create exactly one gllvmTMB shared library.")
  marker <- list(
    source_dir = source_dir,
    source_sha = source_sha,
    source_version = source_version,
    source_archive_sha256 = source_archive_sha256,
    installed_package_description_md5 = unname(tools::md5sum(installed_desc_path)),
    installed_shared_library = installed_shared_path,
    installed_shared_library_sha256 = sha256_file(installed_shared_path),
    built_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  )
  writeLines(jsonlite::toJSON(marker, auto_unbox = TRUE, pretty = TRUE), marker_path)
}
unlink(source_archive)

lib_paths_before <- .libPaths()
.libPaths(c(library_dir, lib_paths_before))
library("gllvmTMB", lib.loc = library_dir, character.only = TRUE)
loaded_path <- normalizePath(find.package("gllvmTMB"), mustWork = TRUE)
expected_loaded_path <- normalizePath(file.path(library_dir, "gllvmTMB"), mustWork = TRUE)
loaded_version <- as.character(utils::packageVersion("gllvmTMB"))
if (!identical(loaded_path, expected_loaded_path)) stop("Loaded gllvmTMB is not from --library: ", loaded_path)
if (!identical(loaded_version, expected_version)) stop("Loaded gllvmTMB Version mismatch: expected ", expected_version, ", found ", loaded_version)
installed_shared_path <- installed_shared_library()
if (is.na(installed_shared_path)) stop("Loaded frozen package has no unique shared-library payload.")
if (!marker_matches(read_marker(marker_path))) stop("The frozen source-identity marker is absent or does not match the required source.")

as_receipt_value <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.matrix(x)) {
    dimnames(x) <- NULL
    return(x)
  }
  if (is.atomic(x)) return(unname(x))
  if (is.data.frame(x)) return(x)
  x
}
report_field <- function(report, name) if (is.list(report) && name %in% names(report)) as_receipt_value(report[[name]]) else NULL
fit_field <- function(fit, name) if (is.list(fit) && name %in% names(fit)) fit[[name]] else NULL
tmb_field <- function(tmb_data, name) if (is.list(tmb_data) && name %in% names(tmb_data)) as_receipt_value(tmb_data[[name]]) else NULL

set.seed(20260908L)
n_site <- 4L
n_replicate <- 2L
n_trait <- 2L
site_levels <- paste0("site_", letters[seq_len(n_site)])
replicate_levels <- c("observation_1", "observation_2")
trait_levels <- paste0("trait_", seq_len(n_trait))
# Long order is site, within-site replicate, then trait: this is exactly the
# trait-within-observation order of Julia's vec(Y) for labels a,a,b,b,c,c,d,d.
site <- factor(rep(site_levels, each = n_replicate * n_trait), levels = site_levels)
species <- factor(rep(rep(replicate_levels, each = n_trait), times = n_site), levels = replicate_levels)
site_species <- factor(paste(site, species, sep = "__"))
trait <- factor(rep(trait_levels, times = n_site * n_replicate), levels = trait_levels)
trait_mean <- rep(c(-0.40, 0.15), times = n_site * n_replicate)
trait_loading <- rep(c(0.90, -0.45), times = n_site * n_replicate)
latent_score <- rep(rep(rnorm(n_site), each = n_replicate), each = n_trait)
value <- trait_mean + trait_loading * latent_score + rnorm(n_site * n_replicate * n_trait, sd = 0.25)
data <- data.frame(value = value, trait = trait, site = site, species = species, site_species = site_species)
data_csv <- tempfile("b1-unit-gaussian-data-", fileext = ".csv")
utils::write.csv(data, data_csv, row.names = FALSE)
data_md5 <- unname(tools::md5sum(data_csv))
unlink(data_csv)

formula_text <- "value ~ 0 + trait + latent(0 + trait | site, d = 1, unique = FALSE)"
receipt <- list(
  receipt_kind = "frozen_R_source_alignment_only",
  limitations = c(
    "Not Julia parity.",
    "Not parameter-recovery evidence.",
    "Not interval validation.",
    "Not B1 qualification.",
    "Not public bridge admission.",
    "One tiny deterministic Gaussian unit-latent fit only."
  ),
  source = list(path = source_dir, git_sha = source_sha, description_version = source_version,
                archive_sha256 = source_archive_sha256),
  installed = list(library = normalizePath(library_dir, mustWork = TRUE), loaded_path = loaded_path, loaded_version = loaded_version,
                   marker_path = marker_path, shared_library = installed_shared_path,
                   shared_library_sha256 = sha256_file(installed_shared_path), marker = read_marker(marker_path)),
  specification = list(formula = formula_text, family = "gaussian()", trait = "trait", unit = "site", REML = FALSE,
                       control = list(n_init = 1L, se = FALSE), n_site = n_site, n_replicate = n_replicate,
                       n_trait = n_trait, n_observation = n_site * n_replicate,
                       row_order = "site, site_species replicate, trait", seed = 20260908L, data_md5 = data_md5),
  mapping = NULL,
  fit = NULL,
  failure = list(present = FALSE)
)

fit_started <- Sys.time()
fit <- tryCatch(
  gllvmTMB::gllvmTMB(
    value ~ 0 + trait + latent(0 + trait | site, d = 1, unique = FALSE),
    data = data,
    family = gaussian(),
    trait = "trait",
    unit = "site",
    REML = FALSE,
    control = gllvmTMB::gllvmTMBcontrol(n_init = 1L, se = FALSE)
  ),
  error = function(e) e
)
fit_seconds <- as.numeric(difftime(Sys.time(), fit_started, units = "secs"))
if (inherits(fit, "error")) {
  receipt$failure <- list(present = TRUE, class = class(fit), message = conditionMessage(fit), fit_seconds = fit_seconds)
} else {
  report <- fit_field(fit, "report")
  opt <- fit_field(fit, "opt")
  tmb_data <- fit_field(fit, "tmb_data")
  mapping <- list(
    trait_id = tmb_field(tmb_data, "trait_id"),
    site_id = tmb_field(tmb_data, "site_id"),
    site_species_id = tmb_field(tmb_data, "site_species_id"),
    n_sites = tmb_field(tmb_data, "n_sites"),
    n_site_species = tmb_field(tmb_data, "n_site_species")
  )
  if (any(vapply(mapping, is.null, logical(1L)))) {
    stop("Frozen-R fit did not retain the required trait/site/site_species mapping payload.")
  }
  fit_convergence <- if (is.list(opt) && "convergence" %in% names(opt)) as_receipt_value(opt$convergence) else NULL
  fit_message <- if (is.list(opt) && "message" %in% names(opt)) as_receipt_value(opt$message) else NULL
  receipt$fit <- list(
    fit_seconds = fit_seconds,
    logLik = as.numeric(stats::logLik(fit)),
    convergence = fit_convergence,
    optimizer_message = fit_message,
    report_fields = if (is.list(report)) unname(names(report)) else NULL,
    fit_fields = unname(names(fit)),
    Lambda_B = report_field(report, "Lambda_B"),
    Sigma_B = report_field(report, "Sigma_B"),
    sigma_eps = report_field(report, "sigma_eps")
  )
  receipt$mapping <- mapping
}

writeLines(jsonlite::toJSON(receipt, auto_unbox = TRUE, pretty = TRUE, digits = 16, na = "null"), output_path)
if (isTRUE(receipt$failure$present)) {
  message("Frozen-R receipt written with an honest fit failure: ", output_path)
  quit(status = 1L)
}
message("Frozen-R source-alignment receipt written: ", output_path)
