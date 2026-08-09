# S0/S1 — ZIP+X call-site map (2026-08-09)

## S0 — merge gate + twin re-cite

| Check | Evidence |
| --- | --- |
| `#197` MERGED | `9c2b18d6` (2026-08-09T15:56:18Z) |
| `#198` MERGED | `6f9050e5` (2026-08-09T15:56:56Z) = `origin/main` tip |
| Fresh wt | `.worktrees/gllvmjl-zip-x-engine-20260809` on `feat/zip-x-engine-20260809` @ `6f9050e5` |
| Twin ZIP cut | local `gllvmTMB` `R/fit-multi.R` `family_to_id`: no ZIP/ZINB arm; abort lists gaussian…multinomial only |
| Collision | no other `feat/zip-x-engine-*` wt / no ac44014a zip lane |

## S1 — call sites

| Symbol | Path | Role for ZIP+X |
| --- | --- | --- |
| `zip_marginal_loglik_laplace` | `src/families/twopart.jl` | kwargs already include `offsetz`/`offsetc` via twopart substrate |
| `_twopart_mode` / `twopart_loglik_site` | same | `η^z = βz + offz + Λz z`, `η^c = βc + offc + Λc z` |
| `fit_zip_gllvm` / `ZIPFit` | same | no-X packs `[βz; βc; pack(Λc)]`; wires **`offsetc` only** today |
| `_build_offset(X, γ)` | `src/families/covariates.jl` | shared site-X → p×n offset (reuse twice for γz/γc) |
| `_BRIDGE_ONEPART` / `_BRIDGE_X` | `src/bridge.jl` | `zip` absent — admit both (Q2) |
| `gllvm` / `@formula` | `src/formula.jl` | no `ZIPoisson` branch — add cov + no-X |
| Post-fit | `src/postfit.jl` | `ZIPFit` getLV/predict/residuals exist; add `ZIPCovFit` hooks |
| Exports | `src/GLLVM.jl` | add `fit_zip_gllvm_cov`, `ZIPCovFit`, export `ZIPoisson` |

## Packing (Identity)

`θ = [βz (p); γz (q); βc (p); γc (q); pack(Λc) (rr)]` with `Λz = 0`.
Offsets: `Oz = _build_offset(X, γz)`, `Oc = _build_offset(X, γc)`.

## Fence for capabilities

- `ci_no_x_*` = true (existing `ZIPFit` confint)
- `ci_x_*` = **false** (Rung 2 not DoD) → `_BRIDGE_NO_CI_X_FAMILIES`
- notes: Julia-forward / twin-asymmetric / no light Δ
