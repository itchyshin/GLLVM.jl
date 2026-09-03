# T12 — grouping levels `unit` / `unit_obs` / `cluster` / `cluster2`: R semantics vs Julia surfaces

Owner requirement (relayed, `true-parity-decision-map.md:46`): *"make sure both Julia
and R have unit_obs, unit, cluster and cluster2 — it is important."* Frozen oracle:
gllvmTMB 0.7.0 `b4d5fee6`; taxonomy docs read via `git show origin/main:docs/design/...`
(design docs move faster than the frozen engine and are not themselves the oracle).

## 1. R semantics (file:line citations, frozen 0.7.0 unless noted)

`gllvmTMB()` signature (`R/gllvmTMB.R:596-599`): `unit = "site"`, `unit_obs = NULL`,
`cluster = NULL`, `cluster2 = NULL`. Resolution (`R/gllvmTMB.R:637-640`):
`unit_obs <- unit_obs %||% "site_species"`, `cluster <- cluster %||% "species"` —
i.e. `unit_obs`/`cluster` are ALWAYS active (default column names), never truly "off";
only `cluster2` stays `NULL`/inactive unless supplied.

- **`unit`** (`R/gllvmTMB.R:80-84`) — between-unit grouping (site, individual, study,
  paper). This is the base row axis of the unit×trait response matrix; every fit has one.
- **`unit_obs`** (`R/gllvmTMB.R:85-97`) — within-unit grouping, one level per
  (unit, replicate) cell. Feeds `latent(0+trait|unit_obs)` / `indep(0+trait|unit_obs)`
  (the "W-tier" covariance). If omitted, the engine synthesises it from `unit`×`cluster`.
- **`cluster`** (`R/gllvmTMB.R:98-125`) — "third grouping" slot, default `"species"`.
  When the column matches a phylogenetic `phylo_vcv`/tree it also drives `phylo_*`
  terms; otherwise it is a plain crossed/nested third grouping (e.g.
  `cluster="population"` for 3-level personality data, distinct from the species axis).
- **`cluster2`** (`R/gllvmTMB.R:126-141`) — optional SECOND independent grouping,
  default inactive. Diagonal-only (`indep(0+trait|cluster2)`), no phylogenetic/spatial
  correlation (those stay bound to `cluster`/`coords`). Must be column-disjoint from
  `unit`/`unit_obs`/`cluster` (`R/gllvmTMB.R:138-140`).
- **Nesting is never enforced by the engine** (`R/gllvmTMB.R:114-115`, 141-152) —
  crossed and nested designs both fit for all three slots.
- **Taxonomy/relationship rules** (`docs/design/01-formula-grammar.md:569-596`, origin/main;
  ratified 2026-05-16, restated `docs/design/04-random-effects.md:789-807`):
  `unit`↔`unit_obs` **MUST be nested** (every `unit_obs` level ⊂ one `unit` level,
  encoded via globally-unique level names, NOT the `(1|g1/g2)` slash form — that is
  explicitly rejected); `unit`↔`cluster` and `cluster`↔`unit_obs` **may be crossed**.
- `cluster2` gets no dedicated taxonomy section; its docstring text (above) is the
  only relationship rule that exists for it.

## 2. Julia surfaces today

