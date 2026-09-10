# Frozen-R Gaussian phylogenetic pilot receipts

Scope: one three-trait, eight-tip, two-replicate Gaussian dense-vcv model,
rank-one phylogenetic loadings only, shared residual SD. Reference source is
gllvmTMB0.7.0, commit b4d5fee64def88bc768dda1f1f77c29b295edd86.
This records likelihood cross-evaluation and one independent Julia fit with
feasible intervals. It is not paired R-interval/recovery qualification, S4
completion or public bridge admission.

## Retained attempts

- `r-attempt-01.json`: retained rejected transport metadata. Missing gradient
  serialized as an empty object; counts also empty. Do not pass this artifact
  by weakening schema validation. SHA256
  `0c4a234b1b5722203f18b003dc60a8274d2ea5b09f0c776e9172f180ac08cef7`.
- `r-attempt-02.json`: corrected NULL serialization and actual optimizer counts.
  Response, matched values/objective and fitted values/objective are identical
  to attempt01 (fresh R `identical` assertions). SHA256
  `5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f`.
- `comparison-attempt-01.json`: actual Julia1.10.0 cross-evaluation of attempt02.
  Matched absolute difference0; R-fitted-point absolute difference
  1.0658141036401503e-14, against unchanged1e-6 threshold. The durable text copy
  adds a terminal newline only: SHA256
  `0bc3583f2967a190d286d5b182372d05a257e026c2147d64e7ff1f5942c1e0e2`;
  original ignored receipt SHA256
  `507100d8ce90446b322be4e0e7e6f7beecb954a42f3026ffcc00a5b7d8b91df2`.

The two R copies preserve original byte hashes. Original attempt RDS/logs and
the comparison remain in `.unlazy/destination-b-s3b-pilot/`. The synthetic
checker suite passed41/41 in6.1s before comparison, rejecting wrong provenance,
response hashes, maps, ridge/scale/covariance, determinant and objective values.
No failed attempt was removed. The exact DLL build receipt is
`../../decisions/destination-b-frozen-r-build.md`; source schema and runners
are described in `../../decisions/destination-b-phylo-gaussian-reference-schema.md`.

Machine-local paths in receipts document execution provenance, not portable
installation requirements. A fresh platform build needs its own authenticated
build receipt; version0.7.0 alone cannot substitute for the pinned source.
Independent source review remains pending approval for external transmission.

## Independent Julia fit

`independent-fit-attempt-01.json` retains an error before optimization: the
standalone runner lacked its `Distributions.Normal` import. No fit result is
inferred from that attempt. SHA256
`f2cbe4dafe276e45e996c04cc95337e221a165fd43b0c2481b34190462b33969`.

`independent-fit-attempt-02.json` uses the same response, model, and Julia
default initialization after that import repair. It converged in25iterations,
with gradient infinity norm1.6867523167504743e-6. The independent fitted NLL
differs from R by-2.4076740601230995e-11; largest absolute fixed-effect and
phylogenetic covariance differences are2.392495413727769e-7 and
1.7018479564478994e-7. The fit took1.294821375s; intervals1.6385815s,
excluding process startup/compilation. These timings describe this tiny shape,
not a campaign estimate. SHA256
`712498737bd4f15998ffe294dacfde5a97fee1afb1b23160d7c1a6a204cc9b5e`.

All12 displayed Wald interval rows are available, with condition249.2738756.
They represent10distinct targets: three fixed effects, six rotation-invariant
phylogenetic covariance entries, and one shared residual variance repeated
for each trait. This is interval feasibility for one dataset, not evidence of
nominal coverage. The receipt keeps qualification=false. Both independent-fit
copies preserve original hashes. Pure receipt tests18/18PASS, with the actual
fit separately invoked and retained; a skipped opt-in test is not counted as
a fit pass. A fresh retained-output check verified finite ordered endpoints.
