# Review: one-part lognormal Identity — ceiling verdict (Opus tier)

**Verdict:** **APPROVED** — `ACCEPTED` status upheld; no blockers.
**Date:** 2026-08-15
**Reviewer role:** ceiling judgment (Rose/Opus tier), adversarial cite audit. Judgment only —
no engine code written by this review.
**Target:** `docs/dev-log/decisions/2026-08-15-lognormal-identity.md` @ `06a3b5a1`
(docs-only, 1 file, +69).
**Lane:** `cursor/lognormal-identity-20260815` (WT `.worktrees/gllvmjl-lognormal-identity-20260815`).
**Programme:** parallel family catch-up 2026-08-15; base = catch-up tip `b2b99463`.

## Method

Every load-bearing twin cite was re-derived from `gllvmTMB` source at file:line rather than
accepted from the decision doc. Julia-side gap claims were re-derived from this worktree.

## Twin cite audit — all verified

| Identity claim | Evidence located | Verdict |
|---|---|---|
| `lognormal()` constructor, `okLinks = identity/log/inverse` | `R/families.R:105-117` | VERIFIED |
| Engine admits **log only** | `R/fit-multi.R:468-469` — `if (fid == 3L && !identical(f$link, "log")) cli_abort("lognormal: only the log link is currently supported.")` | VERIFIED verbatim |
| `family_to_id`: `lognormal = 3L` | `R/enum.R:9`; `R/fit-multi.R:421` | VERIFIED |
| TMB dens fid 3 = `dnorm(log(y), η, σ_eps, true) - log(y)` | `src/gllvmTMB.cpp:2203-2206` | VERIFIED verbatim |
| Dispersion = **shared scalar** `PARAMETER(log_sigma_eps)` | `src/gllvmTMB.cpp:637` (scalar `PARAMETER`, not `PARAMETER_VECTOR`) | VERIFIED |
| Mapped off when no row has fid ∈ {0, 3} | `src/gllvmTMB.cpp:365`; `R/fit-multi.R:4773-4783` — `any_sigma_eps <- any(family_id_vec %in% c(0L, 3L))`, else `tmb_map$log_sigma_eps <- factor(NA_integer_)` | VERIFIED verbatim |
| fid 12 delta uses **per-trait** `log_sigma_lognormal_delta` (distinct from fid 3) | `src/gllvmTMB.cpp:831`, `2295-2309` | VERIFIED |
| Abort/supported-family message lists `lognormal()` | `R/fit-multi.R:438` | VERIFIED |
| Support `y > 0` strictly | Stronger than cited: twin **fails loud** at `R/fit-multi.R:2617-2624` — "Lognormal and Gamma rows: `y` must be strictly positive", gated by `positive_rows <- (family_id_vec %in% c(3L, 4L)) & !masked_response` | VERIFIED (see C2) |

No cite was found to be overstated, and **no bias correction** exists in the twin kernel: η is
the mean of `log y`, not `log E[y]`. The doc's `E[log y] = η` lock is exactly right, and the
common `log(mu) - σ²/2` variant found in sibling ecology packages is correctly *not* adopted.

## Julia-side gap claims — verified independently

- Ledger `docs/design/capability-status.md:87` = `| lognormal | planned |`; line 93
  `| delta_lognormal | implemented |`. Problem statement is accurate.
- No one-part fitter exists: `fit_lognormal_gllvm` / one-part `LogNormalFit` absent from `src/`
  and `test/`; only `DeltaLogNormalFit` (`src/families/twopart.jl:190-280`). Gap is real.
- Packing `[β; pack(Λ); log σ]` matches the live convention: sibling drivers pack via
  `pack_lambda(Λ0)` (e.g. `src/families/gamma.jl:205`), notwithstanding a looser
  `vec(Λ)` phrasing in some docstrings. Lock is idiomatic.
- Scalar dispersion matches the one-part family idiom (`σ::Float64` / `φ::Float64` /
  `α::Float64` across `src/families/`).

