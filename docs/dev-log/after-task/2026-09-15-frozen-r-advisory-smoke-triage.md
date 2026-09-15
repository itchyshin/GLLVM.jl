# After-task — Frozen R 0.7.0 advisory smoke triage (post-#345)

**Date:** 2026-09-15  
**Lane:** `docs/frozen-r-smoke-triage-20260915` (isolated worktree from `origin/main`)  
**Scope:** Docs-only diagnosis + ranked fix-or-waive map. **No** tolerance changes, **no** CI gating flip, **no** `#323` reopen.

## Evidence anchor

| Item | Value |
|---|---|
| **Canonical CI run (post-#345 merge)** | [CI `34947816972`](https://github.com/itchyshin/GLLVM.jl/actions/runs/34947816972) |
| **Merge commit exercised** | `34947816972` parent merge of [#345](https://github.com/itchyshin/GLLVM.jl/pull/345) |
| **`main` at triage** | `25af0c0f1414f5f776febc0eb48ee3b78835756f` (includes #348; advisory job unchanged) |
| **Job** | `Frozen R 0.7.0 family smoke (advisory; rebuilt oracle)` — `continue-on-error: true` |
| **Suite tally (this run)** | **278 pass / 8 fail** / 0 errored |
| **Prior brief tally (#294 era)** | **277 pass / 9 fail** — [`advisory-r070-smoke-fail-brief-2026-09-05.md`](../core070/advisory-r070-smoke-fail-brief-2026-09-05.md) |
| **Frozen R source pin** | gllvmTMB **0.7.0** @ `b4d5fee64def88bc768dda1f1f77c29b295edd86` |
| **#323 disposition** | **WAIVED (B)** — [`2026-09-14-advisory-frozen-r-smoke-323-pending.md`](../decisions/2026-09-14-advisory-frozen-r-smoke-323-pending.md) **ACCEPTED** 2026-09-15; ≠ smoke green |

### Cell-level Test Summary (run `34947816972`)

| CORE-070 cell | Pass | Fail | Total | Δ vs 2026-09-05 brief |
|---|---:|---:|---:|---|
| `NATIVE-06-NB2` | 15 | 3 | 18 | Was 17/1; **+2 R-side health fails** on this runner build |
| `NATIVE-12-TRUNCATED-NB2` | 21 | 0 | 21 | Was 20/1; **green** on this run |
| `NATIVE-10-STUDENT` | 28 | 5 | 33 | Was 26/7; **−2 fails** (near-Gaussian R health now passes) |

---

## Ranked failure inventory (8 live assertions + 1 historical)

Each row is one failing `@test` on run `34947816972`. Historical row **H9** is the truncated-NB2 fail that still appeared at #345 discussion time but is **green** on the measured merge run.

| Rank | ID | Cell | File:line | Assertion (summary) | CI measured (when numeric) | Failure class | Recommendation |
|---:|---|---|---|---|---|---|---|
| 1 | F1 | `NATIVE-06-NB2` | `test/parity/test_negbin_parity.jl:84` | `r_gradient_max ≤ 1e-4` | **2.43×10⁻³** | **CI rebuilt-oracle / R health gate** — same source pin, different `installed_tree_sha256` vs retained Totoro receipt; documented in [`ci-oracle-reproducibility-finding.md`](../core070/ci-oracle-reproducibility-finding.md) | **Leave advisory**; optional **needs-Totoro** refresh against retained build (Track B in G7 handoff) — **not** a Julia likelihood defect |
| 2 | F2 | `NATIVE-06-NB2` | `test/parity/test_negbin_parity.jl:72` | `jl_fit.converged` | `false` (groups 1,3 at dispersion boundary) | **Expected advisory noise** — intentional T14 F1 boundary honesty (`grouped_dispersion.jl`); Δ logLik **1.8×10⁻⁷** still passes | **Leave advisory**; **fix-now (local)** only via **separate tracked issue**: revisit seed-45 fixture vs public “must converge” claim — **do not** widen tolerance |
| 3 | F3 | `NATIVE-06-NB2` | `test/parity/test_negbin_parity.jl:91` | `r.converged` | `false` (follows F1 R fit path) | **Cascade from F1** — R optimizer/gradient state on rebuilt oracle | **Leave advisory** with F1 |
| 4 | F4 | `NATIVE-10-STUDENT` | `test/parity/test_studentt_parity.jl:113` | `r_est.converged` | `false` | **R-side identifiability / false convergence** — seed 71 estimated-ν; flat Gaussian-limit boundary | **Leave advisory**; aligns with #323 waive fence |
| 5 | F5 | `NATIVE-10-STUDENT` | `test/parity/test_studentt_parity.jl:114` | `r_est.optimizer_code == 0` | **1** (`"false convergence (8)"`, 130 iter) | Same as F4 | **Leave advisory** |
| 6 | F6 | `NATIVE-10-STUDENT` | `test/parity/test_studentt_parity.jl:119` | `jl_est.converged` | `false` (ν > 1e6 boundary warning) | **Julia boundary honesty** — not a math bug; pairs with F4–F5 on weakly identified ν | **Leave advisory**; prior diagnosis: [`advisory-studentt-cell9-fail-diagnose-2026-09-05.md`](../core070/advisory-studentt-cell9-fail-diagnose-2026-09-05.md) |
| 7 | F7 | `NATIVE-10-STUDENT` | `test/parity/test_studentt_parity.jl:146` | `abs(Δ logLik) ≤ 0.001` | **2.86×10⁻³** | **Advisory noise at boundary** — engines at different flat-limit trajectories; fixed-ν control on same Y still ~4×10⁻⁹ | **Leave advisory**; **needs-decision** only if promoting estimated-ν seed-71 to gating (rejected under #323) |
| 8 | F8 | `NATIVE-10-STUDENT` | `test/parity/test_studentt_parity.jl:191` | `jl_diag.converged` (near-Gaussian, seed 73) | `false` | **Julia boundary honesty** on intentional ν=1e6 DGP; R lines **189–190 pass** on this run | **Leave advisory**; diagnostic block is explicitly non-substitute for Cell 9 |
| — | **H9** | `NATIVE-12-TRUNCATED-NB2` | `test/parity/test_truncated_nbinom2_parity.jl:80` | `r_gradient_max ≤ 1e-4` | *Not failing on `34947816972`* (21/21) | Was **CI oracle rebuild** class on 2026-09-05 (**5.9×10⁻⁴**) | **No action** on `main` today; keep cited in #345-era notes only |

---

## Fix-or-waive map (programme level)

| Track | Items | Rationale |
|---|---|---|
| **Leave advisory (default)** | F1–F8 | Blocking merge gate remains **8/8 Julia + Documenter** only; job stays `continue-on-error: true`; #323 closed as **maintainer waive**, not pass evidence |
| **Fix-now (local, optional)** | F2 only | Product/test-design: boundary fixture still encodes `@test converged` — fix belongs in a **new issue**, not silent tolerance or gating flip |
| **Needs-Totoro** | F1 (+ optional JSON refresh for OWED note) | Retained-build `r_gradient_max` receipt vs CI rebuild — G7 handoff + launch pack; requires separate **D-139 ack** |
| **Needs-decision (maintainer)** | F7 if ever gating | Whether seed-71 estimated-ν remains a **public parity gate** vs diagnostic-only — **out of scope** while #323 waived |
| **Do not** | All | Widen `1e-4` / `0.001` bars; set advisory job blocking; reopen #323 unless opening a **new** tracked issue |

---

## Oracle / drift notes

1. **Source pin is stable:** all parity helpers and DestB tools record `b4d5fee64def88bc768dda1f1f77c29b295edd86`.
2. **Build pin is not:** CI rebuilds gllvmTMB on ubuntu with date-locked CRAN snapshot (`.github/workflows/CI.yml` `test-parity`); `installed_tree_sha256` differs from retained Totoro authority — see workflow comment (measured **2.4×10⁻³** `r_gradient_max` on NB2 fixture).
3. **Julia parity on failing cells:** NB2 Δ logLik **1.8×10⁻⁷**; Student-t fixed-ν block passes; estimated-ν Δ **2.9×10⁻³** at boundary — consistent with **health/identifiability**, not engine regression on #345 merge.

---

## Rose fence (binding)

- **≠** “frozen-R smoke is green on `main`.”
- **≠** Julia↔R full family parity or Core 0.7.0 ledger promotion.
- **=** Read advisory job conclusion **separately** from Julia shards + Documenter.
- **=** #323 **waived** — this triage **does not** reopen #323; H9/doc references are historical context only.

---

## Checks (this lane)

| Check | Result |
|---|---|
| Files touched | `docs/dev-log/after-task/2026-09-15-frozen-r-advisory-smoke-triage.md` only |
| CI / tests run locally | None (docs-only) |
| Tolerance / workflow edits | None |

---

## Follow-up (not in this PR)

1. Optional: append post-#345 measured values to `docs/dev-log/owed/advisory-frozen-r-smoke-2026-09-14.md` in a **separate** docs slice.
2. Optional: file **new** issue for NB2 seed-45 `converged` vs boundary honesty (F2) if maintainer wants advisory suite to shrink fails without widening bars.
3. Totoro Track A/B only after explicit **`ack Totoro D-139`** (see issue-323 launch pack).
