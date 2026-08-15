# Decision: censored_poisson Identity (Julia-forward engine; twin R-only)

**Date:** 2026-08-15  
**Status:** ACCEPTED (Wave1 / Arc 0 docs-only → engine on owned files)  
**Lane:** `cursor/censored-poisson-identity-20260815`  
**Programme:** `lanes/gllvmjl-parallel-family-catchup-20260815/LOOP/`  
**Depends on:** G0 parallel catch-up; truncated_poisson Identity pattern (support/link discipline).  
**Do not** invent ZIP/ZINB twin Δ; **do not** claim twin engine parity; **do not** ADEMP.

## Problem

Ledger row `censored_poisson` is `missing`. Twin gllvmTMB exports an R
constructor `censored_poisson(link = "log")` in `R/families.R`, but a repo
search finds **no** `family_id` / cpp dens arm for censored Poisson in
`src/gllvmTMB.cpp` and **no** `family_to_id` admission in `fit-multi.R`'s
supported list (abort message lists truncated_poisson / truncated_nbinom2 /
delta_* etc., not censored_poisson).

Without an Identity lock, a Julia engine risks (a) inventing a twin light Δ
against a non-fitting surface, (b) conflating **zero-truncated** Poisson
(fid 10, already implemented) with **right/left/interval censoring**, or
(c) advertising bridge parity before the estimand is locked.

## Twin cites (load-bearing — asymmetric)

| Surface | Evidence |
|---|---|
| Constructor | `gllvmTMB/R/families.R` `censored_poisson()` — **log link only** in `okLinks`; returns a `family` object with name `"censored_poisson"` |
| Enum / cpp | **No** censored fid found in `enum.R` / `gllvmTMB.cpp` dens switch at decision time |
| `family_to_id` | **Not** in the supported-family abort list (live fit path does not admit it) |
| Related twin | `truncated_poisson` fid 10 is a **different** estimand (zero-truncation, y≥1) |

**Fence:** Twin admits a **constructor name** only. There is **no** live twin
fit / dens to Δ against. This Identity is therefore **Julia-forward** for the
engine; light RCall Δ is **forbidden** until twin lands a real dens + Identity
re-check.

## Julia estimand (this Identity) — right-censored counts at known limits

Lock a **right-censored Poisson** observation model suitable for count data
with known upper reporting limits (common ecology / lab “≥ C” coding), distinct
from zero-truncation:

| Item | Lock |
|---|---|
| Response encoding | Integer counts `y ≥ 0`; optional per-observation censor flag / limit `C` (engine API may pass a parallel matrix/mask — exact signature is engine detail, estimand is below) |
| Uncensored obs | Contribute `log Poisson(y; μ)` with `μ = exp(η)` |
| Right-censored obs at limit `C` | Contribute `log P(Y ≥ C)` = `log(1 − F_{Pois(μ)}(C−1))` for `C ≥ 1` (and handle `C = 0` fail-loud / undefined) |
| Linear predictor | `η = β + Λz` (+ optional offset); **log link only** |
| Mean parameter | Untruncated `μ = exp(η)` |
| Dispersion | none |
| Relation to truncated_poisson | **Different family** — truncation renormalises support `{1,2,…}`; censoring keeps support `{0,1,…}` and adds survival contributions |

### Explicit non-claims

- Not interval-censored / left-censored as v1 default (would need a new Identity).
- Not twin-parity / light RCall until twin dens exists.
- Not a rename of truncated_poisson.

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Skip Identity; ship engine as “like truncated” | Different estimand; Rose overclaim |
| Invent twin Δ vs constructor-only surface | No live dens — false parity |
| Treat as truncated_poisson alias | Breaks truncation Identity / twin fid 10 |
| Left/interval censoring as silent default | Underspecified without twin dens |

## Out of scope

- Twin engine surgery in gllvmTMB
- ZIP/ZINB/ZIB
- ADEMP / coverage
- Shared choke points — merge-conductor only
- truncated_nbinom2 (owned elsewhere)
- lognormal / ZIB+X (sibling lanes)

## Ownership (engine Wave2)

- **OWN:** `src/families/censored_poisson.jl` (new), `test/test_censored_poisson.jl` (new), this decision
- **NOT:** truncated_poisson.jl edits beyond necessary cross-refs; shared choke points until admit

## STOP / CONTINUE

Identity ACCEPTED → **CONTINUE** to Julia-forward censored_poisson engine on owned
files. Public claim must say **Julia-forward / twin constructor-only** until twin dens
lands. Verify = FD ≤1e-6 + focused tests (local tiny); no twin Δ.
