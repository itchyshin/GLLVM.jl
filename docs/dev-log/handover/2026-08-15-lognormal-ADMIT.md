# ADMIT — conductor wiring for one-part lognormal (owned-file lane)

**Lane:** `cursor/lognormal-catchup-20260815`  
**Owned files landed:** `src/families/lognormal.jl`, `test/test_lognormal.jl`,
`docs/dev-log/decisions/2026-08-15-lognormal-identity.md`  
**Do not** invent ZIP/ZINB Δ; **do not** ADEMP; **do not** silent rtol widen.

Admit conductor owns shared choke points. Please apply (surgical):

## `src/GLLVM.jl`

1. After `studentt.jl` (or near other continuous families), add:
   ```julia
   include("families/lognormal.jl")   # one-part lognormal (twin fid 3)
   ```
2. Export (with other family exports):
   ```julia
   Lognormal, LognormalFit, fit_lognormal_gllvm,
   lognormal_marginal_loglik, lognormal_response_mean
   ```
   (`lognormal_marginal_loglik_laplace` may stay unexported; thin alias.)

## `src/families/fit_gllvm.jl`

Dispatch (mirror TruncatedPoisson / Student-t pattern):
```julia
fit_gllvm(Y; family::Lognormal, kwargs...) = fit_lognormal_gllvm(Y; kwargs...)
```

## `test/runtests.jl`

```julia
include("test/test_lognormal.jl")
```

## Ledger / bridge (separate admit slices)

- `docs/design/capability-status.md`: flip `lognormal` from `planned` → engine-green
  status only after FD ≤ 1e-6 evidence + Rose fence (this PR’s focused tests).
- `bridge.jl`: light RCall Δ for twin fid 3 **only** when admit opens that file;
  rtol `1e-6`, Jacobian-inclusive logLik.
- Docs cascade: `docs/src/response-families.md`, `docs/src/gllvmtmb-parity.md`
  when the public API is exported (AGENTS.md convention cascade).

## Local verify before admit (owned harness)

Focused tests self-`include` the family file when symbols are missing, so they
pass **without** the choke-point edits above:
```sh
julia --project=. -e 'include("test/test_lognormal.jl")'
```
