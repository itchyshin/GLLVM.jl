#!/usr/bin/env Rscript
# Frozen-R provenance preflight only.  It loads no gllvmTMB namespace and never
# constructs data or calls a fit.  A future approved runner must invoke this
# check successfully before it evaluates the one B1 control.

expected <- list(
  git_sha = "b4d5fee64def88bc768dda1f1f77c29b295edd86",
  version = "0.7.0",
  archive_sha256 = "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc",
  shared_library_sha256 = "3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30",
  reference_runner_sha256 = "9d1f1fa95655bd8887d7e04d2c2d10c0311fac094205a4d47dd7ee6ebb9ca585"
)

args <- commandArgs(trailingOnly = TRUE)
length(args) == 6L || stop("Use --source PATH --library PATH --reference-runner PATH.")
values <- setNames(args[c(FALSE, TRUE, FALSE, TRUE, FALSE, TRUE)], sub("^--", "", args[c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE)]))
identical(sort(names(values)), c("library", "reference-runner", "source")) || stop("Expected --source, --library, and --reference-runner.")
sha256 <- function(path) strsplit(trimws(system2("shasum", c("-a", "256", path), stdout = TRUE)), "[[:space:]]+")[[1L]][1L]
source_dir <- normalizePath(values[["source"]], mustWork = TRUE)
library_dir <- normalizePath(values[["library"]], mustWork = TRUE)
reference_runner <- normalizePath(values[["reference-runner"]], mustWork = TRUE)
identical(trimws(system2("git", c("-C", source_dir, "rev-parse", "HEAD"), stdout = TRUE)), expected$git_sha) || stop("Frozen source SHA mismatch.")
identical(unname(read.dcf(file.path(source_dir, "DESCRIPTION"))[1L, "Version"]), expected$version) || stop("Frozen source version mismatch.")
archive <- tempfile(fileext = ".tar"); on.exit(unlink(archive), add = TRUE)
system2("git", c("-C", source_dir, "archive", "--format=tar", paste0("--output=", archive), expected$git_sha)) == 0L || stop("Frozen archive failed.")
identical(sha256(archive), expected$archive_sha256) || stop("Frozen archive SHA mismatch.")
shared <- list.files(file.path(library_dir, "gllvmTMB", "libs"), pattern = "^gllvmTMB\\.(so|dylib)$", full.names = TRUE)
length(shared) == 1L || stop("Expected one frozen shared library.")
identical(sha256(shared[[1L]]), expected$shared_library_sha256) || stop("Frozen shared-library SHA mismatch.")
marker_path <- file.path(library_dir, "gllvmTMB-frozen-source-identity.json")
marker <- paste(readLines(marker_path, warn = FALSE), collapse = "")
marker_field <- function(key) {
  match <- regmatches(marker, regexec(paste0('"', key, '"[[:space:]]*:[[:space:]]*"([^"]+)"'), marker))[[1L]]
  length(match) == 2L || stop("Frozen-library marker lacks ", key, ".")
  match[[2L]]
}
identical(marker_field("source_sha"), expected$git_sha) || stop("Frozen-library source SHA marker mismatch.")
identical(marker_field("source_version"), expected$version) || stop("Frozen-library source version marker mismatch.")
identical(marker_field("source_archive_sha256"), expected$archive_sha256) || stop("Frozen-library archive marker mismatch.")
identical(marker_field("installed_shared_library_sha256"), expected$shared_library_sha256) || stop("Frozen-library DLL marker mismatch.")
identical(sha256(reference_runner), expected$reference_runner_sha256) || stop("Frozen reference-runner SHA mismatch.")
cat("B1 balanced complete-crossed frozen-R provenance preflight PASS\\n")
