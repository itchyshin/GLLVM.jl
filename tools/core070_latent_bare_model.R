# Retained evidence runner for COV-ORD-LATENT-BARE.  It deliberately writes an
# incremental RDS after every route so an interrupted or failing bridge attempt
# remains inspectable.  Usage:
# Rscript --vanilla tools/core070_latent_bare_model.R <frozen-library> <input.rds> <fresh-outdir>

args <- commandArgs(TRUE)
stopifnot(length(args) == 3L)
frozen_library <- normalizePath(args[[1]], mustWork=TRUE)
input_path <- normalizePath(args[[2]], mustWork=TRUE)
output_dir <- args[[3]]
stopifnot(!dir.exists(output_dir))
dir.create(output_dir, recursive=TRUE)

sha256_file <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  argv <- if (identical(command, "sha256sum")) path else c("-a", "256", path)
  line <- system2(command, argv, stdout=TRUE, stderr=TRUE)
  stopifnot(is.null(attr(line, "status")), length(line) >= 1L)
  sub("[[:space:]].*$", "", line[[1L]])
}

plain <- function(x) {
  if (is.language(x)) return(paste(deparse(x), collapse=" "))
  if (is.list(x)) return(lapply(x, plain))
  if (is.object(x)) return(unclass(x))
  x
}

error_text <- function(e) paste(conditionMessage(e), collapse=" ")

.libPaths(c(frozen_library, .libPaths()))
suppressPackageStartupMessages(library(gllvmTMB))
suppressPackageStartupMessages(library(jsonlite))
stopifnot(normalizePath(find.package("gllvmTMB")) ==
          normalizePath(file.path(frozen_library, "gllvmTMB")))
stopifnot(requireNamespace("JuliaCall", quietly=TRUE))

root <- normalizePath(".")
contract <- jsonlite::read_json(
  file.path(root, "docs/dev-log/core070/latent-bare-model-contract.json"),
  simplifyVector=FALSE
)
negative_control_ids <- unlist(contract$negative_controls, use.names=FALSE)
input_sha256 <- sha256_file(input_path)
stopifnot(identical(input_sha256, contract$input_sha256))
input <- readRDS(input_path)
stopifnot(input$DLL == "gllvmTMB", input$data$n_traits == 3L,
          input$data$n_sites == 18L, input$data$d_B == 1L,
          input$data$use_diag_B == 0L)

Y <- matrix(NA_real_, 3L, 18L)
Y[cbind(input$data$trait_id + 1L, input$data$site_id + 1L)] <- input$data$y
stopifnot(!anyNA(Y), all(is.finite(Y)))
sha256_numeric <- function(x) {
  path <- tempfile("core070-latent-bare-", tmpdir=output_dir)
  on.exit(unlink(path), add=TRUE)
  con <- file(path, open="wb")
  writeBin(as.double(x), con, size=8L, endian="little")
  close(con)
  sha256_file(path)
}
matrix_sha256 <- sha256_numeric(Y)
fixed_point_evidence <- jsonlite::read_json(
  file.path(root, "docs/dev-log/core070/gaussian-fixed-point-evidence.json"),
  simplifyVector=FALSE
)
fixed_point_rows <- Filter(function(x) identical(x$id, "GAUSS-LOADINGS-P1") ||
                           identical(x$id, "GAUSS-LOADINGS-P2"), fixed_point_evidence$points)
fixed_point_max_delta <- max(vapply(fixed_point_rows, `[[`, numeric(1L), "abs_delta"))
fixed_point_ok <- identical(fixed_point_evidence$reference_commit, contract$reference_commit) &&
  length(fixed_point_rows) == 2L && is.finite(fixed_point_max_delta) &&
  fixed_point_max_delta <= contract$tolerances$fixed_point_abs_loglik

model_markers <- list(
  family="gaussian_identity", source_mode="rank_one_latent", source_unique=FALSE,
  residual_sd="free_common", likelihood="normalized_marginal_gaussian"
)
dimensions <- list(traits=3L, units=18L, rank=1L)
shape <- list(response_shape=c(3L, 18L), source_covariance_shape=c(18L, 18L),
              source_projection_shape=c(18L, 18L), free_coordinates=7L)
empty_route <- function(route, engine) list(
  available=FALSE, error="NOT_RUN", warnings=character(), engine=engine,
  class="", route=route, converged=FALSE, code=NA_integer_, gradient_max=Inf,
  loglik=NA_real_, beta=numeric(), loading_crossproduct=matrix(numeric(), 0L, 0L),
  residual_variance=NA_real_, free_coordinates=NA_integer_, dimensions=dimensions,
  shape=shape, data_sha256=matrix_sha256, model_markers=model_markers
)

