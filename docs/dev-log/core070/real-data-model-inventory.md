# Real-data model inventory — GLLVM.jl acceptance-track recon

**Compiled by:** Hopper (read-only recon). **Scope:** four Ayumi-495 repos, shallow-cloned
to `/private/tmp/.../scratchpad/realdata/` (not committed anywhere; recon only, no pushes).
**Verdict rubric** is the bridge coverage matrix at
`/private/tmp/GLLVM.jl-core070-aghq-20260830/docs/dev-log/core070/bridge-coverage-matrix.md`:

- **RUNNABLE-TODAY** — family is on `.GLLVM_JULIA_BRIDGE_FAMILIES` (or per-family list) AND the
  only structural dependency is a single `latent()` reduced-rank (`rr`) ordination block (no
  `phylo_*`/`animal_*`/`kernel_*`/`spatial_*`/`dep`/`indep`, no offsets, no multiple `rr` blocks).
- **R-ADAPTER-BLOCKED** — family and/or structure trips a named or source-confirmed gate in
  `R/julia-bridge.R` (`GJL-GATE-STRUCTURED-TERMS`, `GJL-GATE-MULTI-RR`, the hard-coded offset
  refusal, or a family absent from the bridge family map).
- **JULIA-GAP** — GLLVM.jl's own `src/families/` has no fitter for the family/structure at all
  (none of the models below hit this cleanly; every block found is an R-adapter gate, matching
  the matrix's own finding that no cell is a strict JULIA-GAP).
- **DATA-SHAPE-RISK** — otherwise admitted, but the data itself carries one of the eight
  acceptance-class hazards (polytomies, unicode/space-bearing labels, missing cells, `I(x^2)` /
  interaction terms, etc.) that could break the harness independent of family/structure support.

Where a verdict is UNTESTED-but-admitted at the family layer (e.g. `binomial(probit)`,
`ordinal_probit`), the model is still counted RUNNABLE-TODAY per the task's "family exposed +
structure admitted" instruction — the matrix itself flags these UNTESTED, not blocked.

---

## 1. `Ayumi-495/avian_trait_scales`

Individual- and species-level AVONET morphology scaling models (beak/wing/tarsus etc.), always
Gaussian, always phylogenetically structured. All ~50 `scripts/*.R` model-fitting calls funnel
through three shared helpers in `R/modelling/`: `individual_level_main.R`,
`rank_config.R` (species-level + individual-level rank-configuration sweeps), and
`resilient_multistart.R` (checkpointed multistart wrapper around the same calls). No script
escapes the shared formula template.

**Data**: `data/11167_species.nex` (11,167-tip tree; **taxon labels contain spaces**, e.g.
`Camarhynchus pallidus` — checked binary/fully resolved with `ape::is.binary()`, TRUE, no
polytomies). `outputs/data/avonet_allspecies_hwi_logz/individual_level.csv` — 86,313 individual
records; `species_level.csv` — 9,947 species; `subset_list.csv` — 9,947-row species↔tier lookup.

| Call (representative) | Family | Structure | Data shape | Hazards | Verdict |
|---|---|---|---|---|---|
| `individual_level_main.R`: `traits(...) ~ 1 + log_mass_z + phylo_latent(species, d, unique=TRUE, tree=tree) + latent(1\|species, d, unique=TRUE) + latent(1\|individual_id, d, unique=TRUE)` | `gaussian()` | 3-tier: phylo_latent (species) + 2× ordinary `latent()` (species, individual) — 3 structured blocks, one phylo | n≈86,313 individuals, ~9,947 species, tree 11,167 tips (pruned to matched species) | Tree labels have spaces (`Genus species`, not `Genus_species`); multi-tier nesting; `log_mass_z` covariate | **R-ADAPTER-BLOCKED** — `phylo_latent` is not `rr` (trips `GJL-GATE-STRUCTURED-TERMS`); also 3 structured blocks trips `GJL-GATE-MULTI-RR` even setting phylo aside |
| `rank_config.R` species-level: `traits(...) ~ 1 + phylo_latent(species, d, unique, tree=tree) + latent(1\|species, d, unique)` | `gaussian()` | 2-tier: phylo_latent + ordinary `latent()` | n≈9,947 species | same tree label hazard | **R-ADAPTER-BLOCKED** — same two gates |
| `rank_config.R` individual-level (unique=FALSE diagnostic, script 38) | `gaussian()` | 3-tier as above, with `unique=FALSE` variants on individual tier | n≈86,313 | same | **R-ADAPTER-BLOCKED** — phylo_latent kind alone is sufficient to block, unique=FALSE doesn't change the kind |
| `scripts/45_fit_focused_phylo_within.R`, `53_fit_taxon_level.R`, `56_identifiability_audit_taxon.R`, `60_tier_drop_probe.R`, `62_gllvmtmb_fix_reverification.R` | `gaussian()` | Same phylo_latent-based templates (taxon-restricted subsets, tier-drop variants) | n varies (taxon subsets of the above) | same tree hazard | **R-ADAPTER-BLOCKED** (same reason) |
| `scripts/25/26/30/34/37/39/51` (species/individual-level fits and comparisons) and `archive_pre_2000subset/*` (9 older variants of the same templates) | `gaussian()` | phylo_latent (+ ordinary latent tiers) | n varies (400/2,000/4,000/9,947-species subsets) | same tree hazard | **R-ADAPTER-BLOCKED** (same reason — all route through the shared helpers) |

**Summary for this repo**: every model-fitting call in the repo (≈27 files touching `gllvmTMB()`,
collapsing to a small number of distinct formula templates) uses `phylo_latent()`, alone or
combined with ordinary `latent()` tiers. None reaches an admitted structure. **0 RUNNABLE-TODAY.**

---

## 2. `Ayumi-495/urbanisation_map`

A meta-analytic review-classification project: binary indicator matrix over systematic-review
records, fit as an ordination (`latent(1|review, d)`) under `binomial(probit)`, cross-checked
against `galamm`/`glmmTMB` as alternative engines (never `engine="julia"` — no script in the repo
invokes GLLVM.jl or the bridge at all; this is pure `gllvmTMB` R-engine usage).

**Data**: `data/processed/model_matrix_primary.rds` — data.frame, **191 rows × 54 columns**
(191 reviews, ~44–50 binary indicator columns after non-indicator metadata columns are dropped by
`mk_formula`). `model_matrix_with_region.rds` and `model_matrix_sensitivity_realm.rds` are
row/column variants of the same shape. Review IDs are plain integers cast to factor
(`df$review <- factor(df$review_id)`) — no label hazard.

| Call | Family | Structure | Data shape | Hazards | Verdict |
|---|---|---|---|---|---|
| `R/02_map_model/05_fit_gllvmTMB_map.R` `fit_one()`: `traits(cols) ~ 1 + latent(1\|review, d)`, `unit="review"` | `binomial(link="probit")` | Single `latent()` rr block, grouping = `review`, `d` swept (rank selection) | n=191 reviews, ~44 indicator columns | `unique=` not passed → default `TRUE`, so the bridge silently drops the trait-specific Ψ companion with a `cli_warn` rather than erroring (soft R-ADAPTER-BLOCKED semantic downgrade, not a hard block) | **RUNNABLE-TODAY** (family=binomial-probit admitted-but-UNTESTED on the matrix; structure = single rr) — flag the `unique=TRUE` default as a **DATA-SHAPE-RISK: none of the eight named classes, but a semantic-parity risk** worth noting alongside the run |
| `R/02_map_model/05_fit_gllvmTMB_map.R` constrained refit: same formula + `lambda_constraint = list(unit = M)` | `binomial(link="probit")` | Single rr block + explicit lambda constraint matrix | n=191, d=2 | `lambda_constraint` argument — matrix does not test this kwarg on the bridge path | **RUNNABLE-TODAY** candidate but **DATA-SHAPE-RISK: lambda_constraint (unverified kwarg on bridge)** |
| `R/08_package_comparison/38_main_three_engine.R`: `traits(items) ~ 1 + latent(1\|review, d=2)`, `unit="review"` — the flagship "main" model (44 items, d=2), cross-checked against `gllvm` and `glmmTMB` engines | `binomial(link="probit")` | Single rr block, d=2 | n=191, 44 indicators | same `unique=TRUE` default soft-drop | **RUNNABLE-TODAY** (best single candidate — this is the paper's headline model) |
| `R/02_map_model/05c_ecosystem_sensitivity.R`, `05d_theme_behaviour_sensitivity.R`, `03_region/08_region_sensitivity.R`, `13_region_included_model.R` | `binomial(link="probit")` | Same single-rr template, on stratified subsets (by ecosystem/theme/region) | n≤191 (subsets) | same | **RUNNABLE-TODAY** (variants of the flagship model, smaller n) |
| `R/08_package_comparison/28_unconstrained_comparison.R`, `31_constrained_rr_comparison.R`, `36_lv_predictor_tryout.R`, `37_constraint_pattern_sweep.R` | `binomial(link="probit")` | Single rr block, various `lambda_constraint`/predictor-on-LV variants | n=191 | `lambda_constraint` kwarg (untested on bridge) in most of these | **RUNNABLE-TODAY** (base case) / **DATA-SHAPE-RISK** for the constrained variants |
| `R/02_map_model/14*` series (loading inference, bootstrap, communality bootstrap) | `binomial(link="probit")` | Same single-rr fit, then post-hoc bootstrap/profile inference (not new fit families) | n=191 | none beyond parent fit | Parent fit **RUNNABLE-TODAY**; the bootstrap/profile *inference calls themselves* are outside the bridge's scope (CI extraction, not `gllvmTMB()` calls) — **not separately scored** |
| `R/galamm/20_galamm_comparison.R`, `21_galamm_bootstrap.R`, `22_galamm_publication_outputs.R` | n/a (uses `galamm`, not `gllvmTMB`) | n/a | n/a | n/a | **out of scope** — not a `gllvmTMB`/`gllvm` call, excluded from counts |

**Summary for this repo**: the entire project rests on one structural template (single-rr
`latent(1|review, d)`, binomial-probit) applied to a small (n=191) review matrix with sweeps over
`d`, item subsets, and constraint conventions. This is the single most promising repo for
acceptance runs — small n, single admitted structure, clean labels. **≈13 of the 35
`gllvmTMB()`-touching files are direct model-fit calls on this template** (the rest are
diagnostics/figures/report-building on saved fits, or `galamm` comparisons out of scope);
counting distinct *model definitions* rather than files: the flagship main model, its
constrained-lambda variant, and the ecosystem/theme/region-stratified variants (~6 distinct model
definitions), all RUNNABLE-TODAY modulo the `unique=TRUE` soft-drop and `lambda_constraint`
DATA-SHAPE-RISK flags noted above.

---

## 3. `Ayumi-495/nest_morpho_gllvm`

Nest-morphology-vs-body-mass allometry pilot, small-n phylo-ordination models. Only 3 files touch
`gllvmTMB()`/`gllvm()`; all three route through a single `make_traits_formula()` helper.

**Data**: gitignored (`data_processed/**/*.csv|*.rds` excluded per `.gitignore`; only READMEs are
tracked). No data files available in the shallow clone to inspect shape directly — **data shape:
UNKNOWN**. From script comments/config references: `cfg$pilot$sizes_per_group` sweeps pilot sizes
(`load_pilot(n_each)` reads `data_processed/phylo/pilot_{n}_{n}_species_phylo.csv` /
`..._tree.rds`), i.e. balanced pilot subsets at a config-controlled `n_each` per group — actual N
UNKNOWN without the config file's numeric values (config directory present but not inspected for
this deadline; flagging as UNKNOWN rather than guessing).

| Call | Family | Structure | Data shape | Hazards | Verdict |
|---|---|---|---|---|---|
| `scripts/05_fit_gllvmTMB_smoke_models.R` `fit_morphology_models()`: `traits(morph_traits) ~ 1 + phylo_latent(species_phylo, d, tree=tree)` | `gaussian()` | Single `phylo_latent()` block | n = UNKNOWN (pilot-size-dependent, gitignored data) | phylo structure | **R-ADAPTER-BLOCKED** (`phylo_latent` not `rr`) |
| `scripts/05_fit_gllvmTMB_smoke_models.R` `fit_nest_shape_models()`: `traits(nest_traits) ~ 1 + phylo_latent(species_phylo, d, unique=FALSE\|TRUE, tree=tree)` | `binomial(link="probit")` | Single `phylo_latent()` block | n = UNKNOWN | phylo structure | **R-ADAPTER-BLOCKED** (same reason; family itself is admitted-but-untested, doesn't matter — structure blocks first) |
| `scripts/05_fit_gllvmTMB_smoke_models.R` `fit_combined_models()`: multi-family `traits(...) ~ 0 + trait + latent(0+trait\|species_phylo, d=2) + phylo_latent(species_phylo, d=2, tree=tree)` (mixed morphology+nest traits) | mixed family list (`trait=` dispatch) | Two structured blocks: ordinary rr `latent()` **and** `phylo_latent()` together | n = UNKNOWN | mixed-family dispatch + two structured blocks | **R-ADAPTER-BLOCKED** (multi-block + phylo, doubly so) |
| `scripts/09_fit_mass_x_varimax_constraint.R`: same combined-model template + `lambda_constraint = list(phy = constraint)` | mixed family list | Same two-block structure | n = UNKNOWN | same + constraint kwarg | **R-ADAPTER-BLOCKED** |

**Summary for this repo**: all 3 model-fitting files, and all model variants within them, use
`phylo_latent()`. **0 RUNNABLE-TODAY.**

---

## 4. `Ayumi-495/BIRDBASE_pcm`

The largest and most heterogeneous of the four — cross-family trait-battery PCM validation work
(nest-type, morphology, life-history) across 500/1,500/4,000-species panels, phylogenetic and
non-phylogenetic variants side by side. This repo has the widest spread of verdicts because it
deliberately fits `nonphy` (ordinary `latent()`) and `phy` (`phylo_latent()`) variants of the
*same* model for comparison.

**Data**: `data_processed/cross_family_4000/cross_family_4000_long.csv` — 136,000 rows =
**4,000 species × 34 traits** (long format), families per trait ∈ {`b`=binomial-probit,
`g`=gaussian, `ln`=lognormal, `m`=multinomial, `o`=ordinal_probit} via a `family_map` lookup.
Species labels are `Genus_species` underscore-joined (checked: no space/unicode hits in a
`grep -E "[^A-Za-z0-9_\"]"` scan of the species column). Tree
`cross_family_4000_tree.nex` — 4,000 tips, `ape::is.binary()` **TRUE** (no polytomies).
`data_processed/nest_empirical_validation/` carries parallel 500/1,500/4,000-species panels
(`nest_validation_wide_{500,1500,4000}.csv`, 501/1,501/4,001 lines incl. header) plus a
**balanced 4,000-species panel** (`nest_empirical_validation_balanced_4000/`).

| Call | Family | Structure | Data shape | Hazards | Verdict |
|---|---|---|---|---|---|
| `scripts/13_fit_cross_family_4000.R` per-trait screen: `value ~ 1`, one call per trait, `trait="trait", unit="species"` | Per-trait, one of {binomial-probit, gaussian, lognormal, multinomial, ordinal_probit} (`family_object(key)` switch) | **No structured term at all** — intercept-only per-trait screen | n up to 4,000 species, 1 trait/call | Family varies per call: some admitted (binomial-probit, gaussian), some not (multinomial, lognormal, ordinal_probit is admitted via the per-trait-ordinal list but check needed) | **Mixed — split by trait**: gaussian/binomial-probit/ordinal_probit traits → **RUNNABLE-TODAY** (no structure at all, so the multi-rr/phylo gate is moot); multinomial and lognormal traits → **R-ADAPTER-BLOCKED** (family absent from `.GLLVM_JULIA_BRIDGE_FAMILIES`) |
| `scripts/13_fit_cross_family_4000.R` smoke fit: `value ~ 0 + trait + latent(0+trait\|species, d=2) + phylo_latent(species, d=2, tree=smoke_tree)`, mixed `family_list` | mixed (b/g/ln/m/o) | Two structured blocks (ordinary rr **and** phylo) | n=200-species smoke subset, 34 traits | multi-block + phylo + non-admitted families (multinomial, lognormal) present in the family list | **R-ADAPTER-BLOCKED** (three independent reasons: multi-block, phylo, unadmitted families) |
| `scripts/16_fit_nest_empirical_validation.R` stage=`"nonphy"`: `value ~ 0 + trait + latent(0+trait\|species, d=1)`, `family=families` (b/g/m/o/ln mix, `trait="trait", unit="species"`) | mixed (includes multinomial `m` and lognormal `ln`) | Single ordinary rr `latent()` block, `unique=` unset → default TRUE | n = 500/1,500/4,000 species (panel-dependent), multi-trait | Multinomial + lognormal traits present in the family mix | **R-ADAPTER-BLOCKED** — structure alone would be admitted (single rr), but the per-trait family list includes `multinomial` and `lognormal`, both absent from the bridge family map, so the fit as constructed cannot bridge intact |
| `scripts/16_fit_nest_empirical_validation.R` stage=`"nonphy_shared"`: same formula with **`unique=FALSE`** explicit | same mixed family list | Single rr block, `unique=FALSE` — **this is exactly the bridge's one fully-admitted structural cell** (`COV_ORD_LATENT_BARE_THREE_ROUTE_PASS`) | same panel sizes | same family-mix hazard (multinomial + lognormal) | **R-ADAPTER-BLOCKED** — structure is ideal, but the family composition still blocks it; **would become RUNNABLE-TODAY if refit with only the admitted-family subset of traits** (flag for a follow-up narrowed run) |
| `scripts/16_fit_nest_empirical_validation.R` stage=`"phy"`: `value ~ 0 + trait + phylo_latent(species, d=1, tree=phy_tree)` | mixed family list | Single `phylo_latent()` block | same panel sizes | phylo structure + family mix | **R-ADAPTER-BLOCKED** (phylo kind alone is sufficient) |
| `scripts/16_fit_nest_empirical_validation.R` `stage=` Wald/profile arm: `value ~ 0 + trait + latent(0+trait\|species, d=1, unique=FALSE)` restricted to a `profile_families` subset (whatever families remain after `levels(profile_long$family)` filtering) | subset of {b,g,m,o,ln} — **subset unknown without live data** | Single rr block, `unique=FALSE` | same panels | Depends on which families survive the subset filter — **UNKNOWN** without executing the script | **UNKNOWN** — verdict depends on the runtime-filtered family subset; flagged rather than guessed |
| `scripts/20_fit_balanced_nest_4000.R` stage≠`"phy"`: `value ~ 0 + trait + latent(0+trait\|species, d=1)`, `families = list(m=multinomial, g=gaussian, b=binomial-probit, o=ordinal_probit, ln=lognormal)` | mixed (multinomial + lognormal present) | Single rr block, `unique=` unset → default TRUE | n=4,000 species (balanced panel), multi-trait | multinomial + lognormal in the family mix | **R-ADAPTER-BLOCKED** (family-mix reason, same as above) |
| `scripts/20_fit_balanced_nest_4000.R` stage=`"phy"`: `value ~ 0 + trait + phylo_latent(species, d=1, tree=phy_tree, unique=FALSE)` | same mixed family list | Single `phylo_latent()` block | n=4,000 | phylo structure + family mix | **R-ADAPTER-BLOCKED** (phylo kind) |
| `scripts/21_ci11_regression_check_500.R`, `22_ci11_gaussian_profile_500.R` | n/a — these load a saved fit (`readRDS`) and run `check_gllvmTMB()`/`extract_cross_correlations()`; **no new `gllvmTMB()` call** | n/a | n/a | n/a | **out of scope** — post-fit diagnostics only, not model-fitting calls |
| `archive/500sp/scripts/*` (6 files: `04_fit_trait_intercept_checks.R`, `05_fit_pilot_500_mixed_sequence.R`, `06_retry_failed_pilot_models.R`, `08_stabilize_revised12_rank1.R`, `09_recover_clean_rank1_replication.R`, `R/pilot_model_utils.R`) | mixed, same family palette as above (per script inspection of shared `pilot_model_utils.R` helper, which mirrors the `nonphy`/`phy` templates from script 16 at n=500) | Single rr / single phylo_latent (mirrors script 16's two structural arms) | n=500 species (pilot panel, `pilot_species_500.csv`) | same family-mix hazard for `nonphy`; phylo kind for `phy` | **R-ADAPTER-BLOCKED** (same two independent reasons as the main-tier scripts; archived/superseded by scripts 13–20 per the repo's own naming) |

**Summary for this repo**: the intercept-only per-trait screen (script 13, first row) is the one
clean win — it drops the mixed-family multi-trait latent block entirely and fits one family at a
time with no structural term, so gaussian/binomial-probit/ordinal_probit traits (of the 34) are
genuinely RUNNABLE-TODAY today, while multinomial/lognormal traits in the same script are
R-ADAPTER-BLOCKED by family alone. Every multi-trait joint model (the actual PCM validation work)
is blocked by the multinomial+lognormal family mix even in its best-structured form
(`nonphy_shared`, `unique=FALSE`, single rr) — that combination is the strongest **near-miss**:
restricting the trait battery to gaussian/binomial-probit/ordinal_probit-only traits and refitting
with `unique=FALSE` would very likely produce a genuine RUNNABLE-TODAY joint model. This is
flagged as a **follow-up candidate**, not scored as RUNNABLE-TODAY here since it requires a new
(unobserved) trait subset, not the trait battery as actually fitted in the repo.

---

## Summary table — counts by repo

| Repo | `gllvmTMB()`/`gllvm()`-touching files | Distinct model *templates* identified | RUNNABLE-TODAY | R-ADAPTER-BLOCKED | JULIA-GAP | UNKNOWN/out-of-scope |
|---|---|---|---|---|---|---|
| `avian_trait_scales` | 27 | 3 (individual 3-tier, species 2-tier, taxon/tier-restricted variants) | 0 | 3 (all templates) | 0 | 0 |
| `urbanisation_map` | 35 | ~6 (flagship main model + constrained/lambda variant + ecosystem/theme/region-stratified variants) | ~6 (all templates, modulo `unique=TRUE` soft-drop / `lambda_constraint` risk flags) | 0 | 0 | 3 files out-of-scope (galamm, not gllvmTMB) |
| `nest_morpho_gllvm` | 3 | 4 (morphology, nest-shape, combined, combined+constraint) | 0 | 4 (all templates) | 0 | data shape unknown (gitignored) |
| `BIRDBASE_pcm` | 12 (main) + 6 (archive) | ~9 (per-trait screen [split-by-family], smoke, nonphy, nonphy_shared, phy, wald/profile-subset, balanced-nonphy, balanced-phy, archive mirrors) | Partial — per-trait screen only (subset of 34 traits by family) | 7 joint-model templates + non-admitted-family traits in the screen | 0 | 1 template (Wald/profile family-subset) unresolved without live execution |

**Combined RUNNABLE-TODAY candidates: 7 distinct model definitions** —
6 from `urbanisation_map` (flagship main model + its 5 constrained/stratified variants) plus
1 from `BIRDBASE_pcm` (the intercept-only per-trait screen, restricted to its
gaussian/binomial-probit/ordinal_probit traits — a family-filtered subset of one script, not a
whole file).

## Prioritized RUNNABLE-TODAY candidates (best first acceptance run)

1. **`urbanisation_map` flagship main model** (`R/08_package_comparison/38_main_three_engine.R`,
   lines ~44–52): `traits(items) ~ 1 + latent(1|review, d=2)`, `binomial(link="probit")`,
   `unit="review"`, n=191 reviews × 44 indicators. Smallest, cleanest, single-rr, and it's the
   paper's headline model — best first target. Only caveat: default `unique=TRUE` triggers the
   documented soft Ψ-drop warning, not a hard failure.
2. **`urbanisation_map` base map-fit sweep** (`R/02_map_model/05_fit_gllvmTMB_map.R`
   `fit_one()`), same template swept over `d` and item subsets — good second/third runs to check
   rank sensitivity survives the bridge.
3. **`urbanisation_map` ecosystem/theme/region-stratified variants** (`05c`, `05d`, `08`, `13`) —
   same template, smaller n (subsets of 191) — cheap additional coverage once (1) and (2) pass.
4. **`urbanisation_map` constrained-lambda variant** (`lambda_constraint = list(unit = M)`) — run
   after the unconstrained cases pass, since `lambda_constraint` itself is an untested bridge
   kwarg (DATA-SHAPE-RISK, not a named gate).
5. **`BIRDBASE_pcm` per-trait screen, admitted-family subset** (`scripts/13_fit_cross_family_4000.R`,
   `value ~ 1` intercept-only calls) — filter `family_map` to traits whose `family_key ∈ {b, g,
   o}` before running; this needs a small script edit (skip multinomial/lognormal traits) rather
   than running the file as-is, so it is a *near-miss* RUNNABLE-TODAY, not a zero-effort one. n up
   to 4,000 species, single trait per call, no structural term.

No candidate reaches RUNNABLE-TODAY in `avian_trait_scales` or `nest_morpho_gllvm` — both are
entirely `phylo_latent()`-structured, which the bridge blocks unconditionally regardless of
family, panel size, or `unique=` setting.
