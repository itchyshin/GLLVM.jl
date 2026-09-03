# Maintainer decisions, rounds 2-3 (2026-09-01, interactive)

5. **API-name collisions (38 rows)**: RENAME the Julia functions that shadow
   R names with different semantics (e.g. getREsd -> latent_score_sd),
   freeing the names for future true R-mirrors; rows stay honestly BLOCKED
   until mirrors exist.
6. **Structured-term grammar**: expose publicly via an explicit structure=
   fit kwarg taking term expressions (no macro); full grammar macro later.
7. **Engine priority**: PHYLO TRANSPORT first — reviewed conversion design
   doc (covariance-vs-precision) before any code.
8. **CI-coverage campaign**: Wald-only, chunked DRAC arrays, launched AFTER
   the nobs/cloglog/estimand slices land; pre-run gate first.
9. **99 reclassify rows**: accept contract triage in bulk (apply each row's
   own pointer), summary table for after-the-fact review; ambiguous stays
   PARTIAL.
10. **Plotting stack**: CairoMakie committed as the stack; build in a later
    arc (rows become implementable-cluster, not built now).
11. **A6 Student-t**: boundary-diagnosis fixture — paired evidence at
    interior nu PLUS wire the nu_boundary flag into converged/health
    reporting; rerun the harness cell.
12. **ZI trio**: ship as Julia-beyond capability with ADEMP recovery
    evidence (DRAC array), documented as no-R-twin; not paired parity.
