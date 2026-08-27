<!-- Evidence bundle for maintainer decision #4 (the 8 allegedly understated
ledger rows) + Arc-6 release-debt inventory. Produced by an 11-agent read-only
audit workflow (8 per-row verifiers, 2 inventory sweeps, Rose synthesis),
2026-08-27. Static analysis only: no test was executed. -->

# Rose audit — decision #4 ledger rows + Arc-6 release-debt inventory

**Bottom line:** of the 8 allegedly understated rows, **3 promote, 5 keep**. All verifier work is static analysis only — no test was executed; "wired" means reachable-by-include, not verified-passing. Every promotion below must carry a scope-qualified label, not a bare "implemented".

## 1. Verdict table (8 rows)

| # | Row (ledger line) | Verdict | Decisive evidence | Caveat blocking a bare promotion |
|---|---|---|---|---|
| 1 | Multinomial family (:91) | **Keep** | Code/exports/dispatch/wired test exist (`src/families/multinomial.jl`, export at `GLLVM.jl:203`, test at `runtests.jl:127`), but `fit_gllvm.jl:159` throws on any LV use — v1 is FE-only softmax, no multinomial GLLVM. The ledger's comment block (lines 92–115) already documents exactly this. | Table cell alone is misleading; the honest fix is a "partial (FE-only, no LV)" tier the schema lacks — a schema question, not a promotion. |
| 2 | Missing predictor `mi()` (:225) | **Promote** | Four fitters shipped, included, exported (`fit_gaussian_mi_fiml`, `fit_gaussian_mi_phylo`, `fit_gllvm_mi`, `fit_gllvm_mi_multi` at `GLLVM.jl:145`); seven test files unconditionally wired (`runtests.jl:169–175`). | No `mi(` handling in `src/formula.jl` — the R-style formula surface is absent. Promote as **"implemented (function API; no formula `mi()` term)"**. |
| 3 | Mixed-family vector (:229 vs :245) | **Promote** (resolves a genuine self-contradiction) | Line 245 already says implemented, and the bridge routes through the *native* fitter (`bridge.jl:1763` → `fit_mixed_gllvm`, `families/mixed.jl:420`, exported at `GLLVM.jl:177`, test wired at `runtests.jl:207`). Line 229 "planned" is logically impossible alongside 245. | Scope is narrow: no fixed-effect X, no CI transport, family list capped (Normal/Poisson/Binomial/NB), **no ADEMP recovery test** — that last point violates the repo's own design rule 1 for families. Promote as **"implemented (partial: no X, no CI; bridge-tested only, no recovery evidence)"** and open a recovery-test debt item. |
| 4 | none × dep (:47) | **Promote — conditionally** | `fit_dep_gllvm` exists, is exported (`GLLVM.jl:226`), docstringed, with 39 wired assertions (`test_none_dep.jl` via `runtests.jl:15`) and an after-task report (2026-08-19). | **The identifiability question is real and unresolved by the repo's own admission** (`check-log.md:13796`). The fitter is literally `fit_gaussian_gllvm(Y; K = p)` with σ²_eps *profiled*, so at K=p the ΛΛᵀ vs σ²I split is confounded — the fitted Σ is **not** the total trait covariance decomposition the row name implies. Tests are equivalence + fail-loud only; zero recovery-to-truth evidence for the dep estimand. Promote **only** with the wording: "implemented (Gaussian matrix fitter; K=p wrapper; σ_eps profiled — Σ/σ_eps split not separately identified; no `dep()` formula sugar)". If the maintainer reads the row as "estimate an identified unstructured Σ", the honest verdict is keep-as-planned. This is the one row where I recommend the maintainer decide, not the ledger editor. |
| 5 | kernel × indep (:58) | **Keep** | Repo-wide grep: zero `kernel_indep`/`kernel_dep`/`kernel_latent`/`KernelSource` symbols anywhere; only kernel-named export is `make_cross_kernel` (coevolution K*, a different capability). No named entry point, no docstring, no test. | The Σ_phy slot mechanically accepts any PSD matrix, but by the ledger's own convention (animal/spatial promoted on named builder + tests) that is substrate, not capability. Promotion would be a claim without evidence. |
| 6 | kernel × latent (:60) | **Keep** | Same as row 5: no symbol, no grammar, no test. The cross-kernel tests exercise coevolution, not a `kernel_latent()` capability. | Promoting this would force promoting animal × latent by identical logic — the grid tracks the grammar-level twin surface. |
| 7 | Phylo Model A public intervals (:61, :248, :399) | **Keep (rejected)** | The machinery exists but is *deliberately* internal: all underscore-prefixed, none exported, wired test reaches it only via `GLLVM._` qualification. Two decision docs (2026-06-30 council, 2026-07-01 retirement) fence it on coverage evidence (bootstrap 0.821 under-coverage; profile canary LR 9.99 > 3.84). | This is not an understated ledger row — it is a working claim fence. Reopening requires one of the three named conditions in the council decision, not a ledger edit. |
| 8 | animal × latent (:54) | **Keep** | No `animal_latent` symbol anywhere; `test_structured_cov.jl`'s animal testset runs K_phy=0 only, and its only K_phy>0 test uses `spatial_cov`. No test exercises relatedness + latent. | Engine is source-blind so the combo is reachable by hand, but the ledger's grading bar (spatial × latent promoted *with* a combo test) is correctly failed here. Cheap to close: one testset + a named path. |

