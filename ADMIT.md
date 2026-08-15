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

1. **`src/GLLVM.jl`** — export `fit_zib_gllvm_cov`, `ZIBCovFit` **only**. Exporting
   the `ZIB` family marker belongs to the fenced no-X arc (items 2 and 4), not to
   this PR's conductor admit — it is the precondition for `fit_gllvm` / `@formula`
   reaching ZIB at all, so it must not slip in here.
2. **`src/families/fit_gllvm.jl`** — **OWED / fenced, not this PR.** There is no
   `_fit_gllvm(::ZIB)` arm at all (`src/families/fit_gllvm.jl:139–149` covers
   Normal … ZIPoisson / ZINegBin), the fallback availability list (`:154`) omits
   ZIB, and the `ZIB` marker is **not exported** from `src/GLLVM.jl` (`:198`
   exports `fit_zib_gllvm` / `ZIBFit` / `zib_marginal_loglik_laplace` only,
   while `ZIPoisson` and `ZINegBin` are exported at `:194` / `:196`). So
   `fit_gllvm` cannot reach ZIB today even without X. Adding an X arm here would
   leapfrog a no-X `fit_gllvm` surface ZIB has never had. Route **(b)**, as for
   the bridge: this admit gets its own arc and its own G0, and that arc must land
   **no-X ZIB through `fit_gllvm` first** — export `ZIB`, add the
   `_fit_gllvm(::ZIB)` → `fit_zib_gllvm` arm, add ZIB to the availability list —
   before any X dispatch.
3. **`src/bridge.jl`** — **OWED / fenced, not this PR (Identity R2).** `zib` is in
   **neither** `_BRIDGE_ONEPART_FAMILIES` nor `_BRIDGE_X_FAMILIES`, and this PR leaves
   `src/bridge.jl` untouched. Admitting `zib` here would leapfrog a no-X bridge surface
   ZIB has never had. Route **(b)**: bridge admit gets its own arc and its own G0, no-X
   `zib` first, then X — including the trials-contract reconciliation between `ZIB`'s
   scalar `N::Int` and the bridge's `p×n` `cbind(success, failure)` convention.
4. **`src/formula.jl`** — **OWED / fenced, not this PR.** `src/formula.jl` never
   mentions ZIB: the no-X ladder dispatches `ZIPoisson()` / `ZINegBin()` only
   (`:102–:103`) and the X branch dispatches those two only (`:140–:143`).
   Combined with the unexported `ZIB` marker (above), `@formula` has no no-X ZIB
   route either. Wiring an X route here would leapfrog that missing surface.
   Route **(b)**: own arc, own G0, landing **no-X ZIB through `@formula` first**
   (which itself presupposes the exported marker and the `fit_gllvm`
   availability-list entry from item 2) before any X dispatch. "Mirror
   ZIP/ZINB" is **not** licence on its own — ZIP/ZINB already have both no-X
   and X arms in this file; ZIB has neither.
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
- No `fit_gllvm` or `@formula` admission for ZIB (no-X **or** X) — **OWED**, fenced
  to its own arc; no-X must land first, and the `ZIB` marker is not even exported yet.
- No per-observation trials matrix `N_{ts}` — shared scalar `N` is the locked contract.
