# A0 — Julia bridge transport inventory (scout distill)

**Date:** 2026-08-01  
**Purpose:** Map R↔Julia transport surfaces for catch-up lane; separate **capability drift** from **logLik parity**.

## Twin pairing

| Side | Location | Pin |
| --- | --- | --- |
| **R twin (gllvmTMB)** | `/tmp/gllvmtmb-parity-restart-20260801` | `cee55a07` |
| **Julia lane (GLLVM.jl)** | `.worktrees/gllvmjl-catchup-loglik-20260801` | branch `catchup/loglik-oracle-20260801` |

## Key files (read order)

| File | Role |
| --- | --- |
| `R/julia-bridge.R` (twin) | `gllvm_julia_setup()`, gate registry, `.gllvm_julia_capability_drift()`, `engine = "julia"` routing |
| `tests/testthat/test-julia-bridge.R` (twin) | Pure-R guards + live JuliaCall rows (incl. A2b smoke) |
| `src/bridge.jl` (Julia lane) | `GLLVM.bridge_capabilities()` — capability matrix R compares to registered gates |

## Environment variables

| Var | Consumed by | Notes |
| --- | --- | --- |
| **`GLLVM_JL_PATH`** | `gllvm_julia_setup(jl_path=…)` | Absolute path to GLLVM.jl project root (catch-up worktree for lane work) |
| **`JULIA_HOME`** | JuliaCall setup | e.g. `~/.juliaup/bin`; option `gllvmTMB.julia_home` overrides |

One-time lane prep: `Pkg.instantiate()` on the worktree before first live JuliaCall.

## Drift probe (manual oracle)

```bash
export GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-catchup-loglik-20260801"
export JULIA_HOME="${JULIA_HOME:-$HOME/.juliaup/bin}"
TWIN="/tmp/gllvmtmb-parity-restart-20260801"

Rscript -e '
suppressPackageStartupMessages(devtools::load_all("'$TWIN'", quiet = TRUE))
gllvm_julia_setup()
engine_caps <- JuliaCall::julia_eval("GLLVM.bridge_capabilities()")
drift <- gllvmTMB:::.gllvm_julia_capability_drift(julia_caps = engine_caps)
print(drift[, c("family", "capability", "direction", "status", "gate_id")], row.names = FALSE)
cat("n_drift=", nrow(drift), " unregistered=", sum(drift$status == "unregistered"), "\n")
'
```

**Semantics:**

- **`n_drift = nrow(drift) == 0`**: Julia-reported capabilities match R’s registered gate table (no stale/missing/extra flags).
- **`unregistered = 0`**: no Julia capability marked `status == "unregistered"` (would mean engine exposes something R did not register).
- **`n_drift = 0` does NOT imply logLik parity**, fitted-parameter agreement, or ADEMP — transport/registry alignment only.

## Lightest live smoke (A2b)

Use **exact** `testthat` description (partial strings fail on testthat 3.3.2):

`live GLLVM.jl bridge capabilities drift only through registered gates`

```bash
export GLLVM_JL_PATH="…worktree…"
TWIN="/tmp/gllvmtmb-parity-restart-20260801"
Rscript -e '
suppressPackageStartupMessages(devtools::load_all("'$TWIN'", quiet = TRUE))
testthat::test_file(
  "'$TWIN'/tests/testthat/test-julia-bridge.R",
  desc = "live GLLVM.jl bridge capabilities drift only through registered gates",
  reporter = "summary"
)
'
```

**A2b already passed** — evidence and timings: `LOOP/notes/A2b-bridge-smoke-prep.md` (PASS, `nrow(drift) == 0`, ~21–37 s).

## Caveats (do not skip)

- **Do not** run `devtools::test(filter = "julia-bridge")` with **`GLLVM_JL_PATH` set**: the file runs many **`engine = "julia"` numerical fits** after the drift row — heavy, unrelated to A0 transport proof.
- **`test_file(..., filter=)`** is not supported; filename filters only apply via `devtools::test`, not single-test isolation.
- Offline marshal-only alternative: `desc = "gllvm_julia_fit transposes a matrix N under units_are_rows = TRUE (#593)"` — no live Julia.


