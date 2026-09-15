# After-task — parity_ledger.py TWIN_ALIAS ALIASES (follow-on #350)

**Date:** 2026-09-15  
**Branch:** `chore/parity-ledger-aliases-20260915` from `origin/main` @ `26967038`  
**Scope:** Tool-only — `tools/parity_ledger.py` `ALIASES` extended from
`docs/dev-log/core070/forward-export-disposition-20260915.tsv` (TWIN_ALIAS rows).
**No** `src/`, **no** ledger JSON, **no** covered promotion.

## Rose fence

- Rebinds **name-twin** FORWARD gaps only; does **not** close formula-keyword exports or
  promote capability rows.
- Skipped ambiguous TWIN_ALIAS rows remain genuine FORWARD gaps until a single Julia export
  is chosen or added in a later slice.

## Checks run

```text
python3 tools/parity_ledger.py --self-test
python3 tools/parity_ledger.py   # frozen gllvmTMB oracle b4d5fee6
```

| Metric | Before | After |
|--------|-------:|------:|
| **FORWARD** (genuinely owed export gaps) | **77** | **62** |
| **REVERSE** (unclassified Julia-ahead) | 92 | 91 |

Δ FORWARD = **−15** (15 safe TWIN_ALIAS rows added; 3 TWIN_ALIAS rows skipped — see below).

## ALIASES added (15)

| R export | Julia export |
|----------|--------------|
| `dep` | `fit_dep_gllvm` |
| `Beta` | `fit_beta_gllvm` |
| `kernel_indep` | `fit_kernel_indep_gllvm` |
| `kernel_dep` | `fit_kernel_dep_gllvm` |
| `kernel_latent` | `fit_kernel_latent_gllvm` |
| `kernel_scalar` | `fit_kernel_indep_gllvm` |
| `kernel_unique` | `fit_kernel_latent_gllvm` |
| `animal_dep` | `fit_animal_dep_gllvm` |
| `animal_latent` | `fit_animal_latent_gllvm` |
| `extract_Sigma_B` | `extract_Sigma` |
| `extract_Sigma_W` | `extract_Sigma` |
| `gllvmTMB_wide` | `gllvm` |
| `.proportions_bootstrap_ci` | `extract_proportions` |
| `.proportions_wald_ci` | `extract_proportions` |
| `flag_unreliable_loadings` | `check_gllvmTMB` |

## SKIPPED (3 TWIN_ALIAS rows — ambiguous or no single export twin)

| R export | Reason left out |
|----------|-----------------|
| `animal_indep` | Partial route (`relatedness_cov` + indep Gaussian); no dedicated `fit_animal_indep_gllvm` export |
| `animal_scalar` | Same modifier pattern as `animal_indep`; no single export target |
| `extract_residual_split` | Structural twin split across `extract_residual_cov` and `link_residual`; API not one Julia name |

## Follow-up

- Thin export wrappers or further ALIASES for SKIPPED rows when maintainer picks one Julia symbol.
- Destination B / formula-keyword FORWARD rows unchanged (still in the 62).
