helper <- file.path("tools", "destination_b", "a4_s4_frozen_r_evaluator.R")
source(helper)

expect_error <- function(expression, label) {
  failed <- FALSE
  tryCatch(force(expression), error = function(error) failed <<- TRUE)
  if (!failed) stop(sprintf("expected rejection for %s", label), call. = FALSE)
}

theta <- c(b_fix = -0.2, b_fix = 0.1, b_fix = 0.3,
  log_sigma_eps = -1.1,
  theta_rr_phy = 0.7, theta_rr_phy = -0.4, theta_rr_phy = 0.2)
expected_names <- c(rep("b_fix", 3L), "log_sigma_eps", rep("theta_rr_phy", 3L))

stopifnot(identical(names(theta), expected_names))
rows <- a4_s4_frozen_r_rows()
stopifnot(identical(names(rows), c("tree", "pedigree", "dense")))

requests <- lapply(rows, function(row) {
  request <- a4_s4_frozen_r_request(row$row_id, theta)
  stopifnot(identical(a4_s4_frozen_r_validate_request(request), request),
    identical(request$family, "gaussian"),
    identical(request$public_formula_admission, "closed"),
    identical(request$qualified, FALSE),
    identical(request$r_packed_theta_names, expected_names),
    identical(request$provenance$package_version, "0.7.0"),
    identical(request$provenance$source_pin, a4_s4_frozen_r_source_pin),
    identical(request$provenance$dll_sha256, a4_s4_frozen_r_dll_sha256),
    identical(request$map$observation_to_augmented_zero_based,
      request$map$species_aug_id_zero_based[request$map$species_id_one_based]))
  dry_run <- a4_s4_frozen_r_evaluate(request, dry_run = TRUE)
  stopifnot(identical(dry_run$status, "dry_run_validated_not_evaluated"),
    identical(dry_run$evaluated, FALSE), identical(dry_run$qualified, FALSE),
    identical(dry_run$public_formula_admission, "closed"),
    identical(dry_run$r_packed_theta, request$r_packed_theta))
  request
})

expect_error(a4_s4_frozen_r_request("not-a-row", theta), "unknown row id")
expect_error(a4_s4_frozen_r_request(rows$tree$row_id, theta[-1L]), "short theta")
bad_theta_names <- theta
names(bad_theta_names)[1L] <- "beta"
expect_error(a4_s4_frozen_r_request(rows$tree$row_id, bad_theta_names), "theta names")
bad_theta_value <- theta
bad_theta_value[1L] <- Inf
expect_error(a4_s4_frozen_r_request(rows$tree$row_id, bad_theta_value), "nonfinite theta")

mutations <- list(
  row_id = function(x) { x$row_id <- rows$dense$row_id; x },
  family = function(x) { x$family <- "poisson"; x },
  source = function(x) { x$provenance$source_pin <- strrep("0", 40L); x },
  dll = function(x) { x$provenance$dll_sha256 <- strrep("0", 64L); x },
  fixture_hash = function(x) { x$provenance$fixture_file_sha256 <- strrep("0", 64L); x },
  reference_hash = function(x) { x$provenance$reference_file_sha256 <- strrep("0", 64L); x },
  precision_hash = function(x) { x$provenance$precision_source_sha256 <- strrep("0", 64L); x },
  data_hash = function(x) { x$provenance$data_sha256 <- strrep("0", 64L); x },
  map = function(x) { x$map$species_aug_id_zero_based[1L] <- 0L; x },
  coordinate = function(x) { x$r_packed_theta[1L] <- NaN; x },
  scale = function(x) { x$precision$scale <- 99; x },
  ridge = function(x) { x$precision$ridge_applied_once <- TRUE; x },
  admission = function(x) { x$public_formula_admission <- "open"; x },
  qualification = function(x) { x$qualified <- TRUE; x }
)
for (label in names(mutations)) {
  expect_error(a4_s4_frozen_r_validate_request(mutations[[label]](requests[["tree"]])), label)
}

dense_bad_ridge <- requests[["dense"]]
dense_bad_ridge$precision$ridge_operation <- "A + 1e-8 I"
expect_error(a4_s4_frozen_r_validate_request(dense_bad_ridge), "dense ridge operation")

expect_error(a4_s4_frozen_r_evaluate(requests[["tree"]], dry_run = FALSE),
  "deferred live evaluator")
expect_error(a4_s4_frozen_r_evaluate(requests[["tree"]], theta = rev(theta)),
  "arbitrary evaluator theta")
expect_error(a4_s4_frozen_r_cli(c("--evaluate", rows$tree$row_id,
  "-0.2,0.1,0.3,-1.1,0.7,-0.4,0.2")), "deferred CLI evaluator")
stopifnot(identical(names(formals(a4_s4_frozen_r_evaluate)), c("request", "dry_run")))

source_text <- paste(readLines(helper, warn = FALSE), collapse = "\n")
stopifnot(!grepl("MakeADFun", source_text, fixed = TRUE),
  !grepl("random = NULL", source_text, fixed = TRUE),
  !grepl("gllvmTMB(", source_text, fixed = TRUE),
  !grepl("readRDS", source_text, fixed = TRUE),
  !grepl("\\$tmb_obj\\$fn", source_text),
  grepl("dry_run_validated_not_evaluated", source_text, fixed = TRUE))

cat("A4_S4_FROZEN_R_EVALUATOR_OK\n")
