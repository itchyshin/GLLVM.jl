source("tools/destination_b/juliacall_phylo_readback.R")
testthat::test_that("saved JuliaCall result preserves shapes and rejects invalid evidence", {
  path <- "docs/dev-log/core070/destination-b-adapter/juliacall-dense-readback-01.json"
  result <- jsonlite::fromJSON(path)$result
  # JSON [] has no numeric type; restore the documented empty numeric slot
  # to reproduce the actual JuliaCall object used by this pure checker.
  result$phylo_unique_variance <- numeric()
  expected <- jsonlite::fromJSON("docs/dev-log/core070/destination-b-adapter/dense-result.json")$result
  classed <- structure(result,class="JuliaNamedTuple")
  testthat::expect_identical(destination_b_validate_juliacall_result(classed,expected),result)
  testthat::expect_identical(destination_b_validate_juliacall_result(result,expected),result)
  mutations <- list(
    function(x){x$converged<-FALSE;x},
    function(x){x$admission_status<-"open";x},
    function(x){x$gradient_max<-Inf;x},
    function(x){x$species_aug_id[1]<-0L;x},
    function(x){x$loadings<-as.numeric(x$loadings);x},
    function(x){x$ci_lower[1]<-Inf;x},
    function(x){x$ci_upper[1]<-x$ci_lower[1]-1;x},
    function(x){x$ci_target_names[2]<-x$ci_target_names[1];x},
    function(x){x$ci_lower<-x$ci_lower[-1];x},
    function(x){x$unexpected<-list(value=1);x})
  for(mutate in mutations)
    testthat::expect_error(destination_b_validate_juliacall_result(mutate(classed),expected))
})
