# Destination B — G5 T14 NB2 Wald NaN disposition receipt

**Date:** 2026-09-14  
**Lane:** `cursor/honest-070-destb`  
**Branch base:** `origin/main` @ `23fd0496`

## Disposition (not PAUSED)

**F1 + F2 + F3 already chosen and merged** — maintainer-approved fix set
documented in `docs/dev-log/check-log.md` (2026-09-02) from
`docs/dev-log/core070/t14-nb2-wald-nan-diagnosis.md`. This DestB slice does
**not** re-decide estimands or re-implement engine code; it **receipts** the
existing disposition for the honest-0.7 programme.

| Fix | What shipped | Where |
|---|---|---|
| **F3** | CI comparator treats `x == y` (incl. `Inf`) as agreement before `abs(x-y)` | `test/test_bridge_x.jl` `_bx_ci_max_absdiff` |
| **F2** | Well-conditioned NB2 grouped-cov Wald identity test + named seed-523 degenerate agreement test | `test/test_bridge_x.jl` @testsets "T14 F2" |
| **F1** | `dispersion_boundary`, `converged=false` at boundary; Wald conditions boundary params | `src/families/grouped_dispersion.jl`, `src/confint_family.jl` `_family_wald` |

**Carried open (documented, not silent):** cross-Julia-version well-conditioned seed
for the *legacy* 3×70 `_bx_sim` shape was not found (~35k seed search); F2 uses
an alternate well-conditioned DGP instead (see check-log F2 paragraph).

## Test receipt (2026-09-14)

```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
~/.juliaup/bin/julia --project=. test/test_grouped_dispersion.jl
~/.juliaup/bin/julia --project=. test/test_bridge_x.jl
```

| File | Pass | Fail | Error |
|---|---:|---:|---:|
| `test/test_grouped_dispersion.jl` | 20 | 0 | 0 |
| `test/test_bridge_x.jl` | 192 | 0 | 0 |

## Capability-status

No row status word change (NB2 family row stays `implemented`; issue was Wald
*behaviour* at boundaries, not missing engine). Added T14 prose fence under
**Random slopes and special capabilities** (DestB G5).

## Rose fence

Not a promotion to true parity or DestB FINAL-REVIEW; documents second-order
hygiene for degenerate NB2 grouped dispersion.

## Next

G6 **T15** — knife-edge fixture audit (list first).
