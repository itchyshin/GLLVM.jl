# Random slopes: actual frozen-R preparation

This reference-only annex distinguishes12 requested models prepared,8 rejected
calls and2 animal multi-slope misroutes. No objective, optimizer, slope density,
recovery, native Julia, formula or bridge parity is established. Full manifest
remainsDRAFT; native call design and numerical acceptance fixtures remain unpaid.

| Route | Covariance coordinates | Free covariance count, p3 |
|---|---|---:|
| Ordinary latent d2 | raw triangular L over6 interleaved coefficient rows | 11 |
| Ordinary latent d4 | raw triangular L over6 rows | 18 |
| Ordinary latent default Gaussian | above plus6 log-SD Psi coordinates | 17 |
| Animal latent d2 | two separate raw p3-by2 loading blocks | 10 |
| Animal independent, single bar | log-diagonal Cholesky; independent2-by2 trait blocks | 9 |
| Animal independent, double bar | same packing, all off-diagonals pinned zero | 6 |
| Animal dependent, single bar | log-diagonal full6-by6 Cholesky | 21 |
| Animal dependent, double bar | zero intercept/slope cross-block entries; separate full trait covariances | 12 |
| Phylogenetic dependent, two slopes | full9-by9 log-diagonal Cholesky | 45 |

Ordinary latent slopes have coefficient order(intercept_t,slope_t), t=1..3,
and Z_B_lat selects1,x in the relevant pair. Their covariance L L' can include
intercept/slope association. Default Gaussian adds diagonal Psi and keeps a
free residual SD; unique=false omits Psi. Poisson suppresses the default Psi
with an explicit warning; explicit unique=false is loadings-only without that
warning. The two resulting prepared parameterizations match. Raw loading
diagonals are not exponentiated; sign/rotation and variance-split identification
still require separate fitting design, particularly at high rank.

Structured latent slopes instead use independent p-by-d matrices L0,L1:
Cov(eta_o,eta_v)=C[g_o,g_v]*(U0[t_o,t_v]+x_o*x_v*U1[t_o,t_v]),
Uj=Lj*Lj'. There is no intercept/slope cross term in this route. Default and
explicit unique=false prepare identically here; no ordinary default-Psi
assumption transfers to it. Structured d must not exceedp, whereas ordinary
augmented d may reach2p. The captured animal matrix is C_input+1e-8I.

Dependent structured coefficients have interleaved (intercept,x[,x2]) within
trait. Cholesky packing is diagonal first, then strict lower columns; the
diagonals are exp(theta), off-diagonals raw. Single-bar independent leaves a
correlated2-by2 block per trait; double-bar independent sets within-trait
intercept/slope covariance to zero too. Double-bar dependent retains full
cross-trait intercept and slope covariance, with zero cross-basis covariance.
The12 valid preparations retain three fixed trait coefficients. Gaussian
retains one residual log-SD; Poisson has no free residual log-SD.

## Confirmed reference defects and rejected routes

Ordinary indep/dep wrappers reject augmented slopes, even though related
source-specific engines implement them. Both bar couplings have explicit
wrapper diagnostics. Ordinary rank7 exceeds2p=6; structured rank4 exceedsp=3;
ordinary augmented and intercept latent terms cannot share the unit tier.

`animal_dep(1+x+x2|species,A=C)` uses the single-slope LHS classifier and falls
through to the intercept-only rewrite (R/brms-sugar.R:3251–3276). Both Gaussian
and Poisson reach preparation with use_phylo_dep_slope=0,use_phylo_rr=1,g_phy
and6 free intercept loadings. These are BLOCKED_REFERENCE_MISROUTE cases,
not supported multi-slope models. Do not silently drop terms in Julia to match.
The exact theta_rr_phy map is NULL, correctly leaving those6 coordinates free.
An early diagnostic used R dollar partial matching and read theta_rr_phy_slope's
inactive stub instead; that diagnostic error was corrected, without obscuring
the genuine term-loss defect.

`phylo_dep(1+x+x2|species,vcv=C)` uses the multi-slope classifier
(R/brms-sugar.R:4441–4455). Gaussian prepares45 free Cholesky coordinates over9
coefficients. Poisson reaches and rejects the actual multi-slope family guard
(R/fit-multi.R:2255–2262). A source-specific alias cannot be assumed equivalent
just because its single-slope form works.

All3 capture attempts retained: initial20 cases FAIL5 predicates; second22
outcomes captured but diagnostic used partial map lookup; third22 uses exact
lookup and is authoritative. No requested case was dropped. Full fits were
not run and no R code was repaired by this Julia lane. Any future R repair is
a separate owner-controlled action; the frozen reference remains unchanged.
