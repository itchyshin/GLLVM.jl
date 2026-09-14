# Destination B — G2 capability promotion (honest-0.7 Arc 0 grid)

**Date:** 2026-09-14  
**Lane:** `cursor/honest-070-destb`  
**Base:** `origin/main` @ `23fd0496`  
**Depends:** G1 `docs/dev-log/after-task/2026-09-14-destb-api-boundary.md`

## Scope

Rose-fenced promotion pass for covariance grid arcs **#9–#15** (merged #324–#334).
Update `docs/design/capability-status.md` only — no `src/`, no tests, no
`Project.toml`, no public README parity wording change.

## Row changes (old → new)

| Capability row | Was | Now |
|---|---|---|
| phylogenetic × dep (`phylo_dep()`) | `planned` | `implemented (Arc 0 Gaussian function API only)` |
| animal × dep (`animal_dep()`) | `planned` | `implemented (Arc 0 Gaussian function API only)` |
| animal × latent (`animal_latent()`) | `planned` | `implemented (Arc 0 Gaussian function API only)` |
| spatial × dep (`spatial_dep()`) | `planned` | `planned (Arc 0 fail-loud entry only)` |
| kernel × indep (`kernel_indep()`) | `planned` | `implemented (Arc 0 Gaussian function API only)` |
| kernel × dep (`kernel_dep()`) | `planned` | `implemented (Arc 0 Gaussian function API only)` |
| kernel × latent (`kernel_latent()`) | `planned` | `implemented (Arc 0 Gaussian function API only)` |

Evidence: exported fitters on `main` (`src/GLLVM.jl` exports) and dedicated
`test/test_{phylo,animal,spatial,kernel}_*.jl` files named in the new prose block
under **Honest-0.7 Arc 0 grid promotion** in `capability-status.md`.

## Rose audit (claim vs evidence)

- **PASS:** No row promoted to bare `implemented` without Arc 0 qualifier (except
  spatial × dep, which stays `planned` because only fail-loud admission exists).
- **PASS:** Prose block states ≠ DestB FINAL-REVIEW, ≠ twin Δ, ≠ formula/bridge.
- **PASS:** Matches prior Arc 0 after-task fences (e.g. phylo-dep scaffold:
  “≠ ledger promote” — this slice is the *documented* promote, not a parity claim).
- **PASS:** `Project.toml` untouched; version remains `0.3.0`.

## Not done

- T13 `mi()` row (next slice G4)
- Advisory Frozen R smoke (#323)
- S4 push/probe
- `FINAL-REVIEW` / joint 0.7 decision note

## Verification

Static only: file read + export grep; no `Pkg.test()` this slice.
