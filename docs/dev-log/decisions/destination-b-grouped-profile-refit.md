# Destination B: grouped Gaussian profile nuisance refits

**Status:** private implementation slice only. This record covers a
fixed-natural-variance nuisance refitter. It adds no likelihood-ratio root,
profile interval, public API, coverage, or recovery claim.

## Symbolic contract

For a selected independent source-trait variance \(v_{s,t}\), the constrained
observed-marginal objective is

\[
 Q_v(\psi) = -\ell\{Y;\, \beta, (v_{u,j})_{(u,j)\ne(s,t)},
                    \sigma_\epsilon\},
 \qquad \psi = (\beta, \eta_{-(s,t)}, \log\sigma_\epsilon).
\]

At every supplied natural \(v\ge0\), the callback minimises every coordinate
of \(\psi\). The selected variance is overlaid by the profile-foundation
adapter; it is never represented by inserting `-Inf` into the ordinary packed
vector. Thus \(v=0\) has no reconstructed selected log-SD, while \(v>0\)
records `log(v)/2` as its selected packed-coordinate interpretation.

| Symbol | Stored representation | Refit treatment |
| --- | --- | --- |
| \(Y,D,Z_s\) | copied fit provenance | fixed and verified against input |
| \(v_{s,t}\) | selected profile overlay | fixed natural value |
| \(\beta\), other \(\eta\), `log_sigma_eps` | reduced packed vector | all re-optimised nuisance coordinates |
| \(Q_v\) | profile foundation objective | finite accepted minimum only |

The full fit is accepted as a reference only if it was converged and a freshly
computed central finite-difference gradient (step
`cbrt(eps(Float64))*max(1,abs(theta_i))`) is at most `1e-5`. Each profile point
retains, in order, a same-side warm start (or an explicit skipped record), the
full-fit projection, and a fixed cold start. An attempt is accepted only when
the objective is finite/non-sentinel, Optim reports convergence, and its own
fresh central gradient meets the same bound. The lowest accepted NLL is the
callback result; all unsuccessful starts remain diagnostics.

The factory returns a `NamedTuple` with `refit`, `baseline_nll`, selected
coordinate metadata, fresh full-gradient diagnostics, and copied baseline
provenance. `baseline_nll` is recomputed from retained full-fit parameters;
stored `fit.loglik` must agree within
`64eps(Float64)*max(1,abs(nll),abs(loglik))`. Each callback receipt explicitly
retains every attempt, the selected reduced minimizer, a separately named
evaluator vector/placeholder, and the fixed natural variance. A requested
gradient tolerance may be stricter than `1e-5`, but never looser. A positive
arbitrary-precision variance that underflows to Float64 zero is rejected rather
than silently becoming the exact-zero profile point.

This is optimizer-local numerical machinery. It is not a global-minimum,
interval, Wilks-calibration, or boundary-coverage assertion.
