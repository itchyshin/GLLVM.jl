# SYNTHESIS — one parameterisation gap explains three unpaid parity cells (2026-08-28)

**This note reframes three separate open questions as one.** It changes no
code. It is written because the delta-cell measurement, the student-cell gap,
and the tweedie cell were being tracked as unrelated items, and they are not.

## The pattern

The twin parameterises dispersion **per trait** for essentially every family.
From `gllvmTMB.cpp:1163-1195`, each of these is `length n_traits`:

`log_phi_nbinom2` · `log_phi_nbinom1` · `log_phi_gamma` · `log_phi_tweedie` ·
`log_phi_beta` · `log_phi_betabinom` · **`log_sigma_student`** ·
**`log_df_student`** · `log_phi_truncnb2` · **`log_sigma_lognormal_delta`** ·
`log_phi_gamma_delta`.

GLLVM.jl already has the matching machinery — the **grouped-dispersion**
fitters — and `fit_gllvm` already auto-coerces `disp_group = :species` for
four families (`fit_gllvm.jl:143-146`: NegativeBinomial, Beta, NB1,
BetaBinom), explicitly *"matching gllvmTMB"* (`fit_gllvm.jl:84`). Gamma has
the grouped route as opt-in.

So per-trait dispersion is neither a novel design question nor a twin quirk:
**it is the twin's default everywhere, and it is an established, shipped
pattern on our side for five families.**

## What that explains

| Parity cell | Status | Now explained as |
|---|---|---|
| **12 delta_lognormal** | measured, Δ = −1.92 | twin fits per-trait `log_sigma_lognormal_delta`; we fit one shared σ → the twin has p−1 extra free parameters, so its logLik is generically higher. MEASURED today, cause proven. |
| **13 delta_gamma** | measured, Δ = −2.57 | same, `log_phi_gamma_delta`. |
| **9 student** | unpaid | the twin fits `log_sigma_student` **and** `log_df_student` per trait; we fix ν and share σ. The roadmap called this "an estimator gap"; it is *also* the same dispersion-parameterisation gap. |

Three of the four unpaid cells, one root cause. (The fourth, **6 tweedie**, is
different — its grouped route carries recorded defects, and `log_phi_tweedie`
being per-trait is a *further* reason its Δ would not close today.)

## Why this makes the pending decision cheaper

The delta note (`2026-08-28-delta-shared-predictor-identity.md` and the parity
commit `6c471352`) framed the choice as *"add a per-trait dispersion variant
to the Julia delta fitters, or reclassify the cells"*. In light of the above,
option (1) is **not** bespoke work: it is extending an existing, tested,
five-family pattern (`disp_group` / the grouped fitters) to the delta families
and to Student-t. The precedent, the machinery, the tests, and even the
auto-coerce policy for "match the twin by default" already exist.

That also means the decision is better taken **once, for the class**, than
three times for three cells. The question to answer is:

> Should GLLVM.jl adopt the twin's per-trait dispersion as the DEFAULT for the
> remaining families (delta_lognormal, delta_gamma, Student-t σ, Student-t ν),
> the way it already does for NB2 / Beta / NB1 / BetaBinom?

If yes, the same slice plausibly moves cells 12, 13 and 9 together, and the
existing auto-coerce line is the template for the policy.

## Caveats, so this is not oversold

- **Not measured for student**: cells 12/13 are measured (Δ known, cause
  proven); the student attribution is a *code-and-source reading*, not a fit
  comparison. It should be confirmed by the same kind of live Δ before anyone
  claims cell 9 would close.
- **ν estimation is genuinely extra work** beyond per-trait dispersion —
  estimating a degrees-of-freedom parameter is not the same as splitting a
  scale into p scales, and it carries its own identifiability questions.
- **The twin's df CI is buggy** (off by one; see
  `2026-08-28-studentt-parameterisation.md`), so any student interval
  comparison must account for that before treating a mismatch as ours.
- Per-trait dispersion costs p−1 extra parameters per family: it will change
  AIC/BIC and can be weakly identified at small n. The twin's choice is not
  automatically the better estimator, only the parity-comparable one — the
  same "parity, not accuracy" fence that governed the curvature flips.
