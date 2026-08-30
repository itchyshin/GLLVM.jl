# Original Student-t fixture: public optimizer refinements

The original seed-71, p=5, K=1, n=130 fixture and exact data bytes remain unchanged. Frozen R b4d5fee64def88bc768dda1f1f77c29b295edd86 still estimates per-trait scale and degrees of freedom, ordinary latent unique=FALSE. No engine, fixture, helper or tolerance was changed. [Retained evidence](student-refinement-evidence.json) binds both numerical attempts and the earlier setup failure.

| R route | Optimizer code | Maximum raw gradient | Absolute Julia–R log-likelihood difference | Added checks |
|---|---:|---:|---:|---|
| Original default | 1: false convergence | 0.225440324 | 0.000690345 | Prior required cell remains failed |
| Warm-start nlminb, tighter controls | 1: false convergence | 0.021821174 | 0.000806848 | 9 pass, 2 fail |
| Warm-start optim/BFGS | 0 | 0.206117050 | 0.004688108 | 9 pass, 2 fail |

The public controls are `start_from=original_fit`, `n_init=1L`, `se=FALSE`; nlminb uses `rel.tol=1e-12, eval.max=2000, iter.max=1500`, BFGS uses `reltol=1e-12, maxit=1500`. Exact TMB data, parameter names and maps are asserted identical before/after. BFGS's code0 does not establish health: its gradient and the unchanged absolute likelihood tolerance0.001 both fail. The nlminb refinement passes likelihood but fails code and gradient. Do not choose a successful flag from one run and a successful likelihood from another.

Native fit remains `nu=nothing, disp_group=:species, iterations=400`; same model as the original required target. Both runs give log-likelihood -873.2348783366755, optimizer converged=true, and independently evaluated AD raw gradient maximum6.17704e-6. The gradient uses explicitly documented reordered coordinates `[vec(Λ); β; log σ; log(ν−1)]`, not the optimizer's `[β; packed Λ; ...]`. K=1 has five free loading coordinates, so this is a bijective permutation. Loading sign may differ between engines and is not compared directly.

Native first-trait σ≈7.59e-5 and ν≈3.03e31 indicate a boundary/weak-identification regime. The R point retains σ≈0.0903 and ν≈2.32e10. Small gradients do not establish identification, positive curvature, recovery or intervals. Earlier normalizer cancellation evidence remains relevant, but these two optimizer experiments alone do not prove the sole cause or that all public initialization choices must fail. No upper/lower parameter restriction was introduced to force a pass.

## Verification

Totoro Julia1.12.6/R4.5.3, one Julia/BLAS thread. Commands finished in32.35s and33.10s, below each under-three-minute estimate and300s hard limit; installed R integrity passes before/after. Both supervisors retain actual exit1. The first launch stopped before fitting because ForwardDiff was imported from the parity project; the correction uses GLLVM's existing binding without changing dependencies. All attempts are retained.

`python3 tools/core070_verify_student_refinement.py` verifies source pins, historical nlminb script, exact data/fixture hashes, actual process exits/log hashes, metrics and both failed outcomes. `--require-health` exits nonzero. Six negative controls reject false health, fixture corruption, missing process, fabricated likelihood, stale historical script and corrupt result. The Unlazy evidence gate passes; the health gate remains unmet.

## Review and next action

Independent Terra/high review was refused before dispatch by the approval system because the proposed source/evidence/log payload lacked specific external-service authorization. No reviewer ran; no workaround attempted. Local consistency checks are not independent sign-off.

Student-t required parity remains UNPAID. These public-control attempts rule out the two tested warm-start repairs, not all possible repairs. Next discriminating work should compare frozen R and stable native objective/derivative evaluations at identical retained parameter points, controlling latent-mode initialization and normalizer precision. Any change to the frozen oracle or required model remains a separate consequential decision. Continue unaffected finite-manifest and native capability work; no whole-programme blocking claim follows.
