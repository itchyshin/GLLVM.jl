# Codex handover: GLLVM.jl → GLLVModels.jl rename lane (2026-09-17)

Lane owner: Codex (package rename only).  
Not this lane: R–Julia true-parity programme, Mac Studio MAIN, paste-gated DRAFT harnesses, gllvmTMB engine work.  
From: Cursor (Ada) after maintainer G0 on the in-repo handoff.  
Repo: GLLVM.jl only (read-only reference: gllvmTMB twin).

---

## Rehydrate (always first)

```bash
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main
git rev-parse origin/main   # tip at handoff authoring: 8cc75587e687f56087120f650b7f730dcbe07b9d
~/shinichi-brain/tools/lane_preflight.sh .
```

Twin (reference only, no `src/` edits): gllvmTMB `origin/main` @ `02b46cfc8`; frozen oracle `b4d5fee64def88bc768dda1f1f77c29b295edd86`.

---

## Lane scope

| In scope | Out of scope |
|----------|--------------|
| Rename Julia package **GLLVM.jl** → **GLLVModels.jl** (name, module, docs, CI, registry path planning) | True-parity engine slices, ledger bind, bridge Δ campaigns |
| Docs-only **design note** first (see First deliverable) | Merge or undraft paste DRAFT PRs without Shinichi paste |
| After maintainer **G0 on the design note:** dedicated branch/PR, implementation + convention cascade | gllvmTMB TMB/likelihood surgery |
| Soft-deprecated **`GLLVM` module alias** if feasible (Julia ecosystem pattern) | Silent **`Project.toml` version bump** or parity release claim |
| Convention-change cascade per `AGENTS.md` (docstrings, Documenter, README, tests, capability matrix honesty) | Touch branches **#399**, **#411**, **#409**, **#410** except as read-only context |

Programme parity status for the rename lane: ungated implementable slice none for true-parity. Rename work does not unlock paste rows. True-parity engine remains STOP until Shinichi pastes one of the four exact strings below.

---

## Protected DRAFT PRs (do not merge, rebase, or edit without paste)

Skip **#363** and **#314** (conflicting DRAFT; leave alone).

| PR | Head (2026-09-17) | Exact paste string (Shinichi only) |
|----|-------------------|-------------------------------------|
| [#399](https://github.com/itchyshin/GLLVM.jl/pull/399) | `5249eaa237f3992b0903fd6bff5b1af59d46d639` | `accept delta dispersion A` |
| [#411](https://github.com/itchyshin/GLLVM.jl/pull/411) | `a08cf5fef0d89033b182f3db48af2b4b933369df` | `G0 Stage 1` |
| [#409](https://github.com/itchyshin/GLLVM.jl/pull/409) | `676369c066fe248d0c4b5c6bc6dac5689c42aa7b` | `S4 probe yes` |
| [#410](https://github.com/itchyshin/GLLVM.jl/pull/410) | `8360604617549885e928620d917c3541f5b1c4d2` | `ack Totoro D-139 #323 Track A` |

All four remain DRAFT until paste. Frozen R advisory red on harness PRs is allowed; Julia matrix green is the merge bar after paste.

Reference: [`docs/dev-log/owed/2026-09-16-post-402-paste-packet.md`](../owed/2026-09-16-post-402-paste-packet.md) (refresh tip SHAs after `git fetch`; live `gh pr view` outranks this table).

#357 bridge logLik MERGED on `main` @ `5ee6dc596`. Do not revert.

---

## Hard fences (both lanes)

- No gllvmTMB engine surgery from GLLVM.jl worktrees.
- **`Project.toml` stays `0.3.0`** until a separate maintainer signoff; rename PRs must not bump version for parity theatre.
- Do not mark true-parity `/goal` complete from rename progress.
- Stage by explicit path only (`git add <path>`); never `git add -A`.

---

## First deliverable (Codex Phase 0, docs-only)

1. Add a design note under **`docs/dev-log/decisions/`** or **`docs/dev-log/plans/`** (pick one; do not fork both) covering:
   - Target name **GLLVModels.jl** / module `GLLVModels` (confirm spelling with maintainer if ambiguous).
   - Migration story: General registry, GitHub repo rename timing, Documenter URL, R bridge / `RCall` load path, test env (`test/Project.toml`), CI job names, and deprecation window for `using GLLVM`.
   - Explicit **OUT** list: no parity ledger promotion, no paste-gated work, no twin Δ claims from rename.
2. **STOP at G0:** Shinichi approval on the design note before any `src/` rename commit.
3. Rose-style consistency pass on README/AGENTS/CLAUDE only if the design note touches public naming claims (narrow scope).

Do not start rename code in the same PR as this handover.

---

## After G0 (Codex Phase 1+)

1. Branch from then-current `origin/main` (rehydrate tip SHA in PR body).
2. Implement rename with **soft-deprecated `GLLVM` alias** where Julia allows (re-export or stub module with `@deprecate` messaging per project convention).
3. Run full **convention-change cascade** (`AGENTS.md`): `src/`, `test/`, Documenter, README, capability docs, bridge tests, CHANGELOG/check-log/after-task.
4. Separate PR from true-parity harnesses; no file overlap with paste DRAFT heads without coordination.
5. Definition of Done: `Pkg.test()` green, Documenter green, after-task report, check-log entry, explicit Rose sign-off on user-facing rename claims.

---

## START HERE (Codex new session)

```bash
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main && git rev-parse origin/main
sed -n '1,120p' docs/dev-log/handover/2026-09-17-codex-gllvmodels-rename.md
sed -n '1,60p' docs/dev-log/owed/2026-09-16-post-402-paste-packet.md
rg -n 'GLLVM' Project.toml src/GLLVM.jl README.md | head
```

Next action: draft the rename design note (docs-only PR) and post the PR link for maintainer G0.
