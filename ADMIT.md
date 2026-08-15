# ADMIT — ZIB+X catch-up (`cursor/zib-x-catchup-20260815`)

**Lane:** ZIB+X only (≠ lognormal / censored_poisson / truncated_nbinom2)  
**Worktree:** `.worktrees/gllvmjl-zib-x-20260815`  
**Owned this PR:** `src/families/twopart.jl` (append `ZIBCovFit` / `fit_zib_gllvm_cov` only),
`test/test_zib_x_identity.jl`, `docs/dev-log/decisions/2026-08-15-zib-x-identity.md`,
this file.

**Ceiling:** Identity ACCEPTED / packing / Rose claims need **Sol/Opus APPROVED**.
Composer delivered the mechanical ZIP→ZIB dual-γ clone only.

## Already landed (owned)

| Item | Status |
|---|---|
| Identity ACCEPTED (Julia-forward; packing `[βz; γz; βc; γc; pack(Λc)]`; `Λ_z=0`; **shared scalar `N::Int`**) | decision doc |
| Ceiling review APPROVED + required amendments **R1** (scalar-`N` lock) and **R2** (bridge fence) | cherry-picked from PR #208 (`08ef57a1`, `0041f769`) |
| `ZIBCovFit` + `fit_zib_gllvm_cov` | appended after `fit_zib_gllvm` in `twopart.jl` |
| Focused identity/FD tests | `test/test_zib_x_identity.jl` (run directly; not wired into `runtests.jl`) |
| Twin light Δ | **forbidden** — do not invent |

## Conductor admit (do **not** land in this lane)

Leave these to the merge conductor after Sol/Opus packing/Rose sign-off:

1. **`src/GLLVM.jl`** — export `fit_zib_gllvm_cov`, `ZIBCovFit` (and any public marker if added).
2. **`src/families/fit_gllvm.jl`** — dispatch `X` → `fit_zib_gllvm_cov` for ZIB / binomial-ZI route if applicable.
3. **`src/bridge.jl`** — **OWED / fenced, not this PR (Identity R2).** `zib` is in
   **neither** `_BRIDGE_ONEPART_FAMILIES` nor `_BRIDGE_X_FAMILIES`, and this PR leaves
   `src/bridge.jl` untouched. Admitting `zib` here would leapfrog a no-X bridge surface
   ZIB has never had. Route **(b)**: bridge admit gets its own arc and its own G0, no-X
   `zib` first, then X — including the trials-contract reconciliation between `ZIB`'s
   scalar `N::Int` and the bridge's `p×n` `cbind(success, failure)` convention.
4. **`src/formula.jl`** — `@formula` → `fit_zib_gllvm_cov` when X present (mirror ZIP/ZINB).
5. **`src/postfit.jl`** — `_loadings` / `_loglik` / `_nparams` / `getLV(::ZIBCovFit, Y, X)`.
6. **`test/runtests.jl`** — `include("test_zib_x_identity.jl")`.
7. **`docs/design/capability-status.md`** — ledger note only after Sol/Opus Rose OK.
8. Optional follow-up: `confint(ZIBCovFit)` (ZIP+X confint pattern) — **out of Arc 0**.

## Verify before admit

```sh
julia --project=. --startup-file=no test/test_zib_x_identity.jl
# expect: zero-X ≈ no-X; packed FD max|central-5pt| ≤ 1e-6
```

## Explicit non-claims

- No R-parity / twin light Δ.
- No ADEMP recovery.
- No CI-under-X until confint follow-up.
- No edits to sibling family lanes.
- No bridge admission for `zib` (one-part or X) — **OWED**, fenced to its own arc.
- No per-observation trials matrix `N_{ts}` — shared scalar `N` is the locked contract.
