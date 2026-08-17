# Decision: AGHQ Stage-1b A4(2) per-site adaptation (not a new Identity)

**Date:** 2026-08-17
**Status:** ACCEPTED as an Identity-adjacent lock; **engine NOT started**
(`src/` gated on #251)
**Lane:** `cursor/aghq-stage1b-20260817`
**Tip:** `1550eef3` (`origin/main`; merge of #250)
**Depends on:** Identity `docs/dev-log/decisions/2026-08-17-aghq-identity.md`
§A4(2) (#248); Stage-1a live-pin grid
`docs/dev-log/decisions/2026-08-17-aghq-stage1a-grid.md` (PR #251,
`17857481`, still OPEN at lock time)
**Do not** write a new Identity — the estimand is unchanged (adaptive
Gauss–Hermite of the joint integrand at the Laplace mode).
**Do not** edit `src/families/aghq_grid.jl` until `origin/main` contains
`17857481`. **Do not** merge #251 from this lane.

## Why this note

#248 A4 item (2) named per-site adaptation as the next campaign slice.
Hopper's A4(2) pin is the implementer contract. This note records that
pin so a later lane does not re-derive the map, invent a √2, or fork a
third grid.

## Hopper pin (do not re-derive)

Liu–Pierce (1994) at the existing Laplace mode. Probabilists' nodes from
Stage-1a `aghq_grid` (live `.gllvmTMB_aghq_grid`; **not** the peer
`.aghq_grid` physicists' helper; **not** VA `_gauss_hermite`):

```
z_ij = ẑᵢ + Lᵢ^{-T} uⱼ          # no √2
log Lᵢ = aghq_logdet(i) + logsumexpⱼ(logwⱼ + inner_ll(i,j))
```

Twin DATA_ names (read-only citation): `aghq_mode` / `aghq_Lt` /
`aghq_logdet`. Grid (`aghq_nodes`, `aghq_logw`) computed once.
Adaptation recomputed each pass; mapped nodes + `inner_ll` + `logsumexp`
every eval.

### Julia reuse (extend, do not fork)

Extend `aghq_stage1a_loglik_site`. Do not start a new engine file.

1. `z = _laplace_mode(...)` → `ẑ`
2. `A = Λ'WΛ + I` at that mode — the expected Fisher Hessian already
   built in `laplace_loglik_site` / Stage-1a. Identity says reuse this
   cache, not TMB `spHess`. **Do not** port the twin's 1e-8 eigenvalue
   floor or `aghq_ridge`.
3. `logdet_i = −½ logdet(A)`; `chol(A)` → `R`; `L^{-T} = R^{-1}`
4. For each row `u_j` of `aghq_grid(d, k).nodes`:
   `z_j = z + L^{-T} u_j`;
   `inner_ll` as Stage-1a: `ℓ − ½ z′z − (d/2) log(2π)`;
   `log L = logdet_i + logsumexp(logw .+ inner_ll)`
5. At `k = 1` this **is** the existing golden (`u = 0`, `L^{-T}` unused).
   Keep evaluating the template. **Do not port** the twin's fit-time
   `k = 1` → Laplace skip (that is A4.4).

Fail-loud: keep `_aghq_stage1a_reject_extra` (single loadings-only `z_B`).

## Out of this slice

A4(3) structural gate · A4(4) adaptation loop / fit-time skip · A4(5)
report honesty · `aghq_ridge` · public `aghq=` · ledger promote of either
AGHQ row · twin Δ · `_gauss_hermite` · Tweedie `fit_gllvm` · merge of
#247 or #251

## Rose fence

Both AGHQ status cells stay `missing`. No R-parity, ADEMP, or coverage
claimed. `k = 1` ≡ Laplace remains a template identity, not a capability
claim. Hopper pin is the map; do not guess a third grid convention.

Rose verdict for **this** note: PASS — locks only; no engine code.
