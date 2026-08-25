# Session Handoff → Claude: GLLVM.jl overnight autonomous build (2026-08-24 → 25)

**Meta:** 2026-08-24 (MDT) · **from** Claude · **to** Claude (fresh session, no inherited
chat) · authored under `~/shinichi-brain/protocols/handover-skill.md`
(`TARGET = claude`, `AUTHOR = claude`), content template
`~/shinichi-brain/protocols/handoff.md`.

You are **Claude**, resuming GLLVM.jl. You inherit **no** chat context. This committed
document is authoritative. Read `AGENTS.md` first, then this file, then reconcile
against live `git` / `gh` before touching anything.

**Lane:** `PLATFORM: claude` · `ON BRANCH: claude/lane-beyond-20260824` ·
`WORKTREE: /Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824` ·
`LANE: overnight build — structural Laplace fix + gap roadmap` ·
`OTHER LANES: cursor+#254 (OPEN, leave alone) · claude+#263 (my own prior lane,
/Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818) · worktree×98`

---

## 0. AUTHORITY — the gates Shinichi set before leaving (2026-08-24)

These are explicit and were confirmed in-session. **Do not exceed them.**

| Action | Authorised? |
|---|---|
| Commit to lane branches | **YES**, freely |
| Push lane branches to `origin` | **YES**, freely, standing |
| Open PRs | **YES** |
| **Merge anything to `main`** | **NO. Never. Human merges.** |
| Touch PR #254 or its three files | **NO** |
| Structural Laplace fix | **only if the adversarial reviewer returns PROCEED** |
| Work the roadmap beyond that | Tier 1 (correctness) then Tier 2 (capability), **stop at anything fenced** |
| Lift any further fence, unpark AGHQ, admit Tweedie, flip L47 | **NO — queue for Shinichi** |
| Make a new public capability claim | **NO** |

**The Arc1b fence on `src/families/laplace.jl` IS LIFTED** (Shinichi, 2026-08-24). That
is permission, not an obligation — see §4.

---

## 1. Critical context — read these or you will go wrong

1. **The programme is no longer "parity cells". It is a correctness fault class.**
   The Laplace log-det used the **Fisher (expected)** weight where TMB uses the
   **observed** joint Hessian. **Six confirmed instances.** Four fixed
   (NB1, truncated_nbinom2, Exponential, DeltaGamma); **two open** (Tweedie
   `tweedie.jl:26`, Student-t `studentt.jl:75`); a **seventh surface** flagged at
   `aghq_grid.jl:203`. Full record: `docs/dev-log/check-log.md` 2026-08-24 entries.
2. **Root cause is architectural.** `src/families/laplace.jl:15` defines ONE `W` and
   uses it for TWO roles: the Fisher-scoring **mode search** (expected is fine — same
   score equation, same mode) and the **log-det** (must be observed). TMB never faces
   this: `MakeADFun(..., random=)` AD's the joint nll, so its Hessian is observed
   structurally.
3. **The fix pattern already exists in-repo. Do not invent one.**
   `beta_binomial.jl:81-89`, `com_poisson.jl:109-111`, `ordered_beta.jl:93-95` all
   compute `W` as a nested ForwardDiff second derivative of the log-density and never
   had the bug. `laplace_grad.jl:283` does the same. `DRM.jl` (the Julia sibling)
   encodes it as a `_laplace_d1/d2/d3` contract, ForwardDiff-gated at rtol 1e-10.
4. **The mode solve must stay on Fisher.** Observed curvature belongs in the log-det
   ONLY. Substituting it into a mode search tuned for Fisher is exactly how the
   Exponential fix first went wrong — ‖Λ‖ ran away to ~960 against a true 0.38.
5. **`laplace_grad.jl` currently matches the Fisher marginal DELIBERATELY**
   (~`:264`). If the objective's log-det weight changes, those gradients stop being the
   gradient of the objective and degrade **silently**. They must change in the same arc.
6. **Never merge. Never `gh pr merge --auto`. Never `git add -A`.** One Julia process at
   a time — `Pkg.test()` is ~70 min and ForwardDiff fitters allocate GBs.

