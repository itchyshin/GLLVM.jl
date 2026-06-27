# 2026-06-27 — X_lv point-recovery evidence (all eight routes)

**Executed by**: Claude (Codex on leave), juliaup Julia 1.10, against the family
stack tip (`claude/beta-xlv-20260626`, HEAD `7d7b29d`), which carries Gaussian +
binomial (merged on `main`) plus the held Poisson (#118), NB2, Gamma and Beta
`X_lv` slices.
**Script**: [`bench/lv_recovery.jl`](../../../bench/lv_recovery.jl).

## Why this checkpoint exists

The predictor-informed latent-score (`X_lv`) path had **mechanical** tests only:
`test/test_lv_predictor.jl` asserts the score components decompose
(`Z_total = Z_mean + Z_innov`), shapes, and the identity `B_lv = Λ·α'` — but
that identity is a *tautology* (`B_lv` is defined as `Λ·α'`), so it never checks
the fitted `B_lv` against the data-generating truth. The per-family bridge tests
(`test/test_bridge_lv_predictor.jl`) add `cor(B̂_lv, B_true) > 0.9`, but that is
**single-seed, correlation-only** (rank agreement, not magnitude) and — decisively —
is generated from a **misspecified** process: the fixtures draw the innovation as
`0.2·randn` (sd ≠ 1) while the estimator assumes `z_s ~ N(0, I)` (unit variance,
with `Λ` carrying the scale). Under that mismatch `B̂_lv` can track truth in rank
yet be biased in magnitude, which is exactly why those tests only check
correlation.

So the recovery gate that the whole `latent(..., lv = ~ x)` programme is supposed
to be "gated by" was **not actually met for any family**. This checkpoint closes
the *point-estimate* half of that gate.

## Design (correctly specified)

```
z_total[s] = X_lv[s]·α + z_s,   z_s ~ N(0, 1)        # UNIT innovation
η[t, s]    = β[t] + Λ[t]·z_total[s]
estimand:  B_lv = Λ·α'  (rotation/sign-stable for K = 1)
```

- `p = 5`, `K = q_lv = 1`, `Λ = [0.5, −0.4, 0.3, 0.25, −0.2]`, `α = 0.6`
  ⇒ `B_true = [0.30, −0.24, 0.18, 0.15, −0.12]`.
- Fitting goes through the **user-facing** `bridge_fit(...; X_lv=...)` with the
  **default warm start** (no truth inits) — the genuine pipeline a user gets, not
  the truth-initialised native fit the existing `cor` proxy uses.
- `S = 40` independent datasets per route; `B_lv` is sign-aligned per fit
  (defensive — it is sign-identified for `K = 1`; `flip` counts how often the
  raw sign came out negative).

## Results — n = 160, S = 40

| route             | conv  | flips | mean bias | max\|bias\| | mean RMSE | mean\|cor\| |
|-------------------|-------|-------|-----------|-------------|-----------|-------------|
| gaussian          | 40/40 | 0     | +0.0022   | 0.0036      | 0.0495    | 0.998       |
| binomial_logit    | 40/40 | 0     | +0.0008   | 0.0117      | 0.0531    | 0.998       |
| binomial_probit   | 40/40 | 0     | −0.0005   | 0.0085      | 0.0473    | 0.999       |
| binomial_cloglog  | 40/40 | 0     | −0.0025   | 0.0108      | 0.0480    | 0.999       |
| poisson           | 40/40 | 0     | −0.0020   | 0.0168      | 0.0467    | 0.997       |
| negbinomial       | 40/40 | 0     | −0.0032   | 0.0212      | 0.0552    | 0.993       |
| gamma             | 40/40 | 0     | −0.0024   | 0.0068      | 0.0477    | 0.997       |
| beta              | 40/40 | 0     | −0.0037   | 0.0149      | 0.0555    | 0.994       |

Per-trait bias (sign-aligned), trait order `[0.30, −0.24, 0.18, 0.15, −0.12]`:

| route             | t1 (0.30) | t2 (−0.24) | t3 (0.18) | t4 (0.15) | t5 (−0.12) |
|-------------------|-----------|------------|-----------|-----------|------------|
| gaussian          | +0.0034   | +0.0005    | +0.0036   | +0.0010   | +0.0023    |
| binomial_logit    | −0.0045   | +0.0117    | −0.0068   | −0.0042   | +0.0078    |
| binomial_probit   | −0.0085   | +0.0055    | −0.0015   | −0.0029   | +0.0049    |
| binomial_cloglog  | −0.0108   | +0.0059    | −0.0046   | −0.0068   | +0.0037    |
| poisson           | −0.0168   | +0.0115    | −0.0065   | −0.0019   | +0.0037    |
| negbinomial       | −0.0212   | +0.0174    | −0.0009   | −0.0162   | +0.0049    |
| gamma             | −0.0068   | +0.0057    | −0.0032   | −0.0054   | −0.0022    |
| beta              | −0.0149   | +0.0123    | −0.0084   | −0.0136   | +0.0061    |

## Reading

- **All eight routes recover `B_lv` essentially unbiased.** Mean bias ≤ 0.004
  in absolute value everywhere (≈1% of the average true effect); the worst
  *single-trait* bias is 0.021 (NB2, the largest effect). Full convergence
  (40/40), no sign flips, `|cor|` ≥ 0.993 on every route.
- **The only structure** is a faint *negative* bias on the largest effect
  (trait 1, `B = 0.30`) for the Laplace families. Gaussian — the one closed-form
  marginal, no Laplace inner solve — is the cleanest (all biases positive and
  ≤ 0.004), which points at the residual non-Gaussian bias being **finite-n
  Laplace bias** (slight loading shrinkage), not an estimator defect. The
  n-scaling pass below tests that directly.

## n-scaling (finite-n bias check) — S = 40

From `LV_REC_N="160,320,640" LV_REC_S=40 julia --project=. bench/lv_recovery.jl`
(a separate seed sweep from the headline table above; statistically consistent).
Mean RMSE of `B_lv`:

| route             | n=160  | n=320  | n=640  | ratio 160→640 |
|-------------------|--------|--------|--------|---------------|
| gaussian          | 0.0495 | 0.0286 | 0.0216 | 0.44          |
| binomial_logit    | 0.0502 | 0.0307 | 0.0248 | 0.49          |
| binomial_probit   | 0.0467 | 0.0287 | 0.0214 | 0.46          |
| binomial_cloglog  | 0.0486 | 0.0259 | 0.0219 | 0.45          |
| poisson           | 0.0509 | 0.0309 | 0.0241 | 0.47          |
| negbinomial       | 0.0546 | 0.0362 | 0.0286 | 0.52          |
| gamma             | 0.0565 | 0.0320 | 0.0256 | 0.45          |
| beta              | 0.0524 | 0.0355 | 0.0238 | 0.45          |

Max |per-trait bias| (worst single trait), same sweep:

| route             | n=160  | n=320  | n=640  |
|-------------------|--------|--------|--------|
| gaussian          | 0.0311 | 0.0014 | 0.0028 |
| poisson           | 0.0278 | 0.0063 | 0.0034 |
| negbinomial       | 0.0240 | 0.0088 | 0.0026 |
| gamma             | 0.0212 | 0.0007 | 0.0060 |
| beta              | 0.0153 | 0.0049 | 0.0055 |

Both confirm the prediction. RMSE falls by ~0.44–0.52 from n=160 to n=640 (4×
sample size), i.e. essentially the `1/√n = 0.5` Monte-Carlo rate. Max bias
collapses to ≤ 0.008 everywhere by n=640 and mean bias to ≤ 0.003 — the residual
small-n negative bias on the largest loading is finite-n Laplace bias that
vanishes with n, not a structural defect. Full convergence (40/40) and zero sign
flips at every n.

## Scope and honest limits

- This validates the **point-estimate** path only. It does **not** validate
  intervals: `confint(fit; X_lv)` still throws for every family. Interval
  **coverage** is the next gate and is blocked on building Wald CIs for the
  `X_lv` packed objective (delta-method onto `B_lv`).
- `K = 1`, `q_lv = 1`, complete responses, single ordinary latent block, one
  `X_lv` column, no fixed-effect `X`, no masks, no mixed-family, no structured
  (phylo/animal/spatial/kernel) sources. Each remains its own gate.
- **No capability row is promoted to "validated" on the strength of this run.**
  This is evidence for the maintainer's promotion decision, per the
  validation-debt discipline — not a self-promotion.
