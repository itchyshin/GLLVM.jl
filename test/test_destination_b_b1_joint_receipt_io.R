#!/usr/bin/env Rscript
# Pure receipt-publication regression checks; no gllvmTMB model is fitted.

test_path <- normalizePath(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())]), mustWork = TRUE)
source(file.path(dirname(test_path), "..", "tools", "destination_b", "b1_joint_gaussian_common.R"))

test_dir <- tempfile("b1-joint-receipt-io-")
dir.create(test_dir)
on.exit(unlink(test_dir, recursive = TRUE), add = TRUE)
output <- file.path(test_dir, "receipt.json")

b1_joint_publish_json_new(list(status = "first"), output)
first_bytes <- readBin(output, what = "raw", n = file.info(output)$size)
blocked <- inherits(try(b1_joint_publish_json_new(list(status = "second"), output), silent = TRUE), "try-error")
identical(first_bytes, readBin(output, what = "raw", n = file.info(output)$size)) || stop("Occupied receipt changed.")
blocked || stop("Occupied receipt publication was not rejected.")

dangling <- file.path(test_dir, "dangling.json")
file.symlink("missing-target", dangling) || stop("Could not create dangling-symlink fixture.")
b1_joint_output_occupied(dangling) || stop("Dangling symlink was not rejected as occupied.")
dangling_blocked <- inherits(try(b1_joint_publish_json_new(list(status = "blocked"), dangling), silent = TRUE), "try-error")
dangling_blocked || stop("Dangling-symlink publication was not rejected.")
identical(Sys.readlink(dangling), "missing-target") || stop("Dangling symlink changed.")
cat("B1 joint receipt I/O tests passed\n")
