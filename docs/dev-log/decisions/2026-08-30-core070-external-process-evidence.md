# Bind parity acceptance to the externally observed process exit

Status: implemented and pure process-regression tested; full programme contract
remains DRAFT. No new model fit or full-parity claim.

A Julia-written successful run receipt cannot prove Julia subsequently exited
successfully. Shutdown can fail after the last assertion. The parent process
must observe the exit and bind it to those exact artifacts (Rose repair review).

A reviewed targeted-run command may now declare
`"parity_receipts": "relative/fresh-directory"`. The supervisor rejects existing,
duplicate, escaping or symlinked destinations before launching anything. It sets
that directory in the child's required-parity environment, captures actual exit
and raw log, then hashes run/cell/oracle receipt files after the child exits.
The output retains an exact `execution-plan.json` alongside `process-receipt.json`.
A successful process with missing required parity artifacts is not a passing batch.

The final aggregation command now also requires
`--process-receipt PATH/process-receipt.json`. It checks batch completeness,
observed exits, source freshness, the retained plan, all execution-inventory pins,
raw-log hashes and the precise output receipt hashes. Exactly one process must
bind the run under review. Paths recorded on the execution host remain provenance;
the same verified directory can be copied locally and validated without retaining
the remote mount layout. The loaded Julia root still must match the execution plan.

Regression coverage uses actual short Python child processes, without fits:

- successful child and portable readback pass;
- internal success followed by exit7 fails;
- externally observed nonzero exit fails through the public aggregation entry;
- missing process proof, changed source pins/plan/outputs/logs fail;
- pre-existing receipt directories launch no child;
- prior malformed-timeout and supervisor exception cleanup checks remain green.

The contract-content and numerical-verdict tests are separate; their unit fixtures
must not be presented as programme acceptance. Existing6e59ef54 targeted numerical
receipts retain their earned meaning and raw observed exits, but do not acquire
the new automatic process binding retroactively. No repeat fit is needed solely
to restate those already read-back targeted results. Future programme evidence
must use the new schema.

The programme must eventually combine separately executed required leaves with
consistent source/environment/contract pins and exact required-ID coverage;
a single25-minute batch is not a schedule for the entire capability programme.
The current full-contract checker still expects one complete run. Supporting
that multi-run aggregation is an explicit remaining A3 obligation, not a reason
to narrow or omit required capabilities.