- **`unit` (between-unit)**: intrinsic — every `Y` is p(species)×n(unit); no named
  kwarg needed for the base axis. Two ADDITIONAL surfaces model a genuine unit-level
  *random effect* on top: `src/families/row_effects.jl` (`fit_roweffect_gllvm` /
  `RowEffectFit`) — FIXED per-unit scalar intercept ρ_s (gllvmTMB's `row.eff="fixed"`),
  and `src/families/row_random.jl` (`fit_row_random_gllvm` / `RowRandomFit`) — RANDOM
  per-unit scalar intercept ρ_s~N(0,σ_row²) via an augmenting-loadings-column
  reparameterisation (`row_random.jl:1-24`). Both cover any `Distribution` the dense-Laplace
  machinery already supports (Binomial/Poisson/NegBin/Beta/Gamma). Neither is
  trait-specific — ρ_s is CONSTANT across species (matches gllvmTMB `row.eff`, not a
  full `latent(0+trait|unit)` decomposition).
- **`unit_obs` (within-unit)**: `src/twolevel.jl` (`fit_twolevel_gaussian` /
  `TwoLevelFit`) implements the FULL nested `unit`↔`unit_obs` two-tier decomposition —
  between block Λ_B/σ²_B (shared per unit) + within block Λ_W/σ²_W (per unit_obs
  replicate), both trait-vector-valued (`src/twolevel.jl:1-28`) — **Gaussian only**.
  No non-Gaussian family has any within-unit random effect at all.
- **`cluster` (3rd grouping, non-species)**: **none**. The species axis (R's default
  `cluster="species"`) is already the intrinsic `p` dimension of every Julia fit, so
  the *default* case is trivially "present" — but a genuine third grouping distinct
  from species (R's `cluster="population"` personality example) has no Julia surface.
- **`cluster2` (2nd independent grouping)**: **none** anywhere in the tree.
- No Julia fitter accepts a named `unit=`/`unit_obs=`/`cluster=`/`cluster2=` kwarg at all.

## 3. Mapping table

| Level | R arg (default) | Julia surface | Families | Status |
|---|---|---|---|---|
| `unit` (between) | `unit` ("site") | intrinsic axis; + `RowEffectFit`/`RowRandomFit` (scalar intercept only); + `TwoLevelFit` B-tier (full trait vector, Gaussian) | non-Gauss: scalar only; Gaussian: full | **partial** |
| `unit_obs` (within) | `unit_obs` (NULL→"site_species") | `TwoLevelFit` W-tier only | Gaussian only | **partial** (AGENT-INFERRED: "does Julia have any [obs-level RE]?" — answer: yes for Gaussian, no for the 6 non-Gaussian families) |
| `cluster` (3rd, non-species) | `cluster` (NULL→"species") | none | — | **missing** |
| `cluster2` | `cluster2` (NULL, inactive) | none | — | **missing** |

Proposed ledger rows (style: `fit-input/` and `covariance/` source_ids in
`required-source-case-map.json`), all `classification: required_core` pending
maintainer confirmation of naming (§5):

- `grouping-levels/UNIT-OBS-NONGAUSSIAN-KWARG` — named `unit_obs=` kwarg + within-unit
  RE for a non-Gaussian family.
- `grouping-levels/CLUSTER-THIRD-AXIS-KWARG` — named `cluster=` kwarg for a
  non-species third grouping.
- `grouping-levels/CLUSTER2-INDEP-KWARG` — named `cluster2=` kwarg, disjoint-column
  diagonal variance.
- `grouping-levels/UNIT-KWARG-NAME-PARITY` — thread `unit=`/`unit_obs=`/`cluster=`/
  `cluster2=` through `src/families/fit_gllvm.jl` even where a slot is a no-op on the
  intrinsic axis, so the R↔Julia argument surface matches by name (low-risk, no new math).

## 4. Sequenced build proposal (AGENT-INFERRED priority; not yet maintainer-set)

**Symbolic linear predictor, all four levels, one equation** (trait t, unit s, unit_obs
o nested in s, cluster g ≠ species crossed/nested with s, cluster2 h independent):

```
η_{t,s,o,g,h} = β_t + (Λ z_s)_t + ρ_s + ω_o + κ_{t,g} + δ_{t,h}
z_s ~ N(0, I_K)            ρ_s ~ N(0, σ_unit²)        ω_o ~ N(0, σ_obs²)
κ_{t,g} ~ N(0, σ_cluster²) (per trait)                δ_{t,h} ~ N(0, σ_cluster2²) (per trait)
```

Identifiability (AGENT-INFERRED from the existing reparameterisation proofs in
`row_random.jl` and `twolevel.jl`, not yet verified for the joint 4-term model):
- `ρ_s` vs `(Λz_s)_t`: already solved — ρ is constant-in-t, Λz_s varies by t, separated
  by the augmenting-column trick (`row_random.jl:8-13`).
- `ω_o` vs `ρ_s`: needs `unit_obs` genuinely nested (≥2 replicates per unit) or the
  within block is confounded with residual — this is the SAME caveat `twolevel.jl`
  already documents for Gaussian; carries over unchanged to non-Gaussian.
- `κ_{t,g}` is only jointly identifiable with `(Λz_s)_t` if `g` has enough replication
  independent of `s` (standard crossed-random-effect rule); this is new territory —
  no existing Julia proof to lean on.
- `δ_{t,h}` requires `h` disjoint from `s`/`o`/`g` (R enforces this at the argument
  level, `R/gllvmTMB.R:138-140`); Julia would need the same disjointness check or risk
  double-counting a variance component.

Sequence:
1. **Kwarg name-parity pass** (`UNIT-KWARG-NAME-PARITY`) — thread the four names
   through `fit_gllvm.jl` as accepted-but-currently-no-op-beyond-existing-surfaces
   kwargs. Red-first: `test/test_grouping_kwargs.jl` asserting `fit_gllvm(...;
   unit=:site, unit_obs=:obs, cluster=:species, cluster2=nothing)` does not error and
   is byte-identical to the no-kwarg call. Currently fails — no such kwargs exist.
2. **Non-Gaussian `unit_obs`** — extend `row_random.jl`'s single augmenting column to
   TWO (unit + unit_obs), each ~N(0,σ²), for the 6 dense-Laplace families. Red-first:
   ADEMP recovery test simulating Binomial/Poisson data from a real nested
   (unit, unit_obs) intercept DGP, asserting recovered σ_unit, σ_obs within tolerance.
   Currently fails — no two-tier non-Gaussian fitter exists.
3. **`cluster2`** — generalise the row_random augmenting-column trick to an ARBITRARY
   grouping vector (not just the unit index), giving a per-trait `indep()` variance at
   a caller-supplied grouping distinct from unit/species. Red-first: two disjoint
   groupings (site, year) fit simultaneously, both variances recovered.
4. **`cluster` as genuine 3rd axis** — hardest: needs a grouping orthogonal to BOTH the
   n(unit) and p(species) axes with its own per-trait variance, potentially crossed
   with unit. Sequence last (per `true-parity-decision-map.md:64`: "sequenced after
   phylo transport unless the maintainer reorders").

## 5. Open questions for the maintainer

1. **Naming**: keep the R names verbatim as Julia kwargs (`unit=`, `unit_obs=`,
   `cluster=`, `cluster2=`), or use Julia-idiomatic names with a documented R↔Julia
   map? (`true-parity-decision-map.md:64` flags this as *decide-with-Shinichi*.)
2. **Priority**: does "it is important" mean bump ahead of phylo transport (S1–S2), or
   does the existing "sequenced after phylo transport" default still hold?
3. **Scope for `cluster`/`cluster2`**: diagonal-only (matching R's own `cluster2`
   restriction — no phylogenetic/spatial correlation), or should Julia's `cluster`
   support correlated structures from the start since GLLVM.jl already has
   `Λz_s`-style ordination machinery R lacks on that axis?
4. **Struct collision**: `row_effects.jl`/`row_random.jl` already use "row" for what R
   calls `unit`. Alias the new `unit=`/`unit_obs=` kwargs onto those existing structs
   (renaming fields), or introduce a parallel fitter family to avoid breaking existing
   `RowEffectFit`/`RowRandomFit` callers?

Everything in §1–§3 is read directly from the cited files; §4's sequencing,
identifiability claims for the joint 4-term model, and risk framing are
AGENT-INFERRED and unverified by any test.
