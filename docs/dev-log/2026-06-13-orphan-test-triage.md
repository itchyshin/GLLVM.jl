# Orphan test triage (2026-06-13)

Audit #4 flagged ~9 "functional" test files not wired into `runtests.jl`. I ran
all 9 standalone in one Julia process (mimics the `using GLLVM` + sequential
`include` of `runtests.jl`). Reality is messier than the audit assumed —
**only 5/9 pass, and one of those is far too slow for the routine suite.**

Branch: `codex/non-gaussian-fitter-gradients`.

## Wired into runtests.jl (green + fast)

| file | time | note |
|---|---|---|
| `test_edge_incidence.jl` | 5.5 s | edge-node incidence representation |
| `test_phylo_contrasts.jl` | 23 s | Felsenstein contrasts |
| `test_phylo_branch_re.jl` | 60 s | per-branch random effects |
| `test_relaxed_clock.jl` | 22 s | relaxed-clock prototype |

Added 2026-06-13 before `test_quality.jl`.

## Passes but TOO SLOW — not wired

- **`test_em_squarem_safety.jl` — PASSES but 2274 s (~38 min).** Wiring it would
  blow the routine suite runtime. **Recommend gating behind a `GLLVM_SLOW_TESTS`
  env flag** (same treatment proposed for the COM-Poisson suite, #16), then wire.

## Failing — NOT wired, need diagnosis

| file | time | symptom |
|---|---|---|
| `test_confint_derived_wald.jl` | 17.9 s | runs, then assertion/errors |
| `test_em_phylo.jl` | 1.1 s | early failure |
| `test_em_squarem.jl` | 0.1 s | instant — likely an include-time error |
| `test_sparse_phy_grad.jl` | 213 s | **1 pass / 7 errored**; audit also noted a double-`include` of an already-loaded module at line 8 |

These live on the heavy non-Gaussian-gradient branch, so failures may be API
drift OR real regressions. Error details from the first run were truncated by a
`tail -40` pipe; re-running individually with full output to characterise
(real-bug vs stale-test) before deciding fix-vs-park.

## Note

The 4 wired files were green in a shared-process run (module pre-loaded, as in
`runtests.jl`). The full-suite `Pkg.test()` re-run is terminal-side (~25 min+);
not run in-agent.
