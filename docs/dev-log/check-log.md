# Check Log

## 2026-05-31 — Non-Gaussian ForwardDiff Fitter Gradients

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `a9a860f`

### Implementation Checks

- Switched `fit_binomial_gllvm`, `fit_poisson_gllvm`, `fit_nb_gllvm`,
  `fit_beta_gllvm`, `fit_gamma_gllvm`, and `fit_ordinal_gllvm` from
  `autodiff = :finite` to `autodiff = :forward`.
- Made dense Laplace accumulators and ordinal scratch arrays element-type
  generic so ForwardDiff Dual values survive the inner Fisher-scoring path.
- Kept public APIs unchanged.
- Did not edit `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

### Gradient Verification

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'
```

Result:

```text
Test Summary:                                         | Pass  Total   Time
non-Gaussian fitter objectives: ForwardDiff gradients |   18     18  14.5s
```

The test compares `ForwardDiff.gradient` to a central finite-difference
gradient for the packed objective of each non-Gaussian fitter. Gate: max
absolute difference ≤ 1e-6.

Observed one-off maxima before adding the test:

| family | maximum absolute gradient difference |
| --- | ---: |
| binomial | 5.857e-9 |
| poisson | 1.029e-8 |
| negative-binomial | 6.298e-9 |
| beta | 2.943e-9 |
| gamma | 5.118e-9 |
| ordinal | 2.646e-9 |

### Core Suite

Command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Functional tests passed; the direct core environment
reported the expected quality-tool placeholders as broken because Aqua/JET are
loaded only by `Pkg.test()`.

Key touched blocks:

```text
non-Gaussian fitter objectives: ForwardDiff gradients | 18/18 pass
fit_binomial_gllvm — recovery                         | 8/8 pass
fit_poisson_gllvm — recovery                          | 7/7 pass
fit_nb_gllvm — recovery                               | 7/7 pass
fit_beta_gllvm                                        | 7/7 pass
fit_gamma_gllvm                                       | 7/7 pass
fit_ordinal_gllvm                                     | 9/9 pass
```

### Full Package Suite

Command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       |   12     12  12.0s
Testing GLLVM tests passed
```

Manual tally from the emitted `Test Summary` blocks: 1750 pass, 1 existing
broken sparse-phy precision check, 0 fail, 0 error.

### Benchmarks

Julia version: 1.10.0.
R comparator: R 4.5.2, `gllvmTMB` 0.2.0.

Fixed-iteration Julia before/after smoke, p = 5, n = 60, K = 1,
6 L-BFGS iterations, `g_tol = 0.0`. The finite-difference numbers were recorded
immediately before the code change on the same branch; the ForwardDiff numbers
were recorded immediately after.

| family | finite diff (s) | ForwardDiff (s) | speedup |
| --- | ---: | ---: | ---: |
| binomial | 0.0916 | 0.0049 | 18.7x |
| poisson | 0.0696 | 0.0052 | 13.4x |
| negative-binomial | 0.0808 | 0.0093 | 8.7x |
| beta | 0.0896 | 0.0148 | 6.1x |
| gamma | 0.0926 | 0.0131 | 7.1x |
| ordinal | 0.0514 | 0.0105 | 4.9x |

R-vs-Julia warmed smoke command:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --iterations=80 --reps=1 --warmups=1
```

Cell: p = 5, n = 60, K = 1.

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | ---: | ---: | ---: | --- |
| gaussian | 0.0003 | 0.5120 | 1640.6x | same_data_loglik_comparable |
| binomial | 0.0142 | 0.5150 | 36.2x | same_data_loglik_comparable |
| poisson | 0.0339 | 0.5060 | 14.9x | same_data_loglik_comparable |
| negative-binomial | 0.0195 | 0.6400 | 32.9x | same_data_parameterization_audit_needed |
| beta | 0.0331 | 0.6100 | 18.4x | same_data_parameterization_audit_needed |
| gamma | 0.0219 | 0.5070 | 23.1x | same_data_parameterization_audit_needed |
| ordinal | 0.1083 | 0.5570 | 5.1x | non_equivalent_link |

Log-likelihood spot checks on comparable smoke rows:

| family | Julia logLik | gllvmTMB logLik | absolute difference |
| --- | ---: | ---: | ---: |
| gaussian | -328.9497618208953 | -328.949761826271 | 5.38e-9 |
| binomial | -199.02063720298568 | -199.020637206598 | 3.61e-9 |
| poisson | -557.3922590332276 | -557.392259036326 | 3.10e-9 |

The full small/medium/large grid is implemented in
`bench/non_gaussian_gllvmtmb_bench.jl` but was not run in this slice.

### Quality And Audit Scans

Commands:

```sh
rg -n "autodiff\\s*=\\s*:finite|Finite-difference gradient|finite-difference gradient" src/families test bench README.md docs/src CLAUDE.md AGENTS.md
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src CLAUDE.md AGENTS.md
<private-source trace scan over tracked repo content>
```

Results:

- No remaining `autodiff = :finite` or obsolete finite-difference fitter
  wording under `src/families`.
- No private-source trace in tracked repo content.
- `AGENTS.md` still contains the user-provided stale "Gaussian only" snapshot;
  not edited because AGENTS edits require maintainer approval under that file's
  own rules.
- Allocs.jl was not run: `Package Allocs not found in current path`.

Open PR / collision check:

```text
gh pr list --limit 10 --json number,title,headRefName,updatedAt
[]
```
