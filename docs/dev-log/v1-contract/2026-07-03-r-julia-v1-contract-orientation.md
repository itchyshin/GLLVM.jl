# R + Julia v1.0 Contract Orientation

Date: 2026-07-03

## Goal

Move the `gllvmTMB` and `GLLVM.jl` twin toward v1.0 by making the
capability contract explicit before widening any fitter, bridge route, formula
grammar, or compute evidence. This is a truth-lock and planning artifact, not
a user-facing release claim.

## Current Repos

| Repo | Path | Branch / head checked | State used here |
|---|---|---|---|
| `GLLVM.jl` | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` | `claude/jl-bridge-capabilities-20260619` at `b093dc16` | Current working tree has pre-existing `AGENTS.md` and `CLAUDE.md` footer edits. This packet does not touch them. |
| `gllvmTMB` | `/Users/z3437171/Dropbox/Github Local/gllvmTMB` | `codex/r-bridge-grouped-dispersion` at `5d15209e` | Dashboard/working checkout is heavily dirty from other lanes. It is read as operating evidence only, not used as a clean code-edit worktree. |

## Evidence Sources Read

- `GLLVM.jl`:
  - `AGENTS.md`
  - `docs/dev-log/capability-bridge-matrix.md`
  - `docs/src/roadmap.md`
  - `src/bridge.jl`
  - `test/test_bridge_capabilities.jl`
- `gllvmTMB`:
  - `AGENTS.md`
  - `R/julia-bridge.R`
  - `tests/testthat/test-julia-bridge.R`
  - `tests/testthat/test-canonical-keywords.R`
  - `docs/design/61-capability-status.md`
  - `docs/dev-log/dashboard/status.json`
- Second brain:
  - `gllvmTMB` dossier, read only as orientation. Current repo and dashboard
    files remain the authority for live status.

## Operating Truth

1. The v1.0 arc is R-first. Native `gllvmTMB` user workflows define what the
   public contract means; `GLLVM.jl` mirrors and accelerates admitted rows.
2. `GLLVM.jl` local `bridge_fit` is narrower than the current R-side
   `gllvmTMB` bridge ledger. The Julia branch admits no-X one-part families
   only, rejects fixed-effect `X`, mixed-family vectors, and masks, and does
   not route profile CI through `bridge_fit`.
3. `gllvmTMB` R-side `engine = "julia"` ledger is broader but still partial.
   It includes explicit named gates for unsupported cells, including
   mixed-family CIs, fixed-effect-X CIs, mask+X, structured terms, multiple
   reduced-rank terms, cbind binomial, and richer postfit routes.
4. Source-specific `lv = ~ env` for `phylo_latent`, `spatial_latent`,
   `animal_latent`, and `kernel_latent` remains fail-loud. Ordinary
   `latent(lv = ~ env)` evidence must not be reused to advertise
   source-specific structural `lv`.
5. The separate `unique=` lane is R/TMB-first. Its R contract may later become
   a Julia parity target, but this v1.0 contract packet does not start Julia
   parity for `unique=`.
6. All-six private phylo structural-source non-Gaussian S2 runners are
   plumbing only. They are not authorized endpoint-profile denominators, not
   public source-specific support, and not R grammar exposure.
7. Mixed-family bridge support is point/postfit only for the admitted balanced
   row. Mixed-family fixed `X`, predictor-informed `X_lv`, masks, missing
   responses, and CIs remain blocked.
8. Non-Gaussian speed or optimization language must use observed-information,
   Fisher/natural-gradient, reverse-mode, or implicit-Laplace-adjoint terms
   only when directly validated. Do not borrow REML or AI-REML language for
   non-Gaussian Laplace rows.

## Phase Slices

| Phase | Owner | Output | Gate |
|---|---|---|---|
| 0. Orientation | Ada + Shannon | This orientation note | Current repo states are recorded and dirty worktrees are not hidden. |
| 1. Contract matrix | Hopper + Rose | `r-julia-v1-capability-matrix.md` | Every important row has an evidence path and a next gate. |
| 2. Guard finish | Boole + Curie | Focused source-guard and bridge-guard tests | Unsupported source-specific `lv` and unsupported bridge cells fail loudly. |
| 3. Inference parity | Fisher + Hopper | CI/status contract for admitted rows | CI payloads are either real and tested or unavailable with an explicit gate. |
| 4. Public docs | Pat + Rose + Grace | What-works / guarded / blocked page | No public docs imply source-specific `lv`, mixed-family CI, or broad parity. |
| 5. Next feature gate | Ada + Hopper | Prior-art packet for selected beta-zero constraints | Search prior issues, PRs, design docs, and both repos before proposing API. |

## Immediate Next Gates

1. Reconcile the live R `gllvm_julia_capabilities()` ledger with the local
   Julia `GLLVM.bridge_capabilities()` branch reality. Differences are allowed
   only when a named gate explains them.
2. Done: the historical `docs/dev-log/capability-bridge-matrix.md` is retained
   as pre-v1 context and explicitly superseded by the dated v1.0 matrix for
   current contract decisions.
3. Run focused guard tests in both repos before any code or docs claim is
   promoted:
   - `Rscript -e 'testthat::test_file("tests/testthat/test-julia-bridge.R")'`
   - `Rscript -e 'testthat::test_file("tests/testthat/test-canonical-keywords.R")'`
   - `/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl`
   - `/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_fit.jl`
4. Refresh Mission Control only after the matrix changes operating truth, not
   merely because this orientation packet exists.

## Stop Rules

- Stop if a status row cannot be tied to a specific file, test, PR, dashboard
  row, or gate.
- Stop if any bridge CI payload can be mistaken for support when it is empty or
  unavailable.
- Stop if a planned row would widen source-specific `lv` grammar, public
  source-specific support, or PR #127 without explicit maintainer authorization.
- Stop if a proposed non-Gaussian speed/inference row uses REML or AI-REML
  language without a Gaussian-only derivation and validation.
- Do not launch Totoro or DRAC compute from this contract arc.