---

## 2. What was accomplished (verified live, not recalled)

`origin/main` = `c5b72310`. **PR #263 OPEN, mergeable, unmerged** —
`handover/2026-08-24-claude` → `main`, +3147/−43 across 22 files.

- **Twin logLik parity: 6/17 → 13/17** families paid with live paired RCall Δ, each in a
  run where previously-green cells re-verified in the same invocation.
  Blocked with source-cited reasons: tweedie(6), student(9), delta_lognormal(12),
  delta_gamma(13).
- **Three engine correctness fixes** (NB1, truncated_nbinom2, Exponential), each derived
  analytically, ForwardDiff-verified, `:fisher` preserved bit-for-bit.
- **DeltaGamma curvature fix** — complete and locally verified in the **other** lane
  (`GLLVM.jl-a43-honesty-20260818`): `test_delta_gamma.jl` 50/50, DeltaLogNormal
  unchanged at Δ = 0.000e+00 exactly. **Its full `Pkg.test()` was still running at
  handover.** See §5 OWED.
- **Infrastructure**: `runparity.jl` no longer rewrites its own `Project.toml`.
- **Measured speed**: lognormal ≈1280×, truncated_poisson ≈2.2×, Gamma ≈1.6×. An
  *algorithm* story (closed-form vs dense Laplace), not a language one. **The ~340×
  headline does not generalise** to non-Gaussian families.

## 3. Corrections made in-session — do not re-assert the originals

| Wrong claim | Truth |
|---|---|
| Mission Control board had "drifted" | **False.** `MSPL` lives in 1482 gllvmTMB files; the `#11xx` PRs are its own. Board correctly left untouched. |
| Jacobian gate catches a one-sided dropped Jacobian | A one-sided drop is caught by the ordinary Δ test. The gate uniquely catches a **both-sides** convention error. |
| "NB1 was the only instance of this class" | True only within `fit_*_grouped*`. The generic core is Fisher-only throughout. |
| Exponential bug cost ~530 loglik, ‖Λ‖≈960 | **Artifact of the fix under construction.** Real impact **0.226**, never degenerate. |
| Student-t would be the worst remaining instance | **Measured smallest** (−0.17). DeltaGamma is largest (+3.21). |

**Lesson recorded (`check-log.md`):** agreement at a fixed parameter point does **not**
imply agreement under optimisation — two Laplace paths can match bit-for-bit everywhere
you evaluate and still diverge, because the *mode solver* differs.

---

## 4. The overnight GOAL

```
🎯 GOAL
Solo platform: Claude. Lane: claude/lane-beyond-20260824.
Deliverable: Close GLLVM.jl's correctness debt, then its user-facing capability gaps
  against the gllvmTMB twin.
HEADLINE: Eliminate the Fisher-vs-observed fault class — structurally if the
  adversarial review says PROCEED, otherwise by family-local patches (Tweedie,
  Student-t) using the pattern precedented four times today.
THEN: work the gap roadmap Tier 1 (correctness) → Tier 2 (capability).
GATES: commit+push freely · NEVER merge · stop at any fence · no new public claims.
DISCIPLINE: derive → ForwardDiff-verify → implement → per-file test → parity suite →
  full Pkg.test() · one Julia process at a time · no tolerance widened · no seed
  re-rolled after seeing a result · :fisher always preserved bit-for-bit.
```

### Two workflows were in flight at handover

- **`wpuopy4e7`** — 9-agent gap survey (ledger / covariance grid / estimators+validation
  / "beyond"), each adversarially reviewed, producing a **ranked roadmap**. Its Tier 1
  and Tier 2 are the authorised work list.
- **`w3ywfi2wd`** — design + blast-radius census + **adversarial review** + implementation
  plan for the structural `laplace.jl` fix. **Its reviewer verdict is the go/no-go.**

If either result is lost, re-run from the script paths recorded in
`~/.claude/projects/.../workflows/scripts/`.

---

## 5. Next Immediate Steps — classified. Execute **OWED** only.

### OWED

