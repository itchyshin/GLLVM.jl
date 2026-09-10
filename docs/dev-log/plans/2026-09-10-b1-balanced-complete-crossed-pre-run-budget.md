# B1 balanced complete-crossed — pre-run budget

This is not execution authority. The one future frozen-R control is estimated
at **45 minutes** with a **60-minute stop budget**: 3,600 wide rows are twenty
times the retained 180-wide-row candidate and have no direct timing evidence.
Because it exceeds 30 minutes, an approved pre-run check is required. It was
not run here. At 60 minutes, or on either failure of `convergence == 0` and
`max(abs(gr)) <= 1e-6`, stop; no reseed, restart, or tolerance relaxation.

The estimate remains unapproved. Before any future run, the frozen provenance
preflight must pass against the pinned source/library/reference-runner mapping;
that preflight itself is not a fit and was not run in this repair.

## Authorized execution outcome

The external preflight later passed. The two no-fit output-guard failures
consumed no model time and left no result JSON; a hard-stop timer was present
for each proposed control. They do not authorize a replacement invocation.

The output-guard repair has been static/pure-tested only. The revised runner is
awaiting independent predicate review; no execution estimate is consumed and
no control may launch without a new direction.
