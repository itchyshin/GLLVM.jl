# AP — real Poisson AGHQ adapter (predeclared)

Scope: internal single ordinary loadings-only block, log link, no unique variance,
no loading penalty. Reference b4d5fee64def88bc768dda1f1f77c29b295edd86;
R/fit-multi.R Stage1a and src/gllvmTMB.cpp dpois(y,exp(eta),true).
Public controls, automatic selection, multistart and fit/inference objects remain
separate obligations. Do not relabel PoissonFit's Laplace objective as AGHQ.

| Symbol | Julia input | DGP | Extractor | Truth |
|---|---|---|---|---|
| beta_t | first p theta entries | original seed44 intercepts | theta[1:p] | log([3,5,2,4,3.5]) |
| Lambda_t | pack_lambda tail | .45 * original p5K2 loadings | unpack_lambda | fixture matrix |
| z_s | integrated latent | N(0,I_2) | conditional mode diagnostics only | distribution N(0,I) |
| offset_ts | fixed p by n matrix | zero in original fit; nonzero unit controls | fixed input | known |
| y_ts | p by n counts | original Knuth sampler, seed44 | conditional mean exp(eta) | Poisson draw |
| mask_ts | observed cell mask | full original fit; missing-cell controls | omitted likelihood terms | fixed |

ell_s(z;theta) = sum_observed[y_ts eta_ts - exp(eta_ts) - log(y_ts!)]
                    - z'z/2 - K log(2pi)/2;
eta_ts=beta_t+offset_ts+Lambda_t z. No eta clipping in this target.
H_s=I+Lambda_observed' diag(exp(eta_observed)) Lambda_observed is positive
 definite. Reuse the existing mode search only as a proposal; check the gradient
of THIS joint (ForwardDiff) <=1e-7, finite density/H, and positive curvature.
An invalid mode throws with site/gradient detail; no repaired saddle is admitted.
Adaptation remains outside frozen-surrogate differentiation. All parameters,
including loadings, are optimized by the existing unpenalized outer driver.

AP01: normalized density constants, analytic score/H comparison, k1 Laplace
agreement on moderate masked/offset data; all-missing site contributes zero.
AP02: frozen AD agrees with central FD at steps1e-4 and1e-5 <=1e-6.
AP03: one-dimensional independent Simpson quadrature and node refinement:
k21 error <1e-8; k3 > k9 > k21 errors on fixed count3,beta.2,loading.7.
AP04: malformed K/k/mode controls, masks/shapes/counts/parameters/caches reject;
masked nonfinite placeholders ignored; input copies protect later mutation;
under-iterated modes reject and outer driver cannot claim convergence.
AP05: original seed44 p5K2 n60 diagnostic fit, k5, 400 outer passes maximum,
all14 parameters free. Require usable finite improved objective, final modes
healthy, no curvature repair, independently recomputed objective agreement.
Record convergence and gradients; do not turn nonconvergence into a parity claim.
This is a numerical fitting smoke, NOT recovery or R fit parity. Retain every try.

Parent owns src/families/aghq_poisson.jl, module/test includes, named tests,
runner/verifier and scoped records. Fresh Noether numerical review required.
Totoro one Julia/BLAS thread, estimate1–3minutes, hard300s main process cap.
R oracle before/after, exact source/fixture/environment hashes and retained logs.
Unlazy verifier checks red/green, artifact hash, counts, source freshness and
negative corruptions. No DRAC compute, public API changes, R edits or lane cleanup.
