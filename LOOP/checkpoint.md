# Checkpoint — honest-0.7 parity programme (2026-09-14)

- **origin/main HEAD:** `a72e4421` (#322 post-#318 coordination board on `main`; DestB squash body still **`6c46873a`**)
- **PR #318:** **MERGED** · **PR #321:** **MERGED** (LOOP + honest-0.7 decision note)
- **PR #324:** **OPEN** [`cursor/phylo-dep-070-20260913`](https://github.com/itchyshin/GLLVM.jl/pull/324) @ `82771484` — Arc 0 `fit_phylo_dep_gllvm`; **mergeable** after main merge; CI rerun [`34802132542`](https://github.com/itchyshin/GLLVM.jl/actions/runs/34802132542) (prior run red: Documenter `:missing_docs`, shard 1/4 — shipped `check-log` conflict markers; both fixed in `fe9eab2f`)
- **Merge gate:** 8/8 Julia shards + Documenter green; **ignore** advisory Frozen R smoke (OWED **#323**)
- **Advisory OWED:** `docs/dev-log/owed/advisory-frozen-r-smoke-2026-09-14.md` · GitHub **#323**
- **Active slice:** arc **#9** `phylo_dep()` — capability row stays **`planned`** until Rose + merge
- **Dropbox checkout:** only `docs/dev-log/check-log.md` + `docs/src/api.md` were #324 fixes (now pushed); untracked `.cursor/agents/`, `.uinit/`, `.worktrees/`, etc. = other lanes — **leave unstaged**
- **RESUME:** poll #324 CI → merge-when-green → after-task for phylo-dep Arc 0 → next arc **#10** `animal_dep()` per `LOOP/arcs.md`

---

# Checkpoint — PR #318 overnight (2026-09-14, historical)

- Pre-merge head `5877a8b0`: CI **`34795604693`** — 8/8 Julia + Documenter **PASS**; advisory Frozen R **FAIL** (non-blocking)
- Merge: squash `6c46873a` @ 2026-09-14

---

# Checkpoint — honest-0.7 parity programme (2026-09-13, G0/gap-inventory slice)

- DONE: LOOP scaffold + gap inventory (`LOOP/ultra-plan.md`) + decision `2026-09-13-honest-070-parity-aim.md`
- DestB numerical evidence now on `main` via #318 (G1/G2 docs); `.unlazy/` gates still gitignored / local
