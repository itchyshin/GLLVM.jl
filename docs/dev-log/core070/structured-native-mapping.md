# Structured Core070: native implementation contract

This is the next implementation contract, grounded in Julia f0d83c68 and frozen
R b4d5fee64def88bc768dda1f1f77c29b295edd86. It does not freeze the full Core
manifest or claim newly executed Julia models. No source engine is changed.

## Reuse decisions

The internal `GLLVM._gaussian_source_loglik(Y,beta,L,Cs,groups,sigma_eps)`
implements independent Gaussian residuals plus one or two rank-one additive
sources. It can express the fixed-parameter covariance of STRUCT-PHY-TREE-RR,
PHY-DENSE-RR, ANI-PED-SPARSE and KER-MULTI after explicit source conversion.
It has no optimizer, named source adapter, public formula or bridge entry point.
Do not confuse this reusable kernel with completed native model support.
Source: src/source_covariance.jl:1; retained native-source-evidence.json.

Concrete evaluator calls (with `using GLLVM, LinearAlgebra`; Y is3x12,
beta is3, lambda/lambda1/lambda2 are3-vectors; all groups are one-based):

```julia
# Tree: Qtree is the4x4 augmented precision in structured-input-contract.md.
GLLVM._gaussian_source_loglik(Y, beta, reshape(lambda,3,1),
    [Symmetric(inv(Symmetric(Qtree)))],
    reshape(repeat([2,3,4],inner=4),12,1), sigma_eps)
# Dense phylogenetic source; C is the frozen3x3 dense fixture.
GLLVM._gaussian_source_loglik(Y, beta, reshape(lambda,3,1),
    [Symmetric(C+1e-8I)],
    reshape(repeat([1,2,3],inner=4),12,1), sigma_eps)
# Pedigree: retain both unobserved founders in Qped.
GLLVM._gaussian_source_loglik(Y, beta, reshape(lambda,3,1),
    [Symmetric(inv(Symmetric(Qped)))],
    reshape(repeat([3,4],inner=6),12,1), sigma_eps)
# Two named kernels, independent residual noise.
GLLVM._gaussian_source_loglik(Y, beta, hcat(lambda1,lambda2),
    [Symmetric(C+1e-8I), Symmetric(K2+1e-8I)],
    repeat(reshape(repeat([1,2,3],inner=4),12,1),1,2), sigma_eps)
```

The Symmetric wrappers make the inverse result's symmetry explicit, as the
internal evaluator admits exactly symmetric covariance inputs. They do not
license accepting an asymmetric user matrix; input validation precedes them.

These explicit fixed-parameter calls remain candidates for the newly captured
fixtures; the earlier native tests use different fixtures and cannot pay them.
Public fits and all interface obligations remain UNPAID. No existing fitter
matches the full set simply by changing a keyword.

