# Gaussian empty-design regression
OWNS: Ada src/profile.jl, src/confint.jl, src/confint_profile.jl, test/test_gaussian_empty_design.jl,
central test include, scoped runner/verifier and programme documentation.
Base d180a873; no R/foreign edits. Other a1-nongaussian-ci profile diff is REML
work and does not fix this case; retain that lineage separately.

Hypothesis: q=0 leaves beta=nothing and an explicit empty X makes the objective
request zero(Any). Reproduce ordinary/phylogenetic values, AD gradients/Hessians,
recovery and public zero-column/all-fixed-zero fit with prediction/Wald.
Expected equivalent model to X=nothing, including identifiable covariance.
Do not modify estimator, normalization, tolerances or fixed-effect restrictions.
New source must pass original public Gaussian and frozen R comparison afterward.
Totoro Julia1.12.6/pinned R/environment, one thread. Estimate1–3min targeted,
2–5min integrated, caps300s per run. Retain every red/green receipt. No campaign.
Failure action: diagnose actual stack/inputs, never relax the equality gates.

Second confirmed failure:22PASS2FAIL after fit repair; Wald SEs NaN because
packed-likelihood contract rejects X when q=0. Normalize the empty design to
nothing in the fitted-object likelihood adapter; do not widen low-level admission.

Profile-specific regression24PASS2FAIL produced spuriously narrow bounds;
normalize _profile_free_X too. Separately pure-logic1PASS2FAIL demonstrates
failed refits mistaken for crossings. Require finite outer deviance before
returning final bracket midpoint. Existing wall test incorrectly expected a
finite bound although the wall lies before the chi-square cutoff; correct
that scientific expectation and retain positive feasible-wall crossing control.