**Blunt summary of the original claim:** the "8 understated rows" allegation is 3/8 right. Rows 5, 6, 8 confuse substrate-reachability with shipped capability; row 7 misreads a deliberate rejection as understatement; row 1 was already self-documented in the ledger's own comment block. Rows 2 and 3 are genuine understatements (row 3 an outright self-contradiction), and row 4 is genuinely shipped but shipped *with an unresolved identifiability concession the promotion wording must carry*.

## 2. Orphaned tests (release debt)

Nine top-level `test/` files are unreachable from `runtests.jl`. Two are non-issues; seven form one coherent debt item.

| File | Status | Note |
|---|---|---|
| `test_quality_jet.jl` | Not a true orphan | Conditionally included via `test_quality.jl:31`; must **not** be wired directly (JET-less env would error). No action. |
| `test_phylo_gamma_xlv.jl` | Deliberately unwired, **guards shipped code** | The only orphan covering code in the module (`GLLVM.jl:106`). Its in-file oracle still computes the Fisher log-det; needs an independent-reviewer fix before wiring. **This is the highest-priority wire-in.** |
| `test_edge_incidence.jl`, `test_phylo_contrasts.jl`, `test_em_phylo.jl`, `test_em_squarem.jl`, `test_em_squarem_safety.jl`, `test_relaxed_clock.jl`, `test_phylo_branch_re.jl` | Orphan cluster | All test source files that exist in `src/` but are **not included by `src/GLLVM.jl`** — an entire unshipped subsystem (edge-incidence, contrasts, EM/SQUAREM, relaxed clock, branch-RE) tested only by hand-run self-includes, despite CLAUDE.md/AGENTS.md listing these files as part of the source layout. |

Wiring the cluster as-is would break the suite: duplicate top-level definitions (several re-include `sparse_phy.jl`/`edge_incidence.jl`), slow EM/recovery fits, seed- and optimiser-path fragility (`test_em_squarem_safety.jl` is seed-17-specific by design). The correct sequence is: **first decide whether these files join the module, then convert tests to `GLLVM.`-qualified names** — not a mechanical wire-in. Alternatively, if the subsystem stays out of the module, CLAUDE.md/AGENTS.md's source-layout description is overstated and needs a "not shipped in the module" annotation — one or the other must give.

## 3. Docs gaps

**Family coverage** (`docs/src/response-families.md`): no family with zero coverage. Thinnest — `Exponential()` (2 mentions), `GeneralizedPoisson1` (3), `OrderedBeta` (4), mixed-family (4). Given row 3's promotion, the mixed-family docs thinness becomes a same-PR obligation under design rule 3.

**Speedup-claim inconsistency — four headline framings across four files, one of which disputes another in print:**
- `README.md:33` — "161–698× faster"
- `docs/src/changelog.md:142` — "~340× median"
- `docs/src/comparison.md:35–37` — "~190×/~520×/~280×" per-cell medians
- `docs/src/gllvmtmb-parity.md:87–92` — measured median **265.1×**, and *explicitly flags the ~340× figure as unverified in-repo*

A parity page publicly contradicting the changelog is release-blocking under the pre-publish gate. Pick one canonical framing (the measured 265.1× median + the 161–698× range are the only in-repo-verified numbers) and cascade it through README, changelog, comparison, and the AGENTS/CLAUDE "~340×" lore. The "20–60×" figures are curvature-accuracy, not speed — keep them clearly separated.

**docs/make.jl nav:** clean. No dangling entries, no orphan pages. No action.

## 4. What this changes in the roadmap

Three ledger edits (mi(), mixed-family, none-dep) with scope-qualified wording, five rows untouched. Two new debt items enter Arc-6: an ADEMP recovery test for the mixed family (its promotion currently rests on a bridge metadata test, which fails the repo's own bar for a family), and a maintainer decision on the none-dep identifiability wording — promote-with-concession or hold-as-planned. The orphan cluster forces a scoping decision that has been silently deferred: either the EM/edge-incidence/relaxed-clock subsystem ships in the module (then tests get converted and wired) or the source-layout docs stop implying it already has. The speedup-number reconciliation is the cheapest and most urgent item — the repo currently publishes a page that disputes its own changelog, and that is exactly the class of claim-vs-evidence drift the Rose gate exists to catch before v0.2.0. Nothing here reopens Phylo Model A; its fence is working as designed.

*Basis: verifier JSON + orphan/docs inventories over the read-only lane at `/Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824`. Static analysis throughout; no Julia execution.*
