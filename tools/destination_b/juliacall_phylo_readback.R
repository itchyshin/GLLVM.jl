# Pure saved-result validation. Does not initialize Julia or refit a model.
destination_b_plain_juliacall_result <- function(result) {
  if (inherits(result,"JuliaNamedTuple")) result <- unclass(result)
  if (!is.list(result) || is.null(names(result)) || anyDuplicated(names(result)))
    stop("expected a uniquely named Julia result list")
  permitted <- vapply(result,function(x) is.null(x) ||
    ((is.atomic(x) || is.matrix(x)) && !is.object(x)),logical(1L))
  if (!all(permitted)) stop("unexpected nested or classed Julia result field")
  result
}

destination_b_validate_juliacall_result <- function(result,expected) {
  result <- destination_b_plain_juliacall_result(result)
  stopifnot(isTRUE(result$converged),identical(result$admission_status,"closed"),
    is.finite(result$gradient_max),result$gradient_max<=1e-5,
    abs(result$loglik-expected$loglik)<=1e-8,
    identical(as.integer(result$species_aug_id),as.integer(unlist(expected$species_aug_id))),
    identical(as.character(result$ci_target_names),as.character(unlist(expected$ci_target_names))),
    length(result$ci_target_names)==12L,
    !anyDuplicated(result$ci_target_names),length(result$ci_lower)==12L,
    length(result$ci_upper)==12L,length(result$ci_estimate)==12L,
    all(is.finite(c(result$ci_lower,result$ci_upper,result$ci_estimate))),
    all(result$ci_lower<=result$ci_estimate & result$ci_estimate<=result$ci_upper),
    max(abs(result$ci_lower-unlist(expected$ci_lower)))<=1e-5,
    max(abs(result$ci_upper-unlist(expected$ci_upper)))<=1e-5,
    identical(dim(result$loadings),c(3L,1L)),
    identical(dim(result$phylo_covariance),c(3L,3L)),
    identical(dim(result$mean_design),c(48L,3L)))
  result
}

destination_b_readback_juliacall <- function(rds,expected_path,output) {
  if(file.exists(output)) stop("refusing existing readback receipt")
  receipt <- readRDS(rds)
  expected <- jsonlite::fromJSON(expected_path)$result
  result <- destination_b_validate_juliacall_result(receipt$result,expected)
  receipt$result <- result
  receipt$status <- "pass"
  receipt$stage <- "saved_raw_transport_verified"
  receipt$qualified <- FALSE
  receipt$fit_rerun <- FALSE
  receipt$input_rds_sha256 <- unname(tools::sha256sum(rds))[[1L]]
  receipt$expected_sha256 <- unname(tools::sha256sum(expected_path))[[1L]]
  jsonlite::write_json(receipt,output,auto_unbox=TRUE,pretty=TRUE,digits=17L,null="null")
  decoded <- jsonlite::fromJSON(output)$result
  stopifnot(identical(decoded$loadings,result$loadings),
    identical(decoded$phylo_covariance,result$phylo_covariance),
    identical(decoded$ci_lower,result$ci_lower),identical(decoded$ci_upper,result$ci_upper))
  cat("SAVED_JULIACALL_RAW_TRANSPORT_PASS\n")
  invisible(receipt)
}
