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
audit_path <- file.path(artifact_dir, "frozen-r070-b1-balanced-complete-crossed-single-control-20260910-02.audit.json")
stationary_receipt_path <- file.path(artifact_dir, "frozen-r070-joint-gaussian-stationary-paired-receipt-20260910.json")

requireNamespace("jsonlite", quietly = TRUE) || stop("jsonlite is required to read the retained receipt.")
stopifnot(file.exists(receipt_path), file.exists(marker_path), file.exists(preflight_log), file.exists(control_log), file.exists(audit_path), file.exists(stationary_receipt_path))
sha256 <- function(path) strsplit(trimws(system2("shasum", c("-a", "256", path), stdout = TRUE)), "[[:space:]]+")[[1L]][1L]
stat_triplet <- function(path) {
  values <- strsplit(system2("stat", c("-f", "%d:%i:%l", path), stdout = TRUE), ":", fixed = TRUE)[[1L]]
  setNames(values, c("device", "inode", "link_count"))
}
expected_hashes <- c(
  receipt = "ab090669922d2868469e4aef1b245ed492e9db6ac3c30b578334034af7931d73",
  marker = "ab090669922d2868469e4aef1b245ed492e9db6ac3c30b578334034af7931d73",
  preflight_log = "8058692230a6bb73297562172a7c789f0b3982498803bfc9910c6b8618b20612",
  control_log = "29748552d10906d68027a95df94834063c5c6be3253c3e8da0322166e3bfafb7"
)
observed_hashes <- c(receipt = sha256(receipt_path), marker = sha256(marker_path), preflight_log = sha256(preflight_log), control_log = sha256(control_log))
stopifnot(identical(observed_hashes, expected_hashes))
receipt_stat <- stat_triplet(receipt_path)
marker_stat <- stat_triplet(marker_path)
stopifnot(identical(receipt_stat[c("device", "inode")], marker_stat[c("device", "inode")]))
stopifnot(identical(receipt_stat[["link_count"]], "2"), identical(marker_stat[["link_count"]], "2"))

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
audit <- jsonlite::fromJSON(audit_path, simplifyVector = FALSE)
stopifnot(identical(audit$audit_kind, "frozen_R_B1_balanced_complete_crossed_negative_receipt_sidecar"))
stopifnot(identical(audit$original_receipt_preserved, TRUE), identical(audit$execution$model_or_preflight_rerun, FALSE))
stopifnot(identical(audit$execution$qualified, FALSE), identical(audit$execution$convergence, 1L))
stopifnot(identical(audit$frozen_provenance$source$git_sha, "b4d5fee64def88bc768dda1f1f77c29b295edd86"))
stopifnot(identical(audit$frozen_provenance$source$archive_sha256, "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc"))
stopifnot(identical(audit$frozen_provenance$installed$shared_library_sha256, "3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30"))
stopifnot(identical(audit$frozen_provenance$stationary_reference_runner$sha256, "9d1f1fa95655bd8887d7e04d2c2d10c0311fac094205a4d47dd7ee6ebb9ca585"))
stopifnot(identical(audit$frozen_provenance$preflight_helper$sha256, "2a5f92138dedb8034a4c658dbbdcd04c77ca4ae6266e4580f8c5bd42cb8e249a"))
stopifnot(identical(audit$frozen_provenance$control_runner$sha256, "6579993fe30894e23c252368465df86ace4ce359602cfa55c58552e828df1309"))
stationary <- jsonlite::fromJSON(stationary_receipt_path, simplifyVector = FALSE)
stopifnot(identical(audit$frozen_provenance$source$archive_sha256, stationary$source$archive_sha256))
stopifnot(identical(audit$frozen_provenance$installed$shared_library_sha256, stationary$installed$shared_library_sha256))
stopifnot(identical(audit$frozen_provenance$stationary_reference_runner$sha256, stationary$r_runner$sha256))
stopifnot(identical(trimws(system2("git", c("-C", audit$frozen_provenance$source$path, "rev-parse", "HEAD"), stdout = TRUE)), audit$frozen_provenance$source$git_sha))
stopifnot(identical(sha256(file.path(root, audit$frozen_provenance$preflight_helper$path)), audit$frozen_provenance$preflight_helper$sha256))
stopifnot(identical(sha256(file.path(root, audit$frozen_provenance$stationary_reference_runner$path)), audit$frozen_provenance$stationary_reference_runner$sha256))
stopifnot(identical(sha256(file.path(root, audit$frozen_provenance$control_runner$path)), audit$frozen_provenance$control_runner$sha256))
stopifnot(identical(sha256(audit$frozen_provenance$installed$shared_library), audit$frozen_provenance$installed$shared_library_sha256))
stopifnot(identical(unname(unlist(audit$artifacts$receipt["sha256"])), expected_hashes[["receipt"]]))
stopifnot(identical(unname(unlist(audit$artifacts$no_clobber_marker["sha256"])), expected_hashes[["marker"]]))
stopifnot(identical(unname(unlist(audit$artifacts$preflight_log["sha256"])), expected_hashes[["preflight_log"]]))
stopifnot(identical(unname(unlist(audit$artifacts$control_log["sha256"])), expected_hashes[["control_log"]]))
stopifnot(identical(audit$artifacts$no_clobber_marker$hardlink_to, basename(receipt_path)))
stopifnot(identical(audit$artifacts$no_clobber_marker$link_count_at_audit, 2L))
cat("B1 balanced control receipt I/O PASS\\n")
