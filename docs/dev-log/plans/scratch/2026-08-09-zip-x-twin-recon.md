# Scratch — ZIP+X twin / Julia recon (capacity S3)

**Date:** 2026-08-09  
**Purpose:** file:line cites for Identity fence (not an engine map).

## Twin gllvmTMB (local)

| Fact | Cite |
|---|---|
| ZIP/ZINB cut from 0.2.0 | `docs/dev-log/known-limitations.md` ≈L146–148 |
| No ZIP in `family_to_id` | `R/fit-multi.R` `family_to_id` switch (gaussian…multinomial; abort lists no ZIP) |

## Julia GLLVM.jl (tip `8112e533`)

| Fact | Cite |
|---|---|
| No-X ZIP fitter | `src/families/twopart.jl` — `fit_zip_gllvm` / `ZIPFit`, `Λ_z = 0` |
| Not in bridge X | `src/bridge.jl` — `_BRIDGE_X_FAMILIES` / `_BRIDGE_ONEPART_FAMILIES` omit `zip` |
| Two-part shape | `docs/superpowers/specs/2026-05-31-two-part-families-design.md` §2.2 |

## Conclusion for Identity

Julia-forward / twin-asymmetric ACCEPTED lock — see
`docs/dev-log/decisions/2026-08-09-zip-x-identity.md`.
