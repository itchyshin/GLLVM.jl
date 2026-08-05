# ARC CARD — BetaBinomial+X Arc 1+2 (engine + light RCall)

**Status:** G0 LOCKED — `/goal` executing  
**Mode:** size  
**Requested outcome:** quantified programme — (1) implement locked BetaBinomial+X
twin identity as `fit_beta_binomial_gllvm_grouped` + `_grouped_cov` (+ Julia
identity tests) and bridge/`@formula` admit; (2) land **one** light gllvmTMB
BetaBinomial+X logLik cell @ rtol `1e-6`. Theme = **R–Julia parity**.  
**Mechanism authority:** surgical `src/` + `test/` + narrow docs from
`origin/main` @ `d5d61cb7` (#191 Identity ACCEPTED). Explicit exclusions: no
ADEMP/coverage; no Phylo Model A; no Tweedie/ZIP/+X; no `X_lv` redesign; no
Dropbox-protected writes; no `git add -A`; no push without ask; no “full family
parity”; no silent rtol widen; do not invent a second family in this arc.  
**Recommended arc:** **5.5 hours** (range **4.5–7.5 h**)  
**Time contract:** ceiling ~7.5 h (outcome-first; under-run → stop after green
engine+cell, do not pad)  
**Estimate confidence:** **inferred** (NB1 combined ~4.5 h but BB has no
no-X grouped yet + trials `N` + custom FD Laplace — heavier than NB1 rung)

**Arc 0 gate (done):** ACCEPTED Identity
`docs/dev-log/decisions/2026-08-05-betabinomial-x-dispersion-identity.md` (#191).

**Executable rung and evidence:**
- Exported `fit_beta_binomial_gllvm_grouped` + `fit_beta_binomial_gllvm_grouped_cov`
  (`η = β + Xγ + Λz`, per-trait `log φ`, trials `N`)
- Identity: G=1 ≈ shared; constant `φvec`+offset vs shared marginal; no rtol widen
- Bridge one-part + X + `@formula`+X for `betabinomial` / `beta_binomial`
- Light RCall: Julia vs gllvmTMB `betabinomial()` + shared site-X @ rtol `1e-6`
- Docs/board/check-log/after-task; Rose OK for **engine + light cell only**

### Capacity ladder

| Order | Budget | Outcome | Trigger |
| --- | ---: | --- | --- |
| Gate | — | #191 MERGED Identity ACCEPTED (`d5d61cb7`) | External — **done** |
| Rung A (engine) | 3–4.5 h | grouped + grouped_cov + identity suite | After G0 |
| Rung B (bridge+light) | 1.5–2.5 h | bridge/formula + one RCall cell | After Rung A green |
| Integrate/close | 25–40 min | docs + after-task + Rose ≠ full parity | Always |

### Budget (combined)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient / LOOP | 25–35 | Rehydrate Identity; twin `log_phi_betabinom` + `n_trials`; NB1/Beta cov mirror |
| Grouped no-X core | 70–100 | `fit_beta_binomial_gllvm_grouped` + φvec Laplace (`N` threaded) |
| Grouped cov core | 60–90 | `fit_beta_binomial_gllvm_grouped_cov` + offset; exports |
| Identity verify | 40–55 | `test/test_betabinomial_x_identity.jl`; tallies |
| Bridge/formula | 40–55 | Admit keys; `_bridge_fit_onepart(_cov)`; formula dispatch; capabilities golden |
| Light helper + cell | 40–60 | `:betabinomial` in X helper; one `@testset`; paste Δ or OWED |
| Docs / closeout | 25–40 | board/AGENTS/capability-status/after-task/check-log |

### Actuals

| Field | Value |
| --- | --- |
| Started | 2026-08-05 ~12:59 MDT (S0 scaffold `f538dbc3`) |
| Ended | 2026-08-05 ~14:01 MDT (S6 docs closeout, this slice) |
| Wall clock | ~1h (S0–S4 engine+bridge `f538dbc3`→`185d8847` ~38 min; S5–S6 light cell+docs this slice ~25 min) |
| Outcome vs ladder | Under-run vs 5.5 h recommended (4.5–7.5 h range) — engine mirrored NB1/Beta grouped_cov packing closely enough that no novel debugging was needed; light cell green on first live run (abs Δ≈1.50e-8). Stopped after green per G0 (no Tweedie/ZIP). |
