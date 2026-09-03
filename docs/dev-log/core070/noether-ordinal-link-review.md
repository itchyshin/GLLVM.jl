# Noether — focused ordinal link review, 2026-08-31

Dispatch: native reviewer, requested gpt-5.6-terra / high, fresh context. Public
code only: ordinal guard/test diff and directly related kernels/dispatch/tests.
No private histories, no production slice, no full-programme completion panel.

Verdict: **No P0–P2 findings**. CDF, density, density derivative and warm-start
quantile methods implement only LogitLink/ProbitLink. The guard correctly rejects
unsupported links before response-cell access in all three fitters. The NoRead
regression meaningfully covers named, unified, wide/no-X, wide/X and long-formula
routes. No likelihood, packing, scale, phylogenetic or AD/CHOLMOD path changed.

P3 retained: the nearby source comment says a future link only swaps `(F,f)`;
it must also implement `_ord_fp` and `_ord_quantile`. Queue this comment correction
with the next ordinal source/docs update. It does not affect current supported
models or this guard. The Documenter/developer consistency audit remains open.

Review limitation: Noether did not execute the test independently. Its local
Julia attempt first met compiled-cache restrictions, then missing Optim in this
checkout environment. No dependencies were instantiated by the read-only reviewer.
Parent's pinned Totoro executions supply runtime evidence, independently reviewed
source supplies the code assessment; neither substitutes for final package checks.
