# Six paired binomial link/trial cases — first pre-run retained

This packet moves three unresolved family obligations from an unimplemented
fixture to a runnable, source-bound test definition. It does not freeze the
whole programme or supply numerical evidence. The six seeds and model settings
were written before any data generation; the original declaration records NOT_EXECUTED before data generation. Current results are recorded separately below; those frozen declaration labels are not live status.

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

## First execution — 2026-08-30

Current Julia1.12.6/RCall/frozen-R runtime qualified on Totoro after correcting missing Test/LinearAlgebra imports in the qualification command. Source fingerprint refreshed only for the repaired helper; models, seeds and acceptance rules unchanged.

BINOMIAL-LOGIT-BERNOULLI seed90101 completed in23.53s:13 checks passed,1 failed. Native logLik−322.7456004572379, R default−322.7456004609432; native raw FD gradient2.8422e-8, R raw gradient2.85818e-4 exceeds the unchanged1e-4 gate. Both report convergence, all remaining checks pass. Required result is FAIL, not partial success by likelihood alone.

Separate10-second R diagnostic replayed the exact retained fixture and post-DGP RNG state. Public start_from plus optArgs(control=list(rel.tol=1e-12,eval.max=2000,iter.max=1500)) preserves data/map/parameter names. R gradient improves to1.44901e-5, logLik−322.7456004572691, code0. This qualifies the stopping-tolerance diagnosis; it does not replace the failed default-control receipt. No other five cases were executed.

Next: explicitly qualify reference optimizer precision for the same models while retaining default-control results and fixed gates, then size remaining link-specific checks. A single23.5-second logit fit does not measure probit/cloglog costs. No whole-cohort runtime or broad performance claim follows. See [source-bound evidence](binomial-prerun-evidence.json).
