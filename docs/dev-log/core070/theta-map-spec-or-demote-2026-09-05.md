# θ-map — implement vs demote (2026-09-05)

**Status:** RESEARCH recommendation — **owner still chooses**  
**Pairs with:** `theta-map-parameter-alignment-2026-09-05.md`

## Recommendation: IMPLEMENT (harness-only)

Julia scout confirms batch-1/`fit_gllvm` uses per-trait length **p** (matches R). The length-1 gate in `theta_map.jl:34-42` is the sole blocker on pilot cells — not an engine parameterisation divergence.

Matched-coordinates for beta_logit / nb2_log is blocked by
`theta_map.jl` requiring a single shared `log_phi_*`, while both engines'
**defaults** use per-trait log-dispersion of length p. Pilot lengths already
agree (15 / 19). Fix the map; re-smoke batch-1; do **not** demote on present
evidence.

### Demote fence (only if owner rejects implement)

> Matched-coordinates diagnostic available for {gaussian, poisson, binomial_logit};
> beta_logit / nb2_log each-own-optimum only until a θ-map ships.

### Receipt impact (A9 / A11)

| Branch | A9 BETA-LOGIT-2SO matched | A11 NB2-LOG-2SO matched |
|---|---|---|
| Implement | Unblocked after harness fix + pass | Same (watch boundary NaN separately) |
| Demote | each-own-optimum only | each-own-optimum only |

No §7 claim from either branch until receipts land.
