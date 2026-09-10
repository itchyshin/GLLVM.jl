# Frozen-R B1 joint-Gaussian fixture and evidence publication helpers.
# Both executable receipt runners use this module; it never parses a CLI,
# alters the source/build, or publishes a retained receipt by itself.

b1_joint_sha256_file <- function(path) {
  result <- suppressWarnings(system2("shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE))
  is.null(attr(result, "status")) || attr(result, "status") == 0L || stop("SHA-256 failed.")
  strsplit(trimws(paste(result, collapse = "\n")), "[[:space:]]+")[[1L]][1L]
}

b1_joint_as_value <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.matrix(x)) { dimnames(x) <- NULL; return(x) }
  if (is.atomic(x)) return(unname(x))
  x
}

b1_joint_field <- function(x, name) {
  if (is.list(x) && name %in% names(x)) b1_joint_as_value(x[[name]]) else NULL
}

b1_joint_prepare <- function(source_dir, library_dir) {
  source_dir <- normalizePath(source_dir, mustWork = TRUE)
  library_dir <- normalizePath(library_dir, mustWork = TRUE)
  expected_sha <- "b4d5fee64def88bc768dda1f1f77c29b295edd86"
  expected_version <- "0.7.0"
  run_git <- function(...) {
    result <- suppressWarnings(system2("git", c("-C", source_dir, ...), stdout = TRUE, stderr = TRUE))
    is.null(attr(result, "status")) || attr(result, "status") == 0L || stop("git validation failed.")
    trimws(paste(result, collapse = "\n"))
  }
  identical(run_git("rev-parse", "HEAD"), expected_sha) || stop("Frozen source SHA mismatch.")
  desc <- read.dcf(file.path(source_dir, "DESCRIPTION"))
  identical(unname(desc[1L, "Version"]), expected_version) || stop("Frozen source Version mismatch.")
  archive <- tempfile("gllvmTMB-frozen-r070-b1-joint-", fileext = ".tar")
  on.exit(unlink(archive), add = TRUE)
  archive_result <- system2("git", c("-C", source_dir, "archive", "--format=tar", paste0("--output=", archive), expected_sha), stdout = TRUE, stderr = TRUE)
  is.null(attr(archive_result, "status")) || attr(archive_result, "status") == 0L || stop("Frozen archive failed.")
  archive_sha256 <- b1_joint_sha256_file(archive)

  requireNamespace("jsonlite", quietly = TRUE) || stop("jsonlite is required.")
  marker_path <- file.path(library_dir, "gllvmTMB-frozen-source-identity.json")
  marker <- jsonlite::fromJSON(marker_path, simplifyVector = FALSE)
  shared <- list.files(file.path(library_dir, "gllvmTMB", "libs"), pattern = "^gllvmTMB\\.(so|dylib)$", full.names = TRUE)
  length(shared) == 1L || stop("Expected one installed shared library.")
  shared <- normalizePath(shared[[1L]], mustWork = TRUE)
  shared_sha256 <- b1_joint_sha256_file(shared)
  identical(marker$source_sha, expected_sha) || stop("Frozen-library source SHA marker mismatch.")
  identical(marker$source_version, expected_version) || stop("Frozen-library Version marker mismatch.")
  identical(marker$source_archive_sha256, archive_sha256) || stop("Frozen-library archive marker mismatch.")
  identical(marker$installed_shared_library_sha256, shared_sha256) || stop("Frozen-library shared-library marker mismatch.")
  .libPaths(c(library_dir, .libPaths()))
  library("gllvmTMB", lib.loc = library_dir, character.only = TRUE)
  loaded_path <- normalizePath(find.package("gllvmTMB"), mustWork = TRUE)
  identical(loaded_path, normalizePath(file.path(library_dir, "gllvmTMB"), mustWork = TRUE)) || stop("Wrong loaded package.")
  identical(as.character(packageVersion("gllvmTMB")), expected_version) || stop("Loaded Version mismatch.")

  set.seed(20260913L)
  n_trait <- 2L; n_unit <- 6L; n_obs_per_unit <- 2L; n_rep <- 3L
  n_cluster <- 4L; n_cluster2 <- 3L
  design <- do.call(rbind, lapply(seq_len(n_unit), function(unit_index) {
    local_obs <- rep(seq_len(n_obs_per_unit), each = n_rep)
    position <- seq_along(local_obs)
    data.frame(unit = paste0("unit_", unit_index), obs = paste0("unit_", unit_index, "_obs_", local_obs),
      cluster_id = paste0("cluster_", ((position - 1L) %% n_cluster) + 1L),
      cluster2_id = paste0("cluster2_", c(1L, 1L, 2L, 2L, 3L, 3L)[position]),
      replicate = ((position - 1L) %% n_rep) + 1L, stringsAsFactors = FALSE)
  }))
  trait_levels <- paste0("trait_", seq_len(n_trait)); rows <- design[rep(seq_len(nrow(design)), each = n_trait), , drop = FALSE]
  rows$trait <- rep(trait_levels, times = nrow(rows) %/% n_trait)
  lambda <- c(0.58, -0.37); z_unit <- rnorm(n_unit)
  sd_obs <- c(0.34, 0.24); sd_cluster <- c(0.29, 0.20); sd_cluster2 <- c(0.23, 0.16)
  a_obs <- rbind(rnorm(n_unit * n_obs_per_unit, sd = sd_obs[1L]), rnorm(n_unit * n_obs_per_unit, sd = sd_obs[2L]))
  q_cluster <- rbind(rnorm(n_cluster, sd = sd_cluster[1L]), rnorm(n_cluster, sd = sd_cluster[2L]))
  r_cluster2 <- rbind(rnorm(n_cluster2, sd = sd_cluster2[1L]), rnorm(n_cluster2, sd = sd_cluster2[2L]))
  trait_index <- match(rows$trait, trait_levels); unit_index <- match(rows$unit, paste0("unit_", seq_len(n_unit)))
  obs_index <- match(rows$obs, unique(design$obs)); cluster_index <- match(rows$cluster_id, paste0("cluster_", seq_len(n_cluster)))
  cluster2_index <- match(rows$cluster2_id, paste0("cluster2_", seq_len(n_cluster2)))
  rows$value <- c(-0.18, 0.24)[trait_index] + lambda[trait_index] * z_unit[unit_index] +
    a_obs[cbind(trait_index, obs_index)] + q_cluster[cbind(trait_index, cluster_index)] +
    r_cluster2[cbind(trait_index, cluster2_index)] + rnorm(nrow(rows), sd = 0.21)
  data <- data.frame(value = rows$value, trait = factor(rows$trait, levels = trait_levels), unit = factor(rows$unit),
    obs = factor(rows$obs), cluster_id = factor(rows$cluster_id, levels = paste0("cluster_", seq_len(n_cluster))),
    cluster2_id = factor(rows$cluster2_id, levels = paste0("cluster2_", seq_len(n_cluster2))), replicate = rows$replicate)
  data_csv <- tempfile("b1-joint-gaussian-data-", fileext = ".csv"); on.exit(unlink(data_csv), add = TRUE)
  write.csv(data, data_csv, row.names = FALSE); data_md5 <- unname(tools::md5sum(data_csv))
  formula_text <- "value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) + indep(0 + trait | obs) + indep(0 + trait | cluster_id) + indep(0 + trait | cluster2_id)"
  fit_formula <- value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) + indep(0 + trait | obs) + indep(0 + trait | cluster_id) + indep(0 + trait | cluster2_id)
  fit_seed <- .Random.seed
  run_fit <- function(control, seed_state) {
    assign(".Random.seed", seed_state, envir = .GlobalEnv); started <- Sys.time()
    fit <- tryCatch(gllvmTMB::gllvmTMB(fit_formula, data = data, family = gaussian(), trait = "trait", unit = "unit", unit_obs = "obs", cluster = "cluster_id", cluster2 = "cluster2_id", REML = FALSE, control = control), error = function(e) e)
    list(fit = fit, fit_seconds = as.numeric(difftime(Sys.time(), started, units = "secs")))
  }
  fit_record <- function(fit, fit_seconds) {
    report <- b1_joint_field(fit, "report"); opt <- b1_joint_field(fit, "opt"); tmb_data <- b1_joint_field(fit, "tmb_data")
    opt_par <- opt$par; fitted <- fit$tmb_obj$env$parList(opt_par)
    required <- c("b_fix", "log_sigma_eps", "theta_rr_B", "theta_diag_W", "theta_diag_species", "theta_diag_cluster2")
    all(required %in% names(fitted)) || stop("Frozen R fit lacks a required joint coordinate.")
    Sigma <- function(level) gllvmTMB::extract_Sigma(fit, level = level, part = "total", link_residual = "none")$Sigma
    list(fit_seconds = fit_seconds, logLik = as.numeric(logLik(fit)), convergence = b1_joint_as_value(opt$convergence), optimizer_message = b1_joint_as_value(opt$message), gradient = b1_joint_as_value(fit$tmb_obj$gr(opt_par)), gradient_max_abs = max(abs(fit$tmb_obj$gr(opt_par))), raw_opt_par = list(names = unname(names(opt_par)), values = unname(as.numeric(opt_par))), report_fields = unname(names(report)), b_fix = b1_joint_as_value(fitted$b_fix), log_sigma_eps = b1_joint_as_value(fitted$log_sigma_eps), theta_rr_B = b1_joint_as_value(fitted$theta_rr_B), theta_diag_W = b1_joint_as_value(fitted$theta_diag_W), theta_diag_species = b1_joint_as_value(fitted$theta_diag_species), theta_diag_cluster2 = b1_joint_as_value(fitted$theta_diag_cluster2), Sigma_unit = b1_joint_as_value(Sigma("unit")), Sigma_unit_obs = b1_joint_as_value(Sigma("unit_obs")), Sigma_cluster = b1_joint_as_value(Sigma("cluster")), Sigma_cluster2 = b1_joint_as_value(Sigma("cluster2")), sigma_eps = b1_joint_field(report, "sigma_eps"), mapping = list(trait_levels = b1_joint_as_value(levels(data$trait)), x_fix_names = b1_joint_field(fit, "X_fix_names"), trait_id = b1_joint_field(tmb_data, "trait_id"), unit_id = b1_joint_field(tmb_data, "site_id"), unit_obs_id = b1_joint_field(tmb_data, "site_species_id"), cluster_id = b1_joint_field(tmb_data, "species_id"), cluster2_id = b1_joint_field(tmb_data, "cluster2_id")))
  }
  list(source = list(path = source_dir, git_sha = expected_sha, description_version = expected_version, archive_sha256 = archive_sha256), installed = list(library = library_dir, loaded_path = loaded_path, loaded_version = expected_version, marker_path = marker_path, shared_library = shared, shared_library_sha256 = shared_sha256), specification = list(formula = formula_text, family = "gaussian()", trait = "trait", unit = "unit", unit_obs = "obs", cluster = "cluster_id", cluster2 = "cluster2_id", REML = FALSE, n_trait = n_trait, n_unit = n_unit, n_unit_obs_per_unit = n_obs_per_unit, n_replicate = n_rep, n_cluster = n_cluster, n_cluster2 = n_cluster2, n_observation = nrow(design), row_order = "unit, unit_obs, replicate, trait", seed = 20260913L, data_md5 = data_md5), response_long = list(value = b1_joint_as_value(data$value), trait = as.character(data$trait), unit = as.character(data$unit), obs = as.character(data$obs), cluster_id = as.character(data$cluster_id), cluster2_id = as.character(data$cluster2_id), replicate = data$replicate), fit_seed = fit_seed, run_fit = run_fit, fit_record = fit_record)
}

b1_joint_output_occupied <- function(path) {
  link_target <- Sys.readlink(path)
  isTRUE(file.exists(path)) || (!is.na(link_target) && nzchar(link_target))
}
b1_joint_publish_json_new <- function(receipt, output_path) {
  output_path <- normalizePath(output_path, mustWork = FALSE)
  dir.exists(dirname(output_path)) || stop("Output parent does not exist.")
  b1_joint_output_occupied(output_path) && stop("Refusing to overwrite retained receipt: ", output_path)
  tmp <- tempfile(".b1-joint-receipt-", tmpdir = dirname(output_path)); on.exit(unlink(tmp), add = TRUE)
  writeLines(jsonlite::toJSON(receipt, auto_unbox = TRUE, pretty = TRUE, digits = 16, na = "null"), tmp)
  file.link(tmp, output_path) || stop("Atomic no-clobber receipt publication failed.")
  invisible(output_path)
}
