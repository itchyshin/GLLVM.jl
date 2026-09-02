# T14 — NB2 grouped-cov Wald `d = NaN` diagnosis (systematic-debugging Phase 1–3)

## Symptom (verbatim)

CI run 33643764358, job "Julia 1 - ubuntu-latest" (julia 1.12.7, x64,
OpenBLAS), `test/test_bridge_x.jl:350`, testset `"negbinomial Wald
(grouped_cov)"`: `@test d < 1e-8` evaluated `NaN < 1e-8`. Same test PASSES
on CI's own julia 1.10.12 (x64) job and on every local combination tried
below. Fixture: `test/test_bridge_x.jl:377-388`, `seed = 523`,
`_bx_sim(NegativeBinomial(), 3, 70, 1, 1; seed=523)`.

## Reproduction table

`oracle = fit_nb_gllvm_grouped_cov(Yi; X, K=1, group=1:3)`,
`nat = confint(oracle, Yi; method=:wald, X)`,
`br = bridge_fit(...; family="negbinomial", options=Dict("ci_method"=>"wald"))`,
`d = _bx_ci_max_absdiff(...)` per `test/test_bridge_x.jl:38-49`.

| env | Julia | arch/OS | r_group (t1,t2,t3) | min eig | cholesky | pd_hessian | pattern | d |
|---|---|---|---|---|---|---|---|---|
| local | 1.12.6 | aarch64 macOS | 5.46e9, 2.54e20, 7.47 | −3.96e-14 | fails (PosDef(9)) | false | all-NaN both | 0.0 PASS |
| local | 1.10.12 | aarch64 macOS | 10.3, 2.53e9, 4.34e19 | −2.44e-8 | fails (PosDef(9)) | false | all-NaN both | 0.0 PASS |
| local (Rosetta) | 1.12.7 | x86_64 macOS | 6.23e9, 3.39e20, 7.47 | −7.5e-9 | fails (PosDef(8)) | false | all-NaN both | 0.0 PASS |
| Totoro | 1.12.6 | x86_64 Linux, real OpenBLAS | 1.33e10, 1.84e21, 7.47 | −7.0e-9 | fails (PosDef(8)) | false | all-NaN both | 0.0 PASS |
| **CI** | **1.12.7** | **x86_64 Linux** | not recovered (no log access) | — | — | — | — | **NaN FAIL** |

