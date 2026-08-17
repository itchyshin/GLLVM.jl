## ARC CARD — AGHQ Stage-1a grid + k=1 golden

**Mode:** size
**Requested outcome:** not quantified — a new live-pin grid symbol plus a
golden test that `k = 1` matches the existing dense Laplace marginal
**Mechanism authority:** worktree `cursor/aghq-stage1a-20260817` off
`origin/main`; focused local test only; no push/PR until Shinichi asks.
Explicit exclusions: public `aghq=` knob, ledger promotion, twin Δ,
per-site adaptation, structural gate, adaptation loop, report honesty,
`aghq_ridge`, Tweedie surfaces, Dropbox checkout, #247
**Recommended arc:** 90 minutes (range 60–120)
**Time contract:** ceiling 2 h
**Estimate confidence:** inferred (Identity #248 + twin `.gllvmTMB_aghq_grid`
already pinned; analogue is a focused family-kernel + one test file)
**Arc 0 outcome:** `aghq_grid(d, k)` on the live pin, identity check, and
`k = 1` site/marginal evaluation matching `laplace_loglik_site` /
`poisson_marginal_loglik_laplace`
**State transition:** no AGHQ engine → Stage-1a grid + golden (ledger rows
stay `missing`)
**Executable rung and evidence:** new `src/families/aghq_grid.jl` +
`test/test_aghq_grid.jl`; Mac-light
`julia --project=. --startup-file=no test/test_aghq_grid.jl`

### Budget
| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 15 | Identity A4(1) + twin live pin already scouted |
| Core | 40 | grid + k=1 evaluator + fail-loud guards |
| Verify | 20 | focused test file |
| Repair reserve | 10 | identity / measure mix-up |
| Closeout | 5 | check-log + after-task |
| **Total** | **90** | |

**In scope:** probabilists' GH (`_aghq_gh_normal`, not `_gauss_hermite`);
three-term `logw`; `Σ_j exp(logw_j) φ_d(u_j) = 1`; k=1 ≡ Laplace; fail-loud
unless loadings-only `z_B` and `k = 1`
**Not in this arc:** A4 items (2)–(5); public knob; ledger promote; twin Δ
**Evidence used:** #248 Identity; twin `R/fit-multi.R` `.gllvmTMB_aghq_grid` /
`.gllvmTMB_gh_normal` (read-only)
**Risk branch:** If k=1 does not match Laplace to ~1e-10, stop and inspect
measure (`_gauss_hermite` physicists' vs live probabilists') — do not widen
tolerance.

**Done when:** focused test passes; both AGHQ ledger rows still `missing`;
no `aghq=` on `fit_gllvm`; `_gauss_hermite` not called.
**First action:** write `src/families/aghq_grid.jl`.

EXECUTE DIRECTLY: Arc 0 grid + k=1 golden, starting at `src/families/aghq_grid.jl`.

### Actuals (complete at close)
**Recommended / actual:** 90 / ~75 minutes · **Requested / used:** N/A / ~75 minutes · **Rungs/cohorts completed:** Arc 0
**Under-run event:** none — drafts + Hopper pin already retired the measure unknown
**Calibration:** orient was shorter than 15 min because Identity + Hopper pin were in hand
**Metric movement:** no AGHQ engine → Stage-1a grid + golden; ledger rows still `missing`
**Result:** capacity used · **Next arc:** A4(2) per-site adaptation (unpaid; not this PR)

### Actuals (complete at close)
**Recommended / actual:** 90 / ~45 minutes · **Requested / used:** N/A / ~45 minutes · **Rungs/cohorts completed:** Arc 0
**Under-run event:** Arc 0 predicted 90, actual ~45; Identity + live pin already scouted, so orient was short
**Calibration:** orient bucket was high — next Stage-1a-style kernel can budget ~10 min orient when the Identity already names the pin
**Metric movement:** no AGHQ engine → Stage-1a grid + k=1 golden; ledger rows still `missing`
**Result:** capacity used (under-run) · **Next arc:** A4 item (2) per-site adaptation, only after a fresh arc card; no public knob

