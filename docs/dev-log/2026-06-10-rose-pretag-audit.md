# Rose pre-tag audit — GLLVM.jl (2026-06-10)

Read-only 4-lens audit (claims-vs-evidence · scope/missing-cell · license boundary
· doc drift) run as an ultracode Workflow on branch `a1-nongaussian-ci`. This file
records the verdict, the findings with file:line evidence, and the **disposition**
(what is being fixed in code this session vs what is flagged for the docs/pkgdown
lane, which the maintainer is coordinating separately with Codex).

## Verdict

**Code is in good shape; the package is NOT registry-tag-ready only because the
registry-facing docs describe a smaller package than the one that ships.** ~20
fitters are implemented *and* test-wired; the MIT/GPL license boundary is **clean**
(exhaustive scan of all 62 `src/` files — zero vendored GPL-3/TMB/R source; every
`gllvmTMB` mention is an allowed interface/parity citation). The blocker is
documentation honesty, in *both* directions: stale "planned" claims for shipped
features, and a few over-claims for prototypes that never load.

## Disposition

### Fixed in code this session (clearly the GLLVM.jl/engine lane)

- **Orphan CI module wired** (audit #5/#8/#11/#12): `src/confint_derived_wald.jl`
  (transformed-scale Wald CIs — `transformed_wald_ci_derived`, `correlation_wald_ci`,
  `communality_wald_ci`, `icc_wald_ci`, `phylo_signal_wald_ci`) was committed with a
  test (`test/test_confint_derived_wald.jl`) but **not** `include`-d in
  `src/GLLVM.jl`, not exported, and not in `runtests.jl` — dead code. Wiring it makes
  the feature live, lets `@autodocs` render its docstrings (resolving the broken
  `@ref`s in #11), and removes the CLAUDE.md orphan (#8).
- **Uniform Wald `confint`** (audit #12): extend the `_nongaussian_wald_ci` core to
  the families that lacked CIs (NB1, BetaBinomial, Student-t, TruncPoisson, TruncNB,
  ZIP, ZINB). One new `:logit` back-transform for the ZI probability π. Lognormal
  deferred (it reuses the closed-form Gaussian-on-log path, not a Laplace marginal).
- **`anova`/LRT** (audit #13): nested-model likelihood-ratio test, reusing the
  existing `_bridge_nparams` free-parameter counts (with the K(K−1)/2 rotational df).
- **`fit_gllvm` dispatcher** (audit #9): error text + docstring omit BetaBinomial,
  which the dispatcher actually handles; corrected.

### Flagged for the docs/pkgdown lane (NOT edited here, to avoid colliding with the
### in-flight README/docs work the maintainer is coordinating with Codex)

These are the **registry blocker** and must be reconciled before a tag. The audit
gives exact file:line evidence so the fix is mechanical:

- **#1 (BLOCKER) `README.md`**: titles the package "Fast Gaussian GLLVMs"
  (`README.md:6`), declares "Gaussian family only (binomial, Poisson, etc. planned)"
  (`:99`), and repeats "Fast Gaussian" in the citation (`:107`) — contradicted by ~20
  shipped fitters (`src/GLLVM.jl:113–131`, `test/runtests.jl:37–66`).
- **#2 (major) `README.md:92`**: advertises "Reverse-mode AD (via Enzyme.jl /
  ReverseDiff.jl)" — neither is a dependency (`Project.toml`); the backend is
  ForwardDiff (`src/fit.jl:12–16`). Reword to forward-mode/ForwardDiff.
- **#3 (major) `docs/src/response-families.md:64`**: hurdle/ZI/delta marked "planned
  — not yet started"; table omits Lognormal, Student-t, NB1, Beta-Binomial, truncated
  Poisson/NB, mixed-family. All shipped.
- **#4 (major) `docs/src/gllvmtmb-parity.md:26,51,59,72`**: understates non-Gaussian
  CIs, `@formula`, ZIP/ZINB as planned/"not yet wired". (Delta-Gamma at `:24` IS a
  genuine gap — keep it.)
- **#5 (major) `docs/src/changelog.md:27–29`**: claims Felsenstein-contrasts +
  edge-incidence phylo representations as *shipped*, but `edge_incidence.jl`,
  `phylo_contrasts.jl` (+ likelihoods) are **not** `include`-d and their tests are not
  wired — downgrade to "unwired prototype" (the sparse-precision path IS shipped).
- **#6 (minor)**: headline speedup is inconsistent across the claim surface
  (README "10–100×" `:31`; index/CLAUDE/changelog "~340×"; benchmarks 161–698×;
  comparison 190/520/280×) — pick one provenance-backed number/range.
- **#7 (minor) `index.md:32`, `roadmap.md:28`, `changelog.md:16`**: shipped
  capabilities (ZI/delta families, `fit_phylo_gaussian`) listed as planned.
- **#10 (minor) `response-families.md`**: presents `fit_gllvm(Y; family=…)` as the
  universal entry, but the dispatcher routes only 8 families; note the standalone
  `fit_*_gllvm` drivers for the rest.

### Disclosed-absence / no action for a correct tag

- **#14** structured non-Gaussian dependence is deliberately-unexported prototype
  substrate (correctly disclosed).
- **#15** several phylo/EM prototype source + test files are intentionally unwired —
  confirm intent and label as out-of-package prototypes before tagging.
- **#16** license boundary clean — no action.

## CLAUDE.md (#8, agent guidance — not pkgdown)

The Status line ("six dense-Laplace non-Gaussian fitters") and "Planned next"
(two-part/ZI/delta "when their parameterisations land") undercount the now-14-family
roster. Low-collision to refresh (not in git-status flux, not a pkgdown file);
updated separately if time permits this session.
