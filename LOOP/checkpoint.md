# Checkpoint — honest-0.7 parity programme (2026-09-14)

- **origin/main HEAD:** `1125eafb` (merge log for #318) · squash merge body **`6c46873a`**
- **PR #318:** **MERGED** (DestB G1/G2 closeout docs on `main`)
- **PR #321:** **MERGED** (honest-0.7 LOOP scaffold + decision note)
- **CI @ `6c46873a`:** run [`34798728654`](https://github.com/itchyshin/GLLVM.jl/actions/runs/34798728654) — poll for final tally (Julia 8/8 + Documenter = gate; advisory Frozen R smoke = **expected red**, non-blocking)
- **CI @ `1125eafb`:** run [`34798796239`](https://github.com/itchyshin/GLLVM.jl/actions/runs/34798796239) — Documenter on merge-log commit
- **Advisory OWED:** NB2 + truncated-NB2-BFGS + Student-t fixed-ν Frozen R smoke — see `docs/dev-log/owed/advisory-frozen-r-smoke-2026-09-14.md` · issue **#323**
- **Active slice:** `cursor/phylo-dep-070-20260913` — Arc 0 `fit_phylo_dep_gllvm` scaffold (TDD); capability row stays **`planned`**
- **RESUME:** `LOOP/GOAL.md` → `LOOP/arcs.md` (#9 phylo_dep) → identity `docs/dev-log/decisions/2026-09-14-phylo-dep-identity.md`

---

# Checkpoint — PR #318 overnight (2026-09-14, historical)

- Pre-merge head `5877a8b0`: CI **`34795604693`** — 8/8 Julia + Documenter **PASS**; advisory Frozen R **FAIL** (non-blocking)
- Merge: squash `6c46873a` @ 2026-09-14

---

# Checkpoint — honest-0.7 parity programme (2026-09-13, G0/gap-inventory slice)

- DONE: LOOP scaffold + gap inventory (`LOOP/ultra-plan.md`) + decision `2026-09-13-honest-070-parity-aim.md`
- DestB numerical evidence now on `main` via #318 (G1/G2 docs); `.unlazy/` gates still gitignored / local