1. **Lane preflight first** (absolute path, not repo name):
   `~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824"`
   State the line it asks for. #254 is the other live lane — leave it alone.
2. **Close lane 1.** In `/Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818`,
   check `/private/tmp/.../scratchpad/pkgtest-dg.log`. If it ended green
   (`Testing GLLVM tests passed`, exit 0, expect ~6463 pass / 1 broken), **commit and
   push** the DeltaGamma fix — files: `src/families/twopart.jl`,
   `test/test_delta_gamma.jl`, `docs/dev-log/check-log.md`,
   `docs/dev-log/after-task/2026-08-24-deltagamma-observed-curvature.md` (already
   written). If it went red, **fix the cause, not the test** — and note DeltaLogNormal
   must stay at Δ = 0.000e+00 exactly.
3. **Read the two workflow results.** Take the structural-fix reviewer's verdict as
   binding: `PROCEED` → follow its implementation plan; `PROCEED WITH MODIFICATIONS` →
   apply them; `DO NOT PROCEED` → do the two family-local patches instead.
4. **Whichever path: write the bit-for-bit invariance test FIRST**, before touching
   `laplace.jl`. It must prove canonical-link families (Poisson/log, Binomial/logit,
   Gaussian) are literally unchanged. That is the safety net; the risky step comes after
   it exists.
5. **Then the gap roadmap**, Tier 1 → Tier 2, stopping at every fence.

### DONE — do not redo

13/17 parity cells · NB1 / truncated_nbinom2 / Exponential fixes · the parity-harness
`Project.toml` fix · the six-instance systemic diagnosis · the measured ranking of the
three open instances · the speed measurement · PR #263.

### RETRACTED — do not propagate

The five corrected claims in §3.

### PROTECTED

#254 and its three files · `aghq_grid.jl` (PARKED) · L47 `none × dep` stays `planned` ·
Tweedie `fit_gllvm` admit (STOP #234) · the Dropbox checkout
`/Users/z3437171/Dropbox/Github Local/GLLVM.jl` (stale fork — never commit there) ·
R `gllvmTMB` (read-only reference; no engine surgery) · the `rejected` status of
"Full family R↔Julia parity claim".

---

## 6. Environment

```sh
export PATH="$HOME/.juliaup/bin:$PATH"          # Julia is NOT reliably on PATH
cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824

# R twin IS installed and reachable (this is why parity cells are payable):
#   R 4.6.0 · gllvmTMB 0.7.0 · RCall Rhome already matches R RHOME
export GLLVM_PARITY_TESTS=1
export GLLVM_PARITY_R_LIBS=/Users/z3437171/Library/R/arm64/4.6/library
```

| Command | When |
|---|---|
| `julia --project=. --startup-file=no test/test_<f>.jl` | cheap per-file check |
| `julia --project=test/parity test/parity/runparity.jl` | parity suite (~2 min), expect **219 pass / 0 broken** |
| `julia --project=. -e 'using Pkg; Pkg.test()'` | full gate, **~70 min**, never two at once |

**Do NOT stage:** `.claude/**` · `.cursor/**` · `.codex/**` · `.worktrees/**` ·
`AGENTS.md` · `docs/dev-log/coordination-board.md` ·
`docs/dev-log/handover/2026-08-18-cursor-handover.md` · `test/parity/Manifest.toml`.
Stage by explicit path; `git add -A` is forbidden.

**Gotcha:** a `pgrep -f "Pkg.test"` waiter matches its own command line and never exits.
Wait on the actual PID.

---

## 7. Blockers / open questions for Shinichi

- **PR #263 needs a human merge.** Until then `main` still carries the truncated_nbinom2
  and Exponential bugs.
- **#254 is now 6 days stale** and describes the pre-#263 world. Close as superseded,
  rebase, or leave — his call.
- **CI has not been checked** on #263 (`gh run list --branch handover/2026-08-24-claude`).
  Local suites were green; cross-platform is unconfirmed.
- Any further fence lift (AGHQ unpark, Tweedie admit, L47 promote) is his decision.

---

## Resume prompt

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-24-claude-overnight-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
