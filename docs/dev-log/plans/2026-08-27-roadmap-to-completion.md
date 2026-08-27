# Roadmap to completion — GLLVM.jl (2026-08-27)

**Definition of "complete"** (the standing goal, unchanged): full capability
parity with the gllvmTMB **0.7.0** twin — correctness debt cleared at the root,
the 17-cell parity ladder closed, the capability ledger honest, and the package
releasable (registered in General). The milestone stays **pinned at 0.7.0**;
the twin's 0.7.1 movement is tracked as a separate delta (see the ledger's
"gllvmTMB 0.7.1 delta" section), not folded into the finish line.

## Where we are

- **56 of 73** non-rejected ledger rows implemented (~77% of the intended
  surface); 7 rows deliberately rejected.
- **13 of 17** logLik parity cells paid. The 4 unpaid each have a named
  structural blocker, not an effort gap.
- PRs #263–#267 merged: sentinel-escape class fixed at 84/93 sites, CMP
  overflow, OrderedBeta underflow, GP1 escape, platform-inconsistent
  fragilities converted to observations.
- The `hessian` kwarg (all ten single-part Laplace fitters) is in flight —
  the Fisher-vs-observed headline is now *measurable by fitting*. The class
  is **not** closed; measurement ≠ adjudication.

## The arcs, in dependency order

### Arc 0 — Land the measuring instrument *(in flight, days)*

The `hessian` kwarg PR: commit → push → PR → merge on green CI (authorized).
Includes the Tweedie wrapper escape fix and the honest check-log record of it.

### Arc 1 — Adjudicate the curvature *(~3–5 days; decision #2)*

The headline's second half. Build the exact-quadrature oracle per family;
measure `:fisher` vs `:observed` marginal accuracy across family × link ×
data regime; bring the evidence to the maintainer for the default-flip
decision. Then either flip defaults (with parity oracle re-derivation — done
by someone other than whoever changed the weight) or fence the defaults with
measured justification. **Only after this may any report claim the fault
class closed.** Prior evidence to carry in: Gamma/log favoured observed
12/12; Beta/logit favoured Fisher 10/12 — the answer is per-family, not
global.

### Arc 2 — Engine-debt residue *(~2–3 days)*

Diagnosed, unfixed, all with in-code flags:

- Exponential's undamped Newton divergence in the shared grouped-dispersion
  mode solver (platform-inconsistent; needs step damping or line search).
- NB1 near-zero-dispersion boundary fragility.
- `_CMP_LOGZ_CAP` undersized for log λ ≳ 9.2.
- Two-part fitters don't yet expose `hessian` (kernel already accepts it).
- The 9 variational_* sites without a convergence flag (API decision).
- `fit.jl`'s 1e10 sentinel sits below the 1e11 screen threshold.

### Arc 3 — The four unpaid parity cells *(~1 week; decision #5)*

- **delta_gamma + delta_lognormal**: the twin shares ONE linear predictor
  across both parts; Julia uses two. This is a model-identity decision, not a
  patch — maintainer call, then implementation whichever way it goes.
- **student**: the twin estimates ν (`log_df_student`) and fits σ per-trait;
  Julia fixes ν and shares σ. An estimator gap; buildable without a decision.
