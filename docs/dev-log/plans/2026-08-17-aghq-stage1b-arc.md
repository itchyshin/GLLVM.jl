## ARC CARD — AGHQ Stage-1b A4(2) per-site adaptation

**Mode:** size
**Requested outcome:** not quantified — per-site Liu–Pierce adaptation on
the Stage-1a live-pin grid, with `k > 1` evaluated and `k = 1` still the
Laplace golden
**Mechanism authority:** worktree
`.worktrees/gllvmjl-aghq-stage1b-20260817` on
`cursor/aghq-stage1b-20260817` cut from `origin/main` @ `1550eef3`.
Shinichi said go ahead on this arc. **`src/` is gated:** do not edit
`src/families/aghq_grid.jl` (or any Stage-1a source) until `origin/main`
contains `17857481` / merged #251. This checkpoint is docs only.
Explicit exclusions: public `aghq=` knob, ledger promotion, twin Δ,
A4(3) structural gate, A4(4) adaptation loop, A4(5) report honesty,
`aghq_ridge`, Tweedie, #247, Dropbox checkout, a second Stage-1a worktree
**Recommended arc:** 90 minutes (range 60–120) for the *implementation*
rung once #251 is on `main`; this session is the gated docs lock
**Time contract:** ceiling 2 h once `src/` is unlocked
**Estimate confidence:** measured analogue (Stage-1a card: 90 recommended,
~45–75 actual) + Hopper A4(2) pin (do not re-derive)
**Arc 0 outcome:** Arc Card + Identity-adjacent A4(2) decision with the
Hopper pin locked; no `src/` until #251 merges
**State transition:** this checkpoint — preparation only (no engine
change). After #251: Stage-1a grid → Stage-1b adapted `k > 1` sum
(ledger rows stay `missing`)
**Executable rung and evidence:** blocked on #251 merge. After unlock:
extend `aghq_stage1a_loglik_site` (no new engine file) +
`test/test_aghq_adapt.jl`; Mac-light
`julia --project=. --startup-file=no test/test_aghq_adapt.jl`

### Hopper A4(2) pin (do not re-derive)

Per-site adaptation is Liu–Pierce at the Laplace mode. Map probabilists'
nodes with **no √2**:

```
z_ij = ẑᵢ + Lᵢ^{-T} uⱼ
log Lᵢ = aghq_logdet(i) + logsumexpⱼ(logwⱼ + inner_ll(i,j))
```

Twin DATA_ names (read-only; Julia reuses the Laplace cache, not TMB
`spHess`): `aghq_mode` / `aghq_Lt` / `aghq_logdet`. Grid
(`aghq_nodes`, `aghq_logw`) computed once via existing `aghq_grid` /
`_aghq_gh_normal` (live pin `.gllvmTMB_aghq_grid`). Adaptation
recomputed each pass; mapped nodes + `inner_ll` + `logsumexp` every eval.

Julia reuse — **extend** `aghq_stage1a_loglik_site`, do not start a new
engine file:

1. `z = _laplace_mode(...)` → `ẑ`
2. `A = Λ'WΛ + I` at that mode (expected Fisher Hessian already in
   Laplace; Identity says reuse this cache). **Do not** port the twin's
   1e-8 eigenvalue floor / `aghq_ridge`.
3. `logdet_i = −½ logdet(A)`; `chol(A)` → `R`; `L^{-T} = R^{-1}`
4. For each row `u_j` of existing `aghq_grid(d, k).nodes`:
   `z_j = z + L^{-T} u_j`; `inner_ll` as Stage-1a
   (`ℓ − ½ z′z − (d/2) log(2π)`);
   `log L = logdet_i + logsumexp(logw .+ inner_ll)`
5. At `k = 1` this **is** the existing golden (`u = 0`, `L^{-T}` unused).
   Keep evaluating the template. **Do not port** the twin's fit-time
   `k = 1` → Laplace skip (A4.4 issue).

Fail-loud: keep `_aghq_stage1a_reject_extra` (loadings-only `z_B`).

If a later Hopper pin arrives that only restates this map, fold a
one-line citation into Actuals. Do **not** guess a third grid convention
(peer `.aghq_grid` physicists' / VA `_gauss_hermite` stay out).

### Capacity ladder (implementation gated)

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 20 min | Card + A4(2) decision with Hopper pin | Start now. Stop here while #251 is open. |
| Rung 1 | 50 min | Extend `aghq_stage1a_loglik_site` for `k > 1` | Only after `origin/main` contains `17857481`. |
| Rung 2 | 15 min | `test/test_aghq_adapt.jl` Mac-light green | After Rung 1. |
| Integrate/close | 5 min | check-log + after-task; PR if slice complete | After Rung 2. |
| **Total capacity** | **90** | | Implementation minutes unused until #251. |

### Budget (this checkpoint = Arc 0)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 10 | Identity §A4(2) + Stage-1a + Hopper pin |
| Core | 5 | this card + decision note |
| Verify | 0 | no `src/`; #251 still IN_PROGRESS |
| Repair reserve | 0 | unused until implementation |
| Closeout | 5 | report card path; stop |
| **Total** | **20** | |

**In scope (after #251):** Liu–Pierce map at Laplace mode; live-pin
`aghq_grid` reuse; `k > 1` `logsumexp`; `k = 1` template golden; fail-loud
via `_aghq_stage1a_reject_extra`; focused `test/test_aghq_adapt.jl`
**Not in this arc:** A4(3) gate; A4(4) loop / fit-time `k = 1` skip;
A4(5) report honesty; `aghq_ridge`; public `aghq=`; ledger promote;
twin Δ; `_gauss_hermite`; Tweedie; merge of #247 or #251
**Evidence used:** Identity
`docs/dev-log/decisions/2026-08-17-aghq-identity.md` §A4(2); Stage-1a
`docs/dev-log/decisions/2026-08-17-aghq-stage1a-grid.md` + PR #251
(`17857481`, OPEN; Documenter SUCCESS, four Julia jobs IN_PROGRESS);
Hopper A4(2) pin (Liu–Pierce, no √2, DATA_ names, extend-not-fork)
**Risk branch:** If #251 is still open, stop at this card — do not edit
`aghq_grid.jl` and do not invent a third grid. If `k = 1` drifts off
Laplace after the extension, the template (not a skip) is wrong; do not
widen tolerance.

**Done when (full slice):** focused adapt test passes; `k = 1` still
matches Laplace; both AGHQ ledger rows still `missing`; no public knob;
no `_gauss_hermite` call. **This checkpoint is done when** the card path
exists and `src/` is untouched.
**First action:** write this card. Implementation first action after
#251: extend `aghq_stage1a_loglik_site` in the Stage-1a file (rebase
`origin/main` first).

EXECUTE DIRECTLY: Arc 0 docs lock (this card). Do **not** hand to
ultra-plan — linear slice, `src/` gated, not multi-owner fan-out.

### Actuals (complete at this checkpoint)

**Recommended / actual:** 90 (full) / ~20 (Arc 0 docs) · **Requested /
used:** N/A / ~20 minutes · **Rungs/cohorts completed:** Arc 0
**Under-run event:** none for Arc 0; Rung 1–close unused (external gate)
**Calibration:** Hopper pin retired the map unknown before coding, so
orient stayed short; implementation estimate still 60–70 min after #251
**Metric movement:** none — preparation only. Ledger rows still `missing`
**Result:** blocked · **Next arc:** Rung 1 extend
`aghq_stage1a_loglik_site` after `git fetch` shows `17857481` on
`origin/main`; rebase this branch; then Mac-light
`test/test_aghq_adapt.jl`
