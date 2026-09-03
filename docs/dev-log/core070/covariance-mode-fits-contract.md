# Native Gaussian covariance-mode fitting qualification

Seven separately declared full-rank fitting cases now pass against frozen
gllvmTMB b4d5fee64def88bc768dda1f1f77c29b295edd86 using **explicit tighter R
stopping controls**. The unchanged Julia source fitter uses its independent
default start. See [the pre-run contract and amendment](covariance-mode-fits-leaf.md)
and [machine-readable evidence](covariance-mode-fits-evidence.json).

| Fitting ID | Default R controls | Tighter R controls | Compared covariance |
|---|---|---|---|
| FIT-MODE-ORD-DEP | FAIL: R gradient | PASS | Total U + residual variance I |
| FIT-MODE-ANIMAL-INDEP | PASS | PASS | Diagonal U and residual variance |
| FIT-MODE-ANIMAL-COMMON | PASS | PASS | Common diagonal U and residual variance |
| FIT-MODE-ANIMAL-DEP | FAIL: R gradient and covariance | PASS | Full U and residual variance |
| FIT-MODE-KERNEL-INDEP | PASS | PASS | Diagonal U and residual variance |
| FIT-MODE-KERNEL-COMMON | PASS | PASS | Common diagonal U and residual variance |
| FIT-MODE-KERNEL-DEP | FAIL: R gradient and covariance | PASS | Full U and residual variance |

The follow-up changes only R's public optArgs stopping controls: rel.tol and
sing.tol1e-12, eval.max2000, iter.max1500. Prepared data, maps, parameter names,
seeds, likelihood normalization and acceptance tolerances are unchanged. All
seven original failures/successes remain visible; default health is not upgraded.
The follow-up passes176 assertions in34.24seconds on Totoro, one Julia/BLAS
thread. Maximum absolute likelihood difference7.44649e-12; both engines meet
their declared gradient gates. Independent base-R readback checks all14 retained
fits and recomputes their full normalized Gaussian objectives. The verifier
rejects68 damaged case/aggregate records. Re-run:

    python3 tools/core070_verify_covariance_fits.py

These FIT-MODE IDs use new data from the predeclared DGP; they do not overwrite
the original MODE pointwise fixture. The original ORD-INDEP/COMMON fits remain
qualified separately by [the fixed-residual contract](source-fixed-residual-contract.md).
All nine declared Gaussian mode shapes therefore have native fitted examples,
at the exact documented inputs and numerical controls only.

Ordinary full covariance has a nonidentified source/residual split. Its small
Hessian eigenvalues are diagnostics, not proof that both variances are identified;
only total covariance is compared. The structured pairs use repeated groups,
but one seeded fit is not recovery or coverage evidence. No confidence intervals,
general covariance grammar, formula/bridge route, sparse preprocessing, source
kernel estimation, unique companions, slopes, masks, missing data or non-Gaussian
crossing is qualified here. The full Core/AGHQ manifest remains draft and M1
remains partial. No package version, source engine or public API changed.
