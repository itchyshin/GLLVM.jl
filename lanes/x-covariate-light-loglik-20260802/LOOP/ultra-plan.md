# X/covariate light logLik — Ultra Plan (binding copy)

Frozen at G0 approval / `/goal` execution 2026-08-02.

Solo platform: Cursor. Worktree:
`.worktrees/gllvmjl-x-covariate-light-loglik-20260802` on
`parity/x-covariate-light-loglik-20260802` from `origin/main` (≥ `4d19c503`).

Deliverable: First cohort of X/covariate light logLik parity cells —
Gaussian, Binomial (Bernoulli), Poisson — each with q=1 shared site covariate,
green under `GLLVM_PARITY_TESTS=1` with retained ΔlogLik evidence (rtol 1e-6).

R formula (shared slope): `value ~ 0 + trait + x + latent(0 + trait | site, d=K, unique=FALSE)`.

Fence: NB2/Beta+X; Gamma; Ordinal+X; X+mask; species-specific XB; X_lv; ADEMP;
#129/#128; Totoro/DRAC; full family / fit parity; grouped_dispersion:61;
Dropbox stale fork.

Canonical durable path also:
`docs/dev-log/plans/2026-08-02-gllvm-x-covariate-light-loglik-ultra-plan.md`.
