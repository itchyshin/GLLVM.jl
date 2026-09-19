# Arcs: speed78-20260919 (GLLVM.jl / GLLVModels.jl)

| id | arc | ledger | status |
|---|---|---|---|
| S4 | three profiles, no src/: `bench/profile_laplace_allocs.jl` (Profile.Allocs split of value vs gradient per-site Newton solves, `_poisson_site_diffable` Dual allocs, chunk machinery, at p=20/50), `bench/profile_grouped_glmm.jl` (the Latte 200x5 fixture, warm wall split into outer FD evals x inner Newton x fresh symbolic analyses), `bench/profile_em_phylo_scaling.jl` (wall per EM iteration at p=200/1000/5000, exponent, verdict on the step-8 dispute) | leaf-S4 | todo |
| S6 | per-site route, tests first: share one mode solve per theta between value and gradient inside `fg!` (`src/families/poisson.jl:302-325`); one `GradientConfig` per fit with chunk measured over 12/24/32; allocation-free `_poisson_site_diffable` (`src/laplace_grad.jl:62-96`); wire `test/test_poisson_grad_perf.jl` into runtests.jl; extend the R2 hoist to NB/Gamma/Beta only if the profile ranks it | leaf-S6 (write before dispatch) | todo, after S4 |
| S7b | grouped route (`src/families/grouped_laplace.jl:219-246`): `cholesky!` symbolic reuse across the inner Newton, analytic instead of finite-difference outer gradient; only if S4 puts the Latte 12x on this route | leaf-S7b | conditional on S4 |
| S7 | sparse-phylo/EM hoists, only what the p^3-vs-p^1 verdict names: per-fit workspace for Q_cond and one symbolic then `cholesky!` per evaluation; `takahashi_diag` once per gradient; Woodbury capacitance for any dense p x p inside the E-step; monotonicity check through the sparse loglik | leaf-S7 | conditional on S4 |
| verify | Haiku mechanical re-verify; Opus judgment (refute one passed gate); draft PR by the orchestrator; Rose sign-off per repo AGENTS.md | orchestrator | after S6/S7 |
