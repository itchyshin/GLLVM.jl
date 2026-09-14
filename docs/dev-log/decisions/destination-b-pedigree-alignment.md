# Destination B pedigree ancestor alignment

Scope: Gaussian rank-one animal_latent with shared observation residual,
frozen gllvmTMB0.7.0 at b4d5fee64def88bc768dda1f1f77c29b295edd86.
This begins with a precision/identity fixture, not model admission or recovery.

## Fixed pedigree and independent construction

Twelve individuals are ordered parents before offspring. Individuals1–4 are
unobserved founders. Parent pairs for5–12 are (1,3),(1,3),(2,4),(2,4),
(5,6),(7,8),(9,10),(9,6). Observed order is12,5,9,7,10,6,11,8,
deliberately not precision row order. Each observed individual has two
replicates and three traits in the later model fixture.

Let a_i=.5*a_s+.5*a_d+sqrt(D_i)*e_i for known parents, with independent
standard normal e_i. Founders have D_i=1. With two parents,
D_i=.5-.25*(F_s+F_d), where F_i=Var(a_i)-1. Construct coefficients C
sequentially from this generative equation; A=C*C'. This independent oracle
does not call the R tabular relationship builder, invert R Q, or use Julia's
phylogenetic likelihood. B=I-H, with parent coefficients-.5, gives
Q=B'*Diagonal(1 ./ D)*B. Require R Q=A^{-1} through the identity Q*A=I,
and logdet(Q)=-sum(log(D)). These are small-fixture calculations only.

The old sketch in phylo-transport-design.md section3 refers to the example
in frozen R/animal-keyword.R:63–67. That example mates unrelated founders only:
two founder pairs do NOT imply nonzero inbreeding. This fixture adds explicit
related-parent matings; F_9=F_10=.25 and at least one later F is positive.

## Transport and model identity

Frozen R's .resolve_sparse_phylo_precision keeps the full Q when observed
labels omit ancestors (R/fit-multi.R:633–680). Its determinant covers all12
nodes; observed map indexes those retained nodes. Julia consumes that Q and
map unchanged. No dense-vcv ridge and no second scaling/inversion apply.
Marginal observation covariance is V=(P*A*P') kron (L*L') + sigma_eps^2*I,
with trait-fast vectorization. Dropping founders from Q would CONDITION on
their values, not marginalize them; the negative test must distinguish this.

Initial checks require actual frozen R precision, nonzero inbreeding,
nontrivial tip order, full-node determinant, repeated-label mapping and a
wrong ancestor-drop control. Fitted pairing, intervals, public bridge
admission and retained recovery remain separate subsequent gates.

## Frozen direct-Ainv formula boundary

First fitted attempt on2026-09-07 (61755) failed before optimization when using
animal_latent(species,d=1,Ainv=Q,unique=FALSE). A separate parser diagnostic1286
proved that frozen brms-sugar.R rewrites Ainv into an unqualified private helper
.gllvmTMB_maybe_keep_sparse_ainv(Q). In the user formula environment this raises
function-not-found; parse-multi-formula.R:282 retains the unevaluated expression,
so fit-multi.R's matrix harvester does not obtain Q. The frozen source is NOT
changed. The next attempt uses exported pedigree_to_Ainv_sparse through the
public pedigree=ped route and requires exact same canonical engineQ. It does
not qualify direct Ainv syntax, which remains a separate recorded failure.