result <- list(
  scope="COV_ORD_LATENT_BARE_THREE_ROUTE_FIT",
  reference_commit=contract$reference_commit,
  input_sha256=input_sha256,
  case_id=contract$case_id,
  model=contract$model,
  fixed_point_dependency=list(
    required=TRUE,
    evidence="docs/dev-log/core070/gaussian-fixed-point-evidence.json",
    tolerance=contract$tolerances$fixed_point_abs_loglik,
    case_ids=c("GAUSS-LOADINGS-P1", "GAUSS-LOADINGS-P2"),
    max_abs_loglik=fixed_point_max_delta,
    status=if (fixed_point_ok) "PASS" else "FAIL"
  ),
  process_receipt=list(
    r_version=R.version.string,
    gllvmTMB_version=as.character(utils::packageVersion("gllvmTMB")),
    gllvmTMB_path=find.package("gllvmTMB"), frozen_library=frozen_library,
    input_path=input_path, input_sha256=input_sha256,
    data_matrix_sha256=matrix_sha256,
    julia_home=Sys.getenv("JULIA_HOME"), julia_project=Sys.getenv("JULIA_PROJECT"),
    requested_threads=list(openblas=Sys.getenv("OPENBLAS_NUM_THREADS"), omp=Sys.getenv("OMP_NUM_THREADS"))
  ),
  routes=list(
    r_reference=empty_route("r_reference", "gllvmTMB"),
    native_julia=empty_route("native_julia", "GLLVM.jl"),
    julia_formula=empty_route("julia_formula", "GLLVM.jl"),
    public_r_bridge=empty_route("public_r_bridge", "gllvmTMB engine=julia")
  ),
  comparisons=list(), negative_controls=list(), checks=list(), all_checks=FALSE
)

write_attempt <- function() saveRDS(result, file.path(output_dir, "attempts.rds"))
write_attempt()

capture_r_fit <- function(call, route, engine) {
  warnings <- character()
  value <- tryCatch(withCallingHandlers(call(), warning=function(w) {
    warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning")
  }), error=identity)
  if (inherits(value, "error")) {
    record <- empty_route(route, engine)
    record$error <- error_text(value); record$warnings <- warnings; record$class <- class(value)[[1L]]
    return(record)
  }
  if (is.null(value$tmb_obj) || is.null(value$opt)) {
    record <- empty_route(route, engine)
    record$available <- TRUE; record$error <- "UNSUPPORTED_PUBLIC_RESULT_SHAPE"
    record$warnings <- warnings; record$class <- paste(class(value), collapse="/")
    record$model_markers <- c(model_markers, list(public_object_fields=names(value)))
    record$converged <- isTRUE(value$converged)
    record$code <- if (record$converged) 0L else NA_integer_
    record$loglik <- tryCatch(as.numeric(logLik(value)), error=function(e) NA_real_)
    return(record)
  }
  obj <- value$tmb_obj
  outer <- value$opt$par
  gradient <- as.numeric(obj$gr(outer))
  full <- obj$env$last.par
  parameters <- obj$env$parList(x=outer, par=full)
  report <- obj$report(full)
  loading <- tryCatch(as.matrix(report$Lambda_B), error=function(e) matrix(NA_real_, 3L, 1L))
  record <- empty_route(route, engine)
  record$available <- TRUE; record$error <- ""; record$warnings <- warnings
  record$class <- paste(class(value), collapse="/")
  record$converged <- identical(as.integer(value$opt$convergence), 0L)
  record$code <- as.integer(value$opt$convergence)
  record$gradient_max <- if (length(gradient)) max(abs(gradient)) else 0
  record$loglik <- as.numeric(logLik(value))
  record$beta <- as.numeric(parameters$b_fix)
  record$loading_crossproduct <- tcrossprod(loading)
  record$residual_variance <- exp(2 * as.numeric(parameters$log_sigma_eps))
  record$free_coordinates <- length(outer)
  record$dimensions <- dimensions
  record$shape <- c(shape, list(mean_design_shape=as.integer(dim(as.matrix(obj$env$data$X_fix))),
                                random=as.character(value$random)))
  record$data_sha256 <- matrix_sha256
  record$model_markers <- c(model_markers, list(
    input_random=as.character(value$random), use_diag_B=as.integer(obj$env$data$use_diag_B),
    n_traits=as.integer(obj$env$data$n_traits), n_sites=as.integer(obj$env$data$n_sites)
  ))
  record
}

