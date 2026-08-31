# Gaussian source-fitting layer: exact contract before implementation

Approved programme: Core070+AGHQ; this is an implementation leaf, not a full
parity-manifest freeze. No new paired-R results or recovery claims are authorized
by this record. Existing frozen reference contracts remain unchanged.

Public API for this leaf:
`SourceCovariance(C,P;name=:source,mode=:latent,rank=nothing,unique=false,common=false)`;
convenience `SourceCovariance(C;groups,...same keywords...)` builds one-hot P.
`fit_gaussian_sources(Y;sources,start=nothing,g_tol=1e-6,iterations=500)`;
result `GaussianSourcesFit`. No unrelated existing API changes. Sources are
fixed known SPD matrices with explicit projections, and may have unequal node
counts. Source C is not put on the trait axis. No automatic jitter/ridge.

Domain: finite complete Y(p,n), p>=1 and n>=2, with at least one trait varying
across units. All-constant responses have an unbounded residual-variance ML
limit and are rejected. These checks do not guarantee identification or an
interior optimum for arbitrary source designs. mu=vec(beta repeated n times):

    S_r=P_r C_r P_r';  V=sigma_eps² I_(pn)+sum_r S_r ⊗ B_r
    logL=-.5*(pn*log(2pi)+logdet(V)+(vec(Y)-mu)' V^-1 (vec(Y)-mu))

Mean beta is optimized jointly, never silently estimated by centering. All
covariance contributions are additive; residual noise stays independent.
Factor V using dense Cholesky. This reference-quality implementation costs
O((pn)^2) memory/O((pn)^3) factorization; it is not the performance solution.

| Symbol | API / coordinates | Unit fixture draw | Returned information | Unit truth |
|---|---|---|---|---|
| beta | first p entries of start | deterministic trait means + known residual vector | beta / coef | explicitly fixed in unit fixture |
| sigma_eps | last coordinate logSD | sigma_eps times deterministic residual | sigma_eps | .7 in density fixture |
| C_r/P_r | SourceCovariance known inputs | chol(C_r) times source innovations / projection | source snapshots | named unequal2/3node matrices |
| B_latent | packed raw lower L, optional diagonal Psi | projected latent L times source innovations | trait_covariances | explicit L in density fixture |
| B_indep | exp(2 logSD), common ties all diagonal entries | independent per-trait fields | trait_covariances | explicit logSD vector |
| B_dep | L L', raw full lower triangular L | full trait covariance source innovations | trait_covariances | explicit nonsingular lower L |

Packing matches existing `pack_lambda` (raw diagonal then strict lower); sign
symmetry remains visible, with positive starting diagonals but no loading ridge
or automatic bounds. Indep(common=true) is equal independent variances, not
one shared scalar random field. Latent unique adds diagonal covariance with
p logSDs (one if common=true). unique is otherwise rejected; common is allowed
only for indep or latent+unique. Rank is explicit for latent, implicit p for dep;
reject irrelevant rank and out-of-range ranks.

Parameter order: trait means; each source's free covariance coordinates in
source order (L pack then unique logSD if applicable); residual logSD. `start`
must have exactly this length and finite values. Default beta=rowmeans(Y),
raw loading diagonals .5, off-diagonals .05, source logSD log(.25), residual
SD=max(std(vec(Y))/2,.1). This is only an initial point, not profiled means.
All attempts retained; no success-only start selection. Optim LBFGS with
ForwardDiff gradients; final fresh objective, gradient and Hessian. Converged
requires Optim verdict AND finite gradient infinity norm<=g_tol. Report the
Hessian minimum eigenvalue and positive-definite flag separately; neither
convergence nor PD Hessian is recovery/identification evidence. No CIs here.

Validation leaf: exact independent rowwise covariance and normalization;
zero source limit; unequal groups; source-order and unit-order invariance;
common versus shared-field distinction; ForwardDiff vs finite differences;
known Gaussian fixed-effects-only fit analytic mean/ML variance; nonconvergence
when deliberately zero iterations; invalid inputs/duplicate names/controls.
No unit test result promotes any required paired-model capability row. Add
full source fitting parity and recovery later after full contract freeze.

Additional unit oracle, declared before execution: one-trait balanced random
intercept, four independent groups with means (-1.5,-.5,.5,1.5), three replicates
with centered deviations (-.2,0,.2), intercept .7. Within-contrast ML residual
variance is .04; group-constant eigenvalue is 3*mean(groupmeans^2)=3.75, giving
source variance 1.25-.04/3. Require intercept/variance errors <=1e-6, independent
eigenspace normalized log likelihood error <=1e-8, fresh gradient <=1e-7,
optimizer convergence and positive Hessian. This is a deterministic analytic
fit check, not a stochastic recovery study or a paired-R capability result.
