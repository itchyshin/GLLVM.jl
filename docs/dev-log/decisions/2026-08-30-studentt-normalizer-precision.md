# Student-t normalizer precision: diagnosis and repair contract

Status: **narrow precision checks PASS; original Student parity health remains FAIL**.
No R engine, model, original seed71 fixture or `abs(ΔlogLik) ≤ 0.001` gate changes.

For `r=(y-μ)/σ`, preserve the exact location-scale density

```math
\ell = C(\nu)-\log\sigma-\frac{\nu+1}{2}\log(1+r^2/\nu),\qquad
C(\nu)=\log\Gamma((\nu+1)/2)-\log\Gamma(\nu/2)-\tfrac12\log(\nu\pi).
```

The existing Float64 subtraction in `src/families/studentt.jl` loses digits for
large degrees of freedom. Against a256-bit direct reference, the retained
Totoro diagnostic measures absolute density error1.25e-5 atν2.3175e10 and1.87e-4
atν1e12. These are per-observation errors, not a fitted-model error bound.
The original frozen R fit reproduces exactly, still reports false convergence,
and has max absolute gradient0.22544. Its log-df finite differences are unstable
across step sizes. The Julia density defect is proved independently; it does
not prove the complete cause of R's optimizer failure.

The beta-function identity offers a stable value candidate,
`C(ν)=-logbeta(ν/2,1/2)-log(ν)/2`, but the installed DiffRules rule differentiates
logbeta through a digamma difference. Value stability alone is insufficient;
the outer derivative in `θ=log(ν-1)` and nested differentiation must also pass.

An alternative large-ν evaluation follows by subtracting the two log-gamma
expansions in [NIST DLMF5.11.8](https://dlmf.nist.gov/5.11.E8):

```math
C(\nu)=-\tfrac12\log(2\pi)-\frac{1}{4\nu}
 +\frac{1}{24\nu^3}-\frac{1}{20\nu^5}+\frac{17}{112\nu^7}
 -\frac{31}{36\nu^9}+\cdots.
```

Coefficients were independently derived with exact rational Bernoulli
polynomials. The threshold, truncation and precision dispatch were independently reviewed
before implementation. Noether's independent Terra/high review approves the
Float64 and Float64-backed nested-Dual branch atν≥64 through theν^-9 term;
the next coefficient is691/88, independently checked with rational arithmetic.
BigFloat and BigFloat-backed Duals use the original precision-native formula.
Do not silently apply a fixed Float64-accuracy series
to arbitrary-precision inputs. Differentiate the stable expression directly;
do not attach a derivative rule that reintroduces cancellation.

| Model quantity | Existing contract | Repair boundary |
|---|---|---|
| ν | fixed or estimated; θ=log(ν-1) | No cap, floor, grouping or fitted-coordinate change. |
| σ | scale, fixed grouping semantics | Preserve `-log(σ)` and residual scaling. |
| μ | same ecological predictor/latent effects | No change to predictor or mode model. |
| C(ν) | normalized Student density | Stable value and first/second derivatives against independent high precision. |
| R health | original optimizer outcome | Remains failed until independently resolved; no relabeling as boundary success. |

Regression file `test/test_studentt_normalizer_precision.jl` covers ordinary and
large finite ν, candidate transition points, ForwardDiff gradient/Hessian and
BigFloat precision. It is wired into the central suite. After a repair,
rerun the original Student cell and retain any
new failure; a more accurate Julia density may widen the difference from a
numerically unstable frozen reference. Full-suite and recovery gates remain
separate and unpaid.

Qualification on Totoro Julia 1.12.6: 51/51 precision checks and 113/113 adjacent
regressions pass. The new precision test first failed against the old implementation
(29 passed, 20 failed). The unchanged original parity cell still has 31 passed and
2 failed assertions: absolute likelihood difference 0.000690345 is below 0.001,
but R optimizer health fails. A no-fit evaluation at the retained R parameter
point yields finite full gradient and Hessian. This is not full package,
Documenter, recovery or completed R parity evidence. Float32 retains the original
direct formula and is not claimed improved. See `../core070/student-normalizer-evidence.json`
for source and receipt hashes.
