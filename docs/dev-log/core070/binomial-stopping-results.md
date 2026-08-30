# Binomial stopping diagnostic — partial

The predeclared diagnostic ran on Totoro in 77.26 seconds with one Julia/BLAS thread, below its 180-second limit. It stops at the first complete R fit passing R health, independently of Julia agreement. Original default and unconditional-refinement results remain unchanged.

| Case | Whole fits retained | Final R gradient | Code | Diagnostic |
|---|---:|---:|---:|---|
| BINOMIAL-LOGIT-BERNOULLI | 2 | 1.44900922e-05 | 0 | PASS |
| BINOMIAL-LOGIT-VARYING | 3 | 0.000139191297 | 1 | FAIL |
| BINOMIAL-PROBIT-BERNOULLI | 1 | 7.53993316e-05 | 0 | PASS |
| BINOMIAL-PROBIT-VARYING | 3 | 0.000111725469 | 1 | FAIL |
| BINOMIAL-CLOGLOG-BERNOULLI | 2 | 4.1625776e-05 | 0 | PASS |
| BINOMIAL-CLOGLOG-VARYING | 3 | 0.000121035202 | 1 | FAIL |

All six likelihood comparisons, native baseline health checks, and R finite-difference derivative checks pass. The largest analytic-versus-finite-difference discrepancy is 4.19e-7, below the 1e-4 diagnostic threshold. Reported finite-difference stability ranges from1.36e-7 to4.49e-7. The runner retains the second finite-difference vector and the stability statistic; it does not retain the first vector separately.

For all three varying-trial cases, changing relative tolerance from1e-12 to1e-14 leaves parameters, likelihood and gradient unchanged, but gives code1, “singular convergence (7)”. Thus the hypothesis that another tolerance reduction alone resolves these health failures is not supported. This is a solver stopping diagnosis, not proof of a singular model Hessian.

All Bernoulli cases qualify within this diagnostic: logit and cloglog after one public refinement, probit at its original default fit without refinement. No fields are borrowed from another fit. No default-health promotion: baseline remains1of6, the older unconditional refinement remains2of6, this stopping diagnostic is3of6.

Next: inspect curvature and actual step sizes at the retained parameter vectors; test the objective and gradient at those same points before proposing another optimizer change. Do not keep reducing tolerances, relax gates, or edit the R engine. A public alternative optimizer would need a new bounded, predeclared experiment. No Julia likelihood defect has been demonstrated here.

Evidence: `binomial-stopping-policy.toml`, `binomial-stopping-evidence.json`, and `tools/core070_verify_binomial_stopping.py`. Raw attempts and logs are retained under `.unlazy/core070-aghq/binomial-stopping-01/`. This does not complete Core/AGHQ, inferential recovery, bridge qualification or independent review.
