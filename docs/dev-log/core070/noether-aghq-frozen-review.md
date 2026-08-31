# Noether: fixed-adaptation AGHQ source review

Native fresh-context dispatch: gpt-5.6-terra, high effort; read-only public source
and design files only. One bounded review and one repair follow-up. No private
histories/runtime logs supplied; reviewer ran no fits. This is not a completion
panel or public-estimator sign-off.

No P0/P1 numerical defect found. Reviewer checked normalized joint integral,
B=inv(R) orientation, log Jacobian, fixed-cache AD semantics, finite inputs and
eigenvalue repair only on failed Cholesky. No loading penalty was introduced.

P2: the Julia tests alone reconstructed expected factors with Julia's own
factorization routines, while separate R/Julia emitters did not yet compare them.
Repaired with tools/core070_aghq_frozen_verify.py: source-pinned frozen R helper
execution; orientation-sensitive comparison of modes, all factor entries and
log Jacobians for five matrices; repair flags and artifact corruption controls.
Follow-up verdict: P2 closed; no direct comparison defect found. Parent then
executed comparator successfully. Runtime evidence remains the parent's output,
not an inferred reviewer-run result.
