# CORE-070 oracle contract — draft

`frozen-r070-contract.toml` is deliberately **not frozen**. It records the
immutable R source pin, 215 frozen NAMESPACE exports/registrations in
`frozen-r070-namespace-inventory.tsv`, obligation rows, and machine-readable
blockers. The 17 family cells remain a smoke subset. Links and
parameterisations, covariance/modifier cells, data shapes, post-fit/inference,
formula reach, public bridge, and public Stage 1a AGHQ remain unpaid.
`tools/core070_evidence.py` therefore rejects aggregate evidence from this draft.

The runner has two distinct modes:

```sh
# Optional developer run: absence of this variable is a clean skip.
GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl

# Required runner mode for the family-smoke subset: both variables are required; missing RCall, a receipt
# directory, or installed-reference provenance exits nonzero.
CORE070_PARITY_REQUIRED=1 GLLVM_PARITY_TESTS=1 \
  GLLVM_PARITY_RECEIPT_DIR=/durable/core070-receipts \
  R_LIBS=/private/exact-r070-library \
  GLLVM_PARITY_R_LIBS=/private/exact-r070-library \
  GLLVM_PARITY_R_SOURCE_PIN=/private/exact-r070-library/gllvmTMB/CORE070_SOURCE_PIN.toml \
  julia --project=test/parity test/parity/runparity.jl
```

Before a required run, build the R package from the exact archived source in an
isolated library and write `CORE070_SOURCE_PIN.toml` *inside the installed
`gllvmTMB` directory*.  It must contain the exact commit, the frozen NAMESPACE
SHA-256, a source-tree SHA-256, and an installed-tree SHA-256.  The installed
tree digest excludes the marker itself, so the marker can bind the resulting
bytes without a circular hash.  A package version alone is insufficient.

```toml
reference_commit = "b4d5fee64def88bc768dda1f1f77c29b295edd86"
archive_sha256 = "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc"
namespace_sha256 = "9094613610789faab69c43195d3cfdafb2c7dfef284e6646b10dababa4fa132c"
source_tree_sha256 = "f83545faa6543dbb1f64d64bbf5a9498adcdf036cc3da5851f269912698b1cc7"
installed_tree_sha256 = "<64 lowercase hex characters>"
```

The source hash is the sorted `relpath\0file_sha256` list joined with `\n`,
then SHA-256 hashed, from the exact archived source. The archive SHA-256 is
`0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc`.

Required-runner receipts bind the reference marker, installed R bytes, Julia
`src/` tree, every executed fixture, the cell inventory, and the success marker.
The static verifier is safe to run locally because it creates only temporary
synthetic receipts:

```sh
python3 tools/core070_evidence.py --self-test
```

The 17 records are **family-smoke receipts only**; they cannot be promoted to
programme evidence by this checker.  No numerical parity result is recorded by
this draft.

Parent integration review: the formula route already exists in `src/formula.jl`
for wide and long data; only its complete required coverage remains unpaid.
The source inventory is a catalogue, not the finite executable case matrix:
coarse covariance, data and postfit rows still need expansion before freezing.
Changing the status to FROZEN and supplying only the 17 family IDs must fail;
the checker now explicitly tests that attempted promotion. All obligation IDs
must have frozen executable cases, including fixture hashes and model contracts.
`isdm_source`/`isdm_sources` remain an admission question; they were not excluded
by the user. No engine or API scope is expanded solely from their names.


## Verified source subsets and numerical snapshot

- `aghq-control-subset.json`:39 frozen-source control checks, with both R runtime
  receipts in `aghq-control-evidence.json`; public AGHQ remains unpaid.
- `family-admission-subset.json`:69 source-admission cases, separating19 distinct
  admitted family/link combinations, fixed-shape controls, a Beta alias, rejected
  routes and14 constructor-only families. These are R admission checks, not69
  fitted models or Julia parity passes. See `family-admission-evidence.json`.
- `targeted-replay-6e59ef54.json`: current numerical/helper snapshot's three
  Tweedie power contracts pass28/28; Student31pass/2fail retains the R optimizer
  health failure. No full-suite, recovery, bridge or programme claim.

Required startup also needs exact oracle `build.json` and `source.json` under
`.unlazy/core070-aghq/oracle-receipts/` and `oracle-source/`, respectively. The
loaded GLLVM package root and entry point must equal the checkout being hashed.
Do not hand-create source provenance from a version string.

For future programme acceptance, launch through `core070_targeted_run.py` with
an explicitly reviewed plan and a fresh relative `parity_receipts` directory
on its command row. Retain the supervisor's complete output directory, including
`execution-plan.json`, `process-receipt.json` and raw logs. Pass
`--process-receipt <output>/process-receipt.json` alongside `--receipts` to the
aggregator. Direct invocation above is still a useful developer/diagnostic run,
but a Julia success marker alone no longer satisfies programme acceptance.
The current full-contract checker still rejects DRAFT; aggregation across
separately executed required leaves is the next harness scaling obligation.
