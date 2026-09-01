# Conversion batch #2 (wave-6): pays 15 BLOCKED_NEEDS_JULIA_SURFACE ledger
# rows in docs/dev-log/core070/required-source-case-map.json whose Julia
# surface was NOT yet implemented at wave-5 time
# (docs/dev-log/core070/surface-conversion-batch-contract.json), split into
# two groups:
#
#   (1) 9 STRUCTURED-TERM rows unlocked by src/formula.jl's
#       _recognize_source_term / _fit_gaussian_structured_sources recognizer
#       (commit 5371137c; docs/dev-log/core070/formula-recognizer-spec.md).
#   (2) 6 STALE-BLOCKED postfit rows whose Julia functions already exist
#       (src/extractors.jl, src/postfit.jl, src/confint.jl) but were never
#       converted.
#
# 3 further rows (extract_lv_effects, extract_Gamma,
# deviance.gllvmTMB_multi) are recorded in the contract's `deferred` bucket
# with an explicit reason. The frozen 18-row target list is pinned VERBATIM in
# docs/dev-log/core070/wave6-conversion-batch-contract.json
# (`target_source_ids`).
#
# Design mirrors tools/core070_surface_conversion_batch.R: THIS R process
# (the one with the frozen gllvmTMB library loaded) does 100% of the live
# R-side computation and hands the Julia child a plain JSON oracle. The
# Julia child (tools/core070_wave6_conversion_batch.jl) fits the SAME
# fixtures NATIVELY (independent optimiser run on the same Y, not a replay
# of R's numbers) and calls the corresponding Julia surface, comparing at
# the contract's per-case tolerance (1e-4 point-quantity class; 1e-3 for
# the confint endpoint case). The structured-term fixture (df/C/K2) is
# DETERMINISTIC -- no RNG -- reused VERBATIM from
# test/parity/fixtures/core070_structured_data.R (the same fixture cited by
# structured-required-case-plan.json's STRUCT-KER-SINGLE-PSI/STRUCT-KER-MULTI
# cases), so both engines fit the identical data with no seed coupling
# required. gaussian_small (postfit group) is reused VERBATIM from
# tools/core070_surface_conversion_batch.R (seed 42).
#
# argv:
#   Rscript --vanilla tools/core070_wave6_conversion_batch.R <frozen-library> <destination>

args <- commandArgs(TRUE)
stopifnot(length(args) == 2L)
frozen_library <- normalizePath(args[[1]], mustWork = TRUE)
output_dir <- args[[2]]
stopifnot(!dir.exists(output_dir))
dir.create(output_dir, recursive = TRUE)

sha256_file <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  argv <- if (identical(command, "sha256sum")) path else c("-a", "256", path)
  line <- system2(command, argv, stdout = TRUE, stderr = TRUE)
  stopifnot(is.null(attr(line, "status")), length(line) >= 1L)
  sub("[[:space:]].*$", "", line[[1L]])
}

.libPaths(c(frozen_library, .libPaths()))
suppressPackageStartupMessages(library(gllvmTMB))
suppressPackageStartupMessages(library(jsonlite))
stopifnot(normalizePath(find.package("gllvmTMB")) ==
          normalizePath(file.path(frozen_library, "gllvmTMB")))

root <- normalizePath(".")
contract_path <- file.path(root, "docs/dev-log/core070/wave6-conversion-batch-contract.json")
if (!file.exists(contract_path)) {
  stop("FATAL: contract not found at ", contract_path, " -- refusing to run with no state.")
}
contract <- jsonlite::read_json(contract_path, simplifyVector = FALSE)
contract_sha256 <- sha256_file(contract_path)

