#!/usr/bin/env Rscript

# No-fit verifier for the retained B1 control receipt.  It reads the immutable
# JSON/raw artifacts only; it never loads gllvmTMB or constructs a model.
file_arg <- commandArgs()[grepl("^--file=", commandArgs())]
length(file_arg) == 1L || stop("Could not identify test path.")
root <- normalizePath(file.path(dirname(sub("^--file=", "", file_arg)), ".."), mustWork = TRUE)
artifact_dir <- file.path(root, "docs", "dev-log", "core070", "destination-b-b1")
receipt_path <- file.path(artifact_dir, "frozen-r070-b1-balanced-complete-crossed-single-control-20260910-02.json")
marker_path <- file.path(artifact_dir, ".b1-balanced-control-1d8b75cc6707")
preflight_log <- file.path(artifact_dir, "balanced-complete-crossed-preflight-20260910-02.log")
control_log <- file.path(artifact_dir, "frozen-r070-b1-balanced-complete-crossed-single-control-20260910-02.log")

requireNamespace("jsonlite", quietly = TRUE) || stop("jsonlite is required to read the retained receipt.")
stopifnot(file.exists(receipt_path), file.exists(marker_path), file.exists(preflight_log), file.exists(control_log))
sha256 <- function(path) strsplit(trimws(system2("shasum", c("-a", "256", path), stdout = TRUE)), "[[:space:]]+")[[1L]][1L]
stopifnot(identical(sha256(receipt_path), sha256(marker_path)))

receipt <- jsonlite::fromJSON(receipt_path, simplifyVector = FALSE)
stopifnot(identical(receipt$receipt_kind, "frozen_R_B1_balanced_complete_crossed_single_control"))
stopifnot(identical(receipt$source$git_sha, "b4d5fee64def88bc768dda1f1f77c29b295edd86"))
stopifnot(identical(receipt$installed$loaded_version, "0.7.0"))
stopifnot(identical(receipt$r_runner$sha256, "6579993fe30894e23c252368465df86ace4ce359602cfa55c58552e828df1309"))
stopifnot(identical(receipt$specification$formula, "value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) + indep(0 + trait | obs) + indep(0 + trait | cluster_id) + indep(0 + trait | cluster2_id)"))
stopifnot(identical(receipt$specification$REML, FALSE), identical(receipt$specification$seed, 20260915L))
stopifnot(identical(receipt$specification$n_wide, 3600L), identical(receipt$specification$n_long, 7200L))
stopifnot(identical(receipt$specification$data_md5, "fc98745c31ec15fdf63f95f9ce663813"))
stopifnot(identical(receipt$specification$control$n_init, 1L), identical(receipt$specification$control$se, FALSE))
stopifnot(identical(receipt$specification$control$optimizer, "nlminb"))
stopifnot(identical(receipt$specification$control$eval_max, 100000L), identical(receipt$specification$control$iter_max, 100000L))
stopifnot(isTRUE(all.equal(unname(unlist(receipt$specification$control[c("rel_tol", "x_tol", "xf_tol")])), rep(1e-12, 3L), tolerance = 0)))
stopifnot(identical(receipt$preflight, "PASS"), identical(receipt$status, "success"))
stopifnot(identical(receipt$fit$convergence, 1L))
# The byte-exact receipt is hash-locked above; JSON parsing may change the
# terminal binary representation of this printed decimal by a few ULPs.
stopifnot(isTRUE(all.equal(receipt$fit$gradient_max_abs, 0.00092870391764413951, tolerance = 1e-15)))
stopifnot(identical(receipt$acceptance$qualified, FALSE))
stopifnot(identical(receipt$acceptance$rule, "convergence == 0 && max(abs(gr)) <= 1e-6"))
stopifnot(grepl("frozen-R provenance preflight PASS", paste(readLines(preflight_log, warn = FALSE), collapse = "\n"), fixed = TRUE))
stopifnot(grepl("single control retained: success", paste(readLines(control_log, warn = FALSE), collapse = "\n"), fixed = TRUE))
cat("B1 balanced control receipt I/O PASS\\n")
