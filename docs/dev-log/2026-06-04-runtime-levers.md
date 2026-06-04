# Runtime-needed levers (design notes for a Julia-enabled session)

Two high-value items deliberately **not** implemented blind (no local Julia runtime
in the authoring sessions). Both touch hot numerical paths where a silent error would
corrupt every fit, so they should be built where an `FD-vs-analytic` check and an
allocation/timing profile can actually run.

## 1. Analytic gradient for the Laplace marginal (biggest non-Gaussian speed lever)

Every non-Gaussian fit (`fit_*_gllvm`) and every profile-CI constrained refit uses a
**finite-difference** gradient through the Laplace marginal, because the inner
mode-finder isn't forward-AD-friendly. FD costs ≈ `2·nθ` marginal evaluations per
L-BFGS step. The TMB-style analytic adjoint removes that factor.

Per site `s`, with mode `ẑ` solving `Λᵀs(ẑ) − ẑ = 0`, the contribution is
`ℓ_s(ẑ) − ½ẑᵀẑ − ½ logdet A(ẑ)`, `A = ΛᵀW(ẑ)Λ + I`. The total `θ`-gradient is:

- The `ℓ_s − ½ẑᵀẑ` part: by the envelope theorem the explicit-`ẑ` dependence drops at
  the mode, leaving the **partial** `∂/∂θ` (direct β/Λ dependence only).
- The `−½ logdet A` part: depends on `θ` **and** on `ẑ(θ)`, so it needs the implicit
  `dẑ/dθ = −H⁻¹ ∂g/∂θ` (with `H = ∂g/∂z = −A`), contracted into
  `−½ tr(A⁻¹ ∂A/∂θ)`. This is the term that must be derived and signed carefully.

**Verification (the reason to do it with a runtime):** an exact `analytic ≈ FD`
gradient check at several random `θ` for Poisson first (then NB/Binomial/Beta/Gamma),
to machine-ish precision, gates correctness. Without running that check, a sign or
missing-term error is undetectable and would bias every fit — hence not done blind.

Sequencing: Poisson → the other one-parameter-mean GLMs (share the `_glm_score`/
`_glm_weight` derivatives) → dispersion families (extra `∂/∂(log r/φ/α)` column).
Expected payoff: the dominant per-fit cost (the `2·nθ` FD factor) removed.

## 2. Fast phylogenetic-Poisson (issue #61)

Tracked in `docs/dev-log/2026-06-03-phylo-poisson-handoff-plan.md`. Blocked on the
originator pushing branch `5ff0dbc` and on a runtime for the profiling / ADEMP-recovery
work. The design (Takahashi selected-inverse swap for `tr(H⁻¹ ∂H/∂θ)` + boundary-aware
`σ²` via a nested 1-D profile) is captured there; it lands on the same selected-inverse
substrate the Gaussian phylo path already uses.

## Why these are separated out

Everything else this cycle (offsets, family inference tables, VA SEs, profile-CI
root-finding, NA handling, SPDE spatial fields) carries a **deterministic anchor** that
CI verifies without a runtime — exact reductions, absorption identities, FD-Hessian
sanity, bracket checks. The two items above do not reduce to such an anchor that is safe
to assert blind; they need the live `FD-vs-analytic` / profiling loop. Pick them up in a
runtime-enabled session.
