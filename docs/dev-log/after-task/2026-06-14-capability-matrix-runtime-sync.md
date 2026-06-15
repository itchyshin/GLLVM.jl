# After-Task Audit: Capability Matrix Runtime Evidence Sync

Date: 2026-06-14

## Goal

Bring the durable capability/bridge matrix back into agreement with the latest
local runtime evidence after the #91/#92/#96/Gamma-gradient and gllvmTMB bridge
test slices.

## Files Changed

- `docs/dev-log/capability-bridge-matrix.md`
- `docs/dev-log/check-log.md`

## Tests And Checks

- In-app browser smoke check for `http://127.0.0.1:8770/`: rendered title
  `Finishing the twin - GLLVM.jl + gllvmTMB` and showed current evidence strings
  `3869`, `53/53`, and `phylo_signal`/#92.
- `git status --short --branch` checked the three active worktrees before the
  ledger edit:
  - `GLLVM.jl`: clean, ahead of origin by local dashboard/ledger commits;
  - `GLLVM.jl-integration`: clean on `codex/high-rate-poisson-safeguard`;
  - `gllvmTMB`: clean on `engine-julia`.

No Julia or R tests were run for this ledger-only slice.

## Benchmark Numbers

No new benchmark was run. The matrix now references the existing Gamma
finite-vs-analytic evidence: quick/medium grids showed analytic gradients were
faster with logLik deltas no larger than `1.9e-12`, followed by full
`Pkg.test()` green on the integration branch.

## R-Parity Verdict

Partial. `gllvmTMB` live bridge tests pass 53/53 for the tested Julia bridge
cells, including Gaussian CI transport, but R `{gllvm}` statistical parity is
still not passing for the JuliaConnectoR scaffold.

## JET / Allocs / Aqua Verdict

Not applicable for this docs-only ledger sync. The referenced integration
branch full `Pkg.test()` includes the package quality battery and passed with
one existing broken placeholder.

## Rose Verdict

PASS WITH NOTES. The matrix now says local fixes are local branch facts, not
public closure. No issue was closed, no PR was merged, and no release/tag
wording was promoted.

## Remaining Risks

- `GLLVM.jl#95` is still maintainer-gated despite green CI.
- `GLLVM.jl#94` still needs unique-content audit before closure.
- GitHub issues #91/#92/#96 are not updated from this local session.
- Broader bridge parity, missingness, mixed-family support, visuals, and
  issue-led acceptance gates remain partial.

## Next Command

```sh
git diff --check
```
