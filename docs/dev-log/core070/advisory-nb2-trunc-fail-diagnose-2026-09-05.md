# Advisory R 0.7.0 smoke — NB2 and truncated NB2 fail diagnosis

**Date:** 2026-09-05  
**Run:** [CI 33979515590](https://github.com/itchyshin/GLLVM.jl/actions/runs/33979515590) · job `101342094437`  
**Branch / SHA:** `cursor/m2-foundation-day1-20260905` @ `591022641` (PR #294 context)  
**Job:** `Frozen R 0.7.0 family smoke (advisory; rebuilt oracle)` — **continue-on-error**  
**Artifacts:** `frozen-core070-family-smoke` (`ci-parity-receipts/*`, `r-build/build.json`)

Scope: the two cells named in the PR #294 advisory smoke brief — **not** Student-t (7 fails in the same run).

---

## Executive summary

| Cell | Failed assertion | Measured | Retained-oracle contrast | Likely cause | Disposition |
|---|---|---:|---|---|---|
| `NATIVE-06-NB2` | `jl_fit.converged` (`test_negbin_parity.jl:72`) | `false` | Retained build **18/18 pass** on same fixture hash | Julia optimizer landed at **dispersion boundary** (groups 1, 3); T14 F1 forces `converged=false` — build-sensitive trajectory, not a parity/math defect | **Accept advisory-red**; optional **separate ticket** to revisit fixture vs assertion |
| `NATIVE-12-TRUNCATED-NB2` | `d["r_gradient_max"] <= 1e-4` (`test_truncated_nbinom2_parity.jl:80`) | **5.90×10⁻⁴** | Retained build **2.75×10⁻⁵** (passes) | **CI oracle rebuild** — same source, different `installed_tree_sha256`; R BFGS continuation stops short of retained-build gradient bar | **Accept advisory-red** (documented class) |

**Do not widen tolerances.** Neither fail is evidence of a Julia likelihood bug or gllvmTMB 0.7.1 drift (CI uses frozen **0.7.0** @ `b4d5fee6`).

---

## Run context

- Oracle: gllvmTMB **0.7.0** source @ `b4d5fee6`, rebuilt on ubuntu runner (R 4.5.3, Julia 1.12.7).
- BLAS pinned: `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`, `JULIA_NUM_THREADS=1`.
- CI `installed_tree_sha256`: `d836c1575e5fbe01725236961e8dcb8eb5c0ac265aaf3ed271f883b3a21ce686`
- Retained Totoro authority build: `b25f5b8838d1d476a95f4e79133a5c72fad2496d648ef97cd9422acd39bc5bb5` (same `source_tree_sha256`, different compiled tree — see [`ci-oracle-reproducibility-finding.md`](./ci-oracle-reproducibility-finding.md)).
- Suite tally on this run: **277 pass / 9 fail** (Student-t accounts for 7 of the 9).

---

## 1. `NATIVE-06-NB2` — Negative Binomial (seed 45, p=5, K=2, n=80)

### What failed

```julia
# test/parity/test_negbin_parity.jl:72
@test jl_fit.converged
```

CI log:

```
Expression: jl_fit.converged
```

Immediately preceded by:

```
Warning: NB2 grouped-dispersion fit reached the per-group boundary (r_group outside [1e-6, 1e6])
for group(s) [1, 3]; ... optimizer convergence flags are unreliable for them.
```

### What still passed (17/18)

From artifact `ci-parity-receipts/nb2-health.toml` and log block:

| Quantity | CI value | Gate | Pass? |
|---|---:|---|:---:|
| `r_code` | 0 (`relative convergence (4)`) | R converged | ✓ |
| `r_gradient_max` | **5.62×10⁻⁵** | ≤ 1e-4 | ✓ |
| `native_gradient_max` | 1.40×10⁻⁶ | ≤ 1e-4 | ✓ |
| `loglik_delta` | 3.95×10⁻⁶ | rtol 1e-6 | ✓ |
| `samepoint_delta` | −7.96×10⁻¹³ | ≤ 1e-6 | ✓ |
| Health block (lines 78–90) | all predicates | — | ✓ (ran after line-72 fail in same testset) |

**Important:** this CI fail is **Julia-side `converged`**, not R-side `r_gradient_max`. That differs from the Option D live-R slice ([`advisory-r-smoke-nb2-studentt-2026-09-05.md`](./advisory-r-smoke-nb2-studentt-2026-09-05.md)), where live **0.7.1** missed the gradient bar at **1.35×10⁻⁴**.

### Mechanism (intentional wiring)

`fit_gllvm(...; family=NegativeBinomial())` returns `NBGroupedFit`. After Optim finishes, T14 F1 sets:

```julia
# src/families/grouped_dispersion.jl:386-389
boundary = _dispersion_group_boundary(r̂g)
# ...
return NBGroupedFit(..., conv && !any(boundary), ...)
```

CI fitted per-trait dispersion (log scale excerpt from receipt):

- Trait 1: `r ≈ 2.64×10²⁴` (group 1 boundary)
- Trait 3: `r ≈ 5.76×10⁹` (group 3 boundary)
- Traits 2, 4, 5: O(1–10) — well interior

R's dispersion vector shows the same pathology pattern (`r_dispersion[1] ≈ 2.16×10⁹`, trait 3 ≈ 9.2×10⁵) while still reporting `converged = TRUE`. Julia correctly refuses to advertise convergence at the boundary.

The seed-45 toy fixture is **knife-edge**: latent loadings can absorb overdispersion for some traits, driving φ/r to the Poisson-limit rail. Optimizer starting path differs between retained build and CI rebuild → boundary hit on CI, not on authority receipt (18/18 on retained build per [`ci-oracle-reproducibility-finding.md`](./ci-oracle-reproducibility-finding.md) and [`nb2-required-evidence.json`](./nb2-required-evidence.json)).

### Ruling out other hypotheses

| Hypothesis | Verdict |
|---|---|
| Oracle pin vs 0.7.1 drift | **Ruled out** for this run — frozen 0.7.0 rebuild, not live 0.7.1 |
| Julia likelihood / gradient bug | **Ruled out** — `native_gradient_max` 1.4×10⁻⁶, `loglik_delta` 4×10⁻⁶, same-point identity holds |
| Stale fixture / data hash | **Ruled out** — `data_sha256 = 7abde273…` matches locked DGP |
| Known flake (random DGP) | **Ruled out** — fixed seed 45, deterministic failure class |
| R-side health regression | **Ruled out on this run** — `r_gradient_max` passes |

### Recommended disposition — NB2

**Accept advisory-red** for PR #294 merge posture (job already non-blocking).

Optional follow-up (**separate ticket**, not merge blocker):

- Revisit whether line 72 should assert `!any(jl_fit.dispersion_boundary)` + finite `loglik` (sentinel pattern from `test_known_sentinel_defects.jl`) instead of raw `converged`, **or**
- Replace seed-45 DGP with a well-conditioned NB2 fixture for the *converged* bar while keeping a dedicated boundary sentinel cell.

**Do not:** widen `r_gradient_max`, relax `converged` wiring, or treat as gllvmTMB engine surgery.

---

## 2. `NATIVE-12-TRUNCATED-NB2` — zero-truncated NB2 (seed 58, p=5, K=1, n=120)

### What failed

```julia
# test/parity/test_truncated_nbinom2_parity.jl:80
@test d["r_gradient_max"] <= 1e-4
```

CI log:

```
Evaluated: 0.0005901797966929578 <= 0.0001
```

### What still passed (20/21)

From `ci-parity-receipts/truncnb2-policy.toml`:

| Quantity | CI value | Gate | Pass? |
|---|---:|---|:---:|
| `native_converged` | `true` | — | ✓ |
| `native_gradient_max` | 6.54×10⁻⁶ | ≤ 1e-4 | ✓ |
| `r_code` | 0 | R converged | ✓ |
| `loglik_delta` | 7.35×10⁻⁷ | rtol 1e-6 | ✓ |
| `samepoint_delta` | 1.14×10⁻⁸ | ≤ 1e-6 | ✓ |
| Default R fit (`original_r_code`) | 0 | — | ✓ |
| Fisher vs observed regression | distinct objectives | — | ✓ |

Largest R gradient component: trait 3 index, **5.90×10⁻⁴** (BFGS continuation policy `truncnb2_default_then_public_bfgs_v1`).

### Retained-oracle contrast

From [`truncnb2-required-evidence.json`](./truncnb2-required-evidence.json) (authority campaign, same policy, same fixture hash `ecbcf9f5…`):

| Quantity | Retained build | CI rebuild | Ratio |
|---|---:|---:|---:|
| `r_gradient_max` | **2.75×10⁻⁵** | **5.90×10⁻⁴** | ~21× |
| `loglik_delta` | 8.67×10⁻⁸ | 7.35×10⁻⁷ | same order |
| `native_gradient_max` | 6.54×10⁻⁶ | 6.54×10⁻⁶ | identical |

Julia side is **bit-stable**; only R's post-BFGS gradient norm moves with compiled-oracle differences. This is the canonical pattern from [`ci-oracle-reproducibility-finding.md`](./ci-oracle-reproducibility-finding.md): health gates calibrated on a **specific build artifact**, not reproducible from source-only CI rebuilds.

Option D live **0.7.1** advisory measured **6.47×10⁻⁴** on the same predicate — same failure class, different build.

### Ruling out other hypotheses

| Hypothesis | Verdict |
|---|---|
| Julia truncNB2 kernel / observed-Hessian regression | **Ruled out** — native gradients pass; log-likelihood agreement passes |
| Policy / fixture change | **Ruled out** — fixture hash locked; policy unchanged |
| R default fit failure | **Ruled out** — `TRUNCNB2_DEFAULT_STATUS 0 relative convergence (4)` |
| Known random flake | **Ruled out** — fixed seed 58 |

### Recommended disposition — truncated NB2

**Accept advisory-red.** Documented CI-oracle rebuild limitation; retained pinned receipts remain authority ([`truncnb2-required-evidence.json`](./truncnb2-required-evidence.json): **21/21 PASS**).

Longer-term owed item (already in reproducibility note): re-express blocking gates as **cross-engine same-run invariants**, not R-only gradient magnitude at R's own optimum on a different build.

**Do not:** widen `1e-4` without a retained-build remeasurement campaign.

---

## Cross-reference map

| Document | Relevance |
|---|---|
| [`ci-oracle-reproducibility-finding.md`](./ci-oracle-reproducibility-finding.md) | Root cause for truncated NB2; partial analogue for optimizer trajectory sensitivity |
| [`advisory-r070-smoke-fail-brief-2026-09-05.md`](./advisory-r070-smoke-fail-brief-2026-09-05.md) | One-line fail index for PR #294 run |
| [`advisory-smoke-fail-disposition-2026-09-05.md`](./advisory-smoke-fail-disposition-2026-09-05.md) | Live 0.7.1 Option D disposition (gradient-class fails) |
| [`nb2-required-evidence.json`](./nb2-required-evidence.json) | Retained 39-assertion PASS including both cells |
| [`truncnb2-required-evidence.json`](./truncnb2-required-evidence.json) | Retained `r_gradient_max = 2.75×10⁻⁵` |
| [`decisions/2026-08-30-core070-truncnb2-limit.md`](../decisions/2026-08-30-core070-truncnb2-limit.md) | Near-limit algebra; warns against weakening health gate |

---

## Evidence commands (replay)

```sh
# Failed log excerpt
gh run view 33979515590 --repo itchyshin/GLLVM.jl --log-failed

# Artifact receipts (NB2 + truncNB2)
gh run download 33979515590 --repo itchyshin/GLLVM.jl \
  -n frozen-core070-family-smoke -D /tmp/ci-parity-receipts
```

Key files: `ci-parity-receipts/nb2-health.toml`, `truncnb2-policy.toml`, `cell-NATIVE-06-NB2.toml`, `cell-NATIVE-12-TRUNCATED-NB2.toml`, `r-build/build.json`.

---

## Sign-off table

| Cell | Accept advisory? | Fix in Julia? | Widen tolerance? | Separate ticket? |
|---|---|---|---|---|
| `NATIVE-06-NB2` | **Yes** | Optional: fixture/assertion review only | **No** | Optional: boundary-aware test design |
| `NATIVE-12-TRUNCATED-NB2` | **Yes** | **No** | **No** | Track under CI build-independent gate programme |

**Rose lens:** Neither fail contradicts retained-build parity evidence or promotes capability claims. Advisory job behaviour matches documented expectation.
