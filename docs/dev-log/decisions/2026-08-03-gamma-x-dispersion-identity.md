# Decision: Gamma + X dispersion identity (twin with gllvmTMB)

**Date:** 2026-08-03  
**Status:** ACCEPTED (Arc 0 docs; Ada judgment on Ultra-plan Q1–Q3)  
**Lane:** `docs/gamma-x-identity-20260803`  
**Depends on:** #174 (NB2/Beta+X identity); #175 (NB2/Beta grouped_cov engine);
#169 (NB2/Beta no-X per-trait default). **Does not** depend on #177 (Arc 2
light cells; still OPEN/CONFLICTING at decision write — landing gate only).

## Problem

Public no-X Gamma in Julia is **shared-shape** by default:

| Surface | Dispersion (no-X) | Dispersion (shared site-X) |
|---|---|---|
| R / gllvmTMB ordinary Gamma (fid 4) | **per-trait** shape `φ_γ,t = exp(log_phi_gamma[t])` | same TMB vector under site-X formulas |
| Julia `fit_gllvm(...; family=Gamma())` | **shared** scalar α via `fit_gamma_gllvm` | — |
| Julia bridge no-X `family="gamma"` | **shared** group (`group = fill(1, p)`) — Option B | — |
| Julia `fit_gllvm_cov` / bridge X / `@formula`+X | — | **shared** scalar α + shared `γ` |
| Julia `fit_gamma_gllvm_grouped` | per-trait α available (opt-in `disp_group`) | **no** `fit_gamma_gllvm_grouped_cov` yet |

So under X the twin is inconsistent the same way NB2/Beta were before #174/#175:
Julia’s X path estimates one shared shape; gllvmTMB’s ordinary Gamma surface is
per-trait. Light RCall Gamma+X cells must stay **fenced** until this identity is
locked and an engine path exists.

Historical caveat: the 2026-06-16 bridge Option B note assumed a **scalar-CV**
native Gamma oracle. Live twin `origin/main` evidence (below) shows ordinary
Gamma is **per-trait** `log_phi_gamma`. That tension is load-bearing: do not
cargo-cult Option B into the +X default.

## Twin evidence (fresh `gllvmTMB` `origin/main` @ `840d1da8`)

Cited from `git show origin/main:…` (not a stale local checkout tip):

1. **TMB parameter** — `PARAMETER_VECTOR(log_phi_gamma); // length n_traits … fid 4`
   (`src/gllvmTMB.cpp:746`). Header: “Ordinary Gamma (fid 4) has its own
   per-trait shape/CV parameter below” (`src/gllvmTMB.cpp:313`).
2. **Likelihood** — “per-trait shape phi = exp(log_phi_gamma(t))”;
   `shape_g = exp(log_phi_gamma(t))` (`src/gllvmTMB.cpp:2152–2156`).
3. **Warmstart** — `log_phi_gamma = .clamp_log_phi(rep(0.0, n_traits))` under
   “NB2 / NB1 / Gamma / Tweedie **per-trait** dispersion”
   (`R/fit-multi.R:4034–4040`).
4. **Map comment** — “Ordinary Gamma (fid 4) has **per-trait** log_phi_gamma
   shape” (`R/fit-multi.R:4771`).

Shared / one-group Gamma remains expressible on the twin via disp.group-style
collapsing (map / shared factor), but the **public ordinary-Gamma TMB default**
is the length-`n_traits` vector.

## Julia route map (this repo @ `0e241215` / lane tip)

- No-X public: `fit_gllvm` → `fit_gamma_gllvm` (shared); grouped only if
  `disp_group` set (`src/families/fit_gllvm.jl:18`, `:42`, `:81–84`, `:145`,
  `:158`).
- Bridge no-X Option B: `fit_gamma_gllvm_grouped(...; group = fill(1, p))`
  with comment still describing a scalar-CV oracle
  (`src/bridge.jl:1039–1043`; capability note `:559–560`).
- Bridge / formula X: Gamma falls through to **shared** `fit_gllvm_cov`
  (`src/bridge.jl:1132–1135`; `src/formula.jl:68–70`, `:120`). NB2/Beta already
  use `fit_*_gllvm_grouped_cov`.
- `_cov_has_disp(::Gamma) = true` → one shared log-dispersion in the cov θ
  (`src/families/covariates.jl:108`, `:202–207`).
