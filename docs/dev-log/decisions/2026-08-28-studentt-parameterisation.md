# Student-t parameterisation notes (Arc 3 opening gate, 2026-08-28)

## The twin bug: df profile CIs report df − 1 (CONFIRMED)

Verified against gllvmTMB (read-only reference, local checkout at 0.7.0):

- `src/gllvmTMB.cpp:1180-1185` (and again at `:2798`, `:3570`):
  `df = 1 + exp(log_df_student)` — the parameterisation is `log(df − 1)`,
  keeping df > 1.
- `R/profile-targets.R:206-210`: the profile-CI registry maps
  `log_df_student` with `transformation = "exp"` — so profile bounds are
  back-transformed as `exp(θ)` = **df − 1**, then labeled `df_student`.
- No downstream `1 +` correction exists anywhere in `R/` (grep clean).

**Consequence for the twin**: every reported `df_student` profile confidence
bound is the bound for df − 1 presented as df (exactly 1 too low at both
ends). Point estimates are unaffected. Severity: user-facing CI mislabeling
for a shipped family. To be reported upstream (maintainer's go required for
the outward post; draft below).

**Consequence for GLLVM.jl's Arc 3 (Student-ν estimator)**:
1. Our parameterisation mirrors the twin's likelihood: `ν = 1 + exp(θ_ν)`.
2. Any ν-CI parity comparison against the twin's CURRENT output must correct
   the twin's bounds by +1 (or wait for the upstream fix) — never tune our
   CI machinery toward the twin's mislabeled bounds.
3. logLik parity is untouched (the bug is CI-layer only).

## Parity Cell 9 implementation and closure (2026-08-29)

Joint per-trait ν-estimation (`ν_j = 1 + exp(θ_{ν,j})`, strictly enforcing ν > 1) is now implemented in `src/families/studentt.jl`:
- Initial values: `σ_0 = 1.0`, `ν_0 = 3.0` (`log(ν_0 - 1) = log(2.0)`).
- Full compatibility with `disp_group = :shared` and `disp_group = :species`.
- Live parity check against `gllvmTMB` (`test/parity/test_studentt_parity.jl`):
  - Fixed-ν per-trait σ: `Δ logLik (jl − r) = 9.66e-10`
  - Jointly estimated per-trait ν + σ: `Δ logLik (jl − r) = 1.98e-8`
  - All 22 parity tests passing under `GLLVM_PARITY_TESTS=1`.


> **Student-t df profile CIs are off by exactly 1.** The TMB template
> parameterises `df = 1 + exp(log_df_student)` (gllvmTMB.cpp:1185, :2798,
> :3570), but the profile-target registry (R/profile-targets.R:206-210)
> back-transforms `log_df_student` bounds with `transformation = "exp"`,
> yielding df − 1 labeled as df. Point estimates use the correct 1 + exp
> path; only profile CI output is affected. Suggested fix: a dedicated
> `"one_plus_exp"` transformation for this target (the same convention
> question will recur for any future `log(x − c)` parameterisation).
> Found while building GLLVM.jl's Student-ν parity cell.
