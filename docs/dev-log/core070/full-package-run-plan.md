# Core070 full-package checks — prepared, awaiting run approval

Scope: full registered Julia test suite, not full R parity or recovery/coverage.
Numerical candidate: fb92866759c96b18a88456a3389c7485b7d5bc98. Later records-only
commits do not change this source pin. Protect all foreign checkouts.

## Pre-run evidence
Totoro Julia1.12.6, one Julia/BLAS/OMP thread. Fresh merged package/test environment
resolved in3.73s. Actual repository quality test:12/12 in72.25s including compilation;
packing/source-kernel/source-fitter subset:194/194 in24.52s. No skips or failures.
Aqua0.8.16, JET0.12.1, Optim1.13.3, ForwardDiff0.10.39. Exact environment and source
hashes are in package-qualification-evidence.json and retained raw receipts.
Six verifier negative controls reject incomplete or false success evidence.
This pre-run checks loading, package hygiene, selected kernel type stability and
joint source tests; it cannot forecast the full fitting/interval workload precisely.

## Proposed full runs
Two independent immutable execution directories on Totoro, one process/thread each,
maximum two CPU cores total. Existing shared-server usage must leave room within150.
Estimated85–100minutes per suite from retained programme allowance; plan120minutes
hard timeout per suite, approximately two hours elapsed if run concurrently.
Read memory use and host load before launch; no GPU, no DRAC allocation or scientific
campaign. A timeout is a retained failure/incomplete result, never a success.

1. Core: Julia1.12.6 `--startup-file=no --project=. test/runtests.jl`.
2. Full: Julia1.12.6 `--startup-file=no --project=. -e 'using Pkg; Pkg.test(;allow_reresolve=false)'`.

Before either full command, prepare the root and test environments in a bounded
setup phase, record all resolved package versions and assert the loaded GLLVM path.
Do not copy an absolute-path Manifest pointing at the qualification directory into
another candidate. Pin and compare dependency versions to the pre-run; a changed
numerical dependency requires requalification. The full runner must fail if Aqua
or JET is skipped. Core-only optional quality skips are reported separately.

Archive the complete tracked source tree, including docs/dev-log/core070 files used
by registry tests and tools used by source-binding tests. Preserve source archive,
source hash census, command/environment pins, full stdout/stderr, timestamps, exits,
summary counts, failures, process cleanup and environment readback. Supervise each
process group with a120minute deadline; never kill unrelated processes. No automatic
restart after an observer disconnect: inspect the existing process/job handle first.

## Acceptance and limits
Both commands exit0, exact source unchanged, every registered test file accounted for,
no required quality skip, and all failure/error counts zero. Retain broken/optional
cases explicitly; a passing suite does not discharge those parity obligations.
Do not remove or weaken failed assertions, retry with selected seeds, or infer recovery
from an optimizer/Hessian check. Record exclusions in the existing runner, including
currently unwired phylogenetic tests, as separate unpaid coverage.

Run approval is pending: user was asked for these two Totoro runs with the stated
resource and timeout limits. No full-suite process has been launched. The approved
programme's over30minute run rule requires that approval; safe manifest and code work
can continue meanwhile. No push, merge, release or destructive cleanup.

## Candidate update after fixed-residual work
The later fixed-residual Gaussian change supersedes fb928667 for future current-
candidate validation. Use the exact source hashes retained in default-unique-
evidence.json and the refreshed package-qualify-02 environment; do not report a
full run on the earlier source as validation of this change. Commands, two-core
budget and120minute limits are unchanged. Run approval is still pending.
