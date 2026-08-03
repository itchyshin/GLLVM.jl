# Plan vs actual — Gamma+X engine Arc 1 (2026-08-03)

| Item | Plan | Actual |
|---|---|---|
| Scope | Full one-family #175 mirror; no RCall | Same |
| Worktree | Fresh off origin/main | `.worktrees/gllvmjl-gamma-x-grouped-cov-20260803` @ `fix/gamma-x-grouped-cov-20260803` |
| Identity decision | Cherry-pick if not on main | Cherry-picked `8af4f00f` + `b657b27e` |
| Fitter | FD LBFGS grouped_cov | Done (`GammaGroupedCovFit`) |
| Routing | Bridge + formula | Done |
| Identity | G=1 + constant αvec | **7/7** (seed 8300 for G=1; 8202 hit pre-existing shared-cov DomainError) |
| Bridge_x | Update gamma oracles | **204/204** |
| Formula | 11/11 + route | **11/11** + smoke OK |
| #177 | Fence | Untouched |
| Arc 2 RCall | Deferred | Deferred |
| Push | Ask first | Local only |

**Recommended / actual wall:** ~3.5 h / ~session Arc 1  
**Next:** Gamma+X light RCall Arc 2 (separate `/goal`)
