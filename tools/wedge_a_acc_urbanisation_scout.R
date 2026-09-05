#!/usr/bin/env Rscript
# Wedge A — thin ACC scout: Ayumi urbanisation_map flagship via engine="julia"
# Non-interactive Rscript path; writes machine receipt JSON on exit.

suppressPackageStartupMessages({
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite required for receipt output")
  }
})

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L || is.na(x)[1L]) y else x

RECEIPT_PATH <- Sys.getenv(
  "WEDGE_A_RECEIPT",
  "/Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904/docs/dev-log/core070/acc-bridge-urbanisation-receipt-2026-09-05.json"
)
LOG_PATH <- Sys.getenv(
  "WEDGE_A_LOG",
  "/Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904/logs/wedge-a-acc-urbanisation-scout-2026-09-05.log"
)
GLLVM_JL <- Sys.getenv(
  "GLLVM_JL_PATH",
  "/Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904"
)
GLLVMTMB_R <- Sys.getenv(
  "GLLVMTMB_R_PATH",
  "/Users/z3437171/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904"
)
AYUMI_ROOT <- Sys.getenv(
  "AYUMI_URBMAP_ROOT",
  "/Users/z3437171/Dropbox/Github Local/urbanisation_map"
)

ACC_ID <- "ACC-URBMAP-BRIDGE-RSCRIPT"
COMMAND <- paste(
  "GLLVM_JL_PATH='", GLLVM_JL, "' GLLVMTMB_R_PATH='", GLLVMTMB_R,
  "' AYUMI_URBMAP_ROOT='", AYUMI_ROOT,
  "' Rscript tools/wedge_a_acc_urbanisation_scout.R",
  sep = "", collapse = ""
)

dir.create(dirname(LOG_PATH), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(RECEIPT_PATH), recursive = TRUE, showWarnings = FALSE)
log_con <- file(LOG_PATH, open = "wt")
sink(log_con, split = TRUE)
on.exit({
  sink(NULL)
  close(log_con)
}, add = TRUE)

write_receipt <- function(status, extra = list()) {
  rec <- c(
    list(
      acc_id = ACC_ID,
      status = status,
      command = COMMAND,
      attempted_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
      log_path = LOG_PATH,
      data_path = file.path(AYUMI_ROOT, "data/processed/model_matrix_primary.rds"),
      oracle_note = "frozen gllvmTMB 0.7.0 b4d5fee6 (lane convention; load_all dev tree)",
      wedge = "A-thin-scout",
      scope = "one Rscript engine=julia attempt on urbanisation_map flagship; NOT full bridge expansion (#1236)"
    ),
    extra
  )
  jsonlite::write_json(rec, RECEIPT_PATH, auto_unbox = TRUE, pretty = TRUE)
  cat("\nReceipt written:", RECEIPT_PATH, "\n")
}

cat("=== Wedge A ACC scout ===\n")
cat("ACC_ID:", ACC_ID, "\n")
cat("GLLVM_JL:", GLLVM_JL, "\n")
cat("GLLVMTMB_R:", GLLVMTMB_R, "\n")
cat("AYUMI:", AYUMI_ROOT, "\n\n")

data_rds <- file.path(AYUMI_ROOT, "data/processed/model_matrix_primary.rds")
if (!file.exists(data_rds)) {
  write_receipt("BLOCKED", list(
    exit_code = 1L,
    failure_class = "ACC-DATA-MISSING",
    gate = NA_character_,
    message = paste("Ayumi data not found at", data_rds)
  ))
  quit(save = "no", status = 1L)
}

if (!dir.exists(GLLVMTMB_R)) {
  write_receipt("BLOCKED", list(
    exit_code = 1L,
    failure_class = "ACC-SETUP",
    gate = NA_character_,
    message = paste("gllvmTMB worktree missing:", GLLVMTMB_R)
  ))
  quit(save = "no", status = 1L)
}

if (!dir.exists(GLLVM_JL)) {
  write_receipt("BLOCKED", list(
    exit_code = 1L,
    failure_class = "ACC-SETUP",
    gate = NA_character_,
    message = paste("GLLVM.jl path missing:", GLLVM_JL)
  ))
  quit(save = "no", status = 1L)
}

Sys.setenv(GLLVM_JL_PATH = GLLVM_JL)
if (nzchar(Sys.getenv("JULIA_PROJECT", unset = ""))) {
  cat("JULIA_PROJECT (pre-set):", Sys.getenv("JULIA_PROJECT"), "\n")
} else {
  Sys.setenv(JULIA_PROJECT = GLLVM_JL)
  cat("JULIA_PROJECT set to GLLVM_JL\n")
}

suppressMessages(devtools::load_all(GLLVMTMB_R, quiet = TRUE))
cat("gllvmTMB loaded from", GLLVMTMB_R, "\n")

Mp <- readRDS(data_rds)
df <- Mp
df$review <- factor(Mp$review_id)
cols_pri <- setdiff(names(Mp), c("review_id", "level_individual"))
main_pruning <- file.path(AYUMI_ROOT, "outputs/tables/main_pruning.csv")
if (file.exists(main_pruning)) {
  mp <- read.csv(main_pruning, stringsAsFactors = FALSE)
  seven <- mp$indicator[mp$consensus_pruned]
  items <- setdiff(cols_pri, c(seven, "level_ecosystem"))
} else {
  items <- setdiff(cols_pri, "level_ecosystem")
}
cat("n_reviews:", nrow(df), " n_indicators:", length(items), "\n")

