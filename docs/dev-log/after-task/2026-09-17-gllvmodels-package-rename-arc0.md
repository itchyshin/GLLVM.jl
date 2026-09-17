# After-task — GLLVM.jl → GLLVModels.jl Arc 0

## Outcome

Prepared the Julia package/module rename on an isolated branch. The branch is ready
for review only; it is not merged and the GitHub repository still has its original
name.

## Scope delivered

- `Project.toml` package name and `src/GLLVModels.jl` module/file rename.
- Active source, tests, package projects, Documenter configuration, README,
  changelog, CI, benchmarks and operational tools now load or qualify
  `GLLVModels`.
- UUID `2dc8e01c-4f48-4476-aaae-e919b4a30df7` and version `0.3.0` are unchanged.
- The modelling API remains `gllvm`, `fit_gllvm`, formula helpers, fit types and
  their existing arguments. `GLLVModels.GLLVM` is a documented temporary alias;
  package resolution means `using GLLVM` cannot be retained.
- Active documentation branding assets use `gllvmodelsjl-` names.

## Test-first evidence

Changing `test/runtests.jl` to `using GLLVModels` first produced the expected red
failure: `Package GLLVModels not found in current path`. The package/module rename
then made the new name loadable on Totoro.

## Verification

- `git diff --check`: pass.
- TOML identity invariant and Julia parser check for `src/GLLVModels.jl`: pass.
- Totoro full suite: **16,161 pass, 20 expected broken, 16,181 total** in
  120m30s with `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4`.
- Local Documenter/Vitepress build: pass; rendered entry page at
  `docs/build/1/index.html`.

## Preserved boundaries

- No changes to historical `docs/dev-log/`, design/planning history, reports or
  captured benchmark output.
- No edits to the R bridge, gllvmTMB, protected DRAFT PRs, registry metadata,
  GitHub repository identity, Pages configuration, or books.
- No version bump and no package registration.

## Follow-up gates

1. Review the unmerged source rename PR.
2. Shinichi-only GitHub repository rename click, then remote/Pages repair.
3. Separate gllvmTMB/R bridge migration after its own coordination window.

## Files and evidence

The per-arc check record is
[`check-log.d/2026-09-17-gllvmodels-rename-arc0.md`](../check-log.d/2026-09-17-gllvmodels-rename-arc0.md).
The Totoro retained log is
`/home/snakagaw/hsq_work/GLLVM-rename-gllvmodels-20260917/gllvmodels-full-suite-attempt2.log`.
