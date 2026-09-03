# Branch-RE review correction: auxiliary conditioning is not model admission

Rose's four-tip counterexample has a well-conditioned marginal covariance but
an ill-conditioned branch precision. A precision condition bound therefore
selects a computational representation; it must not turn a valid model into an
infinite objective. This supersedes the rejection policy in the earlier A4 note.

For D = sigma2 diag(ell), retain exactly S = Z D Z' + noise I.
When the sparse precision cannot safely represent the trial, factor
B = S / s, with s = max(sigma2, noise). The same profiled likelihood follows:
mu = (1' B^-1 y)/(1' B^-1 1),
2 nll = p log(2pi) + log|B| + p log(s) + r' B^-1 r / s.
The branch posterior mean is (sigma2/s) diag(ell) Z' B^-1 r.
Centering y before profiling is an exact translation and avoids large means
obscuring residuals. No ridge, tolerance widening, or data/model change occurs.

Both public profile and BLUP paths use the same representation decision.
Non-finite, zero, and negative variances remain invalid. Positive subnormal
noise is not invalid solely because its reciprocal overflows: the marginal
representation can still evaluate the model correctly. Invalid BLUP inputs
raise DomainError (or ArgumentError for a response-length mismatch).

The fallback is dense in the number of tips and can be slower or use more
memory on large trees. Emit a bounded warning when it is selected; do not
include these cases in an unqualified sparse-performance claim. Optimizing
this rare path through another sparse representation is separate work.

Regression before implementation: the exact four-tip comparison checks dense
likelihood, profiled intercept, and BLUP identity at (1e6,1e-6) and
(1,1e-320), plus invalid direct BLUP inputs. Fresh Totoro red/green receipts
are required. This does not by itself reproduce the original Julia1.12.7 CI
failure or establish cross-platform health.


## Targeted evidence

Totoro Julia1.12.6, one Julia/BLAS thread: the regression on candidate d1caddc9
failed with2pass/5fail/1error (exit1). After the representation repair it passed
13/13, and the original branch-RE file passed44/44 (exit0). The count falls from
48 because rejection-only assertions for two valid marginal models were replaced
by dense-reference equality checks in the new file; invalid-domain tests remain.
Raw logs/exits and tested hashes are retained under
`.unlazy/core070-aghq/A4-review/`. Source commentary was subsequently corrected;
the numerical source and these tests still need the final integrated replay.
