# Structured reference preparation contract

Frozen R b4d5fee64def88bc768dda1f1f77c29b295edd86; 2026-08-31.
This is preparation evidence before MakeADFun, not an objective evaluation,
fit, recovery study, native Julia implementation or complete scope freeze.

The frozen 24-call inventory gives eleven prepared requested models, twelve
rejections, and one prepared model that loses requested parameters. The latter
is BLOCKED_REFERENCE_PARAMETER_LOSS: two named kernel_latent(unique=TRUE)
terms silently lose their automatic Psi companions. Captured data, parameters,
maps and random list exactly equal the unique=FALSE call. Explicit kernel_unique
instead rejects. Do not port silent loss; require an accepted explicit Julia
rejection or a documented model extension. R remains a read-only frozen oracle.

## Source matrices and observation maps

The tree ((a:1,b:1):1,c:2) is correlation-scaled by height 2. Its non-root
internal node precedes tips a,b,c. Sparse precision is
Q = [[6,-2,-2,0],[-2,2,0,0],[-2,0,2,0],[0,0,0,1]].
logdet(A)=-log(8), four random scores, and observation indices 1,2,3
(zero-based) repeated for the corresponding observed species. Root is fixed,
not another random node. No dense jitter is added on this sparse path.
Source: R/phylo-tree-precision.R:198; R/fit-multi.R:3794.

Dense phylo and single named kernel use A=C+1e-8I, C=.7I+.3J;
three tip-only scores, observation indices 0,1,2. The verifier independently
uses Sherman-Morrison for inverse and determinant. These are different source
covariances from this tree; comparison here is of transformations, not an
assertion that their fitted models coincide.

Tree phylo_scalar is a deprecated compatibility alias. It uses propto with
three independent trait fields, not one shared scalar field. Tip correlation
Ctree=[[1,.5,0],[.5,1,0],[0,0,1]] receives 1e-8I. One loglambda_phy scales
all three covariances by exp(loglambda_phy), a log-variance parameter. A future public surface should teach phylo_indep(common=TRUE).
Source: R/fit-multi.R propto preparation; src/gllvmTMB.cpp propto prior.

Pedigree a,b founders, c,d full siblings retains all four pedigree nodes even
though only c,d occur in data. Q=[[2,1,-1,-1],[1,2,-1,-1],[-1,-1,2,0],
[-1,-1,0,2]], logdet(A)=-log(4), observation map 2,3. Public calls with a
missing parent or a cycle reject, but expose a generic missing phylo_vcv/tree
message rather than the underlying pedigree error. This does not verify clear
pedigree diagnostics. Source: R/pedigree-precision.R and R/fit-multi.R:3820.

All rank-one loadings have three raw free coordinates, not log-diagonal
loadings. Single kernel unique adds three log_sd_phy_diag coordinates and a
3x3 random companion. Two named kernels have separate rank-one score vectors
packed into length six with offsets 0,3; six raw loading coordinates. Each K
gets 1e-8I before inversion. K2=.6I+.4vv', v=(1,-1,1). The inverse tensor
is tier-first [2,3,3]; kernel_has_diag=[0,0]. Component identification and
recovery remain untested. Source: R/fit-multi.R:3620 and src/gllvmTMB.cpp.

## Spatial contract

Qualified mesh: fmesher0.8.0,35nodes,12x35 projection from the exact long data.
The realized mesh RDS is reused, hash-bound and retained. For every prepared
spatial call the projection and c0/g1/g2 matrices equal the qualified fixture.
Tests check dimensions, finiteness, symmetry and projection row sums.
Public mesh is a top-level gllvmTMB argument; coords is a formula placeholder.
Raw mesh and wrong observation-row count reject.

Qbase=kappa^4 M0+2 kappa^2 M1+M2, kappa=exp(log_kappa_spde).
Independent trait field precision is tau_t^2 Qbase, tau_t=exp(log_tau_spde[t]).
common=TRUE ties the three log_tau entries to one level, preserving three
independent fields. Latent scores use Qbase with tau=1; raw triangular
loadings carry scale. Rank1 has three loading coordinates, rank3 dependent
mode six. unique=TRUE adds independent per-trait fields with three log_tau;
otherwise these fields and their tau parameters are mapped off. All keep one
free kappa and one Gaussian residual coordinate. Spatial scale is not simply
a marginal SD: Qbase also determines field variance. Source: src/gllvmTMB.cpp:2182.

Captured random shapes: indep/common35x3; rank-one latent35x1; latentPsi both;
dependent35x3. The supplied unused cluster argument warns on all five spatial
calls. This warning is retained, not mistaken for a fitting failure.

## Evidence and outstanding work

Qualification passed in1.016s. Capture01 failed in0.666s before the inventory
ran because the fixture needed explicit Matrix method loading. Capture02 ran
all24 in1.316s but four expected diagnostic strings differed. Capture03 passed
all24 in1.317s. All attempts, logs, sources and realized inputs are retained.
There was no optimizer or likelihood execution. No tolerance was widened.

Required native/formula/bridge calls, same-model fitting, negative cases,
identification/recovery, non-Gaussian crossings, slope variants, adapters and
post-fit inference remain unpaid. This inventory supplements the source map;
it is not the exhaustive Core manifest. The parameter-loss case requires an
explicit reviewed disposition before any completion claim.
