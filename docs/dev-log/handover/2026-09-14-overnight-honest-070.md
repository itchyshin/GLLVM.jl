# 5am handoff — honest-0.7 overnight (2026-09-14)

**Lane:** Cursor / julia-engineer · **Programme:** `LOOP/` + DestB docs (#318) + 15-cell grid Arc 0  
**Read first:** `LOOP/checkpoint.md`, `AGENTS.md`, `docs/dev-log/handover/2026-09-12-cursor-handover.md`

## `main` tip (rehydrate)

```text
git fetch origin main && git rev-parse --short origin/main
```

As of this write: **`c1849a82`** — `docs(LOOP): mark kernel_indep arc #13 merged (#331) (#332)` on top of **`5e9bfcd4`** (kernel × indep engine #331).

**`Project.toml` version:** still **`0.3.0`** (no bump this programme).

## Merged tonight (#318 →)

| PR | What |
|---|---|
| [#318](https://github.com/itchyshin/GLLVM.jl/pull/318) | DestB G1/G2 closeout docs (B1 interface limit, S3b consumer, S4 held) |
| [#319](https://github.com/itchyshin/GLLVM.jl/pull/319)–[#322](https://github.com/itchyshin/GLLVM.jl/pull/322) | DestB / board / LOOP programme hygiene |
| [#321](https://github.com/itchyshin/GLLVM.jl/pull/321) | honest-0.7 LOOP docs (`LOOP/`, no version bump) |
| [#324](https://github.com/itchyshin/GLLVM.jl/pull/324) | Arc **#9** `phylo_dep()` |
| [#325](https://github.com/itchyshin/GLLVM.jl/pull/325) | Arc **#10** `animal_dep()` |
| [#326](https://github.com/itchyshin/GLLVM.jl/pull/326) | LOOP post-#324 |
| [#327](https://github.com/itchyshin/GLLVM.jl/pull/327) | Arc **#11** `animal_latent()` |
| [#328](https://github.com/itchyshin/GLLVM.jl/pull/328) | LOOP post-#327 |
| [#329](https://github.com/itchyshin/GLLVM.jl/pull/329) | Arc **#12** `spatial_dep()` fail-loud |
| [#330](https://github.com/itchyshin/GLLVM.jl/pull/330) | LOOP post-#329 |
| [#331](https://github.com/itchyshin/GLLVM.jl/pull/331) | Arc **#13** `kernel_indep()` |
| [#332](https://github.com/itchyshin/GLLVM.jl/pull/332) | LOOP post-#331 |

## In flight at handoff

| PR | Arc | Status |
|---|---|---|
| [#333](https://github.com/itchyshin/GLLVM.jl/pull/333) | **#14** `kernel_dep()` | **Rebased** onto `c1849a82` @ `880ee80d`; **CI re-running** after conflict on `check-log.md`. **Merge when 8/8 Julia + Documenter green** (squash). Advisory Frozen R may stay red. |
| [#334](https://github.com/itchyshin/GLLVM.jl/pull/334) | **#15** `kernel_latent()` | **Draft** Arc 0 scaffold (`fit_kernel_latent_gllvm`); local **12/12**; rebase onto `main` after #333 lands. |

**LOOP tick #14 → #15:** docs-only PR (mirror #332) **OWED** immediately after #333 merge — update `LOOP/arcs.md` + `LOOP/checkpoint.md`.

## OWED — advisory Frozen R

- GitHub **[#323](https://github.com/itchyshin/GLLVM.jl/issues/323)** + `docs/dev-log/owed/advisory-frozen-r-smoke-2026-09-14.md`
- Job **Frozen R 0.7.0 family smoke** is **`continue-on-error`**; treat Julia 8/8 + Documenter as the merge gate only.

## Next arcs (maintainer pick)

1. **Finish #333 merge** → LOOP post-#333 → **#334** ready + CI.
2. **Grid closeout:** only **`kernel_latent`** (#15) left in the 15-cell honest-0.7 matrix; then second-order rows in `LOOP/arcs.md` (#16+).
3. **DestB blocked:** S4 public-formula probe still **HELD** (recorder + authorisation); B1-RECOVERY not authorized.
4. **Advisory R triage** (#323) — optional refresh of NB2 / Student-t gradient receipts on current `main`.

## Resume commands

```bash
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
gh pr checks 333 -R itchyshin/GLLVM.jl
~/shinichi-brain/tools/pr_merge_when_green.sh itchyshin/GLLVM.jl 333 --squash
julia --project=. test/test_kernel_latent.jl   # after loading branch #334
```

## Rose fence (unchanged)

Arc 0 Gaussian matrix wrappers ≠ twin Δ ≠ capability ledger promote ≠ `@formula`/bridge parity.
