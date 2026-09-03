# Noether review: internal AGHQ outer driver

Fresh native gpt-5.6-terra/high, read-only public source/design files. One review
and one repair follow-up, no private histories/logs/brain supplied and no fits.
No full completion-panel claim.

No P0 numerical defect. P1 test gap: malformed caches, nonfinite metadata,
changing dimensions and finalization failures were checked in source but not
exercised. Added deterministic tests. A bad initial/final cache is unusable;
a bad trial can retain an earlier valid accepted point. No convergence is
claimed after either failure.

P2 derivative-test concern resolved by pointing to AF-03 in the included
prerequisite suite: fixed-cache AD matches two finite-difference step sizes,
and differs from re-adapted directional differentiation. Added a non-Dual
callback test: finite objective may remain usable with NaN gradient, but cannot
be marked converged.

Parent also found the non-default rho_min detail: R halves without clipping.
The rho_min=.3 regression failed (.3 vs .25); the one-line repair matches R.
Reviewer confirmed that rule and all added failure tests. Final static verdict:
no remaining P0-P2 findings; runtime validation remains the parent's evidence.
Later parent-added schedule tests exercise every cap and disable controls,
without further source changes; they were not part of the review follow-up.
