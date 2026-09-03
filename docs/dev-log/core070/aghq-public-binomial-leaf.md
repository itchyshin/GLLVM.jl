# Public binomial AGHQ implementation leaf

Goal: expose the frozen Stage1a binomial estimator through BinomialFit without
changing the original k5 acceptance requirement. Parent owns listed files;
no new production child. Execute inline with Superpowers TDD and Unlazy.

1. Add test/test_aghq_public_binomial.jl: missing integration-field red, then
   default/k1 equality, old constructors, invalid controls, X_lv fallback,
   three-link real fits with nonunit N, masks/offsets, immutable inputs,
   retained controls/starts/selected convergence, matching frozen CI objective,
   identity rejection on changed observed N, public generic/formula forwarding,
   retained-mode prediction, count simulation/trial bounds, residual masking.
   tools/core070_aghq_public_binomial_run.jl runs this and adjacent Poisson tests.
2. src/families/aghq_fit_info.jl: add AGHQBinomialData responses/trials/mask/offset;
   include metadata before BinomialFit. Preserve old10arg constructor. Rename
   existing fitter _fit_binomial_gllvm_laplace without numeric edits; new wrapper
   src/families/aghq_binomial_fit.jl accepts aghq/aghq_control. Default off retains
   old behavior; k1 returns Laplace with provenance. Eligibility: K1..5 ordinary
   loadings-only, all3 reference links, automatic cutoff20 traits. Warm start
   existing Laplace, second start .3 loadings and R empirical logit intercept;
   observed exact modes, existing unmodified frozen-surrogate outer algorithm.
   Store selected usable nonconverged result truthfully; fallback only if unusable.
3. Keep normalized observed inputs distinct from finite supplied masked-cell
   prediction inputs. Identity digest includes observed trials; new-data reuse
   cannot silently assume the original nonunit trials or offsets. Simulation
   matches probability branches (cloglog via -expm1(-exp(eta)), no eta30 cap),
   returns count matrix; predict response remains success probability by existing
   Julia convention. Residuals use N*p and N*p*(1-p); zero variance => NaN.
4. src/postfit.jl,simulate_fit.jl,confint_family.jl: reuse caches for original
   data, public N/offset controls, CI same frozen objective with observed AD
   Hessian, profile and same-controls bootstrap; retain failed attempts. No
   R-engine surgery or silent substitution of total derivative. No fit-success
   assertion for the known original seed43 k5 failure.
5. Update src/GLLVM.jl,test/runtests.jl, README.md, CHANGELOG.md,
   docs/src/quickstart.md,api.md,low-level-reference.md in same local slice.
   Add exact run/evidence receipts, check-log and after-task report. Review before
   commit; full candidate remains PARTIAL until original required pair passes.

CHECK (Totoro): Julia1.12.6 --startup-file=no --project=test/parity
 tools/core070_aghq_public_binomial_run.jl, pinned R library/manifest,1thread.
Estimate2–5min, main cap300s; oracle before/after, immutable source and logs.
Red expected hasfield(BinomialFit,:integration) failure. Green must pass all
public/adjacent assertions; paired gate separately retains original k5FAIL.
Strict Documenter estimate3–8min cap590s, no deployment. No >30min campaign.

Source refinement: frozen R/fit-multi.R:6461–6469 uses per-trait mean of raw successes (not success/trial ratio) for its alternate intercept start, clamped then qlogis, even for other links. Preserve that actual callable behavior. Public metadata also retains copied start vectors. Noether mean-component input-validation finding receives a failing regression and repair. Earlier pair runner duplicate kernel include removed; old227 counted executions, new149 distinct prerequisite assertions.
