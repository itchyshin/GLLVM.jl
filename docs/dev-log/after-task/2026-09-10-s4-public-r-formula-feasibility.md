# After-task — S4 public R-formula feasibility probe

## 1. Goal

Exercise the single G0-authorised public frozen-R Gaussian formula and retain
an honest runtime/feasibility observation before any paired S4 work.

## 2. Implemented

Only the local GLLVM.jl evidence runner, its immutable JSON record, and
Destination-B evidence documentation changed. The frozen `gllvmTMB` 0.7.0
source and its R/C++ likelihood were read only. There was no push, merge,
release, registry action, 0.7.1 work, coverage campaign, or FRK work.

## 3. Model and formula

The native call was the public wide workflow:

```r
traits(trait_1, trait_2) ~ 1 + phylo_dep(1 | species, tree = tree)
```

It used three species, three individuals per species, and a three-tip
ultrametric tree whose root-to-tip height is two. The equivalent long design is
`value ~ 0 + trait + phylo_dep(0 + trait | species, tree = tree)`.

## 3a. Decisions and Rejected Alternatives

The valid public grammar is wide `traits()` plus `phylo_dep()`, not Gaussian
`cbind()`. The runner validates the actual sibling frozen-source identity
record rather than creating a marker inside the frozen package. Rejected
alternatives were bypassing source attestation, allowing evidence overwrite,
or routing the formula through `engine = "julia"`, which remains gated.

## 4. Files Touched

`tools/destination_b/run_a4_s4_public_r_formula_probe.R` is the isolated
native probe; `public-r-formula-contract.md`, this directory's `README.md`,
and `docs/dev-log/check-log.md` record its boundary. The retained `-01` JSON
is a failed-provenance development attempt; the cited immutable receipt is
`-02`:

The immutable receipt is
`docs/dev-log/core070/destination-b-a4-s4/public-r-formula-probe-02.json`
(SHA-256 `17b7fd42b4b55f900d62730a71c57019876555b1c7413369acd7487525726f5b`).
It identifies the frozen source pin
`b4d5fee64def88bc768dda1f1f77c29b295edd86`, the adjacent source-identity
record, and the installed shared-library hash
`3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30`.

The fit converged (`native_convergence = 0`) in 0.5924 seconds, with both
`use_phylo_dep` and `use_phylo_rr` true.

## 5. Checks Run

`tools/destination_b/run_a4_s4_public_r_formula_probe.R` validates the frozen
source identity record and DLL hash, refuses existing or dangling-symlink
output paths, runs only the native constructor, and writes one JSON record.
The first implementation incorrectly treated R's `Sys.readlink()` `NA` for a
normal nonexistent file as a dangling symlink; the final runner distinguishes
`NA` from a real symlink and keeps the no-overwrite fence.

The final runner also records and binds the archive, DLL, source identity,
runner hash, command/output, fixture hash, R version, package version, loaded
path, and UTC capture time. It explicitly loads `gllvmTMB` from the frozen
library and rejects a different loaded path or version.

## 6. Tests of the Tests

- `julia --project=. test/test_destination_b_a4_s4_public_r_formula_receipt.jl`
  passed 29/29 in 0.7 seconds.
- The strengthened frozen-R probe completed in 0.5924 seconds.
- The same output command then failed with `refusing to overwrite a
  public-formula probe receipt`.
- `git diff --check` was clean before documentation was added.

The runner validates the exact frozen commit and installed DLL against the
adjacent immutable identity record rather than relying on a package version.
It records explicit `julia_called = false` and `intervals_extracted = false`.
Its reuse attempt tested the no-overwrite path without creating a second
receipt.

## 7a. Issue Ledger

No issue, push, merge, release, registry action, or R-engine action was taken.
FRK remains parked at gllvmTMB#1275. The qualified S3b and S4 rows remain open.

## 8. Consistency Audit

This is native-only formula feasibility/timing evidence. It is not an R--Julia
comparison, an endpoint receipt, an observed-marginal interval result, a
structured `engine = "julia"` admission, or a qualified S3b/S4 row.

## 9. What Did Not Go Smoothly

The first runner assumed a package-internal `CORE070_SOURCE_PIN.toml`; the
existing B1 frozen install instead correctly carries a sibling immutable
source-identity JSON. The runner now validates that actual record. The first
no-overwrite expression also mistook `Sys.readlink()`'s `NA` result for a
symlink, which was repaired before the retained run.

## 10. Known Residuals

The closed S3b adapter still needs a genuine native-fit-to-Julia paired
comparison with its named quantities. S4 additionally needs a Julia-side
observed-marginal interval implementation and matched endpoint evidence before
the public formula can become a paired receipt. The generic public
`engine = "julia"` phylogenetic route remains intentionally gated.

## 11. Team Learning

Independent review found no P0 scope or claim-boundary issue. Its P1 required
the self-contained receipt provenance now present in `-02`; its P2 required
explicit frozen-library loading and loaded-path/version verification, also now
present. R's `Sys.readlink()` returns `NA` for a normal missing pathname, so a
no-overwrite guard must distinguish that from a dangling symlink.

## 12. Cross-Product Coverage

One Gaussian family × two traits × one full phylogenetic covariance × one
three-tip non-unit ultrametric tree × one public wide formula. It covers formula
evaluation and source attestation only; it does not cover Julia routing,
interval endpoints, alternate trees/pedigrees/dense covariance, recovery, or
coverage.
