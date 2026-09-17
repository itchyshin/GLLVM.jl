# GLLVModels rename Arc 0 — check log

| Gate | Evidence | Verdict |
| --- | --- | --- |
| Package identity | `Project.toml`: `name = "GLLVModels"`; UUID remains `2dc8e01c-4f48-4476-aaae-e919b4a30df7`; version remains `0.3.0`. | PASS |
| Entry module and compatibility | `src/GLLVModels.jl` defines `module GLLVModels`; `GLLVModels.GLLVM === GLLVModels` is asserted in `test/runtests.jl`. The alias is documented as source-level only; `using GLLVM` cannot survive a Julia package rename. | PASS |
| Static scope | `git diff --check` passed. Current source, tests, docs, CI, bench and tooling imports were moved to `GLLVModels`; historical `docs/dev-log/`, design/planning material, captured output and the R bridge were not rewritten. | PASS |
| Full suite | Totoro attempt 2, Julia 1.12.6, `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=4`: `Pkg.instantiate(); Pkg.test()` completed in 120m30s: **16,161 pass, 20 expected broken, 16,181 total**. PID `887832`; retained log: `/home/snakagaw/hsq_work/GLLVM-rename-gllvmodels-20260917/gllvmodels-full-suite-attempt2.log`. Attempt 1 did not execute Julia because non-interactive `PATH` lacked `julia`; it is not test evidence. | PASS |
| Documenter | Local `julia --project=docs docs/make.jl --local` completed after developing and instantiating the isolated checkout. Rendered entry page observed at `docs/build/1/index.html`. | PASS |

No GitHub repository rename, merge, registry activity, R bridge release, or book publication occurred in this arc.
