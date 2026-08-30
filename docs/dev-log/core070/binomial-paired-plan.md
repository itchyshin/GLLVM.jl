# Six paired binomial link/trial cases — execution pending

This packet moves three unresolved family obligations from an unimplemented
fixture to a runnable, source-bound test definition. It does not freeze the
whole programme or supply numerical evidence. The six seeds and model settings
were written before any data generation; all results remain NOT_EXECUTED.

| Link | Bernoulli seed | Varying trials seed | Native curvature |
|---|---:|---:|---|
| logit |90101|90102|observed (equivalent to Fisher here)|
| probit |90103|90104|observed|
| cloglog |90105|90106|explicit observed; default Fisher remains separate|

Every model has3 traits,160 units,1 standard-normal latent factor,
trait intercepts and ordinary loadings only (unique=FALSE). R generates data
using its own binomial probabilities/RNG, then the exact Y and N are retained
before fitting. Both engines receive the same data. No cases are selected after
seeing fit health. Varying trials use a fixed asymmetric2/5/8/3/6/9 pattern.

The likelihood is the normalized binomial Laplace likelihood with observed
conditional curvature. Checks require relative likelihood agreement1e-6,
raw gradients<=1e-4, independent native central-difference stability<=1e-4,
objective re-evaluation<=1e-8, R logLik=-objective<=1e-10, matching free parameter
count/trial vectors and zero native saturation/clipped-curvature diagnostics.
Loading signs are not compared. No inferred intervals or calibrated recovery
claim follows these six fixtures. R uses the existing unmodified public controls;
failures require diagnosis, never choosing another seed or weakening a gate.

## Execution and compute

`tools/core070_binomial_paired.jl --check CASE-ID` checks the contract without
loading GLLVM/RCall or generating data. `--execute CASE-ID` additionally requires
both parity flags, an actual Totoro hostname, exact installed R provenance and a
fresh receipt directory. Always launch through core070_targeted_run.py with the
current source/environment pins and a600second single-case timeout, never via an
unbounded direct invocation. No remote submission is prepared with guessed runtime
paths. Restore authenticated observation and recover family-recheck-01 first;
then qualify/copy the candidate into a fresh destination.

First planned pre-run: BINOMIAL-LOGIT-BERNOULLI. Provisional estimate2–8min;
resize the remaining cohort from measured timings and link-specific cost.
Six-case provisional12–48min total means a forecast over30min requires the
pre-run result and sized-run approval. Do not silently launch all six from a
single-case approval. No RCall environment or fitting proof was obtained locally.

Raw realized fixture, metrics/check flags, source inventory, installed-oracle
receipts and terminal case/run receipts are retained. Failed checks produce
failed receipts and nonzero exit; the supervisor records actual process status.
A scientific runtime error preserves the fixture and abort receipt. This packet
uses the existing receipt kernel, but is not yet part of the17-ID smoke runner
or the unavailable full-programme aggregate: later integration must bind these
IDs into the complete manifest, without replacing existing required cases.

## Verified now and not covered

26 local preflight assertions pass, including11 malformed-contract tests.
The actual --check route passes. A real --execute command with opt-ins off exits1
with 'required parity mode missing' before imports/fits. Pure syntax is checked;
R macros and the numerical runner have not executed. No dataset was generated.

This does NOT cover shared-X fits, formula/public bridge reach, missing data,
offsets, all covariance combinations, default cloglog equivalence, inference,
recovery or fullsuite. Those obligations stay open. Independent review not run;
full manifest DRAFT and M1 PARTIAL. Relevant production/helper pins are retained
in binomial-paired-contract.toml; preflight receipts in binomial-paired-preflight.json.
