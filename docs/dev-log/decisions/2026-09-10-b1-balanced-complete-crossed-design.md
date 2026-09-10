# 2026-09-10 — B1 balanced complete-crossed source alignment

**PRE-RUN CONSTRUCTION ONLY.** This fixes a new B1 fixture; it is not a fit,
frozen-R receipt, paired R-to-Julia result, recovery result, or qualification.

`test/fixtures/destination_b_b1_balanced_complete_crossed_design.jl` fixes two
traits, `U=12`, `W=3`, `C=10`, `D=10`, the complete product `(u,w,c,d)`,
`unit=u`, `obs=paste(u,w)`, `cluster=c`, and `cluster2=d`: 3,600 wide and
7,200 long rows. It fixes seed `20260915`, beta `(-0.20,0.27)`, loading
`(0.72,-0.51)`, observation SDs `(0.36,0.27)`, cluster SDs `(0.43,0.32)`,
cluster2 SDs `(0.38,0.29)`, residual SD `0.17`, Gaussian ML (`REML=FALSE`),
and the formula

```r
value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) +
  indep(0 + trait | obs) + indep(0 + trait | cluster_id) +
  indep(0 + trait | cluster2_id)
```

The response SHA-256 is
`0fa63f69d7256b3c4e900cc91db1bf67c1ba41c56d0e0fde64de2c6a11ad738a`.
The normalized ten-channel tensor-kernel has rank 10 and minimum eigenvalue
`0.3408784387221166 >= 0.30`. This is a static construction screen, not
Fisher-information, convergence, recovery, interval, or likelihood evidence.

If explicitly authorized later, run **one** frozen-R ML control only:
`n_init=1`, `se=FALSE`, `optimizer="nlminb"`, `eval_max=iter_max=100000`, and
`rel_tol=x_tol=xf_tol=1e-12`. It passes only with `convergence == 0` and
`max(abs(gr)) <= 1e-6`. Otherwise stop and retain the nonqualifying receipt:
no reseed, restart, optimizer/data/tolerance change, or paired Julia fit.
