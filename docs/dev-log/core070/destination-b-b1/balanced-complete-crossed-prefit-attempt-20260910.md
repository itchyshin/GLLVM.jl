# B1 balanced complete-crossed pre-fit attempt — 2026-09-10

The external frozen-R provenance preflight had passed. The following command
then stopped before package load or `gllvmTMB()` because its runner reported
`Refusing to overwrite an existing B1 receipt.` No JSON receipt exists at the
requested target, and no optimizer was reached.

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 \
  Rscript --vanilla tools/destination_b/b1_balanced_complete_crossed_control.R \
  --source /private/tmp/destination-b-b1-r070-rebuild \
  --library /private/tmp/gllvmTMB-frozen-r070-b1-library-20260910 \
  --data docs/dev-log/core070/destination-b-b1/balanced-complete-crossed-input-20260910.csv \
  --output docs/dev-log/core070/destination-b-b1/balanced-complete-crossed-control-20260910.json
```

Raw output: `balanced-complete-crossed-control-20260910.log`.
The maintainer authorized one fresh, absent JSON target for the unchanged first
control because the command above never entered the fit call.
