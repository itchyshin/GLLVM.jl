# Original Gaussian native and formula cases

Two source-bound cases now run through `test/parity/runparity.jl`:

- `CORE070-FAMILY-00-IDENTITY-NATIVE-MODEL`
- `CORE070-FAMILY-00-IDENTITY-FORMULA-INTERFACE`

They share one execution and must be requested together. The original
`NATIVE-01-GAUSSIAN` smoke case remains unchanged; these are additional model and
interface obligations, not replacements or additional response families.

The retained fixture is the original `CORE070-AGHQ-K1-GAUSSIAN` row from the
admission work: seed 81031, four traits, 120 sites, one factor, zero mean.
`test/parity/fixtures/core070_gaussian_original.toml` is copied byte-for-byte from
that retained file (SHA256 `52a4664c99295ec675a7b666458350bf57ff57e338c77d5ada1cf9d2e5efba92`).
The reference helper is copied from this lane's `tools/core070_default_unique_reference.R`;
its public call targets frozen R commit `b4d5fee64def88bc768dda1f1f77c29b295edd86`.
No R engine code was changed or imported into the Julia engine.

The same-model contract is explicit: triangular loadings, per-trait unique
variances, fixed residual SD `max(0.001sd(vec(Y)),1e-6)`, no mean coefficients,
no penalty, exact Gaussian marginal likelihood including constants. R's four
unique log-SD coordinates correspond to half Julia's log-variance coordinates.
The native fitter uses an explicit empty fixed-effects design. Wide and reversed
long formulas use `y ~ 0` with `pervar=true`. Missing or duplicate long rows reject.

With the pinned R/Julia environment qualified, run:

```sh
GLLVM_PARITY_TESTS=1 CORE070_PARITY_REQUIRED=1 \
CORE070_PARITY_CASE_IDS=CORE070-FAMILY-00-IDENTITY-NATIVE-MODEL,CORE070-FAMILY-00-IDENTITY-FORMULA-INTERFACE \
julia --startup-file=no --project=test/parity test/parity/runparity.jl
```

This command alone is not a complete evidence receipt: the bounded supervisor
also captures the exit code, source/environment pins, logs, and oracle checks.
The retained plan is under `.unlazy/core070-aghq/gaussian-required-02/`.
`python3 tools/core070_verify_gaussian_required.py --self-test` verifies that run
against current execution inputs and tests corrupted receipts.

The final run passed 31 assertions in 32.80 seconds on one Totoro core. The
registry separately passed 28 checks in 3.88 seconds. Absolute log-likelihood
difference is `3.8641e-9`; maximum absolute gradients are `1.5420e-10` in Julia
and `4.4453e-5` in R. Direct and both formula fits agree. This is one retained
model, not recovery or coverage evidence.

The master mapping binds these two executable cases to `family/FAMILY-00-IDENTITY`.
That family still lacks its required public R-bridge case. The family-plan generator
records registration separately from numerical evidence in `gaussian-required-evidence.json`.
`validate_family_roles` continues to reject full-family certification, and the full
manifest remains `DRAFT_INCOMPLETE_NOT_FROZEN`. Other covariance, missingness,
post-fit and inference requirements remain separate. Earlier receipts are historical;
shared runner and contract changes require fresh replay before reusing their claims
on this integrated candidate.
