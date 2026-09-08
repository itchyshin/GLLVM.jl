runner <- file.path("tools", "destination_b", "run_a4_s4_tree_r_own_optimum.R")
if (!file.exists(runner)) stop("tree own-optimum runner is missing", call. = FALSE)
source(runner)

expect_error <- function(expression, label) {
  failed <- FALSE
  tryCatch(force(expression), error = function(e) failed <<- TRUE)
  if (!failed) stop(sprintf("expected rejection for %s", label), call. = FALSE)
}

build_sha <- a4_s4_tree_r_own_optimum_build_receipt_sha256
contract <- a4_s4_tree_r_own_optimum_contract()
request <- a4_s4_tree_r_own_optimum_request(build_sha)
stopifnot(identical(a4_s4_tree_r_own_optimum_validate_request(request), request),
  identical(request$row_id, "tree_height4_nonunit_ultrametric"),
  identical(request$source_pin, "b4d5fee64def88bc768dda1f1f77c29b295edd86"),
  identical(request$map$n_observations, 16L), identical(request$map$n_augmented, 14L),
  identical(request$map$observation_to_augmented_zero_based,
    request$map$species_aug_id_zero_based[request$map$species_id_one_based]),
  identical(request$precision$scale, 4),
  identical(request$precision$log_det_Q, 15.706819081565975),
  identical(request$precision$ridge, 0), identical(request$precision$ridge_applied_once, FALSE),
  identical(request$qualified, FALSE), identical(request$public_formula_admission, "closed"))

mutations <- list(
  source = function(x) { x$source_pin <- strrep("0", 40L); x },
  build = function(x) { x$build_receipt_sha256 <- strrep("a", 64L); x },
  fixture = function(x) { x$hashes$fixture <- strrep("0", 64L); x },
  reference = function(x) { x$hashes$reference <- strrep("0", 64L); x },
  precision_hash = function(x) { x$hashes$precision <- strrep("0", 64L); x },
  response = function(x) { x$hashes$response <- strrep("0", 64L); x },
  map = function(x) { x$map$observation_to_augmented_zero_based[1L] <- 0L; x },
  scale = function(x) { x$precision$scale <- 1; x },
  logdet = function(x) { x$precision$log_det_Q <- 0; x },
  ridge = function(x) { x$precision$ridge_applied_once <- TRUE; x },
  qualification = function(x) { x$qualified <- TRUE; x },
  admission = function(x) { x$public_formula_admission <- "open"; x }
)
for (label in names(mutations)) expect_error(
  a4_s4_tree_r_own_optimum_validate_request(mutations[[label]](request)), label)

theta <- setNames(c(0.1, -0.2, 0.3, -1.1, 0.7, -0.4, 0.2),
  a4_s4_tree_r_own_optimum_theta_names())
runtime <- list(r_version = "R version test", packages = list(
  TMB = list(version = "test", path = "/private/TMB", description_sha256 = strrep("c", 64L)),
  Matrix = list(version = "test", path = "/private/Matrix", description_sha256 = strrep("d", 64L)),
  ape = list(version = "test", path = "/private/ape", description_sha256 = strrep("e", 64L))))
fit <- list(reported_objective = 12.5, direct_objective = 12.5,
  optimizer = list(convergence = 0L, message = NULL, iterations = 7L, par = theta),
  gradient = list(values = rep(1e-7, 7L), l2_norm = sqrt(7e-14), infinity_norm = 1e-7),
  curvature = list(hessian = diag(7L), min_eigenvalue = 1, max_eigenvalue = 1,
    positive_definite = TRUE))