`fit_gaussian_gllvm(...;Σ_phy=...)` puts Σ_phy on the trait axis and adds a
field shared across sites: J_n ⊗ ((Lambda Lambda') .* Σ_phy), in addition to
its ordinary site contribution. The R source model instead adds
(Z C Z') ⊗ V_trait. Matrix shape coincidence (p=3,three source groups) hides
the error; dimensionally asymmetric fixtures are required in B1 tests.
Source: src/likelihood.jl:26 and src/fit.jl.

`fit_coevolution_gaussian(Y,Kstar;d=...)` uses Kstar ⊗
(Lambda Lambda'+sigma_eps²I). R uses (Kstar ⊗ (Lambda Lambda'))+sigma_eps²I.
Preserve the existing coevolution API for its own model. The earlier retained
source counterexample already establishes this distinction; do not rerun it.
Source: src/coevolution_kronecker.jl; source-covariance-contract.md.

`relatedness_cov` validates/builds a dense trait covariance but does not parse
pedigrees or retain observed-to-ancestor mappings. `spatial_cov` is a dense
coordinate kernel, not the R FEM/SPDE model. Neither adapter is a complete
source-model interface. Source: src/structured_cov.jl.

## Spatial reuse requires an identification correction

Existing `fit_spde_latent_gllvm` optimizes both raw loadings Lambda and a common
log_tau, with Q=tau²Qbase. For any c>0, replacing (Lambda,tau) by
(cLambda,cTau) leaves the observation model unchanged: U has covariance
Qbase^-1/tau² and Lambda U has the same distribution. The extra shared scale
is therefore redundant when Lambda is free. The frozen R shared latent field
fixes tau=1 and assigns scale to Lambda. This is a source-level identification
finding, not a new numerical failure receipt. The native optimizer itself has
not been run in this slice. Source: src/spde_latent.jl:276–291;
src/spde.jl:133; frozen src/gllvmTMB.cpp:2182.

`tau_init=1` does NOT fix this: that slot remains optimized. A matched fitter
must omit/map off shared tau. It must separately retain per-trait tau for
unique companions, distinguish equal independent fields from a single common
field, and report requested versus actual model. Do not silently change the
existing fitter's estimator/API as part of this mapping-only slice.

`fit_spde_gaussian` is univariate and recomputes its own mesh FEM. It cannot
stand in for multivariate latent/dependent/Psi cases. Reuse its determinant
lemma and sparse solve implementation after verifying exact same FEM matrices.
Existing native FEM uses lumped C and G C^-1 G; retain the R fixture's M0/M1/M2
as explicit source inputs until equivalence is demonstrated. Rebuilding an
approximately similar mesh would alter the model.

## Shared representation for B1 and B2

For long observation o, source r, source node g and coefficient a:

    eta[o] = X[o,:] beta + sum_r sum_a D_r[o,a] U_r[g_r(o),a]
    vec(U_r) ~ Normal(0, V_r ⊗ C_r)
    Cov(eta[o],eta[v]) = sum_r C_r[g_r(o),g_r(v)]
                                  D_r[o,:] V_r D_r[v,:]'

With a general projection P_r, substitute (P_r C_r P_r')[o,v] for node
lookup. This covers tree/pedigree incidence and SPDE interpolation without
moving covariance onto the trait axis. Missing-response selection acts on
observation rows; it must never drop unobserved ancestors from the prior.
Non-Gaussian likelihood is conditionally independent given eta at admitted
cells; Gaussian residual/known-V contributions are separate additive terms.
Ordinary augmented slopes need D with trait/intercept/slope columns. Structured
latent slopes can have block-separated coefficient covariance; do not invent
cross-basis terms not present in the reference. Different sources keep their
own projections, names, group levels and free/fixed parameter maps.

Implement one typed source specification carrying: source identity and kind;
ordered node/group labels; sparse precision or dense covariance; logdet
convention; projection; trait/coefficient design; covariance mode and rank;
loading/diagonal parameter maps; scale constraints; diagnostic provenance.
A source precision adapter must distinguish raw from already regularized
input and must not apply dense jitter twice. Sparse tree/pedigree Q is not
silently regularized. Numerical factorization is an engine concern, not parser
behavior. Reuse native trees, FEM and sparse factorizations where contracts
match; do not replace unrelated APIs.

Recommended public direction for B1/B2: an explicit `sources` collection on a
model-fitting entry point, using Julia objects for known matrix/tree/pedigree/
mesh inputs and a separate trait-mode object (`latent`, `indep`, `dep`).
These names are DESIGN ONLY until the shared representation review fixes exact
constructors and call signatures. No invented callable symbols are entered in
the executable parity manifest. Exact dispatch names remain the first B1/B2
implementation decision, not an excuse to mark public routes covered.

## Runnable acceptance requirements before implementation

B1 leaf must give exact new paths, constructors and fitter signatures, followed
by tests of: covariance assembly versus independent long-row formulas;
multiple unequal source-group counts; fixed masks; full-rank/raw versus
log-diagonal maps; sparse ancestral retention; PSD input/invalid trial handling;
residual independence; same-FEM spatial scale and shared-tau identification;
normalization/outer derivatives; optimizer health and all retained failures.
Follow with recovery-to-truth at representative identifiable designs.

B2 consumes that representation. `src/formula.jl` currently builds site-level
fixed effects and forwards existing fitter keywords (including the trait-axis
Σ_phy route); it does not parse or represent a structured sources collection. B5's `bridge_fit` currently has no source collection in its
public signature. Both must preserve names/maps/constraints and reject unknown
or unsupported combinations without silently dropping them. A parser-only test
cannot pay a fitted interface obligation.

The 24-row machine-readable mapping keeps existing-call candidates, missing
features, concrete model requirements and original required roles together.
Eleven requested models need fitted native/formula/bridge coverage; twelve
negative calls need explicit dispositions, two with specific pedigree
error assertions; multi-kernel Psi loss needs reviewed rejection or extension.
