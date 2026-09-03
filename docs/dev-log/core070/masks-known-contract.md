# Loading masks and known covariance: frozen-reference findings

Seventeen cases exercise real public R calls at the frozen 0.7.0 commit.
Nine reach MakeADFun preparation, eight reject before it. Eight Gaussian
models receive two fixed-point checks each. The ninth prepared model uses
Poisson and known Gaussian log-predictor effects; it has no density/fit claim.
The full programme manifest remains DRAFT, and all native/formula/bridge
counterparts remain unpaid. These are reference contracts, not Julia parity.

The ordinary and animal rank-two loading vector has five raw coordinates:
L11,L22,L21,L31,L32. Fixing L11=.8 and L32=0 leaves three free coordinates.
The upper-triangle entry L12=99 has no effect: its entire captured input is
identical to the same case without that entry. All-fixed loadings leave zero
free loading coordinates but retain z_B as a random effect. The residual SD
remains free in these unique=false Gaussian models. Raw loading coordinates
are not guaranteed identified: in particular, sign symmetries may remain for
unanchored columns. No optimizer, recovery or covariance-decomposition claim.

An animal_indep term supplies its own diagonal mask and rejects a user mask.
Wrong mask dimensions, non-matrix masks and augmented ordinary latent slopes
with B masks reject. The latter is a limitation of this frozen reference,
not permission to silently strip the constraint in Julia.

meta_V and its legacy meta_known_V alias prepare identical inputs when a full
known_V matrix is supplied. The marker does not transfer the matrix by itself.
Missing, incorrectly sized and list-valued matrices reject on this multivariate
path; proportional scaling is not implemented. Documentation suggesting a
list of blocks does not establish admission here.

The known matrix enters as a Gaussian predictor effect with fixed covariance
V+1e-8I. For Gaussian identity responses it adds directly to sigma^2I.
For Poisson it describes log-predictor effects, not response sampling errors.
Zero V is therefore admitted with a tiny nonzero covariance. This does not
establish validity for arbitrary indefinite, asymmetric or nonfinite inputs.
The block_V fixture independently checks noncontiguous study row groups,
heterogeneous diagonal variances and within-study correlation .25. Remaining
block_V utility error branches are not covered by these seventeen calls.

First capture attempt failed three exact diagnostic-string predicates;
actual admission outcomes were unchanged. Retained first-run source and logs
show those failures. Only diagnostic strings were corrected for replay.
Final capture:17/17; Gaussian fixed points:16/16. Maximum absolute normalized
nll difference 2.273736754e-13; maximum scaled central-FD discrepancy
3.810410862e-9. Mean-shift controls and dropping nonzero known covariance fail
their matching threshold as intended. All checks used one-thread Totoro;
capture1/2 elapsed1.166959/1.167180s, points elapsed0.916852s.

Source census gains17 explicit obligations (752→769; nonexcluded698→715).
Each has a reference call, owner and reference-evidence link. These links are
not executable Julia case IDs: native fitting, same-model health, supported
inference, formula and bridge reachability still prevent full manifest freeze.