**Strongest structural point in the Identity's favour, worth recording:** for fid 3 the twin's
dispersion is *itself* a scalar `PARAMETER`, so Julia's shared scalar `σ` is **exactly
twin-faithful rather than a v1 simplification**. Contrast Gamma (fid 4), where the twin carries
per-trait `log_phi_gamma(t)` and Julia's scalar shape *is* a simplification. Lognormal is a rare
cell where v1 can match the twin parameterisation with no residual gap.

## Blockers

**None.** Identity is twin-faithful, correctly fenced, and structurally at or above the
immediately preceding sibling precedent (`2026-08-15-truncated-poisson-identity.md`).

## Binding conditions for engine Wave2 (acceptance conditions, not blockers)

**C1 — parity must be checked at the log-likelihood scale, not only at estimates.**
The Jacobian `−log(y)` is a data-only additive constant: an implementation that drops it returns
**identical point estimates and identical σ̂** while its log-likelihood is shifted by
`Σ log y`. An estimate-only comparison therefore cannot detect the single most likely
implementation error in this family. Any light RCall Δ must compare `logLik` values.
Note `Distributions.logpdf(LogNormal(η, σ), y)` equals `dnorm(log y; η, σ) − log y` exactly,
so an exact twin match is available without hand-rolling the Jacobian.

**C2 — the `y ≤ 0` guard must be mask-aware.**
The twin gates its abort on `& !masked_response`, i.e. masked/missing cells are exempt.
A Julia guard that scans all of `Y` will fail loud on legitimately masked cells and will
diverge from the twin on any masked cell. This detail is absent from the Identity as written;
treat it as part of the lock.

**C3 — the FD statement must be named and quantitative.**
"FD ≤ 1e-6" is honest and matches the programme's forbidden-list on silent rtol, but the doc
does not name the check. Engine wave must state: central-difference gradient of the packed
objective vs the analytic/AD gradient, over the **full** packed vector **including `log σ`**,
and report the max componentwise deviation as a number. A pass/fail bit is not evidence.
If a cell fails, diagnose Identity vs numerical — do not widen.

**C4 — closure artefacts.** The Identity commit did not touch `docs/dev-log/check-log.md`
(AGENTS.md rule 7). Acceptable for a docs-only Identity; the check-log entry and after-task
report must land with the engine wave, per programme DoD item 5.

**C5 — do not launder the delta gap.** Julia's `DeltaLogNormal` carries a **shared scalar** σ
(`src/families/twopart.jl:150-151`) while the twin's fid 12 uses **per-trait**
`log_sigma_lognormal_delta`. That is a pre-existing two-part gap, correctly out of this lane's
scope. This Identity must not be cited as evidence that `delta_lognormal` is twin-faithful.

## Non-blocking observations

- The `Programme:` pointer (`lanes/gllvmjl-parallel-family-catchup-20260815/LOOP/`) resolves in
  the programme worktree, not in this one. Path is programme-relative; cosmetic only.
- Sibling precedent exists for shipping an executable Identity test alongside the doc
  (`test/test_gamma_x_identity.jl`, `test_zip_x_identity.jl`, `test_betabinomial_x_identity.jl`).
  Recommended, not required, for the lognormal engine wave: a cheap executable lock is the
  cheapest defence against C1.

## Fences observed by this review

No twin Δ invented — the twin admits one-part lognormal (fid 3, live cpp kernel), so light
RCall Δ is legitimately available; nothing was asserted about ZIP/ZINB/ZIB. No ADEMP or
coverage claim is made or implied. No engine implementation was written. No capability claim:
`lognormal` remains `planned` in the ledger until FD + focused tests + ledger flip land.

## STOP / CONTINUE

**CONTINUE** to the lognormal engine on owned files (`src/families/lognormal.jl`,
`test/test_lognormal.jl`, this lane's decision docs) under C1–C5.
