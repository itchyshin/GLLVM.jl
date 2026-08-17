# Decision: AGHQ estimator Identity — missing, not a surface admit

**Date:** 2026-08-17
**Status:** ACCEPTED as a decision record; **engine NOT started** (STOP)
**Lane:** `cursor/aghq-identity-20260817`
**Tip probed:** `51ffa320` (merge of #246, OrderedBeta no-X admit)
**Depends on:** capability gap sheet
`docs/dev-log/plans/2026-08-16-gllvmtmb-capability-gap.md` (named AGHQ the
largest *estimator-shaped* twin gap); Tweedie Identity
`2026-08-16-tweedie-fit-gllvm-identity.md` (#234) as the STOP-shaped
precedent (lock first; do not ship a public knob that cannot earn it).
**Do not** open a Tweedie `fit_gllvm` admit (Identity STOP; T2–T5 unpaid).
**Do not** invent a twin `gllvmTMB` light Δ. **Do not** touch `src/`.
**Do not** add a stub `aghq=` keyword that only errors.

## Why this slice, not another north-star chip

#241–#246 closed the overnight no-X surface-admit sequence (COM-Poisson,
Hurdle-NB, Beta-hurdle, Ordered-beta). Family-row honesty for those admits
already lives on `docs/design/capability-status.md` at `51ffa320`. Exponential
is already `implemented`. Tweedie `fit_gllvm` stays STOP.

The remaining cheap, useful lock is the estimator the twin ships and Julia
does not: adaptive Gauss–Hermite quadrature (AGHQ). This note is that lock.
It is **not** an implementation campaign and **not** a `fit_gllvm` admit.

| Candidate | Why this slice / not |
|---|---|
| Newly admitted family ledger rows | Already honest on `51ffa320` (notes name #241–#246) |
| Tweedie `fit_gllvm` admit | Identity #234 STOP; T2–T5 unpaid — **out** |
| Exponential | Already `implemented` |
| Bridge gaps (lognormal / truncated_*) | Would start a Δ or a `bridge.jl` arc — **out** |
| **AGHQ Identity** | Twin ships it; Julia has no symbol; ledger rows already `missing` with no fence — **this slice** |

## Problem

`docs/design/capability-status.md` already marks `AGHQ estimator` and
`Broad AGHQ (Julia)` as `missing`. That token is true and must stay true.
What it does **not** yet lock:

1. That Julia VA Gauss–Hermite is **not** AGHQ.
2. What the twin actually ships (read off twin files, not inferred).
3. That a one-PR "add `aghq=`" would advertise a capability the package
   does not have.
4. That the next engine is a campaign, not a surface admit.

Without those locks, a later lane can rename `_gauss_hermite` as AGHQ, or
add a failing public knob, or invent a twin logLik Δ for an estimator
Julia cannot evaluate.

### Live surface map (probed at `51ffa320`, not inferred)

| Surface | AGHQ |
|---|---|
| `src/` symbol `aghq` / `AGHQ` | **absent** — `rg -n -i aghq src test` is empty |
| `fit_gllvm` / `@formula` / `bridge.jl` | no AGHQ argument, no quadrature engine |
| VA `_gauss_hermite` (`src/families/variational.jl`) | **ELBO** quadrature for selected VA families — not AGHQ |
| Ledger `AGHQ estimator` | `missing` |
| Ledger `Broad AGHQ (Julia)` | `missing` |
| Twin `gllvmTMB` @ `e3e813f4` (`origin/main`; gap sheet read `114a227e`) | **shipped**, opt-in experimental (see below) |

No Julia `using GLLVM` probe is recorded here: this worktree has no
instantiated depot (Mac-light; `Pkg.instantiate` not run). The `rg` over
`src/` and `test/` is the engine-absence evidence.

## Twin (read-only; no Δ invented)

Read at `gllvmTMB` `origin/main` @ `e3e813f4` (`DESCRIPTION` Version
**0.6.0**). `R/aghq-control.R` and `R/aghq-gate.R` are byte-identical to
the gap sheet's `114a227e` tip; the live grid / Stage 1a fences were
re-read off `e3e813f4`. The four modules named by the 2026-08-16 gap
sheet are still the shipped surface:

| File | Role (from the file header / Rd, not inferred) |
|---|---|
| `R/aghq-control.R` | node grid, per-cell resolve, `aghq = "auto"` on/off; Liu & Pierce 1994 adaptive identity; `.aghq_grid(d, k)` tensor GH |
| `R/aghq-gate.R` | structural eligibility from Hessian sparsity / treewidth; hard exclusions (REML, `equalto()`, `propto()`, multi-kernel) |
| `R/aghq-auto-ridge.R` | experimental `aghq_ridge = "auto"` scale-aware ridge (#847) |
| `R/aghq-report.R` | `fit$aghq` honesty for print / summary / AIC engine labels |

Public knob (from `man/gllvmTMBcontrol.Rd`, not from Julia):

- `gllvmTMBcontrol(aghq = FALSE)` — **default**; Laplace.
- Positive integer — that many quadrature nodes.
- `"auto"` — package decides; declines to Laplace when ineligible or when
  expected gain does not justify cost.
- Twin's own Rd: **opt-in and experimental**; *no capability claim is made
  for quadrature-fitted models*; eligibility is narrow — a single ordinary
  `latent()` block on the unit tier.

The AGHQ helpers are **internal** (file headers: no `@export`, no NAMESPACE
edit). The user-facing name is the control argument, not an exported
`aghq()` constructor.

### Live pin (Stage 1a; do not confuse the two grids)

Twin AGHQ that Julia may one day twin is **Stage 1a only**: quadrature
over the between-unit reduced-rank latent `z_B`, loadings-only
(`latent(..., unique = FALSE)` / no free `s_B`). Default `latent()`
carries per-trait Psi and is **ineligible**. Template fences on
`e3e813f4` also reject `use_lv_B`, `mi()`, and multinomial (fid 16).

Two grids exist. Only one is the template pin:

- **Live pin** — `.gllvmTMB_aghq_grid` in `R/fit-multi.R`, matching the
  C++ `use_aghq` comment. Nodes are **probabilists'** (standard-normal)
  GH. `logw_j = Σ_m log w_{j_m} + (d/2) log(2π) + ½ u_j'u_j`. Identity:
  `Σ_j exp(logw_j) φ_d(u_j) = 1`. **`k = 1` reproduces Laplace exactly**
  and is routed to the Laplace path on purpose.
- **Peer helper** — `.aghq_grid` in `R/aghq-control.R` uses physicists'
  nodes then folds `exp(u'u)` and `(√2)^d`. Fit-time substitution is
  allowed only if `.gllvmTMB_aghq_grid_ok` passes.

Julia `_gauss_hermite` is the physicists' `e^{-t²}` rule (`Σ w = √π`)
for VA `E_q`. It shares Golub–Welsch with the twin helper and **does
not** share the live measure. A later grid slice must implement the
live pin as a **new** symbol; it must not call `_gauss_hermite` and
relabel.

**Locked reading:** a twin light logLik Δ for AGHQ would require a Julia
AGHQ engine that does not exist. Until that engine exists, any numerical
"parity" number would be invented. This note records the twin *files and
knobs*, not a Δ.

## Decision

### A1 — Status stays `missing`. This PR does not promote either AGHQ row

`implemented` requires Julia code under `src/` **and** a test. Neither
exists. Renaming VA GH as AGHQ to flip the token is **rejected**.

### A2 — Julia VA `_gauss_hermite` is not AGHQ

VA evaluates `E_q[log p(y|η)]` under a variational Gaussian for an ELBO
lower bound (`src/families/variational.jl` and the per-family VA files).
Twin AGHQ is *adaptive* quadrature of the **full joint integrand** at the
Laplace mode with a local Cholesky (`aghq_Lt` / `aghq_logdet`; Liu &
Pierce 1994, cited in `R/aghq-control.R`). Same orthogonal polynomials,
different integral, different claim. Do not share a public name.

### A3 — No stub public knob

Do not add `aghq=` / `method = "AGHQ"` that only throws. The twin's own
EVA write-up in the same Rd file states the honesty rule this repo
already uses: an argument that can only error advertises a capability
the package does not have. Julia's honest surface today is Laplace
(default) and VA (selected families). AGHQ is absent.

### A4 — Next engine is a campaign, not a one-PR admit

A Julia AGHQ that could later support a legitimate twin Δ must include,
at minimum, the pieces the twin already separates:

1. tensor GH grid on the **live** `.gllvmTMB_aghq_grid` convention
   (probabilists' nodes + three-term `logw`), with a golden test that
   `k = 1` matches the existing dense Laplace marginal;
2. per-site adaptation (mode + Cholesky) from the existing Laplace
   cache, fail-loud unless the random part is a single loadings-only
   `z_B` block;
3. a structural gate (what is affordable / eligible) — later than (1)–(2);
4. an adaptation loop and a convergence verdict that is not
   `Optim`'s relative f-change alone;
5. report honesty (`used`, `k`, engine label) so AIC/print cannot mix
   Laplace and AGHQ silently. Do not port `aghq_ridge = "auto"` in the
   first engine PR (Bernoulli-only experimental).

That is out of this slice. Tweedie `fit_gllvm` is also out (STOP).
Cross-validation (`R/cv-*.R` on the twin; no `crossval` under Julia
`src/`) is a **sibling** missing estimator, not this Identity.

### A5 — No bridge, no twin Δ, no family-row edits

`src/bridge.jl` stays closed. Newly admitted family rows
(COM-Poisson / Hurdle-NB / Beta-hurdle / Ordered-beta / Student-t /
Delta / Hurdle-Poisson) are not reopened. Exponential is not reopened.

## Out of this PR

- Any `src/` AGHQ / quadrature engine.
- Tweedie `fit_gllvm` admit.
- Twin light Δ for any family or estimator.
- `scalar()` covariance-mode ledger row (cheap, separate Rose pass).
- Cross-validation Identity.
- Mixed-family / `mi()` ledger-verify.

## Rose fence

Both AGHQ status cells stay `missing`. No R-parity, ADEMP, or coverage
claimed. Twin AGHQ is cited from files at `e3e813f4`, not from a Julia
number. VA GH is explicitly not AGHQ. `k = 1` ≡ Laplace is the first
engine test, not a capability claim.

Rose verdict for **this** note: PASS — locks only; no engine code.
