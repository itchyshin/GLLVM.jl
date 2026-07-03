# Arc 1 Rose Claim Audit

Date: 2026-07-03
Worktree: `/private/tmp/gllvmjl-phylo-xlv`
Auditor: Rose

## Verdict

PASS for the internal truth-lock; BLOCK for any public promotion/tag-style claim
that source-specific `lv` is supported, mixed-family CIs exist, bootstrap rescued
the weak phylo route, or `B_eta_realized` evidence revives the old population
`B_lv` target.

The current documentation core is mostly honest: Design 73 says the Gate 0-3
`B_eta_realized` result is "strong internal evidence" only, not public
source-specific `lv` support
(`/private/tmp/gllvmjl-phylo-xlv/docs/design/73-predictor-informed-latent-scores.md:8-15`),
and repeats that mixed-family LV remains point/postfit only
(`/private/tmp/gllvmjl-phylo-xlv/docs/design/73-predictor-informed-latent-scores.md:18-25`).
Mission Control also reports `ready = 0`, `active = 0`, `queued = 0`
(`/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/sweep.json:4-9`).

Rose does not clear broader wording until the public docs and Mission Control
labels stop using terms that can be read as "partial support" or "ready to
expose" without the guard qualifiers.

## Safe Claims

- Ordinary predictor-informed latent-score effects are supported for admitted
  ordinary one-part fits, with intervals targeting `B_lv = Lambda * alpha_lv'`,
  not raw axis-effect `alpha_lv`
  (`/private/tmp/gllvmjl-phylo-xlv/docs/design/73-predictor-informed-latent-scores.md:117-124`;
  `/private/tmp/gllvmjl-phylo-xlv/docs/src/model.md:38-46`).
- Selected-entry ordinary `B_lv` profile route evidence is local for Poisson,
  Binomial logit, NB2, Gamma, Beta, and shared-cutpoint Ordinal, but is route
  evidence only, not coverage calibration or source-specific support
  (`/private/tmp/gllvmjl-phylo-xlv/docs/design/73-predictor-informed-latent-scores.md:154-160`).
- The old phylo population-`B_lv` route is negative and parked: bootstrap_basic
  `591/720 = 0.821`, optimistic bound `671/800 = 0.839`, profile_truth miss
  `LR = 9.9918 > 3.8415`, K=1 profile `98/100`, direct-slope `96/100`
  (`/private/tmp/gllvmjl-phylo-xlv/docs/dev-log/decisions/2026-07-02-lv-arc-final-closeout-and-next-capabilities.md:71-82`).
- The positive Gate 3 result is narrow: internal DRAC/Nibi evidence for
  `B_eta_realized` only, with `2495/2500 = 0.998000000`, MCSE `0.000890835`,
  five LR misses, and no public source-specific support
  (`/private/tmp/gllvmjl-phylo-xlv/docs/dev-log/decisions/2026-07-02-lv-arc-final-closeout-and-next-capabilities.md:84-101`).
- Source-specific `lv = ~ env` remains fail-loud for phylo, spatial, animal,
  and kernel structural keywords and aliases
  (`/private/tmp/gllvmjl-phylo-xlv/docs/design/73-predictor-informed-latent-scores.md:184-201`;
  `/private/tmp/gllvmjl-phylo-xlv/docs/dev-log/decisions/2026-07-02-capability-baseline-review.md:52-59`).
- Mixed-family bridge support is point/postfit only; no X, X_lv, masks, missing
  responses, or CIs are admitted
  (`/private/tmp/gllvmjl-phylo-xlv/docs/src/gllvmtmb-parity.md:161-168`;
  `/private/tmp/gllvmjl-phylo-xlv/test/test_bridge_capabilities.jl:159-178`).

## Blocked Claims

- Do not claim public source-specific `phylo_latent(..., lv = ~ env)` support,
  PR #127 reopening, R grammar exposure, or package API widening
  (`/private/tmp/gllvmjl-phylo-xlv/docs/dev-log/decisions/2026-07-02-lv-arc-final-closeout-and-next-capabilities.md:30-38`).
- Do not call `B_eta_realized` a rescue of old population `B_lv`; Fisher's
  closeout says it is a changed target, not a rescue label
  (`/private/tmp/gllvmjl-phylo-xlv/docs/dev-log/decisions/2026-07-02-lv-arc-final-closeout-and-next-capabilities.md:103-116`).
- Do not claim bootstrap rescue. Design 73 explicitly retires bootstrap for the
  current phylo weak-cell route
  (`/private/tmp/gllvmjl-phylo-xlv/docs/design/73-predictor-informed-latent-scores.md:139-146`),
  and the latest PR #165 report repeats "no bootstrap rescue"
  (`/private/tmp/gllvmjl-phylo-xlv/docs/dev-log/after-task/2026-07-03-pr165-poisson-profile-ci-fix.md:53-53`).
- Do not inherit ordinary non-Gaussian `B_lv` profile evidence into
  source-specific phylo/spatial/animal/kernel LV. Gate 0 says each
  source/family needs a new estimand, derivation, ADEMP gate, and claim audit
  (`/private/tmp/gllvmjl-phylo-xlv/docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md:7-20`;
  `/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/sweep.json:316-316`).
