source("tools/core070_bridge_receipt.R")
example <- list(native=structure(list(alpha=c(1,2),Sigma=diag(2)),class="JuliaNamedTuple"),
                call=quote(gllvmTMB(y~x)))
failed <- tryCatch({jsonlite::toJSON(example);FALSE},error=function(e)
    grepl("JuliaNamedTuple",conditionMessage(e),fixed=TRUE))
stopifnot(failed)
plain <- core070_plain_receipt(example)
stopifnot(identical(plain$native$alpha,c(1,2)),identical(plain$native$Sigma,diag(2)),
          is.character(plain$call),is.list(jsonlite::fromJSON(jsonlite::toJSON(plain))))
stopifnot(core070_all_true(list(a=TRUE,b=TRUE),c("a","b")),
          !core070_all_true(list(a=TRUE,b=logical()),c("a","b")),
          !core070_all_true(list(a=TRUE),c("a","b")),
          !core070_all_true(list(a=TRUE,b=FALSE),c("a","b")),
          !core070_all_true(list(a=TRUE,b=NA),c("a","b")))
cat("BRIDGE_RECEIPT_SERIALIZATION_PASS\n")