capture_bridge_fit <- function(call) {
  warnings <- character()
  value <- tryCatch(withCallingHandlers(call(), warning=function(w) {
    warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning")
  }), error=identity)
  record <- empty_route("public_r_bridge", "julia")
  if (inherits(value, "error")) {
    record$error <- error_text(value); record$warnings <- warnings
    record$class <- class(value)[[1L]]
    return(record)
  }
  if (!inherits(value, "gllvmTMB_julia")) {
    record$available <- TRUE; record$error <- "UNEXPECTED_PUBLIC_BRIDGE_CLASS"
    record$warnings <- warnings; record$class <- paste(class(value), collapse="/")
    record$model_markers <- c(model_markers, list(public_object_fields=names(value)))
    return(record)
  }
  record$available <- TRUE; record$error <- ""; record$warnings <- warnings
  record$class <- paste(class(value), collapse="/"); record$engine <- "julia"
  record$same_model <- TRUE
  record$converged <- isTRUE(value$converged); record$code <- if (record$converged) 0L else 1L
  record$gradient_max <- NULL
  record$loglik <- as.numeric(logLik(value))
  record$beta <- as.numeric(value$alpha)
  record$loading_crossproduct <- tcrossprod(as.matrix(value$loadings))
  record$residual_variance <- as.numeric(value$sigma_eps)^2
  record$free_coordinates <- as.integer(value$df)
  record$dimensions <- list(traits=as.integer(value$n_traits), units=as.integer(value$n_units),
                            rank=as.integer(value$d))
  record$shape <- c(shape, list(bridge_df=as.integer(value$df),
                                bridge_object_fields=names(value)))
  record$data_sha256 <- matrix_sha256
  record$model_markers <- c(model_markers, list(engine="julia", same_model=TRUE,
    bridge_family=as.character(value$family), n_traits=as.integer(value$n_traits),
    n_units=as.integer(value$n_units), d=as.integer(value$d)))
  record
}

df <- data.frame(
  site=factor(input$data$site_id + 1L, levels=seq_len(18L)),
  trait=factor(input$data$trait_id + 1L, levels=seq_len(3L)),
  value=as.numeric(input$data$y)
)
fit_call <- function(engine=NULL, reversed=FALSE) {
  data <- if (reversed) df[nrow(df):1L, , drop=FALSE] else df
  args <- list(
    formula=value ~ 0 + trait + latent(0 + trait | site, d=1, unique=FALSE),
    data=data, unit="site", trait="trait", family=gaussian(),
    control=gllvmTMBcontrol(n_init=1L, se=FALSE,
      optimizer="optim", optArgs=list(method="BFGS", control=list(reltol=1e-14, maxit=2000)))
  )
  if (!is.null(engine)) {
    args$engine <- engine
    args$ci_method <- "none"
  }
  do.call(gllvmTMB, args)
}

result$routes$r_reference <- capture_r_fit(
  function() fit_call(), "r_reference", "gllvmTMB frozen R")
write_attempt()

# The Julia setup is intentionally explicit and non-installing.  The bridge
# route below is still a separate public-R call, so a failure there cannot be
# mistaken for failure of the direct JuliaCall routes.
julia_error <- NULL
julia_payload <- tryCatch({
  # Installed JuliaCall prepends its own Julia libunwind for the child. Keeping
  # the parent's preload produces an unquoted two-path command and can segfault.
  result$process_receipt$parent_preload <- Sys.getenv("LD_PRELOAD")
  Sys.unsetenv("LD_PRELOAD")
  JuliaCall::julia_setup(JULIA_HOME=Sys.getenv("JULIA_HOME"), installJulia=FALSE,
                         install=FALSE, verbose=FALSE)
  gllvmTMB::gllvm_julia_setup(jl_path=root, julia_home=Sys.getenv("JULIA_HOME"))
  JuliaCall::julia_command('include("tools/core070_latent_bare_model.jl")')
  JuliaCall::julia_call("core070_latent_bare_julia", Y)
}, error=function(e) { julia_error <<- e; NULL })
if (is.null(julia_payload)) {
  for (route in c("native_julia", "julia_formula")) {
    result$routes[[route]] <- empty_route(route, "GLLVM.jl")
    result$routes[[route]]$error <- error_text(julia_error)
    result$routes[[route]]$class <- class(julia_error)[[1L]]
  }
  result$negative_control_details <- list(error=error_text(julia_error))
  result$negative_controls <- setNames(
    as.list(rep(FALSE, length(contract$negative_controls))), contract$negative_controls
  )
} else {
  result$routes$native_julia <- plain(julia_payload$native_julia)
  result$routes$julia_formula <- plain(julia_payload$julia_formula)
  result$negative_control_details <- plain(julia_payload$negative_controls)
  result$negative_controls <- as.list(vapply(result$negative_control_details, function(x) {
    is.list(x) && (isTRUE(x$passed) || isTRUE(x$rejected))
  }, logical(1L)))
  result$process_receipt$julia_version <- JuliaCall::julia_eval("string(VERSION)")
  result$process_receipt$julia_project <- JuliaCall::julia_eval("Base.active_project()")
  result$process_receipt$julia_source <- JuliaCall::julia_eval("pathof(GLLVM)")
  result$process_receipt$julia_threads <- JuliaCall::julia_eval("Threads.nthreads()")
  result$process_receipt$blas_threads <- JuliaCall::julia_eval("GLLVM.LinearAlgebra.BLAS.get_num_threads()")
}
write_attempt()

