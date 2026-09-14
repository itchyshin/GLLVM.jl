# Destination B — G10 FINAL-REVIEW prep (not sign-off)

**Date:** 2026-09-14  
**Lane:** `cursor/honest-070-destb` @ `1bbd2c1e` (local; **~14 commits** ahead of `origin/main`)  
**Frozen oracle:** gllvmTMB 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86`

## Status banner

This document **prepares** the Rose + Fisher FINAL-REVIEW panel. It is **not**
FINAL-REVIEW complete, **not** a capability promotion, and **not** authorisation
to bump `Project.toml` (stays **`0.3.0`**).

---

## 1. Branch receipt inventory (G1–G7)

| Slice | After-task | Outcome (one line) |
|---|---|---|
| **R0 / G0** | `LOOP/GOAL.md` + `d68190e3` | G0 Q1–Q3 locked on branch; ultra-plan binding |
| **G1** | [`2026-09-14-destb-api-boundary.md`](2026-09-14-destb-api-boundary.md) | **API-BOUNDARY static PASS** — 32-row scope, `destination_b_scope_check.mjs` exit 0, public fence documented |
| **G2** | [`2026-09-14-destb-g2-capability-promotion.md`](2026-09-14-destb-g2-capability-promotion.md) | Arc 0 grid #9–#15 Rose promotion in `capability-status.md` (Gaussian / fail-loud fences) |
| **G3** | *(no separate after-task on branch)* | Covariance arcs **#14–#15** already on `origin/main` (#333/#334); not re-run this lane |
| **G4 / T13** | [`2026-09-14-destb-g4-t13-mi.md`](2026-09-14-destb-g4-t13-mi.md) | `mi()` row receipt — **57/57** focused tests; status already `implemented` on main |
| **G5 / T14** | [`2026-09-14-destb-g5-t14-nb2-wald-nan.md`](2026-09-14-destb-g5-t14-nb2-wald-nan.md) | F1–F3 **receipt only** (engine on main since 2026-09-02); 20 + 192 tests pass |
| **G6 / T15** | [`2026-09-14-destb-g6-t15-knife-edge.md`](2026-09-14-destb-g6-t15-knife-edge.md) | **18** knife-edge fixtures dispositioned; **0** test edits |
| **G7 / #323** | [`2026-09-14-destb-g7-frozen-r-smoke-handoff.md`](2026-09-14-destb-g7-frozen-r-smoke-handoff.md) | Codex/Totoro handoff only; **no live smoke** |

**On `main` already (via #318):** B1 close-as-limit, S3b 97/97, G1/G2 closeout narrative — see
[`2026-09-13-destination-b-g2-closeout.md`](../2026-09-13-destination-b-g2-closeout.md).

**Re-verify on panel day (cheap):**

```sh
node tools/destination_b_scope_check.mjs   # expect SCOPE_HISTORY_AND_NEGATIVE_CONTROLS_PASS
rg '^version = ' Project.toml              # expect 0.3.0
```

---

## 2. Unlazy / programme ledger (8 gates)

Ledger file: `.unlazy/destination-b-programme/GATES.md` (**gitignored**, local run state).
Authoritative narrative: G2 closeout + this branch receipts.

| Gate | Status | Evidence / note |
|---|---|---|
| `G0-SCOPE` | **Met (static)** | 32-row enum + oracle hash in scope checker; G1 after-task |
| `B1-JOINT-STATIONARY` | **CLOSED — INTERFACE LIMIT** | Decision 2026-09-13; G0 Q1 permanent |
| `B1-JOINT-PAIR` | **CLOSED — INTERFACE LIMIT** | Same |
| `B1-RECOVERY` | **NOT AUTHORIZED** | G0 Q1; off for DestB run |
| `S3B-CONSUMER` | **Met (narrow fence)** | 97/97 adapter-consumer on #318 path |
| `S4-PUBLIC-FORMULA` | **HELD** | Push authorised (G0 Q2); probe needs **second yes**; recorder may be pushed by sibling lane |
| `API-BOUNDARY` | **Met (static)** | G1 after-task on branch |
| `FINAL-REVIEW` | **OPEN — prep only** | This document; panel not held |

**Unlazy leaf `leaf-g10-final-review`:** maintainer + Rose/Fisher sign-off still **owed**.

---

## 3. Closed vs open (DestB programme)

### Closed or dispositioned (safe to cite in panel packet)

- B1 marginal curvature → interface limit (no Julia defect claim).
- S3b adapter-consumer → qualified, adapter scope only.
- 32-row **API-BOUNDARY** static identity.
- Honest-0.7 grid **#9–#15** docs promotion (Arc 0 fences).
- T13 `mi()`, T14 NB2 Wald (F1–F3), T15 knife-edge audit (document-only).
- G7 **scope** for advisory Frozen R smoke (#323).

### Open (must appear in FINAL-REVIEW memo)

| Item | Owner | Blocker |
|---|---|---|
| **#323** Frozen R smoke execution | Codex / Totoro | D-139 ack; handoff ready |
| **S4** recorder push | G9 / gllvmTMB lane | G0 Q2 push-only; object `97214679c` |
| **S4** public-formula probe | — | **Second maintainer yes** after fetch |
| **FINAL-REVIEW panel** | Rose + Fisher | This prep → sign-off memo |
| **G11 joint version note** | Ada + maintainer | Draft stub §5 below → formal `docs/dev-log/decisions/…` |
| **Arc #24** version bump | Maintainer | **Forbidden** until post-panel decision |
| **T5 / T8 / T11 / T22 / T23** | Parallel tracks | Out of DestB headline; cite as non-gates or blocked |

---

## 4. Claim fences (do not relax at FINAL-REVIEW)

- **T1:** One-directional qualification (R workflow → Julia); D8 reverse gaps dispositioned, not debt erased.
- **Arc 0:** `implemented (Arc 0 Gaussian function API only)` ≠ full family parity ≠ bridge Δ.
- **Bridge / S3b:** Experimental partial bridge; S3b ≠ generic routing ≠ B1 Wald grouping programme.
- **B1:** Closed-as-limit ≠ “Julia intervals broken”; no silent reopen without maintainer.
- **Harness:** Julia 8/8 + Documenter = merge gate; advisory Frozen R **red allowed** (`continue-on-error`).
- **Core070 497-row ledger:** Parallel track; DestB FINAL-REVIEW ≠ full ledger bind.
- **Version (D-183):** Julia `0.3.0` signals parity **earned**, not R calendar 0.7.0 ship.

---

## 5. Draft stub — joint 0.7.0 version *proposal* (DO NOT PUBLISH)

*To be promoted to `docs/dev-log/decisions/2026-09-XX-joint-070-version-proposal.md` only after FINAL-REVIEW panel.*

### Recommendation (prep default)

**Keep `Project.toml` at `0.3.0`** through FINAL-REVIEW and through publication of the joint decision note. Any move toward **`0.7.0`** is a **separate maintainer act** after explicit evidence review — not an automatic outcome of merging this branch.

### Evidence that would unlock a *later* bump **discussion** (not automatic bump)

1. **FINAL-REVIEW** signed memo: no stale README / capability-status / LOOP claims vs branch evidence.
2. **32-row DestB scope:** each reconciled row **receipted or dispositioned** in closeout matrix (no silent FREE rows for in-scope surfaces).
3. **S4:** either **HELD** with documented blocker in joint note, **or** push + probe receipt if second yes granted.
4. **#323:** either Codex frozen-oracle refresh **or** maintainer written decision to keep advisory non-gating indefinitely.
5. **CI:** merge candidate **8/8 Julia + Documenter green**; advisory smoke called out separately in release narrative.
6. **Rose pre-publish** pass on any user-facing promotion tied to version talk.

### Evidence that would **not** alone justify bump

- Arc 0 Gaussian scaffolds alone; bridge smoke; advisory-red Frozen R; T14 fix without full scope ledger; sibling gllvmTMB tag calendar.

---

## 6. Rose checklist (panel session)

- [ ] README + `docs/src/gllvmtmb-parity.md`: no “0.7 parity shipped” / no silent bridge promotion.
- [ ] `capability-status.md`: Arc 0 qualifiers intact; T13/T14/T15 pointers honest; no register codes on reader-facing tutorial text.
- [ ] `LOOP/GOAL.md` checkboxes match reality (FINAL-REVIEW still open until sign-off).
- [ ] G1 32-row map still matches `true-parity-gate-tier-2026-09-05.md` (scope script).
- [ ] No `Project.toml` version drift on merge candidate.
- [ ] Foreign-lane overlap: branch diff is docs/LOOP-heavy — confirm no accidental engine claims in docs.
- [ ] Issue **#323** state reflected (open until run or non-gating decision).

---

## 7. Fisher checklist (panel session)

- [ ] B1 close-as-limit consistent across closeout, G0, grouping interval tests (no implied recovery).
- [ ] T14: degenerate NB2 Wald behaviour matches diagnosis (boundary NaN partial, not all-NaN regression).
- [ ] T15: knife-edge fixtures documented; no undisclosed seed retargets.
- [ ] S3b: 97/97 scope matches three fixture classes only; Wald intervals named as R-bridge diagnostics where fenced.
- [ ] Frozen oracle pin unchanged (`b4d5fee6`) in parity narrative.
- [ ] Advisory smoke: R-side gradient fails not reinterpreted as Julia parity failure.

---

## 8. Draft PR readiness (Cursor assessment)

| Criterion | Ready? |
|---|---|
| Coherent docs + LOOP bundle on branch | **Yes** |
| Engine / test churn | **Low** (mostly after-task + capability prose on branch) |
| FINAL-REVIEW complete | **No** — mark PR **draft**; do not claim programme done |
| Merge to `main` | **Maintainer + green CI** only |
| Pre-merge rebase | Rehydrate `origin/main` before PR; resolve LOOP foreign-lane drift if any |

**Suggestion:** Open **draft PR** when maintainer wants visibility; title/fence: *honest-0.7 DestB programme receipts (FINAL-REVIEW pending)*. Optional push of branch — not required for prep completeness.

---

## 9. Verification (this slice)

Static: inventory read + `destination_b_scope_check.mjs` + `Project.toml` grep. No full `Pkg.test()`.

## Next after prep

1. Rose + Fisher panel (Other Models) → short sign-off memo referencing §6–§7.
2. **G11:** publish joint version proposal decision doc from §5 stub.
3. Parallel: Codex **#323**; sibling **S4 push** (no probe without second yes).
