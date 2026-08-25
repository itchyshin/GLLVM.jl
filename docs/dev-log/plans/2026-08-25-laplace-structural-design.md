# Laplace curvature role-separation — design, adversarial review, implementation plan

**Date:** 2026-08-25 · **Lane:** `claude/lane-beyond-20260824` · **Status:** design
accepted with blocking modifications; **implementation NOT started.**

## Provenance

Produced by a four-phase workflow (Design → Census ×2 → Refute → Plan) run read-only
against lane HEAD. Design and Plan on Fable; the adversarial reviewer on Opus, deliberately
a different model from the designer so the review could not merely re-confirm the design's
own priors. The reviewer had veto authority.

**Verdict: PROCEED WITH MODIFICATIONS** — six blocking modifications, M1–M6 in the review.

## The two things to read first

1. **This does NOT close the fault class.** `_glm_weight` is consumed across the package,
   but the proposed `hessian` kwarg reaches exactly **one** kernel (`laplace.jl`). Twelve
   other kernels build their own `Λ'WΛ + I` and their own `logdet` and are untouched —
   including two live user surfaces, `covariates.jl:52-69` (backing `fourthcorner.jl`,
   `species_covariates.jl`, `constrained_ordination.jl`, `row_effects.jl`) and
   `mixed.jl:249-254` (backing `fit_mixed_gllvm`). Buy this contract for the correctness
   of the core-reachable families. **Do not buy it as anti-recurrence, and do not let any
   after-task report record the class as closed.**

2. **The test suite cannot currently tell a fix from a regression.** `test/parity/` is not
   referenced by `test/runtests.jl` at all (verified independently: `grep -c parity
   test/runtests.jl` → 0), so it never runs in CI or under `Pkg.test()`. The only in-suite
   independent oracles are three quadrature comparisons at `atol = 0.5`, `atol = 0.5` and
   `atol = 0.06` — loose enough to pass under *either* curvature. This is why the reviewer
   names oracle re-derivation, not the algebra, as the most dangerous step.

## Two further instances found during design (class is now 13)

- **#12 GP1** (`gp1.jl:65-71`) — CONFIRMED by hand derivation, independently reproduced by
  the reviewer. Shipped Fisher `μ/(1+αμ)²`; observed `μ(1+2αy−αμ)/(1+αμ)³`. `E[y] = μ`
  recovers the shipped value exactly — the signature of this fault class. Note
  `1 + 2αy − αμ` **can be negative**, so GP1 joins Student-t in needing the PD guard and
  must NOT be clamped.
- **#13 mixed-family** (`mixed.jl:249-254`) — `_mixed_loglik_site` builds its own `A` and
  `logdet` from `_glm_weight`. Same conflation, separate kernel, reachable through
  `fit_mixed_gllvm` with NB2/Gamma/Beta traits.