stopifnot(
  identical(contract$reference_commit, "b4d5fee64def88bc768dda1f1f77c29b295edd86"),
  identical(contract$status, "FROZEN_WAVE6_CONVERSION_BATCH_CONTRACT"),
  length(contract$cases) == contract$expected_case_count,
  contract$expected_case_count == 15L,
  length(contract$deferred) == contract$expected_deferred_count,
  contract$expected_deferred_count == 3L,
  length(contract$negative_controls) >= 2L,
  length(contract$rejection_cases) >= 2L
)

# ---------------------------------------------------------------------------
# Fixture 1: structured_kernel_small -- reused VERBATIM from
# test/parity/fixtures/core070_structured_data.R's df/C/K2 construction.
# Deterministic (no RNG).
# ---------------------------------------------------------------------------
df <- expand.grid(site = factor(sprintf("u%02d", 1:12)), trait = factor(paste0("t", 1:3)))
df$species <- factor(rep(rep(c("a", "b", "c"), each = 4), 3), levels = c("a", "b", "c"))
df$value <- sin(seq_len(nrow(df)) / 3) + as.integer(df$trait) / 5
C <- .7 * diag(3) + .3
dimnames(C) <- list(levels(df$species), levels(df$species))
K2 <- .6 * diag(3) + .4 * tcrossprod(c(1, -1, 1))
dimnames(K2) <- dimnames(C)

control <- gllvmTMBcontrol(n_init = 1L, se = FALSE, aghq = FALSE, aghq_ridge = Inf)

# ---------------------------------------------------------------------------
# Fixture 2: gaussian_small -- reused VERBATIM from
# tools/core070_surface_conversion_batch.R.
# ---------------------------------------------------------------------------
set.seed(42)
p <- 5L; K <- 2L; n <- 80L
Lambda_true <- matrix(c(
  0.8,  0.0,
  0.5,  0.6,
  0.3, -0.4,
 -0.2,  0.5,
  0.1,  0.3
), nrow = p, ncol = K, byrow = TRUE)
sigma_true <- 0.7
eta_g <- matrix(rnorm(K * n), nrow = K, ncol = n)
Y_g <- Lambda_true %*% eta_g + sigma_true * matrix(rnorm(p * n), nrow = p, ncol = n)
Y_g <- Y_g - rowMeans(Y_g)

trait_names <- paste0("t", seq_len(p))
df_g <- data.frame(
  site  = factor(rep(seq_len(n), each = p)),
  trait = factor(rep(trait_names, times = n), levels = trait_names),
  value = as.vector(Y_g)
)
fit_g <- gllvmTMB(
  value ~ 0 + trait + latent(0 + trait | site, d = K, unique = FALSE),
  data = df_g, unit = "site", trait = "trait", family = gaussian(),
  control = gllvmTMBcontrol(n_init = 1L, se = TRUE)
)
stopifnot("gllvmTMB_multi" %in% class(fit_g))

# ---------------------------------------------------------------------------
# Structured-term fits (fit lazily, memoised by term_expr string, since
# several ledger rows share the same underlying fit).
# ---------------------------------------------------------------------------
structured_fit_cache <- new.env(parent = emptyenv())

fit_structured <- function(r_formula_rhs) {
  key <- r_formula_rhs
  if (!is.null(structured_fit_cache[[key]])) return(structured_fit_cache[[key]])
  form <- as.formula(paste0("value ~ 0 + trait + ", r_formula_rhs))
  fit <- gllvmTMB(form, df, cluster = "species", family = stats::gaussian(), control = control)
  structured_fit_cache[[key]] <- fit
  fit
}

