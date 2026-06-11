# After-task — overnight non-Gaussian build-out (2026-06-10)

Branch `a1-nongaussian-ci` (worktree `…/GLLVM.jl-a1-ci`). **All work local; nothing
pushed** (per the no-push-without-instruction rule). This report covers the
autonomous overnight session (18 commits, `338c767`→`6e15535`); the earlier
same-day batch is in `ec27dc7` and `a9d1581`.

## Definition of Done — status

| Item | State |
|---|---|
| Code committed (staged by name, one concern per commit) | ✅ 18 commits |
| Focused tests per wave | ✅ all green (tallies below) |
| Canonical `Pkg.test` gates (run ALONE) | ✅ 5 green + a 6th (round-out) running at hand-off |
| Adversarial correctness verification | ✅ zero bugs (independent re-derivation) |
| Durable record (plan log + this report) | ✅ plan Update 3 & 4 + this file |
| Pushed / registered | ❌ not done (awaits explicit instruction) |

## What was done

**Root-cause fix.** `refactor(link_residual)` `338c767` — the four μ̂-dependent
`link_residual` methods shared an identical per-site Laplace-mode loop that the
keep-both merge resolver kept collapsing into a broken function (the recurring
`link_residual.jl` ParseError). Extracted `_link_residual_meanfit`; each method is
now a short distinct call. This removed the merge-mangling class of failure for the
rest of the session.

**New families (6 added this session → 17 total + mixed + 3 two-part):**
- `99296c5` ZIP (zero-inflated Poisson) · `4da52ad` ZINB (zero-inflated NB2) — the
  zero-inflated count pair; two scalar auxiliaries on the aux-count-agnostic generic
  implicit path; weights reduce algebraically to NB2 (π→0) and ZIP (r→∞).
- `36e2a48` ZIBinom (zero-inflated Binomial) — reuses the verified binomial cell +
  ZINB zero-inflation decomposition.
- `4d68c6c` Generalized Poisson GP-1 — over- AND under-dispersion (α unconstrained),
  the modelling gain over NB.
- `376d1eb` Conway–Maxwell–Poisson — flexible dispersion via a truncated-sum
  normaliser; ν=1 → Poisson.

**Inference + post-fit surface (audit-driven):**
- `0272779` wired the orphan `confint_derived_wald.jl` (transformed-scale Wald CIs
  for derived quantities) — it was committed but never `include`-d/exported/wired.
- `3066096` uniform Wald `confint` across the 7 extended families (+ a `:logit`
  back-transform) → **Wald CIs for 15 fit types**.
- `6e15535` Wald confint + predict/aic-bic round-out for ZIBinom/GenPoisson
  (CMPoisson Wald deferred — see Limitations).
- `4ee1566` `anova`/`lrt` nested LRT + `_loglik`/`_nparams` extended → **uniform
  `aic`/`bic`** across families.
- `53455a1` predict/fitted/getLV for the newer one-part families; `6e15535` adds the
  three newest (COM-Poisson `predict(:response)` uses its true mean E[y]).
- `3b56490` `bootstrap_ci_families` — percentile parametric bootstrap CIs for 10
  one-part non-Gaussian fits.
- `136929b` `fit_gllvm` dispatcher doc/error fix (BetaBinomial) (audit #9).

**Audits + corrections:**
- `2f54aae` Rose pre-tag audit (read-only 4-lens ultracode Workflow). Verdict: code
  solid, **MIT/GPL boundary clean**; the registry blocker is documentation drift.
- `51abad8` two doc corrections surfaced by an adversarial re-derivation pass
  (zero correctness bugs found): the `:logit` confint kind, and the bootstrap
  non-converged-refit wording.

## Verification

- Per-family FD-gradient checks (ForwardDiff vs central differences) ≤ 1e-6 on every
  new family marginal AND the implicit fit objective: ZIP 7.4e-9, ZINB 1.1e-8 /
  1.4e-8, ZIBinom 4.4e-9 / 6.2e-9, GenPoisson + COM-Poisson ≤ 1e-6, all green.
- Limiting reductions verified as test oracles: ZIP/ZINB→NB2/Poisson, ZIBinom→Binomial,
  GenPoisson→Poisson (α→0), COM-Poisson→Poisson (ν→1).
- simulate→fit→recover for every family (loadings structure + dispersion within
  documented MC bands; convergence flags informational).
- **Adversarial verification Workflow** independently re-derived ZIP/ZINB scores +
  Fisher weights + link-residuals, the confint scale/packing for every extended
  family, the anova dof convention, and the bootstrap percentile/refit logic —
  **zero correctness bugs**; only two doc-wording fixes (applied).
- Canonical `Pkg.test` (Aqua/JET incl.) run ALONE and green after each wave:
  ZIP, ZINB, orphan+fit_gllvm+confint, anova+postfit+bootstrap, 3-families; the
  round-out gate is the 6th (running at hand-off).

## Engine capability (current)

17 response families (Gaussian, Binomial, Poisson, NB2, NB1, Beta, BetaBinomial,
Gamma, Ordinal, Lognormal, Student-t, TruncPoisson, TruncNB, ZIP, ZINB, ZIBinom,
GenPoisson, COM-Poisson) + mixed-family + 3 two-part (delta/hurdle). Wald CIs for 15
fit types; percentile bootstrap CIs for 10; predict/postfit across the one-part set;
`anova`/`lrt` + uniform `aic`/`bic`; derived-quantity Wald (correlation/communality)
+ bootstrap; cross-family latent correlation; phylo + sparse paths; R→Julia
`bridge_fit`.

## Limitations / deferred (honest)

- **Docs drift is the remaining registry blocker** (NOT the code). README says
  "Gaussian only" + advertises a non-existent Enzyme/ReverseDiff backend; capability
  /parity/status pages mark shipped features as planned; the changelog over-claims two
  phylo representations that are not `include`-d. Exact file:line fixes are in
  `docs/dev-log/2026-06-10-rose-pretag-audit.md`. **Left to the docs/pkgdown lane**
  (those files are actively modified in the main checkout) — not edited here, to avoid
  collision.
- **`phylo_signal_wald_ci` is broken and NOT exported** — `_derived_unpack` rebuilds
  the phylo σ_phy exp-scaled vs the public `phylo_signal` extractor. Quarantined
  (`@test_broken`) and a fix task was spawned (the fix must not regress the shared
  profile-CI path).
- **CMPoisson Wald CI deferred** — its per-eval truncated-sum marginal makes a
  ForwardDiff Hessian slow/fragile; a hand-coded/FD observed information is the route.
  COM-Poisson's test is also slow (~4 min) for the same reason.
- `aic`/`bic`/predict/bootstrap not yet added for MixedFamilyFit and the phylo/EM fit
  types (out of scope this session).

## Suggested next steps

1. Docs reconciliation (registry blocker) per the Rose audit — docs/pkgdown lane.
2. Push + register decisions await explicit instruction.
3. Fix `phylo_signal_wald_ci` (spawned task); then re-export it + un-break its tests.
4. Optional: CMPoisson Wald via FD information; trim the COM-Poisson test runtime.
