# GOAL — default-route-phi-20260801

**STATUS:** COMPLETE
**PLATFORM:** Cursor (solo) via `/goal`
**BASE:** `catchup/loglik-oracle-20260801` @ `bbf5d7d8`
**BRANCH:** `parity/default-route-phi-20260801`
**TWIN R (read-only):** `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`

## Mission

Public `fit_gllvm(NegativeBinomial/Beta)` defaults to per-trait φ
(`disp_group=:species` → `NBGroupedFit`/`BetaGroupedFit`). Keep
`fit_nb_gllvm` / `fit_beta_gllvm` as shared-φ engines. Retarget light
`GLLVM_PARITY_TESTS=1` NB2/Beta cells to plain `fit_gllvm` default path;
cascade tests/docs that assert `NBFit`/`BetaFit` from plain `fit_gllvm`.

Headline: routing flip in `src/families/fit_gllvm.jl` for NB/Beta only
(`nothing`→`:species`), then honesty cascade + live parity.

## API B (Curie) — locked

When `disp_group === nothing` for NB/Beta only, coerce to `:species`
before grouped routing. Do not change Gamma. Do not reopen observed-Hessian
work if grouped path stays green.

## Definition of Done

1. Plain `fit_gllvm(Y; family=NegativeBinomial()|Beta())` returns grouped fits.
2. Named shared fitters still work and remain tested.
3. Live NB2/Beta parity green on default `fit_gllvm` path (prior Δ bands:
   NB2 ~1e-4, Beta ~1e-8; no silent tol widen).
4. Docs/cascade honest; after-task + check-log written; Rose claim fence stated.
5. Checkpoint `STATE=COMPLETE` with RESUME saying DONE.

## Fences (never)

#129/#128; ADEMP; coverage; Totoro/DRAC; “full family parity”; Dropbox stale
fork; attach scratch; catch-up LOOP overwrite; X-cells; ordinal-logit; Phylo
Model A; Gamma default flip; no push without maintainer ask.

## Plan binding

- Durable plan: `docs/dev-log/plans/2026-08-01-default-route-nb2-beta-pertrait-phi.md`
- LOOP copy: `lanes/default-route-phi-20260801/LOOP/ultra-plan.md`