- **tweedie**: fix the three recorded grouped-route defects first (a Δ
  against a defective route measures nothing), then pay the cell. The
  `fit_gllvm` admit fence (STOP #234) is separate and stays until lifted.

### Arc 4 — Ledger honesty + StatsAPI *(~2–3 days; decisions #3, #4)*

- Ledger promotions, per the 2026-08-27 evidence bundle
  (`docs/dev-log/audits/2026-08-27-ledger-evidence-bundle.md`): of the eight
  allegedly understated rows, **three promote, five keep**. Promote `mi()`
  (function API only — no formula term), mixed-family (resolving an internal
  self-contradiction; scope-qualified, with a recovery-test debt item), and —
  conditionally, maintainer wording call — none×dep (the K=p wrapper's
  Σ/σ_eps split is not separately identified; the repo's own check-log admits
  this). The kernel rows, animal×latent, Phylo Model A, and multinomial keep
  their current statuses — the audit refuted those five allegations.
- StatsAPI re-rooting: `coef`, `vcov`, `nobs`, `dof`, `loglikelihood` have
  zero implementations; add them plus `summary` (Phase-1's milestone left
  `summary` unpaid).

### Arc 5 — Capability build-out *(the long arc, ~3–4 weeks)*

In rough priority order:

1. **Covariance grid**: 8 of 16 source×mode rows planned; the twin's
   `scalar()` mode, `*_slope()`/`*_unique()`/`common=` modifiers, and the
   `kernel` source have no Julia grammar at all.
2. **Cross-validation**: twin ships `cv-internal.R` + `cv-metrics.R`; Julia
   has no `crossval` symbol and no ledger row.
3. **`@formula` categorical covariates**: `src/formula.jl` rejects
   non-numeric covariates — a real user-facing gap, small-to-mid arc.
4. **Random slopes**: keyworded (≥1) and uncorrelated (double-bar), both
   planned.
5. **AGHQ**: parked; twin ships four modules; identity already accepted —
   **needs the maintainer's unfence before any work starts.**

### Arc 6 — Release surface *(~1 week)*

- Orphaned tests, corrected by the audit: **one** orphan guards shipped
  module code (`test_phylo_gamma_xlv.jl` — wire-in blocked on an
  independent-reviewer fix of its Fisher-log-det oracle), and a **seven-file
  cluster** tests an entire subsystem (edge-incidence, contrasts, EM/SQUAREM,
  relaxed clock, branch-RE) whose `src/` files are **not included by the
  module at all** — decide ship-or-annotate before any wire-in; a mechanical
  wire-in would break the suite.
- Docs, corrected by the audit: no family has *zero* coverage in
  `response-families.md`; the thin ones are Exponential, GP1, OrderedBeta,
  and mixed-family (the last becomes a same-PR obligation if its ledger row
  promotes).
- Claim reconciliation, worse than first stated: **four** different speedup
  framings across four files (README 161–698×; changelog ~340×; comparison
  per-cell medians; gllvmtmb-parity 265.1× measured — which explicitly flags
  the ~340× as unverified in-repo). Converge on the measured figure and
  publish the non-Gaussian numbers with the "does not generalise" caveat.
- CHANGELOG consolidation + version bump (Unreleased holds ~2.5 months of
  fixes at a stale 0.3.0 pin).
- Decide whether `test/parity/` joins CI at release (currently local-only).
- Local Documenter clean; **Rose full pre-publish audit (mandatory at tag)**;
  General registry submission.

### Post-milestone — the 0.7.1 delta *(size after the 0.7.0 tag)*

Response-column slope family, internal IID column coefficients, per-source
iSDM observation formulas, column-slope covariance helpers; the twin's
mixed-family native programme also strengthened. Scope decision deferred
until the 0.7.0 milestone lands.

## Decision gates (maintainer-only, in the order the arcs reach them)

| # | Decision | Arc |
|---|---|---|
| 2 | Curvature default flips, per family, on quadrature evidence | 1 |
| 5 | Delta-family identity: one shared predictor vs two | 3 |
| — | Tweedie `fit_gllvm` admit (STOP #234) | 3 |
| 3 | StatsAPI re-rooting shape | 4 |
| 4 | Three ledger promotions (per the evidence bundle; the none×dep wording is yours) | 4 |
| — | AGHQ unpark | 5 |
| — | L47 none×dep promote | 5 |
| — | The four `rejected` rows at "full parity" (recommend non-Gaussian REML and delta latent-scale advertising STAY rejected) | 5–6 |
| — | Registration timing + parity-in-CI | 6 |

Housekeeping needing the maintainer's shell: `gh auth refresh -s workflow -h
github.com` to unblock the stranded CI.yml commit.

## Estimate

Roughly **6–8 weeks of serial lane time** to the 0.7.0-parity release,
assuming decisions land when the arcs reach them and D-139 pre-run discipline
holds. **Compressible to ~2–4 weeks** with four levers: (1) route test suites
and simulation campaigns to Totoro, breaking the one-local-Julia-process
bottleneck; (2) parallel lanes over the disjoint file sets of Arcs 2/4/5/6;
(3) the maintainer answering the consolidated decisions doc in one sitting so
no arc stalls on a gate; (4) trimming scope to "0.7.0 parity minus three
named fences" (scalar()/modifier grammar, kernel source, AGHQ) and D-139
pre-run discipline holds
for the simulation-heavy arcs (1, 3, 5). The 0.7.1 delta adds ~2–3 weeks if
taken in full. Compute: quadrature sweeps and ADEMP recovery campaigns in
Arcs 1/3/5 route to Totoro per the standing playbook once they exceed the
30-minute line.