- Check-log Option B: `docs/dev-log/check-log.md` §2026-06-16 Gamma shared
  bridge route.

## Twin rule (non-negotiable)

GLLVM.jl mirrors gllvmTMB on **API and capabilities**, not on engine code.
Bridge execution remains **R→Julia only** (JuliaCall); RCall parity cells are
opt-in developer oracles. No engine surgery on gllvmTMB from this repo.

## Decision (API B under X)

**Choose per-trait Gamma shape as the public / twin-default path when shared
site-X is present**, matching gllvmTMB `log_phi_gamma` / disp.group spirit and
the NB2/Beta+X precedent (#174).

Concretely:

1. **Public twin default (with X):** per-trait shape `α_t` + shared site-X
   slopes `γ` (same shared-X formula shape as the G/Bin/Pois / NB2/Beta X
   cohort: site covariates enter as shared `γ`, not per-trait X slopes).
2. **Shared-shape + X** remains available as an explicit opt-in via
   `fit_gllvm_cov(...; family=Gamma())` / single dispersion group — **not** the
   public twin default under X.
3. **No-X bridge Option B (shared group):** **retain for now** as a **named
   follow-up** — do **not** silently flip the no-X bridge or `fit_gllvm`
   Gamma default in the same PR as the +X lock. Document the inconsistency
   honestly: no-X Julia/bridge shared vs twin per-trait; schedule a separate
   consistency arc (flip bridge + public no-X default, or keep shared with an
   explicit twin caveat and opt-in `disp_group=:species`).
4. **Light parity cells** for Gamma+X land only after an engine path that
   implements (1) exists and is FD/identity-checked; rtol stays `1e-6`
   (no silent widen).

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Keep shared α as twin default under X | Breaks twin with gllvmTMB `log_phi_gamma` length `n_traits` |
| Compare light logLik of shared-α Julia to per-trait R | False parity; estimands differ |
| Silent no-X Option B flip in this Arc 0 | Out of scope; Rose: named follow-up only |
| Cargo-cult 2026-06-16 “scalar-CV oracle” into +X | Contradicted by live twin main cites above |
| Ordinal+X / X_lv / ADEMP / Phylo Model A / “full family parity” | Hard fence |

## Engine shape (next implementation arc — not this doc’s code)

Preferred surgical path (confirm in Ultra-plan for Arc 1):

- Add `fit_gamma_gllvm_grouped_cov` mirroring
  `fit_nb_gllvm_grouped_cov` / `fit_beta_gllvm_grouped_cov`
  (`η = β + Xγ + Λz`, θ packing with per-group `log α`).
- Route bridge X and `@formula`+X for `gamma` through that path when
  dispersion is per-trait (future public default under X).
- Keep `fit_gllvm_cov(...; family=Gamma())` as the **shared** α + X opt-in.
- Identity checks before any RCall cell:
  - G=1 grouped+X with `hessian=:fisher` ≈ shared `fit_gllvm_cov` (Fisher),
    same spirit as #172 / NB2/Beta #175.
  - Constant `αvec` marginal with X offset equals shared cov marginal.

## Rose fence

**OK to claim after implementation + green light cells:**  
“Gamma + shared site-X light logLik under **per-trait** shape α, twin to
gllvmTMB `log_phi_gamma` / disp.group.”

**Not OK (this decision alone does not unlock):**

- full family parity;
- shared-α Julia vs per-trait R light cells;
- ADEMP / coverage claims;
- Ordinal+X;
- `X_lv` Gamma redesign;
- Phylo Model A;
- silent no-X bridge Option B flip;
- any claim that Arc 0 docs imply engine or RCall green.

## Follow-ups

1. Engine Arc 1: `fit_gamma_gllvm_grouped_cov` (+ identity tests) — **only after**
   this note remains ACCEPTED.
2. Parity Arc 2: Gamma+X light RCall cell(s), rtol `1e-6`, only after (1).
3. **Named:** no-X Gamma consistency (bridge Option B vs twin per-trait) —
   separate decision/engine lane; not bundled with (1) unless explicitly
   re-scoped.
4. Land #177 (NB2/Beta+X Arc 2) when green/MERGEABLE — **separate OWED**, not
   content of this note.
