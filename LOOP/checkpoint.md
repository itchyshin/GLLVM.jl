# Checkpoint — honest-0.7 parity programme (2026-09-14)

- **origin/main HEAD:** `5e9bfcd4` (arc **#331** kernel × indep; prior **#329** @ `f110bf3e` spatial × dep)
- **PR #318:** **MERGED** · **PR #321:** **MERGED** · **PR #324:** **MERGED** · **PR #325:** **MERGED** · **PR #326:** **MERGED** · **PR #327:** **MERGED** · **PR #329:** **MERGED** · **PR #331:** **MERGED**
- **Post-#327 CI (Julia):** [`34818578019`](https://github.com/itchyshin/GLLVM.jl/actions/runs/34818578019) on `5e4f38b` — **8/8 PASS** (advisory Frozen R red, non-blocking)
- **Post-#329 CI:** [`34823285459`](https://github.com/itchyshin/GLLVM.jl/actions/runs/34823285459) on `f110bf3e` — **8/8 Julia + Documenter PASS** (2026-09-14)
- **Post-#331 CI:** [`34828508282`](https://github.com/itchyshin/GLLVM.jl/actions/runs/34828508282) on `5e9bfcd4` — **8/8 Julia + Documenter PASS** (advisory Frozen R red, non-blocking)
- **Advisory Frozen R:** non-blocking on #318/#324/#325/#327/#329/#331 pattern; OWED **#323**
- **Active slice:** arc **#14** `kernel_dep()` — branch `cursor/kernel-dep-070-20260914` (Gaussian `SourceCovariance` `:dep` wrapper or fail-loud)
- **RESUME:** open draft PR for #14 → merge → `#15` `kernel_latent()` or maintainer pick

---

# Checkpoint — PR #318 overnight (2026-09-14, historical)

- Pre-merge head `5877a8b0`: CI **`34795604693`** — 8/8 Julia + Documenter **PASS**; advisory Frozen R **FAIL** (non-blocking)
- Merge: squash `6c46873a` @ 2026-09-14

---

# Checkpoint — honest-0.7 parity programme (2026-09-13, G0/gap-inventory slice)

- DONE: LOOP scaffold + gap inventory (`LOOP/ultra-plan.md`) + decision `2026-09-13-honest-070-parity-aim.md`
- DestB numerical evidence now on `main` via #318 (G1/G2 docs); `.unlazy/` gates still gitignored / local
