# Height-four tree precision precursor

Frozen R export `precision-reference.json` retains fourteen root-dropped
nodes, eight observed tips in shuffled order and six marginalized internal
nodes. SHA256: ab01ee47206565eb1af7da391af313953b8a97c6bb11d9b6160655aaa0429170.
The R correlation precision is exactly four times its native precision;
non-ultrametric correlation input is rejected. Export session 67459 exited 0.

The independent Julia path-covariance and marginal-consumer check is in
`test/test_destination_b_tree_precision.jl`. Session 22144 exited 0 with
19/19 assertions passing in 3.3 seconds. Wrong physical scaling, wrong
observation mapping and conditioning on internal nodes are discriminated.
No fitted, interval, recovery,
adapter-admission or Destination B qualification is implied.

## Fitted follow-on — bounded evidence, not admission

The public frozen R tree route preserves the exact fourteen-node precision,
determinant, observation/trait mapping and seven active parameters. Original
nlminb attempt37237 returned status1 (singular convergence), gradient7.495e-6;
it remains unsuccessful. Independent Julia fit65969 starts from its own
defaults, converges in25iterations with gradient3.961e-6, and returns all12
displayed Wald rows (10distinct targets). Marginal condition122.9505;
fit0.113s plus intervals1.678s excludes startup. These are feasibility
diagnostics for this one dataset, not coverage evidence.

Predeclared same-data public R BFGS87715 converges with status0 and
gradient6.585e-7. Its NLL12.750923971504491 differs from retained Julia
12.750923971504555 by approximately6.4e-14. Same-point cross-evaluation9517
differs1.066e-14. Checker2580 passes27/27 assertions, including twelve
corruption controls and checks preserving the unsuccessful baseline.
No Julia refit or R engine edit. R interval pairing and review remain open.

SHA256 receipts (original bytes retained):

- r-fit-attempt-01.json: f702a7859980e29f59b19bee8878171df385ef9bd581dc338520055f0f140223
- r-bfgs-attempt-01.json: 08c2c0f8dca3bb601e716da30d64dae2cd0ce3834766fa557dabb0444ddf4bd7
- independent-attempt-01.json: 681a751f1298fc729218b37c999572e001bc5aba9bcf9e0a37877de40b5294dc
- bfgs-comparison-01.json: 23d25a42fc2ac4243d3e2d977f89cd905117acb4b66a2583fde75d06d18040f3

External review still awaits scoped transmission approval. S3b/S4 admission,
paired intervals, retained recovery and full/core suites remain incomplete.