`nat` and `br` were **bit-identical in every environment tried** —
expected, since `bridge_fit`'s negbinomial branch calls the *same*
`fit_nb_gllvm_grouped_cov(Yi; X, K, group=collect(1:p), ...)` on the same
`Yi` (`src/bridge.jl:1519-1523`), and `confint`'s `_family_ci` route is
shared by both paths (`src/confint_family.jl:2239-2277`,
`src/bridge.jl:291`). None of the 4 tried environments reproduced the CI
failure; all four landed in the "whole-Hessian singular → pd_hessian=false
→ all-NaN both sides → d=0.0" regime already documented in
`docs/dev-log/core070/second-order-prerun-2026-09-02.md` (nb2 finding #1).
**A second, distinct failure regime was reproduced locally** at nearby
seeds 521/525 (same fixture shape): `pd_hessian=true` but one dispersion's
Wald CI bound overflows to `Inf` on **both** sides identically, and the
test's own diff helper turns that agreement into `NaN` (see Hypothesis).

Platform: `BLAS.get_config()`=`LBTConfig([ILP64] libopenblas64_.dylib)`
(macOS)/`libopenblas64_.so` (Totoro Linux); `JULIA_NUM_THREADS=OPENBLAS_NUM_THREADS=1` throughout.

## Data-flow trace

1. `fit_nb_gllvm_grouped_cov` (`src/families/grouped_dispersion.jl:423`)
   fits per-trait dispersion `r_group` via LBFGS on `log r`. At
   `seed=523` (`p=3, group=1:3, n=70`), two of three traits are
   Poisson-like enough that `r → ∞` along the likelihood ridge — the
   optimizer stops with `r_group` anywhere in `1e9`–`1e21` depending on
   environment (table above); `oracle.hessian=:observed` (package default
   for this family/link, `:376-377`). **No boundary flag exists on
   `NBGroupedCovFit`** — fields are `β, γ, γ_fixed, Λ, r_group, group,
   link, loglik, converged, iterations, hessian` (`:361-374`) — nothing
   like Student-t's `nu_boundary`.
2. `_family_ci(fit::NBGroupedCovFit, Y; X)` (`src/confint_family.jl:517`)
   builds one *joint* `θ=vcat(β,γ_free,pack_lambda(Λ),log.(r_group))`
   (10 entries), `kinds` marking all 3 `log r` `:log`.
3. `confint(fit::_CIFit, Y; method=:wald)` (`:2239`) calls `_family_wald`
   (`:1969`), which builds **one** joint `_fd_hessian` (10×10 central
   difference, `:1912`) and does
   `cholesky(Symmetric((H.+H')./2); check=true)`. **This is the exact
   site.** The joint Hessian mixes a near-flat direction (the degenerate
   trait's `log r`, curvature ≈0 or slightly negative from FD noise) with
   well-conditioned β/γ/Λ/non-degenerate-`log r` directions. Two outcomes
   follow depending on exactly how near-singular that one direction is:
   - **Regime A (all 4 local/remote runs above):** the near-zero/negative
     eigenvalue is large enough relative to FD noise that
     `cholesky(...; check=true)` throws `PosDefException` → `factor ===
     nothing` → `pd=false` → `se=fill(NaN,10)` for **every** parameter,
     incl. well-identified β/γ/Λ. `nat`/`br` (identical θ̂) both go
     all-NaN; `_bx_ci_max_absdiff`'s `(isnan(x)&&isnan(y)) && continue`
     treats this as agreement → `d=0.0` → **PASSES** (matches pre-run
     Finding #1 — a real SE-availability gap, but *not* this test's fail).
   - **Regime B (reproduced locally at seeds 521, 525):** the Hessian is
     *barely* PD (`cholesky` succeeds, `pd_hessian=true`); the degenerate
     trait's `log r` gets a **finite but astronomically large** SE
     (Fisher info ≈0 along that direction). The bound `exp(θi + z*sei)`
     (`:1988`) then **overflows Float64 to `Inf`**. Both `nat`/`br`
     compute the *same* `Inf` (same θ̂, same Hessian) — **correct,
     agreeing** (unbounded CI at a Poisson-limit boundary is right). But
     `test/test_bridge_x.jl:38-49`:
     ```julia
     (isnan(x) && isnan(y)) && continue
     @test !(isnan(x) ⊻ isnan(y))
     isnan(x) || (d = max(d, abs(x - y)))
     ```
     When `x=y=Inf`, neither is NaN, so it reaches `abs(x-y)=abs(Inf-Inf)
     = NaN` (confirmed: `julia -e 'println(abs(Inf-Inf))'` → `NaN`), and
     `d=max(d,NaN)=NaN` (two-arg `max` propagates NaN) — `d` stays `NaN`
     for the rest of the loop regardless of any later finite comparison.
     Reproduced verbatim: seed 521 gives
     `nat.upper=br.upper=[...,Inf,Inf,113.86]` (r[1],r[2] both `Inf` both
     sides) → diff-detail print `term=r[1] side=upper br=Inf nat=Inf
     |Δ|=NaN`, `d=NaN`; seed 525 likewise for r[1]. **The exact mechanism
     turning two agreeing engines into a failing test.**

## Pattern comparison

- **Tweedie `:power_at_boundary`** (`src/families/tweedie.jl:209-232`)
  and **Student-t `nu_boundary`** (`src/families/studentt.jl:267-268,
  430-441`) both add a dedicated boolean field, force `converged=false`
  at the boundary, and `@warn` once. `NBGroupedFit`/`NBGroupedCovFit`
  have **no such field** — `grep -rn "boundary"
  src/families/grouped_dispersion.jl` returns only an unrelated
  `elseif reason === :power_at_boundary` branch reused from Tweedie's
  verdict helper, not a per-trait dispersion check.
- The four non-degenerate pre-run cells (Gaussian/Poisson/Binomial/Beta)
  agree with R to ≤1.1e-5 because none sit at a boundary; this NB2
  fixture incidentally does.
- **R/TMB** (from the pre-run doc, carried over, not re-verified here):
  `sdreport()` NaNs only entries whose block is degenerate, leaving every
  other SE finite — per-entry degradation, not all-or-nothing. No
  `pinv`/block-wise fallback exists anywhere in this repo (`grep -rn
  "pinv\b" src/*.jl src/families/*.jl` → no hits); `_family_wald` has one
  `cholesky(...;check=true)` over the whole joint Hessian, nothing else.

## Hypothesis (Phase 3) — tested

**H:** *The `NaN` at `test/test_bridge_x.jl:350` comes from
`_bx_ci_max_absdiff` (`:44`, `d = max(d, abs(x - y))`) computing
`abs(Inf - Inf) = NaN` when the NB2 grouped-cov Wald CI for a
boundary-degenerate trait's dispersion is correctly unbounded (`Inf`) on
**both** the native oracle and the bridge side — because the bound is
computed via `exp(θ ± z·se)` with `se` large enough to overflow — NOT
because `nat` and `br` disagree.*

**Minimal test performed:** isolated arithmetic —
`julia -e 'println(max(1.0, abs(Inf-Inf)))'` → `NaN`, confirming the
mechanism independent of model code. Then reproduced the model-level
version at seeds 521/525 (identical fixture shape), where
`nat.upper[r]=br.upper[r]=Inf` and the diff-detail print shows `|Δ|=NaN`,
reproducing `d=NaN` exactly as the CI symptom, on aarch64 locally.

**Whether seed 523 itself lands in Regime B on CI's x64/1.12.7
specifically was not independently confirmed** — not reproducible on
aarch64 1.12.6/1.10.12, x86_64-macOS/Rosetta 1.12.7, or Totoro's real
x86_64 Linux/1.12.6 (only 1.12.6, not CI's exact 1.12.7, was installable
there — `juliaup add 1.12.7` failed: Totoro has no outbound DNS to
julialang-s3.julialang.org). All four gave **regime A** for seed 523
(`d=0.0` PASS) while producing *measurably different* `r_group`/`β`/`Λ`
at the identical seed across Julia versions — proof the fit is
environment-sensitive at this near-degenerate optimum, consistent with
(not proof of) seed 523 tipping into regime B on CI's 1.12.7 x64.
**Residual candidate, not ruled out:** `Manifest.toml` is git-ignored
(`.gitignore:1`) — CI resolves a fresh dependency graph
(Optim.jl/NLSolversBase.jl/LineSearches.jl/ForwardDiff.jl) each run,
unpinned to any local `Manifest.toml`; a different resolved
Optim.jl/LineSearches.jl patch changing LBFGS's iteration trace could,
alone, move this knife-edge optimum from regime A to B, independent of
architecture. Untested (would need pinning/varying Optim.jl in a fresh
env) — flagged **AGENT-INFERRED**, not confirmed.

## Proposed fix (not implemented) + red-first test sketch

Two independent, additive fixes — root-cause, not tolerance widening:

1. **Fix the test helper's Inf-handling** (`test/test_bridge_x.jl:38-49`):
   treat `x == y` as zero-diff agreement for *any* value, not only NaN —
   add `(x == y) && continue` ahead of the `isnan` check (covers `Inf ==
   Inf`, `-Inf == -Inf`). Red-first test: unit test on
   `_bx_ci_max_absdiff` directly (no model fit) —
   `_bx_ci_max_absdiff(["a"],[Inf],[1.0],["a"],[Inf],[1.0])` must return
   `0.0`, not `NaN`; fails now, passes after the one-line fix.
2. **Root-cause engine fix** (mirrors Tweedie/Student-t): give
   `NBGroupedFit`/`NBGroupedCovFit` (and NB1/Beta/Gamma siblings) a
   `dispersion_boundary::Vector{Bool}` field set when a group's fitted
   dispersion exceeds a documented threshold (mirroring `ν > 1e6` /
   `_TWEEDIE_XI_MAX`), and force `converged=false` there
   (`studentt.jl:441` pattern). Separately, make `_family_wald` (`:1969`)
   degrade per-parameter, not all-or-nothing: on joint-Cholesky failure,
   fall back to a block-wise/`pinv` covariance so well-identified β/γ/Λ
   still get finite SEs (R-parity, closing pre-run Finding #1 too), and
   report `Inf`/`-Inf` explicitly at the overflow limit rather than
   NaN-ing. Red-first test: a fixture with one trait's dispersion forced
   far past boundary (`r=1e15` fixed) — after the fix, `confint(...).se`
   must be finite for β/γ/Λ and the non-degenerate trait's `r`,
   `dispersion_boundary[t]==true` for the forced trait, and the bridge
   test's `d` must be finite (not NaN) on the same fit both sides.

**Accept the fix when:** (a) new `_bx_ci_max_absdiff` unit test on
synthetic Inf/NaN vectors passes; (b) `test/test_bridge_x.jl:350` passes
at seed 523 **and** 521/525 (currently failing locally) without touching
`atol`/`d<1e-8`; (c) `dispersion_boundary` (or equivalent) appears on
`NBGroupedCovFit`'s fields and `Base.show`, following the `nu_boundary`
precedent; (d) no existing passing test's tolerance was widened.

## What this does NOT explain

- Why seed 523 tips into regime B on CI's exact Julia 1.12.7/x86_64/Linux
  combination — only that the mechanism (Inf-Inf test-helper bug) is
  real, reachable at this fixture shape, and distinct from the
  whole-Hessian-singular Finding #1. Four environments all gave regime A
  for seed 523 — Julia 1.12.7 on genuine x86_64 Linux (Totoro has no
  outbound network to fetch it) is the most direct remaining test, not
  obtained here.
- Does not address pre-run Finding #1 beyond noting the same
  all-or-nothing `cholesky` call is implicated in both.
- Does not evaluate whether `Manifest.toml` drift is the actual A→B
  trigger for seed 523 — untested, AGENT-INFERRED only.

## Ada verdict (2026-09-02, after independent verification)

Verified by reading the code, not the child's summary: `test/test_bridge_x.jl:38-49` computes
`abs(x - y)` for any non-NaN pair, so `Inf == Inf` yields `NaN`; `src/confint.jl:278-289` takes
`inv(Hsym)` of the full symmetrised **ForwardDiff** Hessian (the pre-run's "finite-difference
19×19" wording is wrong — it is AD), with no pseudo-inverse and no partition of boundary
parameters; `src/confint.jl:330-334` exponentiates dispersion bounds, so a huge log-scale SE
becomes `Inf`; `Manifest.toml` is git-ignored (`.gitignore:1`), so CI resolves dependencies
fresh each run.

**Root cause, layered.** (1) The seed-523 fixture is degenerate: two of three traits fit at the
NB→Poisson boundary (r = 5.5e9 and 2.5e20 on 1.12.6; the ordering of which traits diverge even
changes across Julia versions). (2) The Wald machinery has no boundary handling: it either NaNs
every parameter (singular joint Hessian) or returns `Inf` bounds (barely-PD Hessian) — R's
`sdreport` returns NaN only for the boundary block. (3) The test helper turns an *agreement* on
`Inf` into `NaN`. Environment sensitivity (Julia patch version, unpinned Manifest, x64 vs
aarch64) is the trigger that selects regime A or B; it is not the cause. Exact-seed reproduction
of regime B was not achieved on four environments including x64 Linux and Rosetta 1.12.7; it was
reproduced at seeds 521 and 525 with the same fixture shape.

**Fix set, in root-cause order (none applied here):**
- F1 engine: per-group `dispersion_boundary` flag for NB2/NB1/Beta/Gamma grouped fits (threshold
  documented, mirrors `nu_boundary` / `:power_at_boundary`), `converged=false` at the boundary,
  and per-parameter Wald degradation (boundary rows conditioned out or `pinv`, NaN only for the
  flagged entries) — closes pre-run finding #1 as well; red-first test with a trait fixed at
  r=1e15. Maintainer sign-off needed (fit-health semantics change).
- F2 test fixture: the bridge-plumbing identity at `test_bridge_x.jl:340-351` should run on a
  well-conditioned NB fixture (seed chosen so all three r are O(1–100), asserted in the test), and
  additionally assert the same NaN/boundary pattern on both sides for a deliberately degenerate one.
- F3 helper: `_bx_ci_max_absdiff` treats `x == y` (incl. `Inf`) as zero difference — a genuine
  helper bug, but on its own it would only hide F1/F2.
