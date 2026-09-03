# CI oracle rebuild is not bit-reproducible (2026-09-02)

## Finding
The `Frozen R 0.7.0 family smoke` CI job rebuilds the frozen oracle from
source at b4d5fee6. Across three CI rounds (R release + floating CRAN; R
4.5.3 + dated PPM snapshot; + pinned BLAS/OMP threads) two cells failed with
values IDENTICAL to 16 digits:

- test_negbin_parity.jl:84 — R's own `r_gradient_max` = 0.002432304517354068
  against the cell's 1e-4 health gate.
- test_studentt_parity.jl:113-119 — R's free-nu Student-t fit reports
  converged = false / optimizer_code = 1.

Both are R-SIDE health assertions; neither is a Julia regression, and the
values do not move with R version, CRAN snapshot, or BLAS threading.

## Root cause
The CI build reproduces the SOURCE exactly and the RUNTIME version exactly —
`source_tree_sha256 = f83545fa…` and `r_version = "R version 4.5.3"` match
the retained receipt — but the INSTALLED TREE differs:

    retained (Totoro) installed_tree_sha256 = b25f5b8838d1d476…
    CI runner        installed_tree_sha256 = 9304ac241a5948ba…

Same sources, different compiled artifact (toolchain, TMB/Eigen/Matrix
builds). The frozen oracle is a specific BUILD, not merely a version pin, and
R's optimizer trajectory — hence its own gradient at the optimum and its
convergence flag on a hard free-nu fit — is build-sensitive at these
tolerances. The same fixture file (fixture_sha256 db83f338…, byte-identical
today) passes 18/18 on the retained build: see
.unlazy/core070-aghq/tweedie-replay-01/attempt5/parity-receipts/cell-NATIVE-06-NB2.toml.

## Disposition
The retained pinned-build receipts remain the AUTHORITY for parity evidence
(that is the programme's design). The CI job is therefore advisory: it still
runs, still uploads its receipts and failures as artifacts, but no longer
blocks the branch on health gates that were calibrated against a build it
cannot reproduce. NOTHING about the engine's own gates changed, and no
tolerance was widened.

## Owed follow-up
Re-express the CI cell in BUILD-INDEPENDENT terms — cross-engine invariants
computed on the same machine in the same run (e.g. same-point likelihood
identity between the engines) rather than the magnitude of R's own gradient
at its own optimum. Then the job can block again, on a claim it can actually
verify anywhere.