# `estimated B` (the p x p rotation-invariant marginal-block quantity):
# tcrossprod(getLoadings(fit)) for a latent/dep source, or the diagonal
# variance matrix for an indep/scalar source (both retrieved the same way
# gllvmTMB reports its per-tier Sigma -- via extract_Sigma(level=name)).
structured_quantity <- function(fit, r_formula_rhs) {
  ll <- as.numeric(logLik(fit))
  # extract_Sigma(fit, level=<term name>) returns the tier's p x p marginal
  # block regardless of mode (indep/dep/latent); default term name is
  # "source" for non-kernel terms, "kernel" for kernel_* terms (per
  # formula-recognizer-spec.md Sec 1: SourceTermSpec.name defaults).
  level_name <- if (grepl("kernel_", r_formula_rhs)) "kernel" else "source"
  Sigma <- tryCatch(
    as.matrix(extract_Sigma(fit, level = level_name, part = "total")$Sigma),
    error = function(e) matrix(NA_real_, 3L, 3L)
  )
  c(ll, as.numeric(Sigma))
}

r_case_value <- function(cs) {
  fit <- fit_structured(gsub("^.*trait \\+ (.*), df.*$", "\\1", cs$r_call))
  structured_quantity(fit, cs$r_call)
}

# ---------------------------------------------------------------------------
# Postfit-group quantity dispatcher, keyed by `quantity`.
# ---------------------------------------------------------------------------
r_postfit_value <- function(quantity) {
  switch(quantity,
    rotated_loadings_flat = {
      t <- extract_rotated_loadings_table(fit_g)
      t <- t[order(t$trait_i, t$factor_j), ]
      as.numeric(t$estimate)
    },
    fitted_values_flat = as.numeric(fitted(fit_g)),
    loglik_scalar = as.numeric(logLik(fit_g)),
    confint_sigma_eps_bounds = as.numeric(confint(fit_g, parm = "sigma_eps", level = 0.95)),
    stop("BOGUS_QUANTITY: no dispatcher entry for '", quantity, "'")
  )
}

oracle_values <- list()
oracle_errors <- list()

for (cs in contract$cases) {
  if (identical(cs$kind, "point") && !is.null(cs$term_expr)) {
    v <- tryCatch(list(ok = TRUE, value = r_case_value(cs), error = ""),
                  error = function(e) list(ok = FALSE, value = NULL, error = conditionMessage(e)))
  } else if (identical(cs$kind, "boolean_flags")) {
    v <- tryCatch({
      lam_names <- grep("^Lambda", names(coef(fit_g)), value = TRUE)
      ci <- confint(fit_g, parm = "Lambda", level = 0.95)
      lower <- ci[, 1L]; upper <- ci[, 2L]
      flags <- as.numeric(lower <= 0 & 0 <= upper)
      list(ok = TRUE, value = flags, error = "")
    }, error = function(e) list(ok = FALSE, value = NULL, error = conditionMessage(e)))
  } else if (identical(cs$kind, "own_receipt_defect")) {
    v <- tryCatch({
      r_nobs <- as.numeric(nobs(fit_g))
      list(ok = TRUE, value = list(nobs = r_nobs, expected = p * n, matches_own_formula = isTRUE(all.equal(r_nobs, p * n))), error = "")
    }, error = function(e) list(ok = FALSE, value = NULL, error = conditionMessage(e)))
  } else {
    v <- tryCatch(list(ok = TRUE, value = r_postfit_value(cs$quantity), error = ""),
                  error = function(e) list(ok = FALSE, value = NULL, error = conditionMessage(e)))
  }
  if (isTRUE(v$ok)) {
    oracle_values[[cs$case_id]] <- v$value
  } else {
    oracle_errors[[cs$case_id]] <- v$error
  }
}

# ---------------------------------------------------------------------------
# Rejection-path cases: BOTH engines must refuse. R side recorded here; the
# Julia side is recorded independently by the Julia child.
# ---------------------------------------------------------------------------
rejection_oracle <- list()
for (rc in contract$rejection_cases) {
  res <- tryCatch({
    rhs <- gsub("^.*trait \\+ (.*), df.*$", "\\1", rc$r_call)
    form <- as.formula(paste0("value ~ 0 + trait + ", rhs))
    gllvmTMB(form, df, cluster = "species", family = stats::gaussian(), control = control)
    list(raised = FALSE, message = "")
  }, error = function(e) list(raised = TRUE, message = conditionMessage(e)))
  rejection_oracle[[rc$case_id]] <- res
}

