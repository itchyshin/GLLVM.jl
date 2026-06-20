# After Task: Bridge mixed-family labels

## Goal

Make the Julia-side mixed-family bridge payload expose row-aligned per-trait
family labels so it can target the native `gllvmTMB` mixed-family selector
oracle.

## Implemented

`_bridge_assemble` now accepts an optional per-trait `families` vector and
checks that its length matches the number of traits. The mixed-family bridge
passes normalized family keys through that field, so `family` remains the compact
model tag (`gaussian+poisson+binomial`) while `families` is the true row-aligned
vector (`gaussian`, `poisson`, `binomial`). A focused test locks payload shape,
mixed CI-status behavior, and a selector-length failure path.

## Mathematical Contract

The model is unchanged:
`y_ts ~ Family_t(link_t^{-1}(beta_t + Lambda_t z_s))`,
`z_s ~ N(0, I)`, evaluated through the existing mixed-family dense Laplace
route. This slice changes only the flat bridge metadata, not the likelihood.

## Files Changed

- `src/bridge.jl`
- `test/test_bridge_mixed.jl`
- `test/runtests.jl`
- `docs/src/gllvmtmb-parity.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-15-bridge-mixed-family-labels.md`

## Tests Added

Added `test/test_bridge_mixed.jl` with one testset:

- successful mixed-vector payload has row-aligned `families`, per-trait `link`,
  finite logLik, dimensions, and note text;
- mixed CI request returns an explicit empty CI-status payload;
- family-vector length mismatch throws `ArgumentError`.

This satisfies the "failure path" and "neighbouring bridge feature" test clauses.

## Benchmark Numbers

N/A - no hot-path likelihood code changed.

## R-Parity Verdict

Parity: N/A - this is a Julia payload metadata fix. The paired live R bridge
regression stayed green, but `gllvmTMB` still deliberately rejects mixed-family
Julia-engine admission.

## JET / Allocs / Aqua Verdicts

- JET: not run - no type-sensitive numerical kernel changed.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package metadata or exports changed.

## Checks Run

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_mixed.jl
```

Result: `18/18 pass` in `5.7s`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `9/9 pass` in `0.1s`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no -e 'using GLLVM; Y = [0.2 0.4 -0.1 0.3 0.5 -0.2 0.1 0.6; 1 3 2 4 1 2 5 3; 0 1 1 0 1 0 1 1]; br = bridge_fit(; y=Y, family=["gaussian","poisson","binomial"], d=1); println(join(br.families, ",")); brci = bridge_fit(; y=Y, family=["gaussian","poisson","binomial"], d=1, options=Dict("ci_method"=>"wald")); println(brci.ci_method); println(length(brci.ci_param_names));'
```

Result:

```text
gaussian,poisson,binomial
wald
0
```

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: `439/439 pass` in
`65.2s`.

## Consistency Audit

`docs/src/gllvmtmb-parity.md` now states that Julia mixed-family payload labels
are fixed while R bridge admission remains queued. No public "covered" claim was
added.

## GitHub Issue Maintenance

No GitHub issue was modified. This is a local bridge metadata slice preparing
the next R-first parity gate.

## What Did Not Go Smoothly

An initial inline Julia smoke command had a syntax typo; the focused test was
already green, and the smoke was rerun successfully.

## Team Learning

Bridge metadata needs direct tests even when the fit itself is already covered.

## Remaining Risks

- `gllvmTMB` still rejects mixed-family `engine = "julia"` fits.
- Mixed-family CI endpoints are not routed; the bridge returns explicit empty
  CI-status payloads for requests.
- Full `test/runtests.jl` was not rerun for this narrow metadata slice.

## Known Limitations

No mixed-family R bridge admission, point/logLik parity, or CI endpoint support
was added.

## Next Command

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_mixed.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - Julia mixed-family payload labels are fixed, but
R admission remains deliberately closed pending parity and CI-status gates.
