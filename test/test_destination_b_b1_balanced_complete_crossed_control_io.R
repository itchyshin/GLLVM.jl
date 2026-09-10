#!/usr/bin/env Rscript

file_arg <- commandArgs()[grepl("^--file=", commandArgs())]
length(file_arg) == 1L || stop("Could not identify test path.")
root <- normalizePath(file.path(dirname(sub("^--file=", "", file_arg)), ".."), mustWork = TRUE)
source(file.path(root, "tools", "destination_b", "b1_balanced_complete_crossed_control_common.R"))

scratch <- tempfile("b1-balanced-control-io-")
dir.create(scratch)
on.exit(unlink(scratch, recursive = TRUE), add = TRUE)
absent <- file.path(scratch, "absent.json")
regular <- file.path(scratch, "regular.json")
symlink <- file.path(scratch, "symlink.json")
writeLines("existing", regular)
file.symlink(regular, symlink) || stop("Could not create symlink control.")

stopifnot(!b1_balanced_control_output_occupied(absent))
stopifnot(b1_balanced_control_output_occupied(regular))
stopifnot(b1_balanced_control_output_occupied(symlink))
cat("B1 balanced control output guard PASS\n")
