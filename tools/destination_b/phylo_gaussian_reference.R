#!/usr/bin/env Rscript
# Frozen-R marginal Gaussian phylogenetic reference export.
#
# Usage:
#   Rscript phylo_gaussian_reference.R /private/library /private/output
#
# The first argument must contain the independently built frozen gllvmTMB
# 0.7.0 library. This runner refuses a different package/DLL instead of using
# a globally installed package. It writes a marginal (random effects
# integrated) TMB objective receipt; it never rebuilds the historical
# random=NULL joint objective.

args <- commandArgs(trailingOnly = TRUE)
if (!(length(args) %in% c(2L, 3L)) ||
    (length(args) == 3L && !identical(args[[3L]], "--preflight-only"))) {
  stop("usage: Rscript phylo_gaussian_reference.R <private-library-dir> <output-dir> [--preflight-only]",
       call. = FALSE)
}
preflight_only <- length(args) == 3L

library_dir <- normalizePath(args[[1L]], mustWork = TRUE)
output_dir <- normalizePath(args[[2L]], mustWork = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output_dir <- normalizePath(output_dir, mustWork = TRUE)
output_json <- file.path(output_dir, "phylo_gaussian_reference.json")
attempt_rds <- file.path(output_dir, "phylo_gaussian_reference_attempt.rds")
attempt_log <- file.path(output_dir, "phylo_gaussian_reference_attempt.log")
uncertainty_json <- file.path(output_dir, "phylo_gaussian_uncertainty.json")
if (any(file.exists(c(output_json, attempt_rds, attempt_log, uncertainty_json)))) {
  stop("output directory already contains a reference or attempt receipt; use a new immutable output directory",
       call. = FALSE)
}

expected_version <- "0.7.0"
expected_source_pin <- "b4d5fee64def88bc768dda1f1f77c29b295edd86"
expected_dll_sha256 <- "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"
ridge <- 1e-8
seed <- 20260803L

path_is_within <- function(path, root) {
  path <- normalizePath(path, mustWork = TRUE)
  root <- normalizePath(root, mustWork = TRUE)
  identical(path, root) || startsWith(path, paste0(root, .Platform$file.sep))
}
as_json_rows <- function(x) {
  x <- as.matrix(x)
  unname(lapply(seq_len(nrow(x)), function(i) unname(as.numeric(x[i, ]))))
}
named_block <- function(x, names, block) unname(as.numeric(x[names == block]))
float64_column_major_sha256 <- function(Y) {
  digest::digest(
    writeBin(as.double(c(Y)), raw(), size = 8L, endian = "little"),
    algo = "sha256", serialize = FALSE
  )
}
condition_number_symmetric <- function(M) {
  values <- eigen(M, symmetric = TRUE, only.values = TRUE)$values
  max(values) / min(values)
}

if (!requireNamespace("jsonlite", quietly = TRUE) ||
    !requireNamespace("digest", quietly = TRUE) ||
    !requireNamespace("ape", quietly = TRUE) ||
    !requireNamespace("TMB", quietly = TRUE)) {
  stop("jsonlite, digest, ape, and TMB must be available in the frozen R library", call. = FALSE)
}
if ("gllvmTMB" %in% loadedNamespaces()) {
  stop("gllvmTMB was already loaded; start a fresh R process so library provenance is auditable",
       call. = FALSE)
}

installed_package <- file.path(library_dir, "gllvmTMB")
if (!dir.exists(installed_package)) {
  stop("the supplied library does not contain gllvmTMB", call. = FALSE)
}
installed_version <- as.character(base::read.dcf(
  file.path(installed_package, "DESCRIPTION"), fields = "Version")[1L, "Version"])
if (!identical(installed_version, expected_version)) {
  stop(sprintf("supplied library gllvmTMB version is %s; expected frozen %s",
               installed_version, expected_version), call. = FALSE)
}

library("gllvmTMB", lib.loc = library_dir, character.only = TRUE)
package_path <- find.package("gllvmTMB")
if (!path_is_within(package_path, library_dir)) {
  stop("loaded gllvmTMB package path is not under the supplied private library", call. = FALSE)
}
loaded_version <- as.character(utils::packageVersion("gllvmTMB"))
if (!identical(loaded_version, expected_version)) {
  stop(sprintf("loaded gllvmTMB version is %s; expected frozen %s",
               loaded_version, expected_version), call. = FALSE)
}
dll <- getLoadedDLLs()[["gllvmTMB"]]
if (is.null(dll) || is.null(dll[["path"]])) {
  stop("gllvmTMB DLL is not loaded", call. = FALSE)
}
dll_path <- normalizePath(dll[["path"]], mustWork = TRUE)
if (!path_is_within(dll_path, library_dir)) {
  stop("loaded gllvmTMB DLL is not under the supplied private library", call. = FALSE)
}
dll_sha256 <- unname(tools::sha256sum(dll_path))[[1L]]
if (!identical(dll_sha256, expected_dll_sha256)) {
  stop(sprintf("loaded gllvmTMB DLL SHA256 is %s; expected frozen receipt %s",
               dll_sha256, expected_dll_sha256), call. = FALSE)
}
if (preflight_only) {
  cat(sprintf("frozen-R preflight passed: gllvmTMB %s; DLL %s\n", loaded_version, dll_path))
  quit(save = "no", status = 0L)
}

set.seed(seed)
n_tips <- 8L
n_traits <- 3L
reps <- 2L
trait_names <- c("a", "b", "c")
tree <- ape::rcoal(n_tips)
tree$tip.label <- paste0("sp", seq_len(n_tips))
if (!ape::is.ultrametric(tree)) stop("fixed-seed tree must be ultrametric", call. = FALSE)
tip_order <- tree$tip.label
A_original <- ape::vcv(tree, corr = TRUE)[tip_order, tip_order, drop = FALSE]
if (!identical(rownames(A_original), tip_order) ||
    !identical(colnames(A_original), tip_order) ||
    !all(diag(A_original) == 1)) {
  stop("original A must be a named unit-diagonal tip correlation matrix", call. = FALSE)
}
A_ridged <- A_original + diag(ridge, n_tips)

beta_true <- c(0.4, -0.2, 0.3)
loading_true <- c(0.9, 0.5, -0.6)
sigma_eps_true <- 0.25
g_species <- as.numeric(t(chol(A_original)) %*% rnorm(n_tips))
names(g_species) <- tip_order
eta <- outer(rep(1, n_tips), beta_true) + outer(g_species, loading_true)
rownames(eta) <- tip_order

long_rows <- vector("list", n_tips * n_traits * reps)
long_index <- 1L
for (species in tip_order) {
  for (trait_index in seq_len(n_traits)) {
    for (replicate in seq_len(reps)) {
      long_rows[[long_index]] <- data.frame(
        species = species,
        trait = trait_names[[trait_index]],
        replicate = replicate,
        value = eta[species, trait_index] + rnorm(1L, sd = sigma_eps_true),
        stringsAsFactors = FALSE
      )
      long_index <- long_index + 1L
    }
  }
}
df <- do.call(rbind, long_rows)
df$species <- factor(df$species, levels = tip_order)
df$trait <- factor(df$trait, levels = trait_names)

# Julia columns are ordered species outer, replicate inner. The mapping below
# is exported for every original long-format row, rather than inferred from
# factor levels on the consumer side.
observation_order <- do.call(rbind, lapply(seq_along(tip_order), function(i) {
  data.frame(species = tip_order[[i]], replicate = seq_len(reps),
             species_index_one_based = i, stringsAsFactors = FALSE)
}))
Y <- matrix(NA_real_, nrow = n_traits, ncol = nrow(observation_order),
            dimnames = list(trait_names, NULL))
for (observation_index in seq_len(nrow(observation_order))) {
  for (trait_index in seq_len(n_traits)) {
    selected <- which(as.character(df$species) == observation_order$species[[observation_index]] &
                        df$replicate == observation_order$replicate[[observation_index]] &
                        as.character(df$trait) == trait_names[[trait_index]])
    if (length(selected) != 1L) stop("long-to-matrix response mapping is not one-to-one", call. = FALSE)
    Y[trait_index, observation_index] <- df$value[[selected]]
  }
}
observation_key <- paste(observation_order$species, observation_order$replicate, sep = "\r")
long_to_matrix <- data.frame(
  long_row_one_based = seq_len(nrow(df)),
  species = as.character(df$species),
  replicate = as.integer(df$replicate),
  trait = as.character(df$trait),
  trait_index_one_based = match(as.character(df$trait), trait_names),
  observation_index_one_based = match(paste(as.character(df$species), df$replicate, sep = "\r"), observation_key),
  stringsAsFactors = FALSE
)
if (anyNA(long_to_matrix$observation_index_one_based) ||
    any(vapply(seq_len(nrow(long_to_matrix)), function(i) {
      Y[long_to_matrix$trait_index_one_based[[i]], long_to_matrix$observation_index_one_based[[i]]] != df$value[[i]]
    }, logical(1L)))) {
  stop("exported long-to-matrix mapping does not reproduce Y", call. = FALSE)
}

fit_warnings <- list()
fit_started <- Sys.time()
writeLines(c(
  sprintf("started_utc=%s", format(fit_started, tz = "UTC", usetz = TRUE)),
  sprintf("library_dir=%s", library_dir),
  sprintf("dll_path=%s", dll_path),
  sprintf("dll_sha256=%s", dll_sha256),
  "status=fit_started"
), attempt_log)
append_attempt_log <- function(line) cat(paste0(line, "\n"), file = attempt_log, append = TRUE)
persist_attempt <- function(payload) saveRDS(payload, attempt_rds)
fit <- tryCatch(
  withCallingHandlers(
    gllvmTMB(
      value ~ 0 + trait + phylo_latent(species, d = 1, vcv = A_original),
      data = df,
      trait = "trait",
      unit = "species",
      cluster = "species",
      family = gaussian(),
      REML = FALSE,
      engine = "tmb",
      control = gllvmTMBcontrol(n_init = 1L,
        optArgs = list(control = list(iter.max = 80, eval.max = 120)))
    ),
    warning = function(w) {
      receipt <- list(message = conditionMessage(w), class = class(w))
      fit_warnings[[length(fit_warnings) + 1L]] <<- receipt
      append_attempt_log(sprintf("warning=%s", receipt$message))
    }
  ),
  error = function(e) {
    append_attempt_log(sprintf("status=fit_error; message=%s", conditionMessage(e)))
    persist_attempt(list(
      status = "fit_error", error = conditionMessage(e), warnings = fit_warnings,
      seed = seed, library_dir = library_dir, dll_path = dll_path, dll_sha256 = dll_sha256,
      started_utc = format(fit_started, tz = "UTC", usetz = TRUE)
    ))
    stop(e)
  }
)
fit_elapsed_seconds <- as.numeric(difftime(Sys.time(), fit_started, units = "secs"))
if (is.null(fit$tmb_obj)) stop("fit did not retain a marginal tmb_obj", call. = FALSE)
append_attempt_log(sprintf("status=fit_returned; elapsed_seconds=%.6f", fit_elapsed_seconds))
persist_attempt(list(
  status = "fit_returned_before_assertions", warnings = fit_warnings,
  elapsed_seconds = fit_elapsed_seconds, tmb_data = fit$tmb_data,
  tmb_params = fit$tmb_params, tmb_map = fit$tmb_map, optimizer = fit$opt,
  seed = seed, library_dir = library_dir, dll_path = dll_path, dll_sha256 = dll_sha256
))

# This is the marginal/Laplace TMB object built by gllvmTMB. Gaussian
# integration is exact here. Do not use MakeADFun(random = NULL): that is the
# historical joint-score target and has a different parameter vector.
marginal_obj <- fit$tmb_obj
fit <- gllvmTMB::standard_errors(fit)
sd <- fit$sd_report
stopifnot(isTRUE(sd$pdHess), all(is.finite(sd$cov.fixed)),
          identical(names(sd$par.fixed), names(fit$opt$par)),
          identical(unname(sd$par.fixed), unname(fit$opt$par)))
public_vcov <- stats::vcov(fit)
stopifnot(all(public_vcov == sd$cov.fixed[1:3,1:3]))
uncertainty <- list(method = "frozen production sdreport cov.fixed",
  parameter_names = names(sd$par.fixed), parameter_values = unname(sd$par.fixed),
  covariance = as_json_rows(sd$cov.fixed), public_beta_vcov = as_json_rows(public_vcov),
  pd_hessian = sd$pdHess, condition_number = kappa(sd$cov.fixed, exact = TRUE))
active_names <- names(marginal_obj$par)
expected_counts <- c(b_fix = 3L, log_sigma_eps = 1L, theta_rr_phy = 3L)
if (any(!active_names %in% names(expected_counts))) {
  stop(sprintf("unexpected active marginal parameter blocks: %s",
               paste(unique(active_names[!active_names %in% names(expected_counts)]), collapse = ", ")),
       call. = FALSE)
}
active_counts <- vapply(names(expected_counts), function(block) sum(active_names == block), integer(1L))
if (!identical(active_counts, expected_counts)) {
  stop(sprintf("active marginal block counts are [%s], expected [b_fix=3, log_sigma_eps=1, theta_rr_phy=3]",
               paste(sprintf("%s=%d", names(active_counts), active_counts), collapse = ", ")),
       call. = FALSE)
}
if (any(grepl("phi|disp|theta_rr_B|theta_diag_B|g_phy|s_B|z_B", active_names))) {
  stop("Gaussian loadings-only marginal objective contains a forbidden ordinary/unique/dispersion block",
       call. = FALSE)
}

beta_theta <- c(0.4, -0.2, 0.3)
log_sigma_eps_theta <- log(0.3)
theta_rr_phy_theta <- c(0.9, 0.5, -0.6)
theta <- numeric(length(marginal_obj$par))
theta[active_names == "b_fix"] <- beta_theta
theta[active_names == "log_sigma_eps"] <- log_sigma_eps_theta
theta[active_names == "theta_rr_phy"] <- theta_rr_phy_theta
if (!all(is.finite(theta))) stop("explicit marginal theta is not finite", call. = FALSE)
marginal_nll <- marginal_obj$fn(theta)
marginal_nll_repeat <- marginal_obj$fn(theta)
if (!is.finite(marginal_nll) || !identical(marginal_nll, marginal_nll_repeat)) {
  stop("marginal tmb_obj$fn(theta) must be finite and repeat-identical", call. = FALSE)
}

Q_canonical <- as.matrix(fit$tmb_data$Ainv_phy_rr)
log_det_A_phy_rr <- as.numeric(fit$tmb_data$log_det_A_phy_rr)
if (!identical(dim(Q_canonical), c(n_tips, n_tips)) ||
    max(abs(Q_canonical - solve(A_ridged))) > 1e-6) {
  stop("canonical engine Q does not equal the documented inverse(A + 1e-8 I)", call. = FALSE)
}
tmb_long_species_id_zero_based <- as.integer(fit$tmb_data$species_id)
tmb_long_species_aug_id_zero_based <- as.integer(fit$tmb_data$species_aug_id)
engine_y <- as.numeric(fit$tmb_data$y)
engine_trait_id_zero_based <- as.integer(fit$tmb_data$trait_id)
if (length(tmb_long_species_id_zero_based) != nrow(df) ||
    length(tmb_long_species_aug_id_zero_based) != nrow(df) ||
    length(engine_y) != nrow(df) || length(engine_trait_id_zero_based) != nrow(df)) {
  stop("TMB long-format species maps have an unexpected length", call. = FALSE)
}
input_species_id_zero_based <- as.integer(df$species) - 1L
input_trait_id_zero_based <- as.integer(df$trait) - 1L
engine_long_to_original_long_row_one_based <- vapply(seq_len(nrow(df)), function(engine_row) {
  candidate <- which(
    input_species_id_zero_based == tmb_long_species_id_zero_based[[engine_row]] &
      input_trait_id_zero_based == engine_trait_id_zero_based[[engine_row]] &
      abs(df$value - engine_y[[engine_row]]) <= 16 * .Machine$double.eps *
        max(1, abs(engine_y[[engine_row]]))
  )
  if (length(candidate) != 1L) {
    stop("could not determine a one-to-one TMB long-row permutation against df", call. = FALSE)
  }
  as.integer(candidate[[1L]])
}, integer(1L))
expected_mean_design <- stats::model.matrix(~ 0 + trait, data = df)
engine_mean_design <- as.matrix(fit$tmb_data$X_fix)
expected_engine_design <- expected_mean_design[
  engine_long_to_original_long_row_one_based, , drop = FALSE]
if (!identical(dim(engine_mean_design), dim(expected_engine_design)) ||
    any(engine_mean_design != expected_engine_design)) {
  stop("TMB fixed-effect design differs from the declared trait-intercept design",
       call. = FALSE)
}
tip_to_aug_zero_based <- vapply(0:(n_tips - 1L), function(species_zero_based) {
  values <- unique(tmb_long_species_aug_id_zero_based[
    tmb_long_species_id_zero_based == species_zero_based])
  if (length(values) != 1L) stop("a tip does not have one canonical augmented-node map", call. = FALSE)
  as.integer(values[[1L]])
}, integer(1L))
node_labels <- rownames(Q_canonical)
if (is.null(node_labels)) node_labels <- tip_order
if (length(node_labels) != nrow(Q_canonical) || any(!nzchar(node_labels))) {
  stop("canonical Q node labels are missing or misaligned", call. = FALSE)
}
matrix_species_id_zero_based <- as.integer(observation_order$species_index_one_based - 1L)
matrix_species_aug_id_zero_based <- tip_to_aug_zero_based[matrix_species_id_zero_based + 1L]

fitted_theta <- fit$opt$par
fitted_names <- names(fitted_theta)
if (is.null(fitted_names) || any(!fitted_names %in% names(expected_counts))) {
  stop("optimizer fixed parameter receipt has unexpected active blocks", call. = FALSE)
}
fitted_counts <- vapply(names(expected_counts), function(block) sum(fitted_names == block), integer(1L))
if (!identical(fitted_counts, expected_counts)) {
  stop("optimizer fixed parameter receipt does not have the required b_fix/log_sigma_eps/theta_rr_phy blocks",
       call. = FALSE)
}
fitted_marginal_nll <- marginal_obj$fn(fitted_theta)
fitted_gradient <- fit$opt$gradient
if (is.null(fitted_gradient)) fitted_gradient <- NULL else fitted_gradient <- unname(as.numeric(fitted_gradient))

receipt <- list(
  schema_version = "destination-b-phylo-gaussian-marginal-1",
  provenance = list(
    frozen_source_pin = expected_source_pin,
    source_pin_reference = "docs/dev-log/decisions/destination-b-phylo-shared-residual.md",
    expected_package_version = expected_version,
    library_dir = library_dir,
    package_path = package_path,
    dll_path = dll_path,
    dll_sha256 = dll_sha256,
    expected_dll_sha256 = expected_dll_sha256,
    session_info = paste(capture.output(sessionInfo()), collapse = "\n")
  ),
  fixture = list(
    seed = seed, n_traits = n_traits, n_tips = n_tips, reps = reps,
    trait_names = trait_names, tip_order = tip_order,
    observation_order_species_then_replicate = observation_order,
    long_to_matrix = long_to_matrix,
    tree_newick = ape::write.tree(tree)
  ),
  response = list(
    Y_traits_by_observations = as_json_rows(Y),
    shape = as.integer(dim(Y)),
    matrix_orientation = "nested trait rows x observation columns; columns are species outer then replicate inner",
    data_sha256 = float64_column_major_sha256(Y),
    data_hash_encoding = "Float64 little-endian column-major"
  ),
  source_covariance = list(
    A_original = as_json_rows(A_original),
    A_ridged = as_json_rows(A_ridged),
    ridge = ridge,
    ridge_operation = "A_ridged = A_original + 1e-8 * I; Q_canonical = solve(A_ridged)",
    condition_number_original = condition_number_symmetric(A_original),
    condition_number_ridged = condition_number_symmetric(A_ridged)
  ),
  precision = list(
    Q_canonical = as_json_rows(Q_canonical),
    n_aug = as.integer(nrow(Q_canonical)),
    n_tips = n_tips,
    node_labels = unname(node_labels),
    species_aug_id_by_tip_zero_based = unname(tip_to_aug_zero_based),
    matrix_observation_species_id_zero_based = unname(matrix_species_id_zero_based),
    matrix_observation_species_aug_id_zero_based = unname(matrix_species_aug_id_zero_based),
    tmb_long_species_id_zero_based = unname(tmb_long_species_id_zero_based),
    tmb_long_species_aug_id_zero_based = unname(tmb_long_species_aug_id_zero_based),
    engine_long_to_original_long_row_one_based = unname(engine_long_to_original_long_row_one_based),
    log_det_Q = -log_det_A_phy_rr,
    log_det_A_phy_rr = log_det_A_phy_rr,
    scale = 1.0
  ),
  matched_theta = list(
    active_parameter_names = unname(active_names),
    values = unname(theta),
    blocks = list(
      b_fix = beta_theta,
      log_sigma_eps = log_sigma_eps_theta,
      theta_rr_phy = theta_rr_phy_theta
    ),
    beta = beta_theta,
    loading_rank1 = theta_rr_phy_theta,
    log_sd_residual = log_sigma_eps_theta,
    marginal_nll = marginal_nll,
    marginal_nll_repeat_identical = identical(marginal_nll, marginal_nll_repeat)
  ),
  fitted_r = list(
    active_parameter_names = unname(fitted_names),
    values = unname(as.numeric(fitted_theta)),
    blocks = list(
      b_fix = named_block(fitted_theta, fitted_names, "b_fix"),
      log_sigma_eps = named_block(fitted_theta, fitted_names, "log_sigma_eps"),
      theta_rr_phy = named_block(fitted_theta, fitted_names, "theta_rr_phy")
    ),
    marginal_nll = fitted_marginal_nll,
    convergence = fit$opt$convergence,
    message = fit$opt$message,
    counts = fit$opt$evaluations,
    optimizer_objective = fit$opt$objective,
    gradient_if_available = fitted_gradient,
    elapsed_seconds = fit_elapsed_seconds,
    warnings = fit_warnings
  ),
  assertions = list(
    active_block_counts = as.list(active_counts),
    fitted_block_counts = as.list(fitted_counts),
    no_ordinary_or_unique_or_dispersion_blocks = TRUE,
    canonical_precision_matches_ridged_A = TRUE,
    mean_design_matches_trait_intercepts = TRUE,
    marginal_objective_not_joint_random_null = TRUE
  )
)

pending_json <- file.path(output_dir, "phylo_gaussian_reference.pending.json")
jsonlite::write_json(receipt, pending_json, auto_unbox = TRUE, pretty = TRUE,
                     digits = 17L, na = "null", null = "null")
# digits=NA is not lossless in jsonlite: a 1/3 and pi probe changed Float64
# bits. Validate the actual exported data before publishing the reference file.
decoded <- jsonlite::fromJSON(pending_json, simplifyVector = FALSE)
decoded_Y <- do.call(rbind, lapply(decoded$response$Y_traits_by_observations,
                                 function(row) as.numeric(unlist(row))))
if (!identical(unname(Y), unname(decoded_Y)) ||
    !identical(float64_column_major_sha256(decoded_Y), receipt$response$data_sha256)) {
  append_attempt_log("status=transport_error; response JSON changed Float64 values or hash")
  stop("reference JSON response failed exact Float64/hash round-trip; pending artifact retained",
       call. = FALSE)
}
if (!file.rename(pending_json, output_json)) {
  stop("could not publish validated reference JSON; pending artifact retained", call. = FALSE)
}
append_attempt_log("status=reference_export_validated")
sidecar <- list(schema_version = "destination-b-dense-uncertainty-1",
  reference_sha256 = unname(tools::sha256sum(output_json))[[1L]],
  data_sha256 = receipt$response$data_sha256, dll_sha256 = dll_sha256,
  uncertainty = uncertainty,
  gradient = unname(as.numeric(marginal_obj$gr(fitted_theta))),
  qualified = FALSE)
jsonlite::write_json(sidecar, uncertainty_json, auto_unbox = TRUE,
  pretty = TRUE, digits = 17L, null = "null", na = "null")
cat(sprintf("wrote frozen marginal phylogenetic Gaussian reference: %s\n", output_json))
