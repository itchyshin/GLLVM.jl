# Seven registered cases: current source-bound replay

The required parity runner now has explicit master-contract bindings for seven
existing case IDs across five family facts. The native and formula Gaussian IDs
share one execution, giving six executions and 121 assertions. These are five
specific fitted models, not five complete response-family certifications.

| Model | Verified routes | R controls | Absolute log-likelihood difference |
|---|---|---|---:|
| Gaussian, original default-unique | Native, wide and reversed-long formula | Declared BFGS controls, fixed residual scale | 3.8641e-9 |
| Poisson, seed44 | Native | Original fit retained, public start_from refinement | 1.4325e-11 |
| NB2, seed45 | Native, wide and reversed-long formula | Original default fit | 3.4128e-6 |
| Beta, seed45 | Native | Original fit retained, public start_from refinement | 1.9867e-11 |
| Truncated NB2, seed58 | Native | Original fit retained, public BFGS refinement | 8.6731e-8 |

All final fits pass both engines' absolute-gradient threshold of 1e-4. The original
truncated-NB2 default R fit still has nonzero convergence status; the receipt keeps
that failure and verifies the declared refinement without changing data, maps or
free parameter names. Poisson/Beta controls likewise remain explicit. No claim
that all default optimizer calls succeed follows from this replay.

Source-role planned IDs retain their existing stable required-runner IDs as
aliases. The family-case generator and master source map agree on those links.
`registered-models-contract.json` states actual calls, data hashes, parameter
scales, curvature, normalization, controls and acceptance. The `executable_case`
tables are the precise selected model contracts; earlier broad obligation/census
rows remain programme requirements and do not substitute for these call records.

Reproduction uses the pinned environment and the existing supervised launcher in
`.unlazy/core070-aghq/registered-models-01/`. Its case selection is:

```text
NATIVE-03-POISSON,NATIVE-06-NB2,NATIVE-08-BETA,NATIVE-12-TRUNCATED-NB2,CORE070-FAMILY-05-LOG-FORMULA-INTERFACE,CORE070-FAMILY-00-IDENTITY-NATIVE-MODEL,CORE070-FAMILY-00-IDENTITY-FORMULA-INTERFACE
```

The launcher invokes `test/parity/runparity.jl` in required mode on one Totoro
core, retaining oracle checks before/after, source/runtime pins, process exit,
logs and every case receipt. The measured combined run took 77.78 seconds;
registry checks took 3.12 seconds. These durations are operational measurements,
not performance comparisons or speedup claims.

`python3 tools/core070_verify_registered_models.py --self-test` verifies the
current subset. It checks numerical reports against their logged hashes and
reads the retained raw R fits, including the original/refined data and maps.
Twenty-two corruptions of controls, health, cases, totals and formula outputs
must fail. Forty-two local metadata tests and the evidence self-test also pass.
No frozen status is fabricated to call the full-programme aggregator.

Seven executable links cover parts of five source facts. The remaining 710
nonexcluded source facts are unmapped, and the five linked families still lack
required interfaces or broader model variants. None passes the full-family
coverage guard; the full manifest stays `DRAFT_INCOMPLETE_NOT_FROZEN`.
Public R bridge, remaining formulas, covariance/data/post-fit/AGHQ cells,
recovery/coverage, final full suites and independent review remain separate work.