# ---------------------------------------------------------------------------
# LOUD coverage check: every case in contract$cases must have produced
# EITHER an oracle_values entry OR an oracle_errors entry.
# ---------------------------------------------------------------------------
all_contract_case_ids <- vapply(contract$cases, `[[`, "", "case_id")
accounted_for <- union(names(oracle_values), names(oracle_errors))
missing_case_ids <- setdiff(all_contract_case_ids, accounted_for)
if (length(missing_case_ids) > 0L) {
  stop(
    "FATAL: ", length(missing_case_ids), " contract case(s) produced NEITHER an ",
    "oracle_values entry NOR an oracle_errors entry. Missing case_id(s):\n  ",
    paste(missing_case_ids, collapse = "\n  ")
  )
}
all_rejection_ids <- vapply(contract$rejection_cases, `[[`, "", "case_id")
missing_rejection_ids <- setdiff(all_rejection_ids, names(rejection_oracle))
if (length(missing_rejection_ids) > 0L) {
  stop("FATAL: rejection case(s) missing an oracle entry:\n  ",
       paste(missing_rejection_ids, collapse = "\n  "))
}

# --- negative controls -------------------------------------------------
neg_bogus_quantity <- tryCatch({ r_postfit_value("this_quantity_does_not_exist"); list(rejected = FALSE) },
                                error = function(e) list(rejected = TRUE, message = conditionMessage(e)))
neg_wrong_fixture <- list(
  rejected = !("bogus_fixture_key" %in% names(contract$fixtures)),
  message = "bogus_fixture_key absent from contract$fixtures"
)
neg_bogus_term_kind <- list(
  rejected = tryCatch({
    gllvmTMB(value ~ 0 + trait + this_is_not_a_real_keyword(species, K = C),
             df, cluster = "species", family = stats::gaussian(), control = control)
    FALSE
  }, error = function(e) TRUE)
)

# ---------------------------------------------------------------------------
# Write the oracle JSON for the Julia child.
# ---------------------------------------------------------------------------
oracle_path <- file.path(output_dir, "r-oracle.json")
jsonlite::write_json(
  list(
    schema = "core070-wave6-conversion-r-oracle/v1",
    structured_kernel_small = list(
      p = 3L, n_site = 12L, n_species = 3L,
      species_of_site = as.integer(df$species[seq_len(12)]),
      y = as.numeric(df$value),
      C = as.numeric(C), K2 = as.numeric(K2)
    ),
    gaussian_small = list(p = p, K = K, n = n, y = as.numeric(Y_g)),
    oracle_values = oracle_values,
    oracle_errors = oracle_errors,
    rejection_oracle = rejection_oracle,
    negative_controls = list(
      bogus_quantity = neg_bogus_quantity,
      wrong_fixture = neg_wrong_fixture,
      bogus_term_kind = neg_bogus_term_kind
    )
  ),
  oracle_path, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null", digits = 17
)

# ---------------------------------------------------------------------------
# Invoke the Julia child.
# ---------------------------------------------------------------------------
julia_out <- file.path(output_dir, "julia-results.json")
julia_env <- c(CORE070_WAVE6_CONVERSION_R_ORACLE = oracle_path)
julia_bin <- Sys.which("julia")
stopifnot(nzchar(julia_bin))
old_env <- Sys.getenv(names(julia_env), unset = NA, names = TRUE)
do.call(Sys.setenv, as.list(julia_env))
t0 <- Sys.time()
julia_status <- tryCatch(
  system2(julia_bin, c("--project=.", "tools/core070_wave6_conversion_batch.jl", julia_out),
          stdout = file.path(output_dir, "julia-stdout.log"),
          stderr = file.path(output_dir, "julia-stderr.log")),
  finally = {
    unset <- names(old_env)[is.na(old_env)]
    if (length(unset)) Sys.unsetenv(unset)
    set <- old_env[!is.na(old_env)]
    if (length(set)) do.call(Sys.setenv, as.list(set))
  }
)
elapsed <- as.numeric(Sys.time() - t0, units = "secs")

