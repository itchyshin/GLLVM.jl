# Decision: none × dep() Identity (twin-aligned; standalone unstructured Σ)

**Date:** 2026-08-18
**Status:** ACCEPTED (docs-only; engine NOT started)
**Lane:** `cursor/lane-none-dep-identity-20260818`
**Base:** Julia `origin/main` **`3d5acba0`**
**Programme:** parent Phase C item 1
(`~/local-scratch/lanes/GLLVM.jl-parity-beyond-20260818/LOOP/` —
covariance grammar; cheapest first = `none × dep()`).
**Depends on:** gap sheet
`docs/dev-log/plans/2026-08-16-gllvmtmb-capability-gap.md` (row
`none × dep` is **planned**); style precedent
`docs/dev-log/decisions/2026-08-15-lognormal-identity.md`.
**Do not** edit `docs/design/capability-status.md` this run (L47 stays
**planned**; #258 / #259 own that file).
**Do not** invent a twin light Δ. **Do not** touch `src/`.
**Do not** open `formula.jl` / `packing.jl` / `aghq_grid.jl` / `bridge.jl`.
**Do not** start `phylo_dep` / animal / kernel / Tweedie admit.

## Problem

Ledger row `none × dep` is `planned` while twin gllvmTMB already exports
standalone `dep(0 + trait | g)` as the always-alone full-unstructured
trait covariance. Julia already ships **none × indep** and **none ×
latent** but has **no** `dep()` sugar and no unstructured-Σ-without-LV
path. Exact ledger quote at `3d5acba0` (file **not** edited this run):

```
| none × dep (`dep()` / unstructured trait covariance) | planned |
```

Notes (same file, not a status row): `full unstructured dep() without LV is still a gap.`
Neighbour: none × indep implemented; none × latent implemented.

`git grep -n 'dep(' 3d5acba0 -- src/` is **empty** (exit 1).

Without an Identity lock, a later engine risks treating `dep` as a new
covariance law instead of full-rank packed-triangular Λ, shipping
`dep` + `latent` on the same grouping (over-parameterised), promoting
L47 on grammar rename alone, or inventing a twin logLik Δ before Julia
can evaluate `dep()`.

## Twin cites (load-bearing)

Read-only pin: `gllvmTMB` `origin/main` **`b8a1891a`** (Merge #1139).
Blob `R/brms-sugar.R` = **`e1922dbf`**. Cites below are that `git show`
only. This file does **not** contain the combo `cli_abort` body.

| Surface | Evidence |
|---|---|
| Grid | L6–14: 5×3 keyword grid. **L10** `none \| indep() \| dep() \| latent()` |
| Cholesky header | **L32**: Cholesky \(\boldsymbol\Sigma = \mathbf{L}\mathbf{L}^\top\) |
| Constructor | **L1721** `dep <- function(formula) {` |
| Free count / Cholesky | **L1661–1662**: \(T(T+1)/2\) via Cholesky |
| PSD / free count | **L1681–1682**: PSD via Cholesky; \(T(T+1)/2\) parameters |
| Same-grouping fence (docs only) | **L1694–1698** documents that `dep` + `latent` on the same grouping is over-parameterised, and documents that a fit raises `cli_abort`. The abort **implementation is not in this file**. Parser plants `.dep = TRUE` at L4193–4200; guards are named as elsewhere / `fit-multi.R` |
| Not this slice | **L1787** `phylo_dep <- function` (roxygen L1725) |

## Julia estimand (this Identity)

| Item | Lock |
|---|---|
| Source × mode | **none × dep** only — unstructured trait covariance, **no** phylogenetic / animal / spatial / kernel source, **no** LV companion |
| Formula (twin) | Standalone `dep(0 + trait \| g)` |
| Covariance | Unstructured \(T \times T\) \(\boldsymbol\Sigma\), PSD |
| Free count | \(T(T+1)/2\) |
| Parameterisation | Cholesky \(\boldsymbol\Sigma = \mathbf{L}\mathbf{L}^\top\) |
| Equivalence | Same estimand as standalone `latent(0 + trait \| g, d = T)` (twin L32) |
| Packing cite only (not this run) | `src/packing.jl` at `3d5acba0`: `rr_theta_len(p,K) = p*K - K*(K-1)/2`; at \(K=p\) this is \(p(p+1)/2\). A later engine **may** reuse that length as \(\mathbf{L}\); this Identity does **not** implement it |
| Same-grouping fence | Twin **documents** `dep` + `latent` as over-parameterised (L1694–1698). Julia fail-loud waits for sugar; do not claim `brms-sugar.R` implements `cli_abort` |
| Ledger | Stays **`planned`**. Exact row (do **not** edit the file): `\| none × dep (\`dep()\` / unstructured trait covariance) \| planned \|` |
| `src/` | `git grep -n 'dep(' 3d5acba0 -- src/` **empty** (exit 1). No `@formula` `dep()`, no exported `dep`, no `fit_gllvm` route this run |

## Twin light Δ

**Forbidden this run.** `git grep` shows Julia cannot evaluate `dep()`.
A number would be invented. rtol is not in play. A later engine + light
RCall cell may quote a live Δ; this Identity does not.

## Out of scope

- `src/` of any kind (`formula.jl`, `packing.jl`, `aghq_grid.jl`,
  `bridge.jl`, fitters)
- `phylo_dep` / `animal_dep` / `spatial_dep` / `kernel_*` (twin L1787
  is not this slice)
- `scalar()` ledger-row insert
- AGHQ / Tweedie `fit_gllvm` admit
- Ledger promote of L47; any edit of `capability-status.md`
- Inventing that `R/brms-sugar.R` contains the combo `cli_abort` body
- Invented twin Δ
- Aborting #255–259
- Writes on the Dropbox checkout
- Engine G0 in the same commit as this Identity

## Ownership

- **OWN:** this decision; `LOOP/` kit for this lane; check-log append;
  after-task `docs/dev-log/after-task/2026-08-18-none-dep-identity.md`
- **NOT:** `docs/design/capability-status.md`; sibling worktrees;
  parent Phase C items after `none × dep`

## Docs-only vs engine gate

This commit is **docs-only**. **No test run applies.** Mac-light is
**N/A**. STOP/CONTINUE below is **not** a green engine gate. Engine
green requires a later G0, then `src/` + focused FD ≤ 1e-6 + tests, and
only then a ledger flip.

## STOP / CONTINUE

Identity **ACCEPTED** → **STOP**. Sibling push / docs-only PR is the
OPEN GATE. Do **not** start the engine. Do **not** `gh pr merge`.
Public capability claim waits for engine + tests + a later Rose promote
of L47.
