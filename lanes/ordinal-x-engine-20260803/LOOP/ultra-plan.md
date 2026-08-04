# Ultra-plan (frozen) — Ordinal+X engine Arc 1

Approved by Shinichi yes to start after #179 merge (2026-08-03).

## Scope

1. `fit_ordinal_gllvm_pertrait_cov` — η = β + Xγ + Λz; per-trait τ₁=0 / K−2.
2. Offset support on per-trait Laplace marginal.
3. Bridge `ordinal` / `ordinal_probit` + X; `@formula` `Ordinal()` + X.
4. Identity tests vs no-X / zero-offset; bridge oracle ≈ native.
5. Fence: no RCall Arc 2; no ADEMP; no Phylo Model A; no tolerance widen.

## Analogue

Gamma+X `fit_gamma_gllvm_grouped_cov` / NB2+X grouped_cov pattern; cutpoint
packing reused from `fit_ordinal_gllvm_pertrait`.
