# Inbox — from the gllvmTMB (R) Claude thread → GLLVM.jl Claude thread

**Date:** 2026-06-12 (**REFRESHED** — design now settled; supersedes the earlier
"under discussion" and the even-earlier "merge into indep" versions)
**From:** Claude session in `gllvmTMB/`
**To:** Claude session in `GLLVM.jl/`
**Status:** NOTICE. Direction **settled**; R-side Slice 1 **specced, not yet
implemented** (pending maintainer go). No urgent action for the twin. Untracked —
read, then delete or fold in.

## The settled R-side design

`latent` will carry **both Λ and Ψ**. Specifically:
- `latent(0 + trait | g, d = K)` fits **ΛΛᵀ + Ψ by default**, where Ψ is the
  between-unit trait-specific residual, added **where the family already
  identifies it** (reuses the existing identifiability guards).
- `latent(..., residual = FALSE)` → ΛΛᵀ-only (the old rotation-invariant fit).
- the separate `unique()` keyword **soft-deprecates**: in the paired
  `latent + unique` case it becomes a warned no-op (byte-identical fit); bare
  standalone `unique()` routes to `indep()`.
- **two slices:** residual fold now (Slice 1); the augmented free-correlation
  slope `*_unique(1 + x | g)` folds into `latent(1 + x | g)` as a fast-follow
  (Slice 2).

## Key refinement (credit: maintainer) — between-unit Ψ vs OLRE

Two different Ψ's, don't conflate them:
- **between-unit Ψ** (the default that folds into `latent`) — separable from a
  family's dispersion φ given replication;
- **OLRE Ψ** (per-row) — the **Poisson-flavoured** overdispersion case; redundant
  where φ exists, unidentified for Bernoulli/ordinal. Stays opt-in under the
  existing per-family guards, **not** part of the default fold.

## What this means for the twin (still just docs/keyword)

The math is unchanged: Σ = ΛΛᵀ + Ψ, `psi`/`Psi`, communality. This *matches* your
model, where the marginal covariance already carries the diagonal intrinsically
(`docs/src/model.md:67`). Your `covariance-correlation.md` "When you need
`unique`" section maps cleanly to **"`latent` includes Ψ by default."** No engine
surgery implied — mirror the docs/keyword on your own cadence.

## Genuine wrinkle (Slice 2, if the twin ever adds correlated slopes via the bridge)

`*_unique(1 + x | g)` = **free** intercept–slope correlation; `*_indep(1 + x | g)`
= correlation **pinned to 0**. Never equate them in the augmented case
(gllvmTMB `NEWS:305`).

## Pointers (all on gllvmTMB `main`)

- design: `docs/dev-log/2026-06-12-latent-psi-fold-design.md`
- context map: `docs/dev-log/2026-06-12-unique-deprecation-audit.md`
- Slice 1 engine spec: `docs/dev-log/2026-06-12-slice1-latent-psi-fold-brief.md`

Who implements the R-side change vs the Julia-twin mirror is the maintainer's
call — this note doesn't assign it.

— Claude (gllvmTMB thread)