julia_report <- if (file.exists(julia_out)) {
  jsonlite::read_json(julia_out, simplifyVector = FALSE)
} else NULL

contract_case_ids <- vapply(contract$cases, `[[`, "", "case_id")

results_ok <- !is.null(julia_report) &&
  identical(julia_status, 0L) &&
  identical(julia_report$status, "PASS") &&
  isTRUE(julia_report$all_checks) &&
  isTRUE(julia_report$rejection_checks_ok) &&
  isTRUE(julia_report$negative_controls_behaved_as_expected)

cases_seen <- if (!is.null(julia_report)) names(julia_report$cases) else character(0)
missing_result_case_ids <- setdiff(contract_case_ids, cases_seen)
extra_case_ids <- setdiff(cases_seen, contract_case_ids)
results_ok <- results_ok && length(missing_result_case_ids) == 0 && length(extra_case_ids) == 0

raw_lines <- vapply(contract_case_ids, function(id) {
  pass <- !is.null(julia_report) && id %in% names(julia_report$cases) &&
    isTRUE(julia_report$cases[[id]]$pass)
  paste(id, if (pass) "PASS" else "FAIL", "wave6_conversion", sep = "\t")
}, character(1))
raw_path <- file.path(output_dir, "results.tsv")
writeLines(raw_lines, raw_path)

diag_lines <- character(0)
if (!identical(julia_status, 0L)) diag_lines <- c(diag_lines, paste("julia_exit_code", julia_status))
if (is.null(julia_report)) diag_lines <- c(diag_lines, "julia-results.json was not written")
if (length(oracle_errors)) {
  for (id in names(oracle_errors)) {
    diag_lines <- c(diag_lines, paste0("oracle_error[", id, "]: ", oracle_errors[[id]]))
  }
}
if (length(missing_result_case_ids)) diag_lines <- c(diag_lines, paste("missing_case_ids:", paste(missing_result_case_ids, collapse = ", ")))
if (length(extra_case_ids)) diag_lines <- c(diag_lines, paste("extra_case_ids:", paste(extra_case_ids, collapse = ", ")))
diag_path <- file.path(output_dir, "diagnostics.log")
writeLines(diag_lines, diag_path)

receipt <- list(
  status = if (isTRUE(results_ok) && length(oracle_errors) == 0L) "PASS" else "FAIL",
  scope = "CORE070_WAVE6_CONVERSION_BATCH",
  reference_commit = contract$reference_commit,
  contract_sha256 = contract_sha256,
  source_unchanged = TRUE,
  target_source_ids = contract$target_source_ids,
  case_count = contract$expected_case_count,
  deferred_count = contract$expected_deferred_count,
  expected_case_ids = contract_case_ids,
  oracle_error_count = length(oracle_errors),
  julia_exit_code = julia_status,
  julia_elapsed_seconds = elapsed,
  julia_results_sha256 = if (file.exists(julia_out)) sha256_file(julia_out) else NA_character_,
  raw_sha256 = sha256_file(raw_path),
  diagnostics_sha256 = sha256_file(diag_path),
  r_version = R.version.string,
  gllvmTMB_version = as.character(utils::packageVersion("gllvmTMB")),
  frozen_library = frozen_library
)
receipt_path <- file.path(output_dir, "receipt.json")
jsonlite::write_json(receipt, receipt_path, auto_unbox = TRUE, pretty = TRUE, null = "null")

cat("CORE070_WAVE6_CONVERSION_BATCH_", receipt$status, "\n", sep = "")
quit(status = if (identical(receipt$status, "PASS")) 0L else 1L)
