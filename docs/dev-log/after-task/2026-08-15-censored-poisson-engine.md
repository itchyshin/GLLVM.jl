# After-task: censored_poisson Identity→Engine (Julia-forward)

**Date:** 2026-08-15  
**Lane:** `cursor/censored-poisson-catchup-20260815`  
**WT:** `.worktrees/gllvmjl-censored-poisson-20260815`  
**Perspectives:** Ada (slice), Opus ceiling (Identity APPROVED), Composer (mechanical engine)

## Goal

Ship Wave2 censored_poisson engine under the ceiling-amended Identity, twin-fenced
(no light Δ), on owned files only.

## Done

- Absorbed Identity + ENGINE-GATES tip from `cursor/censored-poisson-engine-20260815`
  (`73d3a1bc`) rather than forking the decision doc.
- Added `src/families/censored_poisson.jl`: stable `logcdf(Gamma(C,1),μ)` survival,
  hand-coded η derivatives `G` / `G(C−μ−G)`, interval-ready `(lower,upper)` API,
  Bool `censored` convenience, Poisson packing, FD outer fit.
- Added `test/test_censored_poisson.jl` with local `Base.include` until conductor wires.
- Conductor ADMIT fragment at
  `docs/dev-log/handover/2026-08-15-censored-poisson-ADMIT.md` (shared ADMIT.md untouched).

## Evidence

Focused run (`julia --project=. -e 'using GLLVM, Test; include("test/test_censored_poisson.jl")'`):

```
Test Summary: censored_poisson family (Julia-forward) | Pass  Total  Time
                                                     |   43     43  5.7s
```

## Twin fence (unchanged)

Constructor-only; no dens; FAM-16 blocked. No RCall Δ. Claim wording:
**Julia-forward / twin constructor-only**. Rose public claim **PENDING**.

## Not done (conductor)

`GLLVM.jl` include/export, `fit_gllvm` dispatch, `runtests.jl`, ledger, check-log.

## Rose

Engine slice OK for owned files. Public README/capability claim **blocked** until
Rose pre-publish after admit wiring.