- Do not claim R bridge profile/bootstrap transport for `X_lv`; native Julia
  selected-entry `B_lv` profile does not imply bridge profile/bootstrap payloads
  (`/private/tmp/gllvmjl-phylo-xlv/docs/src/gllvmtmb-parity.md:128-145`;
  `/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/sweep.json:245-248`).
- Do not claim mixed-family X, X_lv, masks, missing responses, or CIs
  (`/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/status.json:946-949`;
  `/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/status.json:987-987`).

## Stale Wording Risks

- Public CI prose overstates method reliability. `docs/src/confidence-intervals.md`
  says profile has "Better coverage than Wald" and bootstrap is "The gold
  standard for skewed or bounded parameters"
  (`/private/tmp/gllvmjl-phylo-xlv/docs/src/confidence-intervals.md:59-74`).
  That wording conflicts with the Arc 1 lesson that profile and bootstrap both
  failed or were retired for the old phylo `B_lv` weak cell. It should be
  narrowed to "often preferable when calibrated for the regime" and "a
  calibration layer/fallback, not a guaranteed rescue."
- README feature bullets are mostly guarded, but the CI wording is easy to
  quote out of context. "Wald / profile / bootstrap CI routes across..." needs
  the same "where the family/structure row has passed its local evidence gate"
  qualifier used in the roadmap
  (`/private/tmp/gllvmjl-phylo-xlv/README.md:109-115`;
  `/private/tmp/gllvmjl-phylo-xlv/docs/src/roadmap.md:30-38`).
- `gllvmtmb-parity.md` uses a green-check row for "Confidence intervals" while
  later paragraphs say mixed-family and bridge `X_lv` intervals are blocked
  (`/private/tmp/gllvmjl-phylo-xlv/docs/src/gllvmtmb-parity.md:51-60`;
  `/private/tmp/gllvmjl-phylo-xlv/docs/src/gllvmtmb-parity.md:140-145`;
  `/private/tmp/gllvmjl-phylo-xlv/docs/src/gllvmtmb-parity.md:161-168`).
  The table row should carry the guard directly, not rely on later prose.
- `bridge_capabilities()` marks every row as `"partial"`
  (`/private/tmp/gllvmjl-phylo-xlv/src/bridge.jl:526-550`), and the test asserts
  that status
  (`/private/tmp/gllvmjl-phylo-xlv/test/test_bridge_capabilities.jl:157-159`).
  This is internally useful, but public surfaces must not turn "partial" into
  partial support for source-specific LV or mixed-family CIs.
- The source-specific S1 files are internal and underscore-prefixed, but they
  exist in `src/` and tests. That makes wording discipline critical: functions
  such as `_phylo_poisson_xlv_marginal_loglik` and `_fit_phylo_poisson_xlv` are
  route/canary evidence, not exported support
  (`/private/tmp/gllvmjl-phylo-xlv/src/GLLVM.jl:127-170`;
  `/private/tmp/gllvmjl-phylo-xlv/docs/design/73-predictor-informed-latent-scores.md:254-266`).

## Mission Control Updates Needed

- Rename or split the `active_work` panel in `sweep.json`. It contains guarded,
  covered, and blocked historical rows even though metrics say no active work
  (`/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/sweep.json:12-18`;
  `/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/sweep.json:48-68`).
  Suggested label: `recent_truth_events` or `operating_log`.
- Keep `ready = 0`, `active = 0`, `queued = 0` visible beside every Arc 1 panel
  that mentions S2/Totoro manifests or Gate 3, because "manifest" and "Gate 3
  passed" otherwise read like active compute
  (`/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/sweep.json:4-9`;
  `/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/sweep.json:174-174`).
- In the `status.json` source string, split the very long mixed claim paragraph
  into fields: `old_population_B_lv_negative`, `B_eta_realized_internal`,
  `source_specific_lv_fail_loud`, `mixed_family_point_only`, and
  `native_profile_B_lv_route_only`
  (`/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/status.json:5-5`).
  The current line is accurate but too dense to audit safely.
- Add an explicit dashboard glossary entry: `covered` means evidence-covered for
  the named row only; `partial` is not public support; `guard` is a blocker label
  unless a row names a direct user-facing route.
- Add a recurring Mission Control scan for the exact blocked phrases already
  used in check-log: `partial support`, `ready to expose`, `source-specific.*covered`,
  `active compute`, `bootstrap rescue`, and `mixed-family CI`
  (`/private/tmp/gllvmjl-phylo-xlv/docs/dev-log/check-log.md:10244-10252`;
  `/private/tmp/gllvmjl-phylo-xlv/docs/dev-log/check-log.md:10296-10304`).

## Rose Gate

Rose gate: BLOCK public widening; ALLOW internal closeout wording.

Required safeguards before public promotion:

1. Public docs must qualify CI methods by family/structure evidence gate and
   remove unconditional "gold standard" / "better coverage" wording.
2. README and parity tables must carry guard text inline, not only in later
   paragraphs.
3. Mission Control must avoid `active_work` as a label when no compute is active.
4. Source-specific `lv` may be claimed only after direct user-facing grammar/API
   evidence exists; internal S1 likelihood/canary files are insufficient.
5. Mixed-family CIs remain blocked until the bridge ledger, tests, docs, and
   dashboard all name a direct CI route and pass a new Rose audit.