result$routes$public_r_bridge <- capture_bridge_fit(
  function() fit_call(engine="julia", reversed=TRUE)
)
write_attempt()

route_ok <- function(route) {
  gradient_ok <- is.null(route$gradient_max) ||
    (is.finite(route$gradient_max) && route$gradient_max <= contract$tolerances$gradient_max)
  isTRUE(route$available) && isTRUE(route$converged) && gradient_ok &&
  is.finite(route$loglik) && identical(as.integer(route$free_coordinates), 7L) &&
  identical(as.integer(route$dimensions$traits), 3L) && identical(as.integer(route$dimensions$units), 18L) &&
  identical(as.integer(route$dimensions$rank), 1L)
}
compare <- function(left, right) list(
  abs_loglik=abs(left$loglik-right$loglik),
  beta_max_abs=max(abs(left$beta-right$beta)),
  loading_crossproduct_max_abs=max(abs(left$loading_crossproduct-right$loading_crossproduct)),
  residual_variance_abs=abs(left$residual_variance-right$residual_variance)
)
safe_compare <- function(left, right) tryCatch(compare(left, right), error=function(e) list(error=error_text(e)))
passes_compare <- function(x) is.list(x) && is.null(x$error) && is.finite(x$abs_loglik) && x$abs_loglik <= contract$tolerances$fit_abs_loglik &&
  x$beta_max_abs <= contract$tolerances$beta_max_abs &&
  x$loading_crossproduct_max_abs <= contract$tolerances$loading_crossproduct_max_abs &&
  x$residual_variance_abs <= contract$tolerances$residual_variance_abs

r <- result$routes$r_reference; native <- result$routes$native_julia
formula <- result$routes$julia_formula; bridge <- result$routes$public_r_bridge
result$comparisons <- list(
  native_julia=if (isTRUE(r$available) && isTRUE(native$available)) safe_compare(r, native) else NULL,
  julia_formula=if (isTRUE(r$available) && isTRUE(formula$available)) safe_compare(r, formula) else NULL,
  public_r_bridge=if (isTRUE(r$available) && isTRUE(bridge$available)) safe_compare(r, bridge) else NULL
)
result$checks <- list(
  input_sha256=identical(input_sha256, contract$input_sha256),
  fixed_point_dependency=fixed_point_ok,
  r_reference_health=route_ok(r), native_julia_health=route_ok(native),
  julia_formula_health=route_ok(formula), public_r_bridge_health=route_ok(bridge),
  r_native_invariants=passes_compare(result$comparisons$native_julia),
  r_formula_invariants=passes_compare(result$comparisons$julia_formula),
  r_bridge_invariants=passes_compare(result$comparisons$public_r_bridge),
  bridge_callable=isTRUE(bridge$available),
  bridge_same_model=isTRUE(bridge$available) && isTRUE(bridge$same_model) &&
    isTRUE(bridge$engine == "julia"),
  raw_loading_sign_not_compared=isTRUE(result$negative_controls$raw_loading_sign_not_compared),
  negative_controls=identical(sort(names(result$negative_controls)), sort(negative_control_ids)) &&
    all(unlist(result$negative_controls, use.names=FALSE))
)
result$all_checks <- all(unlist(result$checks[c(
  "input_sha256", "fixed_point_dependency", "r_reference_health", "native_julia_health", "julia_formula_health",
  "public_r_bridge_health", "r_native_invariants", "r_formula_invariants", "r_bridge_invariants",
  "bridge_callable", "bridge_same_model", "raw_loading_sign_not_compared", "negative_controls"
)]))

saveRDS(result, file.path(output_dir, "latent-bare-results.rds"))
jsonlite::write_json(plain(result), file.path(output_dir, "latent-bare-results.json"),
                      auto_unbox=TRUE, pretty=TRUE, digits=NA, null="null")
cat("CORE070_LATENT_BARE_RESULTS_SHA256", sha256_file(file.path(output_dir, "latent-bare-results.json")), "\n")
if (!isTRUE(result$all_checks)) quit(status=1L)