mkf <- function(cols, d) {
  as.formula(paste0(
    "traits(", paste(cols, collapse = ", "),
    ") ~ 1 + latent(1 | review, d = ", d, ", unique = FALSE)"
  ))
}

CTRL <- gllvmTMBcontrol(
  n_init = 1L,
  init_jitter = 0.1,
  start_method = list(method = "res", jitter.sd = 0.2)
)

fml <- mkf(items, d = 2L)
cat("Formula class:", paste(class(fml), collapse = ","), "\n")
cat("Formula:", deparse(fml), "\n\n")

fit_tmb <- tryCatch({
  t0 <- Sys.time()
  fit <- suppressWarnings(suppressMessages(
    gllvmTMB(
      fml, data = df, unit = "review",
      family = binomial(link = "probit"),
      control = CTRL, silent = TRUE
    )
  ))
  list(
    fit = fit,
    secs = as.numeric(difftime(Sys.time(), t0, units = "secs")),
    error = NULL
  )
}, error = function(e) list(fit = NULL, secs = NA_real_, error = conditionMessage(e)))

if (!is.null(fit_tmb$error)) {
  write_receipt("BLOCKED", list(
    exit_code = 2L,
    failure_class = "ACC-SETUP",
    gate = NA_character_,
    message = paste("TMB baseline refused:", fit_tmb$error)
  ))
  quit(save = "no", status = 2L)
}

fit_r <- fit_tmb$fit
cat(sprintf(
  "TMB baseline: conv=%s logLik=%.8f wall=%.1fs max_grad=%.4g\n",
  fit_r$opt$convergence,
  as.numeric(logLik(fit_r)),
  fit_tmb$secs,
  fit_r$fit_health$max_gradient %||% NA_real_
))

fit_julia <- tryCatch({
  t0 <- Sys.time()
  fit <- suppressWarnings(suppressMessages(
    gllvmTMB(
      fml, data = df, unit = "review",
      family = binomial(link = "probit"),
      control = CTRL, silent = TRUE,
      engine = "julia"
    )
  ))
  list(
    fit = fit,
    secs = as.numeric(difftime(Sys.time(), t0, units = "secs")),
    error = NULL
  )
}, error = function(e) list(fit = NULL, secs = NA_real_, error = conditionMessage(e)))

if (!is.null(fit_julia$error)) {
  gate <- NA_character_
  msg <- fit_julia$error
  if (grepl("GJL-GATE-STRUCTURED-TERMS", msg, fixed = TRUE)) {
    gate <- "GJL-GATE-STRUCTURED-TERMS"
    failure_class <- "ACC-STRUCTURED-REFUSE"
  } else if (grepl("GJL-GATE-FAMILY", msg, fixed = TRUE)) {
    gate <- "GJL-GATE-FAMILY"
    failure_class <- "ACC-FAMILY-REFUSE"
  } else if (grepl("JuliaCall", msg, fixed = TRUE) || grepl("GLLVM_JL_PATH", msg, fixed = TRUE)) {
    gate <- NA_character_
    failure_class <- "ACC-BRIDGE-SETUP"
  } else if (grepl("RCall", msg, fixed = TRUE) || grepl("JULIA_PROJECT", msg, fixed = TRUE)) {
    gate <- NA_character_
    failure_class <- "ACC-BRIDGE-RSCRIPT-SETUP"
  } else {
    failure_class <- "ACC-BRIDGE-REFUSE"
  }
  write_receipt("BLOCKED", list(
    exit_code = 3L,
    failure_class = failure_class,
    gate = gate,
    message = msg,
    tmb_loglik = as.numeric(logLik(fit_r)),
    tmb_wall_secs = fit_tmb$secs
  ))
  quit(save = "no", status = 3L)
}

fit_j <- fit_julia$fit
ll_r <- as.numeric(logLik(fit_r))
ll_j <- as.numeric(logLik(fit_j))
ll_diff <- abs(ll_r - ll_j)

cat(sprintf(
  "Julia bridge: conv=%s logLik=%.8f wall=%.1fs max_grad=%.4g\n",
  fit_j$opt$convergence,
  ll_j,
  fit_julia$secs,
  fit_j$fit_health$max_gradient %||% NA_real_
))
cat(sprintf("logLik |diff| = %.3e\n", ll_diff))

bridge_class <- if (inherits(fit_j, "gllvmTMB_julia")) "gllvmTMB_julia" else class(fit_j)[1]

write_receipt("PASS", list(
  exit_code = 0L,
  evidence = LOG_PATH,
  model = list(
    family = "binomial_probit",
    structure = "single rr latent(1|review,d=2,unique=FALSE)",
    n_reviews = nrow(df),
    n_indicators = length(items),
    admitted = TRUE,
    structured_terms = FALSE
  ),
  tmb = list(
    loglik = ll_r,
    convergence = fit_r$opt$convergence,
    max_gradient = fit_r$fit_health$max_gradient %||% NA_real_,
    wall_secs = fit_tmb$secs
  ),
  julia_bridge = list(
    loglik = ll_j,
    loglik_abs_diff = ll_diff,
    convergence = fit_j$opt$convergence,
    max_gradient = fit_j$fit_health$max_gradient %||% NA_real_,
    wall_secs = fit_julia$secs,
    bridge_class = bridge_class
  ),
  caveats = c(
    "Thin scout only — not ACC programme complete or true parity",
    "Loading crossproduct / coef shape parity not asserted (prior ACC-URBMAP-01 flagged class 4/5)",
    "n_init=1 for scout speed; Ayumi production uses n_init=5"
  )
))
quit(save = "no", status = 0L)
