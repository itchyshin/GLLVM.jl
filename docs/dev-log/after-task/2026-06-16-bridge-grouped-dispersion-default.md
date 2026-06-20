# After Task: Bridge Grouped-Dispersion Default

## Goal

Make the Julia bridge default match native `gllvmTMB` / `gllvm` nuisance
structure for no-X NB2, NB1, Beta, and Gamma point fits: per-trait dispersion by
default, not shared scalar dispersion.

## Implemented

- `bridge_fit()` now routes complete no-X NB2, NB1, Beta, and Gamma rows through
  the existing grouped-dispersion fitters with `group = 1:p`.
- The bridge payload now includes `dispersion_group`, `dispersion_group_id`,
  `dispersion_parameter`, `dispersion_engine_scale`, and
  `dispersion_public_scale`, while preserving the expanded per-trait
  `dispersion` vector.
- `df` for the four grouped rows now counts `p` nuisance parameters instead of a
  shared scalar.
- Non-`none` CI requests for these grouped rows now fail loudly until grouped-fit
  CI engines are implemented.
- `bridge_capabilities()` now reports CI support only for the current scalar-CI
  bridge rows: Gaussian, Poisson, Binomial, Ordinal, and Ordinal-probit.

## Files Changed

- `src/bridge.jl`
- `test/test_bridge_grouped_dispersion.jl`
- `test/test_bridge_capabilities.jl`
- `test/test_bridge_ci.jl`
- `test/test_bridge_missing_mask.jl`
- `test/runtests.jl`
- `README.md`
- `docs/src/index.md`
- `docs/src/gllvmtmb-parity.md`
- `docs/src/roadmap.md`
- `docs/dev-log/check-log.md`

## Tests Added Or Updated

`test/test_bridge_grouped_dispersion.jl` locks the grouped payload contract and
the CI refusal for NB2, NB1, Beta, and Gamma. Adjacent capability, CI, and
missing-mask tests were updated so they no longer assume shared-scalar
dispersion or grouped CI endpoints.

## Checks Run

```sh
julia --project=. -e 'include("test/test_bridge_grouped_dispersion.jl")'
```

Result: `40/40 pass`.

```sh
julia --project=. -e 'include("test/test_bridge_capabilities.jl")'
```

Result: `32/32 pass`.

```sh
julia --project=. -e 'include("test/test_bridge_missing_mask.jl")'
```

Result: `35/35 pass`.

```sh
julia --project=. -e 'include("test/test_bridge_ci.jl")'
```

Result: `63/63 pass`.

Final reruns after the docs/status wording edits:

```sh
julia --project=. --startup-file=no -e 'include("test/test_bridge_grouped_dispersion.jl"); include("test/test_bridge_capabilities.jl")'
```

Result: grouped dispersion `40/40 pass`; capabilities `32/32 pass`.

```sh
julia --project=. --startup-file=no -e 'include("test/test_bridge_missing_mask.jl")'
```

Result: `35/35 pass`.

```sh
julia --project=. --startup-file=no -e 'include("test/test_bridge_ci.jl")'
```

Result: `63/63 pass`.

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB` on branch
`codex/julia-per-trait-dispersion-spec`: `FAIL 0 | WARN 0 | SKIP 0 | PASS 21`
in `22.8s`. This is a narrow smoke check, not full R-side grouped-dispersion
parity promotion.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: `3981 pass / 3 broken / 0 fail` in `31m57.5s`. Direct core run reported
`Aqua not in this environment` and `JET not in this environment`; run
`Pkg.test()` for the full quality battery.

```sh
rg -n "bridge_fit|bridge_capabilities|confidence intervals|CI routes|NB2|NB1|Beta|Gamma|grouped dispersion|per-species / grouped" README.md docs/src docs/dev-log src test -g '!docs/node_modules/**'
```

Result: relevant hits reviewed; public wording was narrowed for grouped-
dispersion CI status.

```sh
git diff --check
```

Result: clean.

## Rose Verdict

PASS WITH NOTES. The bridge no-X point route now matches the R oracle's
per-trait nuisance default for NB2, NB1, Beta, and Gamma. CI endpoints are not
overclaimed: grouped-dispersion rows carry explicit unavailable status until the
CI engine exists.

## Remaining Risks

- Full `Pkg.test()` and Documenter were not run in this slice; the direct core
  suite was green.
- The paired `gllvmTMB` branch still needs an R-side payload/parity update before
  public bridge rows can be promoted beyond point status.
- Grouped-dispersion CI engines remain follow-up work.
