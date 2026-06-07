# Codex runtime handoff — GLLVM.jl

This brief hands the **runtime-gated** work to Codex (or any local agent with a
Julia + R toolchain). A long cloud-agent session brought GLLVM.jl to full
gllvmTMB parity and beyond (families, per-species dispersion, links, fixed +
random row effects, unified `fit_gllvm` API, Conway–Maxwell–Poisson, the
JuliaConnectoR R-bridge scaffold) and a first wave of **bit-exact** speedups —
but that session had **no Julia/R runtime**, so everything below was deliberately
left for a machine that can measure and numerically validate.

Branch off the latest `main`. Read `bench/SPEED_NOTES.md` and
`docs/src/gllvmtmb-parity.md` (the "R bridge: parameterization map") first.
Every change must stay **accuracy-anchored** (exact-equality or grad-vs-FD test) —
that is the project's bar.

## Priority 1 — Measure & decide the gradient default (biggest speed win)

- Run `julia --project=. bench/speed_bench.jl`. It times each GLM fitter with
  `gradient=:finite` vs `gradient=:analytic` and prints the **logLik delta** so
  you can confirm accuracy is preserved.
- If `:analytic` is faster across the grid AND the logLik deltas are ≈0 (≤1e-6),
  **flip the default** to `gradient=:analytic` in `fit_poisson_gllvm`,
  `fit_nb_gllvm`, `fit_binomial_gllvm`, `fit_gamma_gllvm`, `fit_beta_gllvm`. The
  analytic path already exists in `src/laplace_grad.jl`, gated to no-mask/no-offset
  with a finite-difference fallback. Then run `Pkg.test()`; if green, commit. This
  is ≈ `2·nparams → 1` marginal-evaluations per L-BFGS step — the single largest
  speedup, kept opt-in here only because it changes the optimizer trajectory and
  the cloud session could not measure it.

## Priority 2 — Validate the R↔Julia bridge

- Run `r/parity_check.R` (needs R `{gllvm}` + a Julia install with GLLVM.jl).
- Fix the `## VERIFY:` spots in `r/gllvmtmb_julia.R` — JuliaConnectoR field access
  on Unicode struct fields (`β`, `φ`, `α`, `φ²`), the zero-arg family constructors,
  Symbol marshaling — then confirm logLik / β / loadings (Procrustes-aligned) /
  dispersion agree after the conversions (NB `r = 1/φ`, Gamma `α→φ`, etc.).

## Priority 3 — Exact algorithmic speedups (from `bench/SPEED_NOTES.md`)

- **Takahashi / selected-inverse O(p) log-det gradient** for the sparse-phylo path:
  `src/node_gradient.jl` (`node_grad`) is already O(p) and documented to match
  `sparse_phy_grad` (the O(p²) path currently wired) to ≤1e-13 for `K_aug==1`.
  Wire `node_grad` in where verified; validate the equality + the speedup.
- **Reverse-mode / implicit-function-theorem Laplace adjoint** for the general
  non-Gaussian marginal (TMB/RTMB design — Kristensen et al. 2016;
  `ImplicitDifferentiation.jl` or Enzyme), replacing the finite-difference outer
  gradient. Validate `grad ≈ finite-diff` to 1e-6, then `Pkg.test()`. Biggest exact
  non-Gaussian win.
- **Gaussian closed-form path** allocation reduction (`src/likelihood.jl`) is
  AD-entangled (ForwardDiff `Dual`s flow through the marginal), so the buffer-reuse
  trick used for the Laplace path needs a runtime to confirm AD-compatibility +
  bit-exactness — left for you.

## Already landed (do NOT redo)

- Bit-exact buffer reuse in the **Laplace mode-finder** (`src/families/laplace.jl`)
  and the **two-part mode-finder** (`src/families/twopart.jl`), and the Poisson/NB
  objective + FD-grad-fallback allocation hoists. These are strictly behavior-
  preserving (no FP-order change) and CI-validated against the suite's
  machine-precision anchors.

## Coordination

- The session's open `codex/*` PRs (#60, #67) on the phylo-Poisson gradient are
  left for you to reconcile — check what is genuinely new vs already on `main`
  (the `node_gradient.jl` / `sparse_phy_grad.jl` / `takahashi_selinv.jl` engine
  files are already merged).
- Keep commits one-concern, accuracy-anchored, and run the full `Pkg.test()` before
  proposing a PR.
