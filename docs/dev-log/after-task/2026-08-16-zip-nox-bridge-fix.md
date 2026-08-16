# After-task — ZIP no-X bridge arm fix (`fit.link` on a `ZIPFit`)

**Date:** 2026-08-16
**Lane:** `cursor/zip-nox-bridge-fix-20260816`, worktree from `origin/main` @ `7254edda` (#233)
**Origin:** pre-existing defect named in the #231 after-task
(`docs/dev-log/after-task/2026-08-16-zib-bridge-nox-engine.md`, "One deviation from
the Identity"), where ZIB deliberately avoided `_bridge_assemble_ng` because it reads
`fit.link`. ZIP had the same shape and had not avoided it.
**Reviewed as:** Ada (scope / claim wording), Gauss (bridge assembly), Rose
(claim-vs-evidence fence).

## Goal, stated as a check before writing code

`bridge_fit(; y, family = "zip", d)` with **no** `X` returns the flat contract with
`alpha`, `beta_zero`, `loadings`, and `loglik` matching a direct `fit_zip_gllvm(Y; K)`
to ≤ 1e-8, and routes a Wald CI payload identical to native `confint(::ZIPFit)`.

## The defect

`ZIPFit` has fields `βz, βc, Λc, loglik, converged, iterations` — **no `link`**. The
no-X ZIP arm assembled through `_bridge_assemble_ng`, whose final line builds
`link = fill(_bridge_link_name(fit.link), p)`. That read is outside the arm's
`MethodError` fallback `try`, so it was unconditional. Reproduced live at `7254edda`:

```
ZIP no-X FAILED: ErrorException
type ZIPFit has no field link
ZINB no-X OK: ["log", "log", "log"]
```

The arm was therefore **dead on every call**: the error fired before any contract,
CI, or note check could run. It survived because every pre-existing ZIP bridge test
(`test/test_bridge_x.jl`, four call sites) drives the `+X` arm, which goes through
`_bridge_assemble_zip_cov` and never touches `fit.link`.

## What landed

`src/bridge.jl` — the ZIP no-X arm only (one hunk):

- Swapped `_bridge_assemble_ng` for a direct `_bridge_assemble` call, the same
  resolution ZINB and ZIB already use. This is the smaller blast radius of the two
  options: adding a `link` field to `ZIPFit` would change a public struct, break
  positional construction at every `ZIPFit(...)` call site, and put an inert tag on a
  fit object whose link is fixed by the family anyway.
- `Σ`/`correlation`/`communality` come from the shared block `ΛcΛcᵀ` (communality 1).
  This is not a downgrade: `ZIPFit` has no `link_residual` extractor either, so the
  old code path would have taken the `MethodError` fallback to exactly this quantity
  had it ever reached it.
- `link = fill("log", p)`, matching `_bridge_assemble_zip_cov` (ZIP+X) and both ZINB
  arms verbatim, so the no-X and +X ZIP routes agree on the link string.
- Note rewritten as one honest string (the old `isempty(base.note)` branch existed
  only to prepend the extractor-fallback sentence and is now dead): states
  Julia-forward / twin-asymmetric, the shared-block `Σ`, and the twin fence.

`test/test_bridge_zip_nox.jl` (new, registered in `test/runtests.jl`) — the first test
that **fits** the no-X ZIP route rather than only `+X`: point estimates vs
`fit_zip_gllvm` at 1e-8, contract shape (`model == "zip_rr"`, NaN dispersion, NaN
`sigma_eps`, `link == ["log", …]`, symmetric unit-diagonal correlation, `nobs = p·n`,
`df == _nparams`), the four family aliases, no-X Wald CI vs native `confint`, and the
mask rejection.

## Sweep for the same defect elsewhere

Item 4 of the brief. All 15 one-part families were driven through the no-X route live
on the patched tree; **ZIP was the only broken arm**:

```
OK gaussian IdentityLink   OK negbinomial LogLink   OK ordinal        LogitLink
OK poisson LogLink         OK nb1         LogLink   OK ordinal_probit ProbitLink
OK binomial LogitLink      OK beta        LogitLink OK zip            log
OK binomial_probit Probit  OK gamma       LogLink   OK zinb           log
OK binomial_cloglog CLog   OK betabinomial LogitLink OK zib           LogitLink
```

One cosmetic inconsistency is left **untouched and recorded, not fixed**: the three
zero-inflated arms report `link` as lowercase `"log"` / `"LogitLink"` while the
one-part arms report `_bridge_link_name` forms. ZIP no-X now matches ZIP+X, which is
the consistency that matters for a single family; harmonising the string convention
across families is a separate, wider-blast change and is out of this lane.

## Verification

- New focused file: **39/39 Pass** locally (`ZIP bridge no-X Wald CI: max|Δ| vs
  native = 0.0`).
- Full suite (`Pkg.test()`, incl. Aqua/JET): tally recorded on the PR.
- No twin RCall Δ was run or invented — the twin `gllvmTMB` cut ZIP, so there is no
  reference to compare against. No parity, ADEMP, or coverage claim is made here.

## Fences held

- Bridge + tests + `check-log` + this report only. `docs/design/capability-status.md`
  deliberately **not** touched, to stay clear of the concurrent Tweedie Identity lane.
- No capability row, no `_BRIDGE_*` list membership, and no CI policy changed: `"zip"`
  was already in `_BRIDGE_ONEPART_FAMILIES` and already advertised no-X CI. This PR
  makes the advertised route actually run; it does not widen any claim.
- Files staged by name.
