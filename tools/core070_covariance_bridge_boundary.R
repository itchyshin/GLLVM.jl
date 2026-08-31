#!/usr/bin/env Rscript

# Replay only the frozen public bridge's pre-Julia structured-term guard.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("usage: core070_covariance_bridge_boundary.R OUTPUT", call. = FALSE)
output <- args[[1L]]
if (file.exists(output)) stop("output already exists", call. = FALSE)

suppressPackageStartupMessages(library(gllvmTMB))
source("test/parity/fixtures/core070_covariance_modes.R", local = environment())
poisoned_julia_path <- "/CORE070/POISONED/NO-GLLVM-JL"
options(gllvmTMB.GLLVM.jl.path = poisoned_julia_path)
Sys.setenv(GLLVM_JL_PATH = poisoned_julia_path)

hex_text <- function(x) paste(sprintf("%02x", as.integer(charToRaw(enc2utf8(x)))), collapse = "")
records <- character()
wrong_gate <- character()
for (case in cases) {
  call <- case$call
  call$engine <- "julia"
  condition <- tryCatch(
    {
      eval(call, envir = environment())
      NULL
    },
    error = identity
  )
  if (!inherits(condition, "error")) {
    stop(sprintf("%s unexpectedly crossed the frozen bridge", case$id), call. = FALSE)
  }
  message <- conditionMessage(condition)
  gate <- if (grepl("[GJL-GATE-STRUCTURED-TERMS]", message, fixed = TRUE)) {
    "GJL-GATE-STRUCTURED-TERMS"
  } else {
    "EARLY-GENERIC-ERROR"
  }
  expected <- if (identical(case$id, "MODE-ORD-DEP")) {
    "EARLY-GENERIC-ERROR"
  } else {
    "GJL-GATE-STRUCTURED-TERMS"
  }
  if (!identical(gate, expected)) wrong_gate <- c(wrong_gate, case$id)
  records <- c(records, paste(case$id, gate, hex_text(message), sep = "\t"))
}

header <- c(
  paste("reference_package_version", as.character(utils::packageVersion("gllvmTMB")), sep = "\t"),
  paste("reference_package_path", find.package("gllvmTMB"), sep = "\t"),
  paste("r_version", R.version.string, sep = "\t"),
  paste("poisoned_julia_path", poisoned_julia_path, sep = "\t"),
  paste("case_count", length(cases), sep = "\t")
)
writeLines(c(header, records), output, useBytes = TRUE)
if (length(wrong_gate)) {
  stop(sprintf(
    "wrong public refusal for %s",
    paste(wrong_gate, collapse = ",")
  ), call. = FALSE)
}
cat(sprintf("CORE070_COVARIANCE_BRIDGE_BOUNDARY_PASS cases=%d\n", length(cases)))