record <- list(schema_version = a4_s4_tree_r_own_optimum_schema,
  status = "r_tree_own_optimum_recorded_unqualified", request = request,
  frozen = list(package_version = "0.7.0", package_path = "/private/frozen/library/gllvmTMB",
    dll_path = "/private/frozen/library/gllvmTMB/libs/gllvmTMB.so", dll_sha256 = a4_s4_tree_r_own_optimum_dll_sha256,
    source_pin = a4_s4_tree_r_own_optimum_pin, archive_sha256 = a4_s4_tree_r_own_optimum_archive_sha256,
    namespace_sha256 = a4_s4_tree_r_own_optimum_namespace_sha256,
    source_tree_sha256 = a4_s4_tree_r_own_optimum_source_tree_sha256,
    installed_tree_sha256 = a4_s4_tree_r_own_optimum_installed_tree_sha256, marker_path = "/private/frozen/library/gllvmTMB/CORE070_SOURCE_PIN.toml",
    marker_sha256 = a4_s4_tree_r_own_optimum_marker_sha256, oracle_build_root = "/private/frozen",
    oracle_build_receipt_path = "/private/frozen/build.json", oracle_build_receipt_sha256 = build_sha,
    oracle_source_path = "/private/frozen/source", oracle_install_log_sha256 = a4_s4_tree_r_own_optimum_install_log_sha256,
    runtime = runtime, source_provenance = "verified_installed_marker"), fit = fit,
  qualified = FALSE, public_formula_admission = "closed", intervals = "not_computed",
  paired_comparison = "not_computed")
stopifnot(identical(a4_s4_tree_r_own_optimum_validate_record(record, request), record))
record_mutations <- list(
  source = function(x) { x$frozen$source_pin <- strrep("0", 40L); x },
  build = function(x) { x$frozen$oracle_build_receipt_sha256 <- strrep("0", 64L); x },
  installed_tree = function(x) { x$frozen$installed_tree_sha256 <- "not-a-digest"; x },
  marker = function(x) { x$frozen$marker_path <- "/private/other/marker"; x },
  runtime = function(x) { x$frozen$runtime$packages$TMB$description_sha256 <- "not-a-digest"; x },
  coordinate = function(x) { x$fit$optimizer$par <- x$fit$optimizer$par[-1L]; x },
  convergence = function(x) { x$fit$optimizer$convergence <- 1L; x },
  objective = function(x) { x$fit$direct_objective <- 12.6; x },
  gradient = function(x) { x$fit$gradient$values[1L] <- NaN; x },
  gradient_norm = function(x) { x$fit$gradient$infinity_norm <- 1e-4; x },
  curvature = function(x) { x$fit$curvature$hessian[1L, 1L] <- Inf; x },
  non_pd = function(x) { x$fit$curvature$positive_definite <- FALSE; x },
  nonpositive_eigen = function(x) { x$fit$curvature$min_eigenvalue <- 0; x },
  qualification = function(x) { x$qualified <- TRUE; x },
  admission = function(x) { x$public_formula_admission <- "open"; x },
  intervals = function(x) { x$intervals <- "computed"; x },
  paired = function(x) { x$paired_comparison <- "computed"; x }
)
for (label in names(record_mutations)) expect_error(
  a4_s4_tree_r_own_optimum_validate_record(record_mutations[[label]](record), request), label)

# The binding checker is exercised without fitting: it verifies the objective
# closure, integrated g_phy block, canonical precision facts, maps, response,
# and fixed design as one inseparable marginal contract.
binding_data <- data.frame(species_id = 1L, trait_id = 1L, value = 2,
  trait = factor("a", levels = c("a", "b", "c")))
binding_tmb <- list(Ainv_phy_rr = diag(14L), log_det_A_phy_rr = -request$precision$log_det_Q,
  n_aug_phy = 14L, species_id = 0L, species_aug_id = 13L, trait_id = 0L, y = 2,
  X_fix = stats::model.matrix(~ 0 + trait, data = binding_data))
binding_env <- new.env(parent = baseenv())
binding_env$data <- a4_s4_tree_r_own_optimum_tmb_canonical_data(binding_tmb)
binding_env$parameters <- list(b_fix = rep(0, 3L), log_sigma_eps = 0,
  theta_rr_phy = rep(0, 3L), g_phy = rep(0, 14L))
binding_env$DLL <- "gllvmTMB"; binding_env$random <- 8:21
binding_obj <- list(par = theta, fn = evalq(function(x) sum(x^2), binding_env), env = binding_env)
binding_fit <- list(tmb_obj = binding_obj, tmb_data = binding_tmb,
  opt = list(par = theta))
