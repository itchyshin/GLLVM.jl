# A2b bridge transport smoke — prep note

**Date:** 2026-08-01  
**Twin:** `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`  
**Julia lane:** `.worktrees/gllvmjl-catchup-loglik-20260801` @ `catchup/loglik-oracle-20260801` / `05210eca`

## Lightest testthat targets (`tests/testthat/test-julia-bridge.R`)

| Tier | What | JuliaCall live? | GLLVM fit? |
| --- | --- | --- | --- |
| **A2b live transport (preferred)** | `test_that("live GLLVM.jl bridge capabilities drift only through registered gates", …)` @ L2848 | yes (`gllvm_julia_setup` + `julia_eval("GLLVM.bridge_capabilities()")`) | no |
| **Offline R→Julia marshal only** | `test_that("gllvm_julia_fit transposes a matrix N under units_are_rows = TRUE (#593)", …)` @ L4167 | package only; mocks `gllvm_julia_setup` + `JuliaCall::julia_call` | no |
| **Pure R (not transport)** | Earlier guard / `.gllvm_julia_capability_drift()` tests (e.g. L700) | no | no |

**Do not** use file-level `devtools::test(filter = "julia-bridge")` when `GLLVM_JL_PATH` is set: that file also runs many `engine = "julia"` numerical fits after L2848.

### testthat 3.3.2 filtering

- `testthat::test_file(..., desc = "<full test_that string>")` — **exact** description required (partial strings fail).
- `filter` on `test_file()` is not supported; `devtools::test(filter=…)` matches **filenames**, not test names.

## One-time Julia lane prep (this session)

Fresh worktree needed deps before `using GLLVM` via JuliaCall:

```bash
~/.juliaup/bin/julia --project="/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-catchup-loglik-20260801" -e 'using Pkg; Pkg.instantiate()'
```

## Key command — live A2b smoke (setup + `bridge_capabilities`)

```bash
export GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-catchup-loglik-20260801"
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

**Result (2026-08-01):** **PASS** — 3 expectations, `nrow(drift) == 0`, no unregistered capabilities.  
**Wall time:** ~21–37 s (warm vs cold JuliaCall); under 60 s budget.

**Warnings observed (non-blocking for this smoke):** Julia stderr noise from `LogExpFunctionsInverseFunctionsExt` (`UndefVarError: loglogistic`) during extension load while `using GLLVM`; `bridge_capabilities()` still returned and test passed.

Equivalent manual oracle (same assertions):

```bash
export GLLVM_JL_PATH="…worktree…"
Rscript -e '
suppressPackageStartupMessages(devtools::load_all("'$TWIN'", quiet = TRUE))
gllvm_julia_setup()
engine_caps <- JuliaCall::julia_eval("GLLVM.bridge_capabilities()")
drift <- .gllvm_julia_capability_drift(julia_caps = engine_caps)
stopifnot(nrow(drift) == 0L, !any(drift$status == "unregistered"))
cat("SMOKE_OK\n")
'
```

**First attempt before `Pkg.instantiate()`:** FAIL — `Distributions` missing in lane env.

## Offline transport check (optional, no `GLLVM_JL_PATH`)

```bash
TWIN="/tmp/gllvmtmb-parity-restart-20260801"
Rscript -e '
suppressPackageStartupMessages(devtools::load_all("'$TWIN'", quiet = TRUE))
testthat::test_file(
  "'$TWIN'/tests/testthat/test-julia-bridge.R",
  desc = "gllvm_julia_fit transposes a matrix N under units_are_rows = TRUE (#593)",
  reporter = "summary"
)
'
```

**Result:** PASS, ~0.3 s test time.

## Next heavier live step (out of A2b scope)

Next light **live** Julia eval without full `gllvmTMB` fit: `NB1 grouped likelihood matches…` @ L3189 (`gllvm_julia_setup` + single `julia_eval` on `nb1_grouped_marginal_loglik_laplace`).

## Not done here

- No push, no ADEMP, no full `test-julia-bridge.R` file run.