**Boundary confirmed:** DeltaGamma (#5) does *not* route through this core — its Fisher
`Wc = α` is the fourth tuple element of `_tp_pieces(::DeltaGamma, …)`
(`twopart.jl:610`). This contract does not absorb that fix; it lands separately.

## Own-the-verifier constraint, carried forward verbatim

> Whoever changes the weight must not be the one who writes the new expected numbers.

When the stored identities go red, the natural repair is to paste in whatever the new code
prints — making the new code its own oracle and shipping a *different* wrong weight, fully
green. That is the same fault this arc exists to fix, one level up.

---

## 1. Design

# Design: role-separated curvature contract for `src/families/laplace.jl`

All paths below relative to `/Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824/`.

## 0. Verdicts requested up front

**GP1 (candidate #12) is CONFIRMED an instance — by hand derivation, pending one numerical gate.** From the coded log-pmf at `src/families/gp1.jl:75-81` (`ℓ = y(log μ − log g) + (y−1)log h − logΓ(y+1) − μh/g`, `g = 1+αμ`, `h = 1+αy`, log link):

- observed: `−∂²ℓ/∂η² = μ(1 + 2αy − αμ)/(1+αμ)³`
- shipped Fisher (`gp1.jl:65-71`): `μ/(1+αμ)²`

These are equal only when `α = 0` or `y = μ`. Consistency check that validates the algebra: `E[y] = μ` gives `E[W_obs] = μ(1+αμ)/g³ = μ/g²` — Fisher is exactly the expectation of the observed weight, the signature of the fault class. The `gp1.jl:37` comment "EXACT Fisher info wrt η" is *true* but names the wrong role: exact expected information is still the wrong log-det weight. Same derivation method reproduced the shipped NB1 fix verbatim (`grouped_dispersion.jl:1088-1098`), so I trust it; the settling experiment (I could not run Julia — suite in progress) is: nested `ForwardDiff.derivative` of `η → _glm_logpdf(GeneralizedPoisson1(α), max(exp(η),1e-12), 1, y)` vs the formula, grid `α ∈ {−0.15, −0.05, 0.1, 0.5}`, `μ ∈ {0.5, 2, 10}`, `y ∈ {0,1,5,20}` ∩ support, rtol 1e-12. Note `1 + 2αy − αμ` **can be negative** (α<0 with y near the support cap; α>0 with μ > 1/α + 2y) — GP1 joins Student-t in needing the PD guard.

**One additional unlisted instance found while checking callers:** `_mixed_loglik_site` at `src/families/mixed.jl:249-254` builds its **own** `A = Λ'WΛ + I` and `logdet` from `_glm_weight(families[t], …)` — the same Fisher-in-the-log-det conflation, in a separate kernel, reachable via `fit_mixed_gllvm` with NB2/Gamma/Beta traits. It is not on the 11-instance ledger. The contract below fixes it for free *only if* mixed adopts the same weight switch; flagged in §8.

**Boundary confirmation:** DeltaGamma (instance 5) does **not** route through this core — its Fisher `Wc = α` is the 4th tuple element of `_tp_pieces(::DeltaGamma, …)` at `src/families/twopart.jl:610`. This contract does not absorb that fix; the uncommitted worktree fix must land separately.

## 1. The contract — (a)+(c) combined, because they are one design at two layers

**Chosen:** a new per-cell hook `_glm_obs_weight` with a nested-ForwardDiff default (option a), selected by a `hessian::Symbol` kwarg threaded through the core (option c), plus a trait that keeps canonical links on the literal existing code path. **These are not competing options.** The four shipped fixes are already exactly this shape at kernel granularity: `_nb_grouped_laplace_weight(hessian, f, μ, me, y, link)` (`grouped_dispersion.jl:18`), `_beta_grouped_laplace_weight(…, η)` (`:403`), `_gamma_grouped_laplace_weight` (`:747`), `_nb1_grouped_laplace_weight` (`:1088`), `_truncnb2_laplace_weight` (`truncated_nbinom2.jl:98-104`) — each is "a Symbol selects `_glm_weight` vs an observed formula". The generic core needs the same selector plus a generic observed default so a family without a hand-derived formula is *correct by default* rather than silently Fisher.

**Option (b) (DRM d1/d2 ladder) rejected concretely:** it would replace the `_glm_score(f, μ, n, me, y)` / `_glm_weight(f, μ, n, me)` signatures consumed by 13 family files plus `mixed.jl:250`, `spde_latent.jl:54`, `aghq_grid.jl:203`, and the variational files — guaranteeing digit churn in the verified-correct set, which the constraints forbid. DRM's *discipline* (d2 gate-tested against ForwardDiff at rtol 1e-10; damped search + exact value curvature) is imported as the test gate and the search/value split, not as a signature rewrite.

### New generic code in `laplace.jl`

```julia
# ---- Curvature-role separation (2026-08-25) --------------------------------
# `_glm_weight` (:15) is the FISHER (expected) information wrt η — the mode-
# search metric, always ≥ 0 ⇒ Λ'WΛ+I SPD inside Newton. The marginal's log-det
# needs the OBSERVED curvature −∂²ℓ/∂η² (what TMB's Laplace uses, structurally,
# because MakeADFun differentiates the coded joint nll).

# Trait: the existing `_glm_weight` slot already computes the correct log-det
# curvature at this (family, link) — either because observed ≡ Fisher pointwise
# (canonical link) or because the slot is hand-coded observed (CensoredPoisson).
# Trait-true families take the branch containing the UNTOUCHED existing code.
_glm_weight_matches_observed(family, link::Link)            = false
_glm_weight_matches_observed(::Poisson,          ::LogLink)      = true
_glm_weight_matches_observed(::Binomial,         ::LogitLink)    = true
_glm_weight_matches_observed(::Normal,           ::IdentityLink) = true  # const 1/σ²
_glm_weight_matches_observed(::TruncatedPoisson, ::LogLink)      = true  # fid-10 proof, truncated_nbinom2.jl:66-73
_glm_weight_matches_observed(::CensoredPoisson,  ::LogLink)      = true  # slot IS observed, censored_poisson.jl:67-75

# Policy: which curvature the log-det uses when the caller does not choose.
_default_hessian(family, link::Link) = :observed

"""
    _glm_obs_weight(family, μ, n, me, y, link, η) -> −∂²ℓ(y|η)/∂η²

Observed conditional curvature wrt the linear predictor at one cell — the
log-det weight of TMB's Laplace. May be NEGATIVE (Student-t, GP1); the PD guard
lives at the Λ'WΛ+I assembly, never here (do NOT clamp — see ordinal.jl warning).
Default: nested ForwardDiff through the CODED conditional log-density, μ-clamp
included — exactly the function the objective sums. Families with an analytic
form override (typed on their supported link); unsupported links fall through
to this default, which is link-general.
"""
function _glm_obs_weight(family, μ, n, me, y, link::Link, η)
    f = ηv -> _glm_logpdf(family, _clamp_mu(family, linkinv(link, ηv)), n, y)
    g = ηv -> ForwardDiff.derivative(f, ηv)
    return -ForwardDiff.derivative(g, η)
end
```

`ForwardDiff` is already imported module-wide (`src/GLLVM.jl:3`). The signature extends `_glm_weight(family, μ, n, me)` with `(y, link, η)` — mirroring the repo's own convergent form `_beta_grouped_laplace_weight(hessian, f, μ, me, y, link, η)`, and passing μ/me so analytic overrides reuse the caller's already-clamped values digit-for-digit with the grouped kernels.

## 2. The ForwardDiff fallback, exactly

The composition differentiated in η is `η → _clamp_mu(family, linkinv(link, η)) → _glm_logpdf(family, μ, n, y)` — written above. Points that matter:

- **It differentiates the coded objective, clamps included.** `_clamp_mu` uses `max`/`clamp`; ForwardDiff gives derivative 0 in the saturated region — the true local derivative of the coded function, which is TMB's semantics (TMB differentiates its coded nll, guards and all). The η-clamp (`laplace.jl:20`) is *outside* the composition, matching how the current Fisher weight is evaluated at already-clamped η — no change in convention.
- **Where our clamp differs from the twin's coded guard**, the hook is faithful to *our* objective; only the parity test against R can adjudicate the residual — the hook cannot and should not.
- **Non-twice-differentiable points** (clamp corners): ForwardDiff returns the active branch's one-sided value — deterministic, measure-zero, matching evaluation of the coded piece. No current family has positive-measure kinks in η; one that did must override by hand.
- **Dual-safety through `Distributions` constructors** (`logpdf(Beta(μφ,…))`, `logpdf(NegativeBinomial(r, r/(r+μ)))` with Dual μ) is precedented in this repo — `ordered_beta_logp` (`ordered_beta.jl:85`) already runs `logpdf(Beta(Dual,…))` under nested ForwardDiff — but is not universally proven, so **every family relying on the fallback needs the rtol-1e-10 gate test** (§7). If a family's logpdf is not dual-safe, the fallback **fails loudly** (MethodError), never silently reverts to Fisher — correct-or-loud is the anti-recurrence property; a silent `_glm_weight` fallback would rebuild the fault class invisibly.
- **Cost:** one `Dual{Dual}` second derivative per cell, once per site, only in the log-det tail — never inside the Newton loop (constraint satisfied). It is the safety net; the six hot families get analytic overrides (§4), because FD-gradient fitters call the objective O(dim) times per gradient and the fallback there would be genuinely slow (p·n nested evals per objective call).

## 3. Canonical fast path — zero cost, bit-for-bit

In `laplace_loglik_site` (`laplace.jl:152-182`) the tail becomes:

```julia
h = hessian === :auto ? _default_hessian(family, link) : hessian
h in (:fisher, :observed) || throw(ArgumentError("hessian must be :fisher, :observed or :auto; got :$hessian"))
...mode solve and η/μ/me exactly as now (lines 158-165)...
if h === :fisher || _glm_weight_matches_observed(family, link)
    # >>> lines 166-181 VERBATIM — same broadcasts, same buffers, same
    # logdet(Symmetric(Amat)) call — nothing on this branch is new arithmetic. <<<
else
    W = _glm_obs_weight.(Ref(family), μ, n, me, y, Ref(link), η)
    mask === nothing || (W = ifelse.(mask, W, 0.0))
    ...same A assembly...
    C = cholesky(Symmetric(Amat); check = false)     # PD guard, §6
    issuccess(C) || return -Inf
    ...ℓ sum as now...
    return ℓ - 0.5 * dot(z, z) - logdet(C)           # logdet from the Cholesky
end
```

- The guard is **one Symbol compare + one trait call per site** (the trait const-folds to `true`/`false` at dispatch; the log-det W is computed once per site, not per Newton iteration or per cell). Poisson/log, Binomial/logit, Gaussian-in-mixed, TruncatedPoisson, CensoredPoisson execute the identical expressions on identical inputs — bit-for-bit is by construction, and tests assert `===` (§7).
- ~14 duplicated tail lines in the observed branch are the price of keeping the Fisher branch literally untouched; accepted deliberately.
- `marginal_loglik_laplace` (`laplace.jl:198-209`) already forwards `kwargs...` to the site function, so `hessian` threads with **no signature change** — which is also how the structural variants (`quadratic.jl`, `row_random.jl`, `random_slopes.jl`, `constrained_ordination.jl`, `missing_predictor_*.jl`) and every family wrapper (`studentt.jl:101`, `tweedie.jl:139`, `gp1.jl:121`, `negbin.jl:25`, `gamma.jl:25`, `beta.jl:41`, `negbin1.jl:92`) inherit the contract with zero per-file edits. Docstrings of both core functions must document `hessian` (convention-change cascade, AGENTS.md rule 3), and a math note goes under `docs/dev-log/decisions/` (rule 4).

## 4. Per-family observed methods (same arc) — delegate, don't duplicate

Single source of truth: where a gate-tested observed formula already ships in a grouped kernel, the generic method **delegates to it**, guaranteeing digit-identity between shared and grouped routes (making the G=1 identity tests exact):

| family | new method (typed on supported link) | body |
|---|---|---|
| NB2 (`negbin.jl`) | `_glm_obs_weight(f::NegativeBinomial, μ,n,me,y, l::LogLink, η)` | `= _nb_grouped_laplace_weight(:observed, f, μ, me, y, l)` (`grouped_dispersion.jl:18-25`: `r μ (r+y)/(r+μ)²` — same formula `laplace_grad.jl:148` already uses for the implicit step) |
| Gamma (`gamma.jl`) | `…(f::Gamma, …, l::LogLink, η)` | `= _gamma_grouped_laplace_weight(:observed, f, μ, me, y, l)` (`:747-755`: `α y/μ`) — **closes instance 8, the public default** (`fit_gllvm.jl:142-148` excludes Gamma from the `disp_group=:species` coerce, so the shared route is what real users hit) |
| Beta (`beta.jl`) | `…(f::Beta, …, l::LogitLink, η)` | `= _beta_grouped_laplace_weight(:observed, f, μ, me, y, l, η)` (`:403-415`: `W_F − φ(y*−μ*)·me·(1−2μ)` — analytic, dual-safe, no nested-tag issue) |
| NB1 (`negbin1.jl`) | `…(f::NB1, …, l::LogLink, η)` | `= _nb1_grouped_laplace_weight(:observed, f, μ, me, y, l)` (`:1088-1098`) — closes instance 11; note the observed weight is *cheaper* than the pmf-summed Fisher `_nb1_fisher_mu` (`negbin1.jl:50-71`), which stays as the search metric |
| Tweedie (`tweedie.jl`) | `…(f::TweedieED, …, l::LogLink, η)` | new analytic `μ^(1-f.p)/f.φ * ((f.p-1)*y + (2-f.p)*μ)`; check `E[·] = μ^{2−p}/φ = Fisher` ✓; **always ≥ 0** on `1<p<2, y≥0` — no PD exposure |
| Student-t (`studentt.jl`) | `…(f::StudentTFamily, …, l::IdentityLink, η)` | new analytic `(ν+1)(νσ² − r²)/(νσ² + r²)²`, `r = y−μ` (identity link ⇒ no me′ term); genuinely negative for `|r| > σ√ν` — **no `max(·,0)`**, PD guard handles it |
| GP1 (`gp1.jl`) | `…(f::GeneralizedPoisson1, …, l::LogLink, η)` | new analytic `μ(1 + 2aμy′)/g³` — precisely `μ*(1 + 2f.α*y − f.α*μ)/(1+f.α*μ)^3`, with the `abs(α)<1e-10 → me²/μ` short-circuit mirroring `gp1.jl:66`; can be negative — PD guard |
| TruncNB2 (`truncated_nbinom2.jl`) | optional | `= _truncnb2_observed_weight(f, μ, y, l)` (`:76-91`) — makes the generic core correct too if reached; its wrapper kernel route is untouched |
| Exponential | none required | its wrapper (`exponential.jl:50-68`) already implements both branches; see follow-up in §8 |

Families on the trait (Poisson, Binomial/logit, Normal, TruncatedPoisson, CensoredPoisson): **one trait declaration line each, zero numeric change.** Separate-kernel families (BetaBinomial, CMP, OrderedBeta, Ordinal) already observed by construction: untouched. Non-canonical-link Binomial (probit/cloglog): trait is false, so under `:observed` they land on the fallback — this is the *same fault class* previously unlisted (the ledger verified Binomial/**logit** only); it changes probit-binomial numbers, correctly, and must be named in the maintainer-facing report with a parity measurement rather than silently pinned back to Fisher.

## 5. Coupled analytic gradients — same commit, or the gradient stops being the gradient

The three coupled sites in `src/laplace_grad.jl` change with the default flip, exactly as the brief established:

- **NB2 `:156`**: `Wz = μz ./ (1 .+ μz ./ r)` → the observed expression already computed for the implicit step at `:148` (`μ r (r+y)/(r+μ)²`), re-evaluated at the differentiable `z`.
- **Gamma `:221-222`**: `Wf = fill(α, p)` → `α .* y ./ μz` (dual-safe, matches `_gamma_grouped_laplace_weight`).
- **Beta `:302-303`**: `WFz = φ².*νz.*mez.²` → the same analytic expression as `_beta_grouped_laplace_weight(:observed,…)`: `WFz .- φ .* (ystar .- μstar) .* mez .* (1 .- 2 .* μz)` — analytic, so no nested-Dual-tag risk in the Dual log-det; the stale comment at `~:264` ("the log-det uses the Fisher weight (Dual) to match the marginal") is rewritten to state the new invariant: *the log-det weight matches whatever the objective's `hessian` resolves to*.
- Poisson (`:73/:84`) and Binomial (`:359/:369`) untouched — canonical, one formula serves both roles (confirmed in the code).
- Contract rule going forward, stated in the laplace.jl header: **any change to the objective's log-det weight and to the analytic gradient's log-det weight is one commit**, FD-verified ≤ 1e-6 (Workflow Q check 1).

## 6. PD guard — guard the matrix, never clamp the cell

- **What:** in the observed branch only, `C = cholesky(Symmetric(Amat); check=false)`; on `!issuccess(C)` return `-Inf` for the site; on success take `logdet(C)`. Per-cell `W < 0` is *fine* as long as `Λ'WΛ + I ≻ 0` — the empirical finding (PD held across the 1400-site-solve ‖Λ‖ sweep) says the guard should almost never fire; when it does, `-Inf` propagates to the fitters' existing `isfinite(v) ? v : 1e12` guards (e.g. `poisson.jl` negll; same pattern repo-wide), so the L-BFGS backtracking line search rejects the step — the same effective behavior as TMB's NaN from a non-PD inner Hessian. It also fixes a latent hazard: `logdet(Symmetric(A))` on an indefinite A can throw `DomainError` (negative determinant) or silently return `log|det|` with paired negative eigenvalues; the explicit Cholesky makes non-PD a defined, finite-handled event.
- **Where:** `laplace_loglik_site`'s observed branch only. The Fisher/trait branch keeps the existing `logdet(Symmetric(Amat))` call untouched (bit-for-bit). The mode search needs no guard — it stays on Fisher, SPD by construction (`laplace.jl:9-10`).
- **What NOT to do:** `max(W, 0)` — safe for the log-concave links in `ordinal.jl:72` but for Student-t/GP1 it would silently evaluate a different objective than TMB with no diagnostic; the brief's DRM answer (damp the *search*, exact curvature for the *value*) is exactly the Fisher-search/observed-value split this design institutionalizes.

## 7. Default: `:auto` resolving to `:observed` — argued

Core default `hessian = :auto`, resolved per (family, link) by `_default_hessian`, which is globally `:observed`. Reasons: (i) **precedent** — all four shipped family fixes defaulted `:observed` with `:fisher` reachable, and this contract is that precedent generalized; (ii) **the urgent instance demands it** — Gamma's shared route is the public default surface (`fit_gllvm.jl:142-148` coerce excludes Gamma), and a `:fisher` default would leave instance 8 shipping; (iii) **it removes a live inconsistency** — today `fit_gllvm(Y; family=NegativeBinomial(…))` (grouped, `:observed`) and `fit_nb_gllvm` / `disp_group=nothing` / `bridge.jl:1111` / the bootstrap-refit and Wald paths (`confint_family.jl:183` refit via `fit_nb_gllvm`; `_family_wald` at `:1911` FD-Hessian of the same nll at `:1913`) optimize *different objectives*; after the flip, the shared route, the grouped route at G=1, and the twin agree, and the Wald/bootstrap detection gap closes automatically because the FD Hessian and refits inherit the corrected objective with zero confint code changes; (iv) `:fisher` stays one kwarg away for regression comparison. The honest bill: every stored value test for shared-route NB2/Beta/NB1, Gamma, Tweedie, Student-t, GP1 marginals changes numbers and must be re-baselined against the R twin **in the same arc** — that is a re-derivation of oracle values, not a tolerance widening. If the maintainer wants a staged rollout, the mechanism is a one-line per-family pin (`_default_hessian(::StudentTFamily, ::IdentityLink) = :fisher`) — but I recommend no pins: land the PD guard in the same commit and flip everything on the audit table at once, because a partial flip recreates the split-objective inconsistency the contract exists to end.

**Mode search stays on Fisher — safe because:** the mode is defined by the W-free score equation `Λ's(ẑ) = ẑ` (`laplace.jl:96-97`), and Fisher scoring is only the (always-SPD) metric used to solve it, so the converged `ẑ` is the same stationary point observed-Newton reaches, to step tolerance 1e-9 — and `ẑ` enters the returned value only through `ℓ(ẑ)`, `ẑ'ẑ`, and the separately computed log-det. Reviewer check: swap W inside `_laplace_mode` alone and confirm `ẑ` agrees to solver tol while the objective is unchanged. (Non-log-concave caveat: for Student-t multiple stationary points can exist; Fisher's SPD metric plus the existing backtracking is precisely the damped search DRM prescribes.)

**Tests shipped with the arc:** (1) observed-weight gate: every override vs the nested-FD fallback vs central finite differences of the coded logpdf∘linkinv, rtol 1e-10 (DRM discipline), grid spanning clamps and dispersions — this also settles GP1 numerically; (2) bit-for-bit: trait-true families assert `laplace_loglik_site(…; hessian=:observed) === (…; hessian=:fisher) ===` pre-change recorded values; (3) route identity: shared vs grouped at G=1 now exact for NB2/Beta/NB1/Gamma; (4) R-parity cells for Gamma (instance 8) and one probit-Binomial measurement; (5) FD-vs-analytic gradient ≤ 1e-6 re-run for NB2/Gamma/Beta after the `laplace_grad.jl` swap; (6) PD-guard test constructing an indefinite Student-t/GP1 site (large `|r|`, large ‖Λ‖) asserting `-Inf`, no throw, and a fit smoke where the line search recovers. The named missing detector — broad-grid CI *coverage* — remains the only test class that catches this fault end-to-end and should be filed as its own follow-up campaign (Totoro-sized), not stuffed into this arc.

## 8. Out-of-core items this contract touches but does not fix

- **`mixed.jl:249-254`** — adopt the same `h`-branch in `_mixed_loglik_site` (its own kernel; same arc or immediate follow-up; report as a new ledger entry).
- **`aghq_grid.jl:203`** (instance 7, PARKED) — stays parked; the hook makes the eventual fix a one-line weight swap.
- **`exponential.jl:50-68`** — optional simplification: with the core contract, `:observed` no longer needs the Gamma-grouped kernel reroute, regaining the generic core's backtracking mode solver (the file itself documents the ‖Λ‖→960 runaway of the grouped solver). Mode-iteration digits may shift — measure before landing; not required for correctness.
- **DeltaGamma (`twopart.jl:610`)** — separate uncommitted fix; unaffected here.
- **Stale docs to correct in the same PR:** `laplace.jl:15` ("Fisher information wrt η" becomes the two-role contract), the `laplace_grad.jl:264` comment, and the two check-log errors the brief names (DeltaGamma "fixed" claim; NB1 fix-site misattribution to `negbin1.jl:77`, which this arc now *actually* closes via the delegate method).

**Uncertainty register:** GP1 formula and the Tweedie/Student-t analytic forms are hand-derived (each with the `E[W_obs] = W_F` identity confirmed symbolically, and NB1's twin derivation matching shipped code) but not yet machine-checked — gate test (1) settles all of them; dual-safety of the fallback through every `Distributions` constructor is precedented but unproven per family — gate test (1) again; whether TMB's coded twin clamps μ where we do is family-specific — only the R-parity cells adjudicate the residual after the weight fix.
---

## 2. Adversarial review (Opus, veto authority)

VERDICT: **PROCEED WITH MODIFICATIONS**

Lane HEAD is `3958210e`, not `a96e5526` — both censuses are three commits stale. The three intervening commits are docs-only, so their `src/` citations still hold, but neither agent re-checked.

## Strongest objection

**The design's central justification is false as built.** Its purpose is stated as "separate the two roles so the fault class cannot recur." I counted the call sites: **13 files in `src/` consume `_glm_weight` at a call site. The `hessian` kwarg reaches exactly one** (`laplace.jl`). Twelve kernels build their own `Λ'WΛ + I` and their own `logdet` and are untouched:

`grouped_dispersion.jl` (7 uses; Tweedie has no selector), `covariates.jl`, `quadratic.jl`, `mixed.jl`, `spde_latent.jl`, `aghq_grid.jl`, `phylo_glm.jl`, `phylo_nb_xlv.jl`, `phylo_beta_xlv.jl`, `phylo_gamma_xlv.jl`, `phylo_binomial_xlv.jl`, `coevolution_glm.jl`, `truncated_nbinom2.jl`.

Two are live user surfaces: `covariates.jl:52-69` backs `fourthcorner.jl`, `species_covariates.jl`, `constrained_ordination.jl`, `row_effects.jl`; `mixed.jl:249-254` backs `fit_mixed_gllvm` with NB2/Gamma/Beta traits. After this arc the repo has *more* internal divergence, not less, and a new family added through any of those twelve doors still silently gets Fisher. **Buy the contract for the correctness of the twelve core-reachable families. Do not buy it as anti-recurrence, and do not let the after-task report record the class as closed.**

## What I verified in the code

Confirmed: S1 (`_tweedie_grouped_loglik_site`, `grouped_dispersion.jl:1445-1481`, Fisher at :1471, no `hessian` anywhere — last occurrence in the file is :1374); S2; S3 (`covariates.jl:52-69`, `quadratic.jl:64-79` standalone); the split grouped defaults (marginals `:fisher` at :30/:129/:420/:471/:759/:810/:1103/:1154, fitters `:observed` at :212/:332/:555/:674/:894/:1015/:1253/:1374 — Census A's correction (b) is right); the three coupled gradient sites verbatim with their comments.

Derived by hand, independently — **all four design formulas are correct**: GP1 `μ(1+2αy−αμ)/(1+αμ)³` (the `g − aμ = 1` collapse is real); Tweedie `μ^(1−p)[(p−1)y+(2−p)μ]/φ`, always ≥ 0 on `1<p<2, y≥0`; Student-t `(ν+1)(νσ²−r²)/(νσ²+r²)²`; and TruncatedPoisson observed ≡ Fisher — expanding `var_tr = μtr(1+μ−μtr)` gives exactly `μ[(1−p₀)−μp₀]/(1−p₀)² = μ·dμtr/dμ`. Each satisfies `E[W_obs] = W_Fisher`.

**Tweedie's infinite series is NOT a hazard.** `_tweedie_logA(y::Float64, φ::Float64, p::Float64)` receives only primals (`y` is the response, `φ`/`p` are struct fields), so the series and its adaptive window never see a Dual and never branch on η; and `Base.float(d::Dual)` exists (ForwardDiff `dual.jl:469`), so `float(μ)` in `tweedie_logpdf` is safe. The hazard you asked me to check does not exist.

**Census B is wrong in a way that helps the design**: it lists `laplace_loglik_site` as called from `ordered_beta.jl` and `quadratic.jl` — both are *comments* (`ordered_beta.jl:19`, `quadratic.jl:24/:61`). The only real calls are `random_slopes.jl:86` and `binomial.jl:40`. Consequence: BetaBinomial, CMP, OrderedBeta and Ordinal define no `_glm_weight` method at all, so they *cannot* reach the core (MethodError). The already-correct nested-FD families are structurally safe. Also, the reachable set is **12**, not 14: `Normal` is spde-only (`spde_latent.jl:47` says so in prose), and `TruncatedNegBin2` uses its own kernel — so the design's `_glm_weight_matches_observed(::Normal, ::IdentityLink)` is dead code and its "TruncNB2 optional" is genuinely optional.

## Five findings neither census has

**N1 — the FD fallback and every analytic override implement different functions, so the design's own gate test cannot pass as written.** Three clamp conventions coexist: the existing core uses clamped `μ` with `me = mu_eta(link, η)` from *unclamped* η (a hybrid); the proposed fallback puts `_clamp_mu` inside the differentiated composition, giving derivative **exactly 0** where the clamp binds; the analytic overrides take `(μ_clamped, me_unclamped, y)` and match the existing hybrid. `_clamp_mu(::Beta, μ) = clamp(μ, 1e-6, 1-1e-6)` binds at |η| > ≈13.8, well inside the ±30 η clamp and reachable in optimisation. Design §7 test (1) — "every override vs the nested-FD fallback, rtol 1e-10, grid spanning clamps" — **fails by construction** at any clamped cell. This also weakens "correct by default": a future family on the fallback gets a weight disagreeing with a hand-derived one precisely in the saturated region.

**N2 — `laplace_grad.jl` is *already* not the gradient of the objective in the clamped region.** NB and Gamma use `μ = exp.(η)`, Beta uses `μ = 1 ./(1 .+ exp.(-η))` — none applies `_clamp_mu`, which the objective does. Pre-existing; name it in the arc so it isn't discovered mid-flip and misread as new.

**N3 — `test/parity/` is not included by `test/runtests.jl` at all.** grep for "parity" in `runtests.jl` returns nothing; `runparity.jl:7-8` states it is the only entry point and never runs in CI. The only in-suite independent oracles are `test_beta_laplace.jl:37` and `test_gamma_laplace.jl:36` at `atol=0.5`, and `test_binomial_laplace.jl:38` at `atol=0.06` — all loose enough to pass either weight. **The suite contains no mechanism that can distinguish a fix from a regression.**

**N4 — `test_exponential.jl:84` becomes a vacuous guard while staying green.** `old = marginal_loglik_laplace(Exponential(1.0), …)` and `lf = …(; hessian=:fisher)` both flow to the core, so after the flip both compute observed and `lf == old` still passes. Its comment says it guards "a real, already-observed failure" (the ‖Λ‖→960 runaway). A test that silently stops testing is worse than one that fails.

**N5 — AGHQ.** `cholesky(A).U` at `aghq_grid.jl:217` is unguarded and :203 stays Fisher. If the core flips and AGHQ does not, the k=1 ≡ dense-Laplace identity becomes silently false for every non-canonical family, and all three assertions that would catch it use `Poisson()` so they stay green.

## Answers to the five tests

1. **Citations**: ~90% held; corrections above.
2. **Bit-for-bit**: the fast path is airtight *for the value* — the trait-true branch runs identical expressions on identical inputs and `_laplace_mode` is untouched, so `z` is identical. The claim rests on trait **coverage**, not floating point, and coverage is where it leaks: Exponential (S2), probit/cloglog Binomial, and TruncatedPoisson at a non-log link all fall off it.
3. **FD fallback**: Tweedie safe. Real hazards are N1's clamp convention and `Binomial(Int(n), μ::Dual)` / `NegativeBinomial(Float64, Dual)` construction — precedented but unproven here, and probit-Binomial is the one family the design actually routes onto the fallback *in production*.
4. **Gradient obligation**: understated for Gamma, overstated overall. It is a 3-line substitution (no `dW/dη` is encoded anywhere; the outer `ForwardDiff.gradient` supplies it) and it is *mechanically gated* by `test_laplace_grad.jl` at rtol 1e-4. But Gamma's `Wf = fill(α, p)` is constant in `z` today, so `∂logdet/∂z = 0` and the implicit correction has never been exercised through Gamma's log-det — after the flip it is, and Gamma is instance 8. If left inconsistent it **stalls, not diverges**: `_optimize_with_analytic` line-searches on the correct `negll`, and with the repo-wide `isfinite(v) ? v : 1e12` sentinel a PD-guard `-Inf` region gives a flat objective, a zero central-FD gradient, and a *declared convergence*.
5. **Worth it?** The conservative framing is out of date. It is not two patches but **eight** (NB2, Beta, Gamma, NB1, Tweedie, Student-t, GP1, probit-Binomial), and four already have a gate-tested observed weight in a grouped kernel, so family-local is a one-line delegate each. Family-local and structural therefore cost nearly the same; the only thing structural buys is the FD fallback, which by N1 is a different function from the overrides and by the 1-of-13 count cannot reach the kernels where the next instance will appear. **Take the role separation and the trait; be sceptical of the fallback-as-default.** Killing the arc outright is wrong — Gamma (instance 8) is a wrong public default today.

## Blocking modifications

- **M1 — split the arc into two verifiable commits.** (A) Contract with `_default_hessian = :fisher`: trait, `_glm_obs_weight`, the 7 overrides, PD guard, gate tests — **whole suite bit-for-bit green with zero test edits**. (B) The flip: default → `:observed`, the 3 `laplace_grad.jl` lines, `exponential.jl:60`, the Tweedie grouped selector, grouped-marginal defaults, oracle re-derivation. Unmerged, "the suite is green" carries no information — A's failures and B's intended changes are indistinguishable in one diff.
- **M2** — `exponential.jl:60` must pass `hessian = :fisher` explicitly, **and** `test_exponential.jl:84` must be re-armed against a recorded literal so it cannot pass vacuously.
- **M3** — add the `hessian` selector plus the observed weight to `_tweedie_grouped_loglik_site`. Not optional; the design does not budget it, and no kwarg can rescue the two `atol=1e-10`/`rtol=1e-6` Tweedie identities.
- **M4** — no oracle may be re-baselined from the new code's own output. Cheapest independent adjudicators needing no R: convert `test_beta_laplace.jl:37`, `test_gamma_laplace.jl:36`, `test_binomial_laplace.jl:38` from "within atol" to "**the error is strictly smaller than with `hessian=:fisher`**" — a direction-of-change assertion that is exactly the claim being made, and free.
- **M5** — the after-task report states the 1-of-13 coverage and files the twelve uncovered kernels (naming `covariates.jl` and `mixed.jl` as live surfaces). The check-log already carries two errors of this exact kind.
- **M6** — resolve N1: either have `_glm_obs_weight` consume the caller's `(μ, me)` and differentiate the unclamped link, or document it as deliberately a different object and exclude clamped cells from the gate grid.

## Single most dangerous step to get wrong

**Re-deriving the stored oracle values.** Every other step is mechanically gated — the gradient coupling by `test_laplace_grad.jl` at rtol 1e-4, Exponential by `test_exponential.jl:74`, Tweedie by two identities, the PD guard by a constructed indefinite site. Oracle re-derivation has **no gate at all**: `test/parity/` never runs in `runtests.jl`, and the only in-suite independent checks are three quadrature comparisons loose enough to pass either way. When five `atol=1e-10` identities and N stored marginals go red, the natural repair is to paste in whatever the new code prints — making the new code its own oracle and shipping a *different* wrong weight fully green. That is the same fault this arc exists to fix, one level up. Own-the-verifier applies: whoever changes the weight must not be the one who writes the new expected numbers.
---

## 3. Implementation plan

# Implementation plan — role-separated curvature contract for the Laplace log-det weight

Lane root (all paths below relative to it): `/Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824`. Verified at HEAD `ef471a75` (censuses cited `a96e5526`, review cited `3958210e`; the intervening commits are docs + the **already-landed Exponential wrapper restructure** — `src/families/exponential.jl` now has `hessian::Symbol = :observed` with a `:fisher` branch routed through the generic core **without a pin**, and `test/test_exponential.jl:71-84` exists as the review described). I re-verified in code: the three `laplace_grad.jl` coupled sites, the grouped marginal `:fisher` / fitter `:observed` default split, `_tweedie_grouped_loglik_site` having no `hessian` selector, `test/runtests.jl` containing no parity include, and that the plain family-Laplace test files carry essentially **no stored marginal literals** (the re-baselining burden is smaller than the censuses feared; the real breakage set is the identity tests, the grad gates, and the exponential guards).

---

## 1. Go / no-go

**GO — on the reviewer's modified structural contract, not the design as written, and not the family-local alternative.** Reasoning:

- "Do the two family-local patches instead" is a strawman at current HEAD: **eight** core-routed families change (NB2, Beta, Gamma, NB1, Tweedie, Student-t, GP1, probit/cloglog Binomial). Four are one-line delegates to already-gate-tested grouped kernels under *either* approach, so family-local saves almost nothing and forfeits: the single PD guard, the `:fisher` regression lever, the documented two-role contract at the single most-used core, and loud failure (MethodError) instead of silent Fisher for future core-routed families.
- Do-nothing is not on the table: Gamma (instance 8) is a wrong **public default** today (`fit_gllvm.jl` shared route).
- The reviewer's strongest objection is accepted, not argued away: the `hessian` kwarg reaches 1 of 13 `_glm_weight` consumers; 12 sibling kernels build their own `Λ'WΛ+I` and logdet. **This arc is bought as "the core-routed families are fixed," never as "the fault class is closed"** (§8).
- All six blocking modifications M1–M6 are folded into the ordering below. The FD fallback is demoted per the review: it is the gate oracle and safety net; the only production family riding it is probit/cloglog Binomial, which gets a named measurement.

## 2. Ordered steps (smallest first; risky steps only after the net exists)

Estimate (D-139): scratch scripts minutes each; full `Pkg.test()` ~70 min, one Julia process at a time; whole arc ≈ 3 full-suite runs + targeted runs ≈ 4–6 h wall locally. Below campaign threshold; no Totoro needed inside this arc.

### Phase 0 — safety nets, zero `src/` edits

**0.1 Bit-for-bit invariance test** — see §3. Files: new `test/test_curvature_contract.jl` + one `include` line in `test/runtests.jl`. Check: green on unmodified HEAD, standalone (`julia --project=. test/test_curvature_contract.jl`) and in the quick core run.

**0.2 Formula settling (scratch, not committed)** — script in the session scratchpad: nested `ForwardDiff.derivative` of `η → _glm_logpdf(fam, linkinv(link,η), n, y)` on **interior (unclamped) grids** vs the seven analytic forms — the four delegates (NB2 `rμ(r+y)/(r+μ)²`, Gamma `αy/μ`, Beta `W_F − φ(y*−μ*)me(1−2μ)`, NB1) and the three new ones (Tweedie `μ^{1−p}[(p−1)y+(2−p)μ]/φ`, Student-t `(ν+1)(νσ²−r²)/(νσ²+r²)²`, GP1 `μ(1+2αy−αμ)/(1+αμ)³` over the design's α/μ/y grid), rtol 1e-10. Check: all match; GP1 and Student-t negativity regions observed. **Any mismatch = STOP** — the formulas were hand-derived three times but never machine-checked; this is the design's own pending gate.

**0.3 Truth-direction evidence (scratch)** — evaluate a handful of sites both ways against the independent quadrature oracles that already exist in-repo (1-D GH comparisons in `test/test_beta_laplace.jl:37`, `test_gamma_laplace.jl:36`, `test_binomial_laplace.jl:33-40` incl. probit; 2-D GH in `test/test_missing_predictor_dispersion.jl` gate 2 for NB/Gamma/Beta). Record |Laplace − quadrature| under `:fisher` vs `:observed`. Check: observed error ≤ Fisher error at the tested sites. If observed is *not* closer somewhere, that is a maintainer-facing finding to surface before Phase B, not to bury.

### Phase A — the contract, global default `:fisher`, provably zero behavior change (one commit)

**A1 `src/families/laplace.jl`**: add (i) trait `_glm_weight_matches_observed` — `true` for Poisson/LogLink, Binomial/LogitLink, TruncatedPoisson/LogLink, CensoredPoisson/LogLink; **no Normal method** (spde-only, unreachable through this core — dead code; note in comment); (ii) `_default_hessian(family, link) = :fisher` (A-state; flipped in B); (iii) `_glm_obs_weight` nested-FD fallback with the M6 decision **documented in its docstring**: it differentiates the *coded, clamped* composition (TMB semantics, derivative 0 where the clamp binds), while analytic overrides use the caller's hybrid `(μ_clamped, me_unclamped)` convention matching the shipped grouped kernels — the two agree on interior cells and are gate-compared only there; (iv) `hessian::Symbol = :auto` kwarg on `laplace_loglik_site` with `ArgumentError` on bad symbols; `h===:fisher || trait` → the existing tail **verbatim**; else the observed branch: `_glm_obs_weight` broadcast, mask zeroing, `cholesky(Symmetric(Amat); check=false)`, `issuccess || return -Inf`, `logdet(C)`. No per-cell clamp of W, ever. `marginal_loglik_laplace` needs no signature change (verified: it forwards `kwargs...`); both docstrings document `hessian` (AGENTS rule 3).

**A2 the 7 overrides** (typed on the supported link; delegates give digit-identity with the grouped route): `negbin.jl` → `_nb_grouped_laplace_weight(:observed,…)`; `gamma.jl` → `_gamma_grouped_laplace_weight`; `beta.jl` → `_beta_grouped_laplace_weight`; `negbin1.jl` → `_nb1_grouped_laplace_weight`; new analytic in `tweedie.jl`, `studentt.jl`, `gp1.jl` (with GP1's `abs(α)<1e-10 → me²/μ` short-circuit mirroring `gp1.jl:66`); plus the one-line TruncNB2 delegate.

**A3 `src/families/exponential.jl`** (M2, half already landed): the `:fisher` branch's `marginal_loglik_laplace(...)` call gains an explicit `hessian = :fisher`. No-op in A; load-bearing at B (without it, B silently makes both branches observed and `test_exponential.jl:74` fails / `:84` goes vacuous).

**A4 `test/test_exponential.jl`** (M2): pin the live `old = marginal_loglik_laplace(...)` reference with `hessian = :fisher` explicitly **and** add a hard-coded Float64 literal (captured now, while bit-for-bit is provable) so `lf == old == <literal>` can never pass vacuously after B.

**A5 `src/families/grouped_dispersion.jl`** (M3): give `_tweedie_grouped_loglik_site` a `hessian` selector and an observed weight (single source of truth — delegate to the `tweedie.jl` `_glm_obs_weight` method); switch only the **tail** `A` (the mode loop keeps Fisher — search metric); thread through `tweedie_grouped_marginal_loglik_laplace` with default `:fisher` in A.

**A6 gate tests** (committed, e.g. in `test/test_curvature_contract.jl`): every override vs the nested-FD fallback vs central-FD of the coded logpdf∘linkinv at rtol 1e-10 on interior grids spanning dispersions (this repeats 0.2 as a permanent gate); clamp-bound cells asserted separately per the M6 documentation; trait-true families `site(…;hessian=:observed) === site(…;hessian=:fisher) ===` the Phase-0 literals; PD-guard unit: constructed indefinite Student-t and GP1 sites (large |r|/‖Λ‖) → `-Inf`, no throw; probit/cloglog Binomial fallback dual-safety — if `Binomial(Int, μ::Dual)` construction MethodErrors, hand-code the Binomial observed weight then and there (loud, per the contract).

**A-check**: full `Pkg.test()` green with **zero pre-existing-test edits except A4** (which strengthens an assertion, re-points nothing). Green-A proves the contract is pure infrastructure.

### Phase B — the flip (one commit; this is the risky step, taken only behind the A net)

**B1** `_default_hessian` → `:observed` globally. **B2** grouped **marginal** defaults `:fisher`→`:observed` in the same commit (NB2 `grouped_dispersion.jl:129`-area, Beta `:471`, Gamma, NB1, and the new Tweedie selector) so the G=1 route identities hold without touching the `atol=1e-10` tests; update the grouped docstrings that currently instruct "identity checks should force `hessian=:fisher`". Grouped **fitters** already default `:observed`. **B3** the three `laplace_grad.jl` lines + comment rewrites (§5). **B4** test edits, each individually justified: drop the `hessian = :fisher` pin and rewrite the comment at `test/test_grouped_dispersion.jl:56-59`; convert the three quadrature tests (`test_beta_laplace.jl:37`, `test_gamma_laplace.jl:36`, `test_binomial_laplace.jl:38`) to **direction-of-change** — assert error(:observed) < error(:fisher) against the quadrature truth, keeping a loose absolute bound (M4: free, independent adjudication; this is also the only in-suite truth check probit-Binomial has); any recovery/threshold test that trips is investigated per case — allowed outcomes are pass, genuine-bug-found, or maintainer-approved re-derivation with an *independent* oracle; never a widened tolerance (AGENTS rule 5). **B5** docs in-commit-family: `laplace.jl` header two-role contract; math note under `docs/dev-log/decisions/` (rule 4); `docs/dev-log/check-log.md` entry **including the two named corrections** (the DeltaGamma "fixed" claim; the NB1 fix-site misattribution — now actually closed by the delegate). The stale `laplace_grad.jl` mask-fallback docstring claim goes in a separate tiny docs commit (one concern per commit).

### Phase C — recommended, detachable follow-on commits, only after B is green (skip = ledger entry)

**C1 AGHQ** (`src/families/aghq_grid.jl:203`): thread `h`, guard the unreviewed `cholesky(A)` at `:217`; new test: k=1 ≡ Laplace for **NB2** at the default (the existing Poisson k=1 tests are uninformative). If skipped, the after-task report states outright that k=1 ≡ Laplace is now false for non-canonical families. **C2 mi kernels** (`src/missing_predictor_poisson.jl:185/:204`, `src/missing_predictor_multi.jl:168/:199`): take the already-computed `Wobs` tuple element instead of `WF` (~4 lines, gradients self-consistent by construction); rewrite the Fisher-convention header of `test/test_missing_predictor_dispersion.jl:1-13`; check = its own gate 1 (AD-vs-FD) plus gate 2's GH-truth margin, which must not degrade — the one flip with a built-in independent oracle. **C3 `src/families/mixed.jl:249-254`**: same h-branch in `_mixed_loglik_site`; new ledger entry either way.

## 3. The bit-for-bit invariance test (written FIRST)

`test/test_curvature_contract.jl`, committed in **0.1 before any `laplace.jl` edit**. Families that must never change a bit: **Poisson/LogLink, Binomial/LogitLink (n>1 trials), TruncatedPoisson/LogLink, CensoredPoisson/LogLink**, plus the Exponential wrapper's `:fisher` branch. For each: `marginal_loglik_laplace` and `laplace_loglik_site` at fixed StableRNG seeds and fixed (Λ, β), in plain / masked / offset configurations, asserted with **exact `==` against hard-coded Float64 literals** captured from current HEAD via `repr` (Float64 literals round-trip exactly). This is the one legitimate use of the code's own output as oracle, because the claim is "never changes," not "is correct." Phase A extends it with `…(; hessian=:observed) === (; hessian=:fisher) === literal` for the trait-true set, and a probit-Binomial literal pinned under explicit `hessian=:fisher` (stable forever; the *default* probit value is expected to change at B and is reported as a measured delta, not pinned). Runtime target < 5 s.

## 4. Which families gain what

| outcome | families |
|---|---|
| **Nothing — bit-for-bit** | Poisson/log, Binomial/logit, TruncatedPoisson/log, CensoredPoisson/log; Exponential `:fisher` branch (pinned); all own-kernel families (BetaBinomial, CMP, OrderedBeta, Ordinal, TruncNB2 wrapper route, all two-part incl. DeltaGamma — its `twopart.jl:610` fix stays a separate arc); all VA paths; `getLV`/BLUPs/residuals (mode solver untouched, stays Fisher) |
| **Keep analytic search weight; gain observed log-det via delegate; value changes** | NB2, Gamma, Beta (all three also get the §5 gradient swap), NB1 |
| **Gain a new analytic observed method; value changes; PD guard load-bearing** | Student-t, GP1 (Tweedie also gains a method + selector in the grouped kernel; its weight is ≥ 0, no PD exposure) |
| **Value changes via the FD fallback — named 14th instance, measured, reported** | Binomial probit/cloglog |
| **Unchanged and still wrong (ledgered, §8)** | every family through `covariates.jl`, `quadratic.jl`, `mixed.jl` (unless C3), `spde_latent.jl`, `phylo_glm.jl`, `coevolution_glm.jl`, `phylo_{nb,beta,gamma}_xlv.jl`, `aghq_grid.jl` (unless C1), mi kernels (unless C2) |

## 5. Gradient consistency (same commit as the flip — B3)

Verified at HEAD: `Wobs` is already computed for the implicit step (NB `Wobs = μ.*r.*(r.+y)./(r.+μ).^2`; Gamma `Wobs = α.*y./μ`; Beta via `ForwardDiff.derivative` of `_beta_score_scalar` on primals) — only the **log-det** weights are Fisher. Swap, evaluated at the differentiable `z`: NB `Wz = μz ./ (1 .+ μz ./ r)` → `μz .* r .* (r .+ y) ./ (r .+ μz).^2`; Gamma `Wf = fill(α, p)` → `α .* y ./ μz` (keep the masked `ifelse` shape); Beta `WFz = φ.^2 .* νz .* mez.^2` → append `.- φ .* (ystar .- μstar_z) .* mez .* (1 .- 2 .* μz)` with `μstar` recomputed at `μz` — **analytic form, never the nested-FD hook** (the log-det sits under the outer `ForwardDiff.gradient` Dual; nesting a second tag there is untested in this repo and unnecessary). Rewrite the "Fisher weight — matches the marginal's logdet" comments to the new invariant. Poisson and Binomial sites untouched (canonical, verified). No `dW/dη` is hand-coded anywhere — the outer AD supplies it, so this is a three-line substitution, **mechanically gated** by `test/test_laplace_grad.jl` (`:86/:109/:132`, FD-vs-analytic at rtol=atol=1e-4) and `test/test_masked_dispersion_grad.jl`, plus the finite-vs-analytic fit-loglik checks. **Watch Gamma hardest**: its log-det becomes z-dependent for the first time, making the existing implicit `Aobs` correction load-bearing for Gamma for the first time — a Gamma FD-gate failure points at the newly-exercised implicit path, not necessarily the weight. Known residual risk to document: an inconsistent gradient *stalls* rather than diverges (line search is on the correct `negll`), and the `-Inf` → `1e12` sentinel makes a fully non-PD neighbourhood FD-flat; the PD-guard smoke test (a fit that encounters `-Inf` and recovers) is the canary.

## 6. Verification ladder

1. **Per-file** after each step (test files are standalone — `julia --project=. test/<file>.jl`): 0.1 the contract file; A: contract + gate files, `test_exponential.jl`, each touched family file; B: `test_laplace_grad.jl`, `test_masked_dispersion_grad.jl`, the three grouped-identity files, `test_tweedie_grouped_engine_health.jl`, `test_exponential.jl`, family files, `test_offset.jl`, the three direction-of-change files.
2. **Quick core**: `julia --project=. test/runtests.jl`.
3. **Full `Pkg.test()`** (~70 min, one Julia process at a time): once after A (must be green with only the A4 edit), once after B, once after any C. Aqua/JET ride along.
4. **Parity** (the only fix-vs-regression adjudicator): `GLLVM_PARITY_TESTS=1` locally — verified **not** included by `runtests.jl`, so CI green says nothing here. Re-derive the R oracle cells (NB2, Beta, a new Gamma cell — the public-default instance — and one probit-Binomial measurement) against live `gllvmTMB`. Numerical parity claims require paired live evidence; if RCall/R is not available in this lane, hand the parity slice to the Codex lane (division of labour) — until it runs, the arc's claim ceiling is "internally consistent + closer to quadrature truth," not "matches R."
5. **What green proves**: canonical invariance; objective–gradient coupling; route identity shared/grouped/G=1; direction-of-improvement vs quadrature truth; PD-guard behavior. **What it does not prove**: R parity (gated off); CI *coverage* calibration (no such tests exist — the named missing detector; file the Totoro-sized broad-grid coverage campaign as its own follow-up); correctness of the 12 sibling kernels (known Fisher); TMB equivalence in clamp-bound regions (family-specific; only parity adjudicates).

## 7. Rollback

- **A is behavior-neutral by construction and by proof** (step-0 literals + zero-edit green): if B goes red late, `git revert <B-sha>` alone restores the pre-flip objective everywhere (core default, grouped marginal defaults, grad lines are all in B); post-revert check = `test_curvature_contract.jl` + the grouped-identity files green. A stays as pure, keepable infrastructure.
- C commits are individually revertible; none is depended on by B.
- Emergency valve: per-(family,link) `_default_hessian` pins — **diagnostic use only during a red-suite investigation, never merged** (a partial flip recreates the split-objective inconsistency this contract exists to end).
- Everything stays on the lane branch; nothing merges to `main` until the ladder completes and the after-task report + check-log land (Definition of Done); no push without explicit maintainer instruction.
- Own-the-verifier: whoever writes the weight code does not author new *correctness* numbers alone — every re-pointed assertion carries its independent oracle (quadrature, formula, or R) and provenance in a test comment.

## 8. What must NOT be claimed when it lands

- **Not "the Fisher-in-the-log-det fault class is closed."** The kwarg reaches 1 of 13 `_glm_weight` consumers; the after-task report must list the uncovered kernels by name — `covariates.jl` (behind fourth-corner / species-covariates / constrained-ordination / row-effects) and `mixed.jl` as *live user surfaces* — plus `quadratic.jl`, `spde_latent.jl`, `phylo_glm.jl`, `coevolution_glm.jl`, the three `phylo_*_xlv.jl`, grouped-Tweedie-siblings, `aghq_grid.jl` and the mi kernels if C is skipped, each as a ledger entry. Internal divergence *widens* for those paths until they are threaded.
- **Not "R parity" / "matches TMB"** until the parity cells actually run against live R — and never for clamp-bound regions without a measured residual.
- **Not "validated" or "coverage-correct."** Converged ≠ validated (recovery-over-pdHess); the end-to-end detector for this fault class — broad-grid CI coverage — still does not exist and is filed as its own campaign.
- **Not "AGHQ-consistent"** unless C1 lands; otherwise state plainly that k=1 ≡ Laplace is now false for non-canonical families and its tests cannot see it.
- **Not a DeltaGamma fix** (separate arc, `twopart.jl:610`), **not a performance claim**, and **not a new Exponential capability** (already shipped; this arc only pins its Fisher branch against silent vacuity).
- Probit/cloglog Binomial is reported as a **newly named 14th instance whose numbers changed**, with the measured delta and the direction-of-change evidence — not silently absorbed.