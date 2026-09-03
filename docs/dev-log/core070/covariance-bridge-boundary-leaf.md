# Covariance public-R bridge boundary leaf

## Scope and ownership

Ada owns the central manifest, source map, public bridge registry and aggregate
verifier. Hopper provides read-only R-to-Julia admission review. No Julia or R
engine file changes. The frozen reference is commit
`b4d5fee64def88bc768dda1f1f77c29b295edd86`.

## Contract

Exercise the public `gllvmTMB(..., engine="julia")` route for the same nine
Gaussian covariance formulas already qualified through native Julia and Julia
formula interfaces. Record the exact frozen-reference outcome before any Julia
entry point. A rejection or reference adapter failure is boundary evidence; it
must never be reported as a callable bridge fit or same-model parity.

## Runnable gates

`OWNS`: the covariance boundary R/Python helpers and tests, the fourteen-row
public bridge registry, manifest bridge rows, source links and evidence notes.

`CHECK`:

```sh
Rscript --vanilla tools/core070_covariance_bridge_boundary.R
PYTHONPATH=tools python3 tools/core070_verify_covariance_bridge_boundary.py --self-test
PYTHONPATH=tools python3 tools/core070_programme_bridge.py --verify
PYTHONPATH=tools python3 tools/core070_verify_manifest_coverage.py
```

`EXPECT`: nine retained outcomes from the exact installed oracle; eight contain
`GJL-GATE-STRUCTURED-TERMS`, while ordinary `dep()` records the exact early
symbol-to-integer adapter failure. The combined component contains exactly
fourteen public-R IDs: three same-model pairs, two earlier reference boundaries
and these nine covariance boundaries. The draft-integrity gate passes while the
full programme remains `DRAFT_INCOMPLETE_NOT_FROZEN`.

`SOURCE/ENVIRONMENT`: frozen source, namespace, archive, installed-tree marker,
R library search path, R version, one-thread environment and complete supervisor
receipts are hash-bound. The Julia source path is poisoned for the nine boundary
calls so any unexpected bridge admission fails rather than reaching an unrelated
checkout.

`TIMEOUT`: five minutes for each bounded Totoro replay; 480 seconds for the
three-model public bridge batch. No DRAC job and no campaign.

`FAILURE ACTION`: retain every failed attempt and its logs. Fix missing runtime
dependencies or verifier assumptions without changing the frozen R source. If a
formula reaches Julia, stop and define a transported structured-covariance model
contract before treating it as parity.

## Negative controls

The verifier must reject an omitted case, changed outcome, wrong gate, altered
source pin, changed installed marker, missing receipt, nonzero process status,
unretained failed attempt or stale combined registry/manifest. Native and Julia
formula rows alone must still fail the public bridge role requirement.