binding_inputs <- list(expected_Q = diag(14L))
a4_s4_tree_r_own_optimum_assert_fit_binding(binding_fit, binding_inputs, request, binding_data)
bad_binding_q <- binding_fit; bad_binding_q$tmb_data$Ainv_phy_rr[1L, 1L] <- 2
expect_error(a4_s4_tree_r_own_optimum_assert_fit_binding(bad_binding_q, binding_inputs, request, binding_data),
  "canonical Q binding")
bad_binding_map <- binding_fit; bad_binding_map$tmb_data$species_aug_id <- 0L
expect_error(a4_s4_tree_r_own_optimum_assert_fit_binding(bad_binding_map, binding_inputs, request, binding_data),
  "augmented map binding")
bad_binding_random <- binding_fit; bad_binding_random$tmb_obj$env$random <- 1:14
expect_error(a4_s4_tree_r_own_optimum_assert_fit_binding(bad_binding_random, binding_inputs, request, binding_data),
  "g_phy random binding")

probe <- list(status = "nonconverged_probe", elapsed_seconds = 0.01,
  reported_objective = 12.5, direct_objective = 12.5, optimizer_convergence = 1L,
  optimizer_par = theta, gradient = list(values = rep(0.1, 7L), l2_norm = sqrt(0.07), infinity_norm = 0.1))
probe_record <- list(schema_version = a4_s4_tree_r_own_optimum_schema,
  status = "r_tree_five_iteration_probe_unqualified", request = request, frozen = record$frozen,
  probe = probe, qualified = FALSE, public_formula_admission = "closed", intervals = "not_computed",
  paired_comparison = "not_computed", finality = "non_final_probe")
stopifnot(identical(a4_s4_tree_r_own_optimum_validate_probe_record(probe_record, request), probe_record))
expect_error(a4_s4_tree_r_own_optimum_validate_probe_record(transform(probe_record, finality = "final"), request),
  "probe finality")
bad_probe <- probe_record; bad_probe$probe$optimizer_par <- theta[-1L]
expect_error(a4_s4_tree_r_own_optimum_validate_probe_record(bad_probe, request), "probe coordinates")

publish_dir <- tempfile("tree-r-own-optimum-")
dir.create(publish_dir)
output <- file.path(publish_dir, "receipt.rds")
a4_s4_tree_r_own_optimum_output_fence(output)
a4_s4_tree_r_own_optimum_publish(record, output)
stopifnot(file.exists(output), identical(readRDS(output), record))
expect_error(a4_s4_tree_r_own_optimum_output_fence(output), "existing output fence")
expect_error(a4_s4_tree_r_own_optimum_publish(record, output), "no-clobber publish")

source_text <- paste(readLines(runner, warn = FALSE), collapse = "\n")
stopifnot(grepl("engine = \"tmb\"", source_text, fixed = TRUE),
  grepl("native_default_data_derived_no_external_coordinate", source_text, fixed = TRUE),
  grepl("iter.max = 5L", source_text, fixed = TRUE),
  grepl("gllvmTMBcontrol(n_init = 1L, optimizer = \"nlminb\", se = FALSE", source_text, fixed = TRUE),
  grepl("a4_s4_tree_r_own_optimum_assert_frozen_unchanged", source_text, fixed = TRUE),
  grepl("optimHess", source_text, fixed = TRUE), grepl("obj$gr", source_text, fixed = TRUE),
  !grepl("JuliaCall", source_text, fixed = TRUE), !grepl("bridge", source_text, fixed = TRUE),
  !grepl("confint", source_text, fixed = TRUE), !grepl("raw-frozen-r", source_text, fixed = TRUE),
  !grepl("readRDS", source_text, fixed = TRUE), !grepl("file.rename", source_text, fixed = TRUE),
  !grepl("pedigree", source_text, fixed = TRUE), !grepl("dense", source_text, fixed = TRUE))

cat("A4_S4_TREE_R_OWN_OPTIMUM_UNIT_OK\n")
