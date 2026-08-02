# NB2 / Beta + X identity → light logLik — Ultra Plan

> **For agentic workers:** implement task-by-task. Checkboxes track progress.
> Design lock: `docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md`

**Goal:** Unlock NB2+X and Beta+X light gllvmTMB logLik cells under the
**per-trait φ + shared site-X** twin identity (API B under X).

**Architecture:** Reuse grouped NB2/Beta Laplace + `fit_gllvm_cov` X offset
machinery; public/bridge default = per-trait φ with X; shared φ+X stays opt-in.
Parity cells only after Julia identity greens.

**Tech stack:** GLLVM.jl (Julia ≥1.10), opt-in RCall parity vs gllvmTMB twin,
Mission Control claim fences.

**Out of scope this plan:** Gamma+X default flip; Ordinal+X; species-specific XB;
X_lv; ADEMP; coverage; Phylo Model A; changing no-X API B.

---

## Arc 0 — Design lock (THIS PR / branch)

- [x] Decision note: `docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md`
- [x] This ultra-plan
- [x] Board pointer + START HERE refresh
- [x] PR docs-only (no `src/` engine edits) — #174 merged

**Done when:** decision merged or at least reviewed; fence text cites per-trait+X.

---

## Arc 1 — Engine: per-trait φ + shared X (separate PR)

### Files (expected)

- `src/families/grouped_dispersion.jl` and/or `src/families/covariates.jl`
- `src/families/fit_gllvm.jl` / `src/bridge.jl` (routing only)
- `test/test_grouped_dispersion.jl` or new `test/test_nb_beta_x_identity.jl`
- Docstrings + `docs/src/response-families.md` / tutorial cascade if API user-facing

### Tasks

- [x] **T1** Sketch θ packing: `[β; γ; pack(Λ); log r_1…log r_G]` (NB2) and
      analog for Beta φ; confirm vs `rr_theta_len` and cov γ length.
- [x] **T2** Implement marginal with X offset + per-species family markers
      (reuse `_nb_grouped_loglik_site` / beta twin with offset).
- [x] **T3** Fit driver (new or extended) with warm start = cov Zemp + SVD +
      moderate per-trait log-disp; default `hessian=:observed` for TMB; expose
      `hessian=:fisher` for identity.
- [x] **T4** Identity tests (no R):
  - G=1 + X + `hessian=:fisher` ≈ `fit_gllvm_cov` shared (atol/rtol as #172 spirit;
    **no silent widen**)
  - constant rvec/φvec with X equals shared cov marginal (machine precision on ll)
- [x] **T5** Wire public/bridge default for NB2/Beta+X to per-trait path; keep
      shared `fit_gllvm_cov` as opt-in.
- [x] **T6** Focused tests green; update check-log + after-task; Rose fence.

**Done when:** identity tests green; bridge capabilities note per-trait under X;
no light RCall claim yet.

---

## Arc 2 — Light RCall cells (separate PR)

### Files

- `test/parity/parity_helpers.jl` (reuse `fit_gllvmtmb_parity_loglik_x` /
  `parity_site_design`)
- `test/parity/test_x_covariate_parity.jl` (add NB2 + Beta cells)
- twin gllvmTMB @ fresh `origin/main` (not Dropbox coverage fork)
- LOG under `docs/dev-log/`

### Tasks

- [ ] **P1** Recreate twin + R lib; confirm R formula is shared-X
      (`0+trait + x + latent(..., unique=FALSE)`), **not** `(0+trait):x`.
- [ ] **P2** Julia call uses per-trait+X path from Arc 1.
- [ ] **P3** Mild DGP if R warns (Binomial lesson from #170); **rtol 1e-6 fixed**.
- [ ] **P4** Live `GLLVM_PARITY_TESTS=1` run; paste ΔlogLik; after-task + board.

**Done when:** NB2+X and Beta+X light cells green at rtol 1e-6; claim fence
updated (still ≠ full family parity).

---

## Compute

- Arc 0–1: laptop / Totoro fine.
- Arc 2: ask *"Totoro or DRAC?"* before large grids; light cells OK on Totoro.

## Dependencies / sequencing

```text
#172 one-group Fisher identity (land) ──┐
#169 per-trait no-X                    ├──► Arc 0 (design) ► Arc 1 (engine) ► Arc 2 (parity)
#170 G/Bin/Pois+X helpers              ──┘
```

Do **not** start Arc 2 before Arc 1 identity greens.
