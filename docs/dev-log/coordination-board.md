# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **Cursor handover — surface-admit era close** | **ACTIVE / rehydration entrypoint** | `main` @ `a0e0d696` (#249) + `#250` correction | handover `docs/dev-log/handover/2026-08-17-cursor-handover.md` | OWED/DONE/RETRACTED/PROTECTED ledger for #205–#248; env + safe-verify + do-not-stage list; Landing State ledger declaring the `handoff_gate.sh` FAIL items. **OWED:** confirm tip → AGHQ Stage-1a grid + `k=1` golden (arc-creation first) → near-parity leftovers. **≠ Tweedie `fit_gllvm` admit ≠ invent twin Δ ≠ AGHQ ledger promote ≠ write in the Dropbox checkout ≠ re-merge #247.** |
| **Overnight surface admits #241–#246** | **MERGED** (#241 `5bd236dc` · #242 `fce43de4` · #243 `104ec5a7` · #244 `07a01ede` · #245 `320c83b1` · #246 `51ffa320`) | engine record on `main`; its docs PR [#247](https://github.com/itchyshin/GLLVM.jl/pull/247) **CLOSED UNMERGED** 13:01Z | COM-Poisson / Hurdle-NB / Beta-hurdle / Ordered-beta no-X `fit_gllvm` admits + two tag-payload Identities — all on `main`. #247's overnight handoff file never landed; its substance is carried into the 2026-08-17 Cursor handover. **Do not reopen or re-merge #247.** |
| **AGHQ estimator Identity** | **ACCEPTED** (docs-only; MERGED #248) | `main` @ `1dafee68` | decision `docs/dev-log/decisions/2026-08-17-aghq-identity.md` · after-task `docs/dev-log/after-task/2026-08-17-aghq-identity.md` | Both AGHQ ledger rows stay `missing`. Stage-1a live pin `.gllvmTMB_aghq_grid`; `k=1` ≡ Laplace is the first golden test. **≠ rename VA `_gauss_hermite` ≠ stub `aghq=` knob ≠ twin Δ ≠ `src/` engine without a fresh arc.** |
| **truncated_nbinom2 Identity→Engine** | **ACTIVE / CLOSEOUT** | `cursor/truncated-nbinom2-20260815` from #205 tip `b2b99463` | plan `docs/dev-log/plans/2026-08-15-truncated-nbinom2-identity-engine.md` · after-task `docs/dev-log/after-task/2026-08-15-truncated-nbinom2-identity-engine.md` · LOOP checkpoint cites plan | Identity ACCEPTED + engine + focused **11/11**; FD 1.12e-7; Status `implemented` (shared-`r`; Arc1b OWED). Await #205 merge → rebase → PR. **≠ invent ZIP/ZINB Δ ≠ Phylo #127 ≠ ADEMP ≠ silent rtol**. |
| **Capability catch-up (post-#204)** | **LANDING (#205)** | `cursor/capability-catchup-20260815` @ `b2b99463` | after-task `docs/dev-log/after-task/2026-08-15-gllvm-jl-capability-catchup.md` · PR https://github.com/itchyshin/GLLVM.jl/pull/205 | truncated_poisson + ledger honesty; Documenter PASS; Julia CI pending. Sole merge-on-green owner = keep-going. |
| **ZINB+X confint under X** | **MERGED** #204 | `main` @ `2914cc18` | after-task `docs/dev-log/after-task/2026-08-14-zinb-x-confint.md` · Ubuntu one-fit `2026-08-15-zinb-x-confint-ubuntu-onefit.md` | `confint(ZINBCovFit)` + bridge CI lift; `_BRIDGE_NO_CI_X_FAMILIES` empty; `ci_x_*` true for `zinb`. Closed. **≠ twin Δ ≠ ADEMP ≠ per-trait r**. |
| **ZINB+X engine Arc 0** | **MERGED** #203 | `main` @ `d589bd40` | after-task `docs/dev-log/after-task/2026-08-14-zinb-x-engine.md` | `fit_zinb_gllvm_cov` / `ZINBCovFit` + identity/FD + bridge/`@formula`. Closed. **≠ twin Δ ≠ ADEMP ≠ per-trait r**. |
| **ZINB+X Identity Arc 0** | **ACCEPTED** (docs-only; MERGED #202) | `main` @ `daf95da6` | decision `docs/dev-log/decisions/2026-08-13-zinb-x-identity.md` | Shared site-X, separate `γ^z`/`γ^c`, `Λ_z=0`, **shared scalar `r`**. Closed before engine. |
| **ZIP+X confint under X** | **MERGED** #201 | `main` @ `8abdd751` | after-task `docs/dev-log/after-task/2026-08-13-zip-x-confint.md` | `confint(ZIPCovFit)` + bridge CI lift. Closed. **≠ twin Δ ≠ ZINB+X engine ≠ ADEMP**. |
| **ZIP+X engine Arc 0** | **MERGED** #200 | `main` @ `5d570b11` | after-task `docs/dev-log/after-task/2026-08-09-zip-x-engine.md` | Engine + identity/FD + bridge/`@formula`. Closed. |
| **Post-#192 capacity programme** | **CLOSED** (#197+#198 MERGED) | `main` @ `6f9050e5` | LOOP `lanes/post-bb-x-capacity-20260807/LOOP/` · decision `docs/dev-log/decisions/2026-08-09-zip-x-identity.md` | S1 #196 · S2 #197 · S3 #198 Identity. Closed before ZIP engine; engine is the lane above. |
| **Post-#192 ultra-plan G0** | **MERGED** #194 | `main` @ `49056186` | ultra-plan `docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md` | Binding G0 + arc card. Closed. |
| **Post-#192 board/handover hygiene** | **MERGED** #193 | `main` @ `2f07ad37` | handover `docs/dev-log/handover/2026-08-07-cursor-handover-post-bb-x.md` | Board/AGENTS truth + Cursor handover. Closed. |
| **BetaBinomial+X engine Arc 1+2** | **MERGED** #192 | `main` @ `f56befc1` | after-task `docs/dev-log/after-task/2026-08-05-betabinomial-x-engine-arc12.md` | Engine + bridge/`@formula` + light RCall Δ abs ≈1.50e-8 (seed=49). Closed. |
| **BetaBinomial+X Identity Arc 0** | **MERGED** #191 | `main` @ `d5d61cb7` | decision `docs/dev-log/decisions/2026-08-05-betabinomial-x-dispersion-identity.md` | ACCEPTED: per-trait φ + shared site-X γ. Closed. |
| **Post-NB1 closeout programme** | **DONE** (packaging A) | `main` @ `#187`/`#190` + this Identity | LOOP `lanes/post-nb1-closeout-20260805/LOOP/` · after-task `docs/dev-log/after-task/2026-08-05-post-nb1-closeout-programme.md` | Hygiene + Species-XB + Identity. Closed. |
| **Species-XB light RCall Arc 0** | **MERGED** #190 | `main` @ `a8d19579` | after-task `docs/dev-log/after-task/2026-08-04-species-xb-light-rcall.md` | Poisson `(0+trait):x` Δ≈4.20e-9. Closed. |
| **Post-NB1 hygiene** | **MERGED** #187 | `main` @ `f230b372` | after-task `docs/dev-log/after-task/2026-08-05-post-nb1-hygiene.md` | Board truth + Distributions + capabilities golden. Closed. |
| **NB1+X combined Arc 1+2** | **MERGED** #186 | `main` @ `a100cc63` | after-task `docs/dev-log/after-task/2026-08-05-nb1-x-engine-arc12.md` | Engine + light cell; **live Δ abs ≈1.53e-9** (seed=48). Closed. |
| **NB1+X identity Arc 0** | **MERGED** #185 | `main` @ `210de76d` | decision `docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md` · after-task `docs/dev-log/after-task/2026-08-05-nb1-x-identity.md` | ACCEPTED: per-trait φ + shared site-X γ. Closed. |
| **Board / snapshot hygiene** | **MERGED** #183/#184 | `main` @ `13d97b13` | after-task `docs/dev-log/after-task/2026-08-05-board-hygiene.md` | Post-#181 pointer truth + merged-branch GC. Closed. |
| **Ordinal+X light RCall Arc 2** | **MERGED** #181 | `main` @ `a92c5040` | after-task `docs/dev-log/after-task/2026-08-03-ordinal-x-arc2-parity.md` | `:ordinal` X helper + light `ordinal_probit`+X cell (Δ≈5e-9). Closed. |
| **Ordinal+X engine Arc 1** | **MERGED** #180 | `main` @ `e4c20195` | after-task `docs/dev-log/after-task/2026-08-03-ordinal-x-engine.md` | `fit_ordinal_gllvm_pertrait_cov` + bridge/`@formula`. Closed. |
| **Ordinal+X identity Arc 0** | **MERGED** #179 | `main` @ `0630f8e4` | decision `docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md` | ACCEPTED: per-trait cutpoints + shared γ. Closed. |
| **Gamma+X Arc 1–2 land** | **MERGED** #178 | `main` @ `5f027f19` | handover `docs/dev-log/handover/2026-08-03-cursor-handover-gamma-x-arc2-close.md` | Identity+engine+OH+Gamma+X light cell. Closed. |
| **NB2/Beta+X Arc 2** | **MERGED** #177 | `main` | after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md` | Closed. |
| **NB2/Beta+X engine Arc 1** | **MERGED** #175 | `main` | after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-grouped-cov.md` | Closed. |
| **Windows row-effect NA budget** | **MERGED** #176 | `main` | after-task `docs/dev-log/after-task/2026-08-02-windows-roweffect-na-gate.md` | Closed. |
| **Grouped dispersion one-group bug** | **MERGED** #172 | `main` | after-task `docs/dev-log/after-task/2026-08-02-grouped-dispersion-one-group.md` | Closed. |
| **MC Julia capability-status** | **MERGED** #173 | `main` | `docs/design/capability-status.md` | Closed. |
| **X/covariate light logLik** | **MERGED** #170 | `main` | after-task `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md` | Closed. |
| **Default-route NB2/Beta φ** | **MERGED** #169 | `main` | `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md` | Closed. |
| **Catch-up logLik oracle** | **DONE** | `catchup/loglik-oracle-20260801` | `docs/dev-log/handover/2026-08-01-cursor-handover.md` | Closed. |
| **Phylo Model A redesign** | Deferred / parked | PR #127 closed | `docs/dev-log/handover/2026-06-30-codex-handover.md` | Do not orphan. |
| **Dropbox checkout (stale fork)** | **PROTECTED** | `claude/jl-bridge-capabilities-20260619` | — | Never write. New work = `origin/main` worktree. |

## Current Rule

- Rehydrate via **this Active-Lane-Split**, not a single orphaned START HERE bullet.
- `START HERE (Cursor):` **`docs/dev-log/handover/2026-08-17-cursor-handover.md`**
  — the surface-admit-era close, from `origin/main` @ `1dafee68`. It classifies
  every item OWED / DONE / RETRACTED / PROTECTED and carries the Landing State
  ledger. **OWED only:** (1) confirm the tip and open-PR list — **#247 is closed
  unmerged, do not try to merge it**; (2) AGHQ Stage-1a grid + `k=1`-≡-Laplace golden test, behind a
  fresh `/arc-creation` (#248 says the engine campaign is unpaid) — **not** a
  family or surface admit; (3) near-parity leftovers: unstructured `dep()`,
  cross-validation, coverage certificate on Totoro/DRAC. Do **not** reopen
  ZIP/ZINB Identity, and do **not** open a Tweedie `fit_gllvm` admit.
- Earlier pointer, superseded but not orphaned: **Capability catch-up STOP** —
  programme landed on `cursor/capability-catchup-20260815` (after-task
  `2026-08-15-gllvm-jl-capability-catchup.md`). Its remaining chips —
  truncated_nbinom2 Arc1b per-trait dispersion, REML `test_reml.jl` promote,
  light RCall truncated cell — stay available as short slices.
- Rose fence: ≠ invent twin light Δ for cut ZIP/ZINB ≠ ADEMP/coverage unless
  Totoro/DRAC sized+asked ≠ Phylo Model A public intervals ≠ silent rtol
  widen ≠ hurdle/Tweedie+X / none×dep / slopes / AGHQ / multinomial as this
  programme's primary engine; do not re-open ZINB Identity.
- Bridge execution R→Julia only (JuliaCall); RCall = opt-in oracle.
- Stage by name; never `git add -A`; no push without instruction.
- Dropbox checkout remains PROTECTED.

## Status

- 2026-08-17 — **Cursor handover written; surface-admit era closed.** Tip
  `1dafee68` (merge of #248). Ledger at that tip: **58 implemented · 3 partial ·
  13 planned · 4 missing** (multinomial, coverage certificate, AGHQ estimator,
  Broad AGHQ). Era landed: #234 Tweedie Identity **STOP** + #236/#238 engine
  health · #235 ZIP no-X bridge fix · #241–#246 four no-X surface admits
  (COM-Poisson, Hurdle-NB, Beta-hurdle, Ordered-beta) + two tag-payload
  Identities · #248 AGHQ Identity (`missing`, no engine). ZIB three-surface arc
  complete (#218 `fit_gllvm` → #220 `@formula` → #231 bridge). `handoff_gate.sh`
  FAILed on pre-existing debris only (protected Dropbox checkout, 36 unpushed
  commits on 20 stale branches, stale `.git/index.lock` — Shinichi clears that
  one); all declared CARRIED-OVER/PROTECTED in the handover's Landing State
  ledger. Pointer: `docs/dev-log/handover/2026-08-17-cursor-handover.md`.
- 2026-08-17 — AGHQ estimator Identity **MERGED**
  [#248](https://github.com/itchyshin/GLLVM.jl/pull/248) @ `1dafee68`. Both AGHQ
  rows stay `missing`; VA `_gauss_hermite` is explicitly **not** AGHQ; Stage-1a
  live pin is `.gllvmTMB_aghq_grid` (probabilists' nodes); `k=1` ≡ Laplace is the
  first engine test. No stub knob, no twin Δ, no `src/`.
- 2026-08-17 — Overnight no-X surface admits **MERGED**: #241 `5bd236dc`
  (COM-Poisson) · #242 `fce43de4` (Hurdle-NB Identity) · #243 `104ec5a7`
  (Beta-hurdle Identity) · #244 `07a01ede` (Hurdle-NB) · #245 `320c83b1`
  (Beta-hurdle) · #246 `51ffa320` (Ordered-beta, focused 36/36 in 11.5 s).
  Tweedie `fit_gllvm` deliberately **not** opened.
- 2026-08-16 — Tweedie engine health **MERGED** #236 `cb3c8716` / #238
  `e0eabb6f`: `fit_tweedie_gllvm` and `fit_tweedie_gllvm_grouped` no longer
  advertise false convergence. Surface admit stays **STOP** (#234 `7b45ba04`;
  T2–T5 unpaid). ZIP no-X bridge arm made reachable, #235 `497be1c4`.
- 2026-08-15 — Capability catch-up programme **STOP** (Arc0–Rung4+Close).
  Ledger 49→52 implemented; bare zip/zinb; student+com_poisson promoted;
  REML OWED; truncated_poisson Identity+engine (focused 10/10). Rung5 skipped.
  Full `Pkg.test` + push/PR = next human gates.
- 2026-08-15 — ZINB+X confint under X **MERGED**
  [#204](https://github.com/itchyshin/GLLVM.jl/pull/204) @ `2914cc18`.
  `_family_ci(::ZINBCovFit)` + guard lift; `ci_x_*` true; shared scalar `r`;
  Ubuntu one-fit bridge_x 357/357.
- 2026-08-14 — ZINB+X engine Arc 0 **MERGED**
  [#203](https://github.com/itchyshin/GLLVM.jl/pull/203) @ `d589bd40`.
  `fit_zinb_gllvm_cov` / `ZINBCovFit`; shared scalar `r`; identity/FD
  green; bridge/`@formula` admit no-X `zinb` + ZINB+X.
- 2026-08-13 — ZINB+X Identity Arc 0 **ACCEPTED** (docs-only) on
  `docs/zinb-x-identity-20260813` @ `8abdd751`. Decision
  `2026-08-13-zinb-x-identity.md`: separate `γ^z`/`γ^c`, `Λ_z=0`, **shared
  scalar `r`**, Julia-forward / twin-asymmetric. **STOP** before engine.
- 2026-08-13 — ZIP+X confint under X **MERGED**
  [#201](https://github.com/itchyshin/GLLVM.jl/pull/201) @ `8abdd751`.
  Dual-γ `_family_ci` + bridge CI lift; no twin Δ.
- 2026-08-09 — ZIP+X engine Arc 0 **MERGED**
  [#200](https://github.com/itchyshin/GLLVM.jl/pull/200) @ `5d570b11`.
- 2026-08-09 — Capacity S3 ZIP+X Identity **MERGED**
  [#198](https://github.com/itchyshin/GLLVM.jl/pull/198) @ `6f9050e5`.
- 2026-08-09 — Capacity S2 BetaBinomial grouped CI **MERGED**
  [#197](https://github.com/itchyshin/GLLVM.jl/pull/197) @ `9c2b18d6`.
- 2026-08-09 — Capacity S3 ZIP+X Identity **ACCEPTED** (docs-only): decision
  `2026-08-09-zip-x-identity.md` (separate `γ^z`/`γ^c`, `Λ_z=0`, twin-
  asymmetric). Programme → **STOP** before ZIP engine (engine lane opened after merges).
- 2026-08-09 — Capacity S2 BetaBinomial grouped(_cov) CI **PR #197**
  (Wald/profile/bootstrap routed, FD Hessian; guard lifted). Focused
  tallies: capabilities 130; grouped_dispersion 131; missing_mask 89;
  confint_family 163; bridge_x 248.
- 2026-08-08 — Capacity S1 Species-XB Binomial **MERGED**
  [#196](https://github.com/itchyshin/GLLVM.jl/pull/196) @ `6aa8e0cb`
  (Δ abs ≈1.322e-9). Gaussian skipped.
- 2026-08-07 — Capacity programme ultra-plan G0 **MERGED**
  [#194](https://github.com/itchyshin/GLLVM.jl/pull/194) @ `49056186`.
  Next: `/goal` via handover
  `docs/dev-log/handover/2026-08-07-cursor-handover-post-bb-x-goal.md`.
- 2026-08-07 — Post-#192 board/handover hygiene **MERGED**
  [#193](https://github.com/itchyshin/GLLVM.jl/pull/193) @ `2f07ad37`.
- 2026-08-07 — BetaBinomial+X engine Arc 1+2 **MERGED**
  [#192](https://github.com/itchyshin/GLLVM.jl/pull/192) @ `f56befc1`
  (live Δ abs ≈1.50e-8).
- 2026-08-05 — BetaBinomial+X engine Arc 1+2 **live Δ proven** (pre-merge
  tip): abs Δ ≈ `1.50e-8`, rel Δ ≈ `1.29e-11` @ rtol `1e-6` (seed=49).
- 2026-08-05 — BetaBinomial+X Identity Arc 0 **MERGED**
  [#191](https://github.com/itchyshin/GLLVM.jl/pull/191) @ `d5d61cb7`.
- 2026-08-05 — Post-NB1 closeout programme **packaging A complete** (#187
  hygiene, #190 Species-XB, this BetaBinomial+X Identity).
- 2026-08-05 — Species-XB **MERGED**
  [#190](https://github.com/itchyshin/GLLVM.jl/pull/190) @ `a8d19579`
  (Poisson Δ≈4.20e-9).
- 2026-08-05 — Post-NB1 hygiene **MERGED**
  [#187](https://github.com/itchyshin/GLLVM.jl/pull/187) @ `f230b372`
  (#189 closed as superseded).
- 2026-08-05 — NB1+X **live Δ proven** (local focused cell seed=48): abs
  Δ ≈ `1.531e-9`, rel Δ ≈ `1.379e-12` @ rtol `1e-6`.
- 2026-08-05 — NB1+X **combined Arc 1+2 MERGED**
  [#186](https://github.com/itchyshin/GLLVM.jl/pull/186) @ `a100cc63`.
- 2026-08-05 — NB1+X **identity Arc 0 MERGED**
  [#185](https://github.com/itchyshin/GLLVM.jl/pull/185) @ `210de76d`.
- 2026-08-05 — Board hygiene **merged** [#183](https://github.com/itchyshin/GLLVM.jl/pull/183) /
  [#184](https://github.com/itchyshin/GLLVM.jl/pull/184) @ `13d97b13`.
- 2026-08-04 — Ordinal+X **light RCall Arc 2 merged**
  [#181](https://github.com/itchyshin/GLLVM.jl/pull/181) @ `a92c5040`.
- 2026-08-04 — Ordinal+X **engine Arc 1 merged**
  [#180](https://github.com/itchyshin/GLLVM.jl/pull/180) @ `e4c20195`.
- 2026-08-03 — Ordinal+X identity Arc 0 **merged**
  [#179](https://github.com/itchyshin/GLLVM.jl/pull/179) @ `0630f8e4`.
- 2026-08-03 — Gamma+X stack **merged** [#178](https://github.com/itchyshin/GLLVM.jl/pull/178) @ `5f027f19`.
- 2026-08-03 — #177 **merged**; #176 **merged**.
- 2026-08-02 — NB2/Beta+X engine #175 / identity #174 / grouped #172 / MC #173 /
  X cohort #170 / default-route φ #169 **merged**.
