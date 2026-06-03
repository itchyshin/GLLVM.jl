# Handoff plan — fast phylogenetic Poisson (Laplace, implicit-gradient) route

**Source:** issue #61 (Codex team shutdown handoff). **Owner of follow-up:** load-code team.
**Status:** received; substantive continuation **blocked** (see below). This note
captures the tracked checklist + a concrete design for the one item that can be
grounded in code already on `main`, so the runtime-backed work is faster later.

## Blocker (verified 2026-06-03)

The handoff's deliverable is **not reachable** from a fresh clone / CI session:

- branch `codex/phylo-poisson-implicit-gradient` is **not on the remote**
  (`git ls-remote` — absent); commit `5ff0dbc` is **not a valid object** here.
  Per the issue, it "exists but has not been pushed" — it lives only on the
  originating worktree `/tmp/gllvm-phylo-nongaussian-bench`.
- PR #60's base branch (`codex/non-gaussian-fitter-gradients` @ `2d90305`) **is**
  reachable — the structured-Poisson Laplace substrate + benches live there; only
  the implicit-gradient *slice* is missing.
- The next-work list is overwhelmingly **profiling / benchmarking / ADEMP**, which
  needs a live **Julia + R `gllvmTMB`** runtime. Neither the code nor a runtime is
  available in this session.

**To proceed substantively, one of:** (1) push `5ff0dbc` (or cherry-pick onto
PR #60) so the code is reachable; (2) a runtime session for the profiling/ADEMP.

## Tracked checklist (from issue #61)

- [ ] **1. Push/cherry-pick `5ff0dbc`** into PR #60 — *blocked on the originator
      pushing the branch.*
- [ ] **2. Profile the large estimated-σ² cell** (the `--full --cells=large
      --structures=bm-tree --estimate-julia-sigma2 --iterations=400` run) — *runtime.*
- [ ] **3. Time breakdown** — outer iters / mode solves / Schur factor+logdet /
      dense trace & log-σ² derivative / cache reuse — *runtime + allocation tooling.*
- [ ] **4. Improve the large estimated-σ² path** — *design below; code lands once
      the branch is reachable.*
- [ ] **5. ADEMP recovery** for augmented phylo Poisson — *runtime; before any
      user-facing claim.*
- [ ] **6. Docs discipline** — keep fixed-σ² *speed* rows separate from estimated-σ²
      *likelihood-parity* rows in every report (a reporting rule, applicable now).

## Design — item 4 (grounded in current `main`)

### 4a. Replace dense trace/logdet with the Takahashi selected inverse

The Poisson phylo route is a Laplace approximation: per outer `(β, Λ, log σ²)` step
it solves the latent mode, builds Poisson weights `W=diag(μ̂)`, forms the Laplace
Hessian `H = Q_phy(σ²) + Zᵀ W Z` (sparse on a tree), and needs `logdet H` plus the
implicit-gradient/Jacobian-correction terms, which all reduce to
**`tr(H⁻¹ ∂H/∂θ)`** for sparse `∂H/∂θ`:

- `∂H/∂σ² = ∂Q_phy/∂σ²` is tree-sparse;
- `∂H/∂Λ_{·}` enters only through `Zᵀ W Z` and is on-pattern.

`tr(H⁻¹ ∂H/∂θ) = Σ_{(i,j)∈pat(∂H)} (H⁻¹)_{ij} (∂H)_{ji}` needs `H⁻¹` **only on the
sparsity pattern of `∂H`** — exactly the **selected inverse**. So:

- `logdet H` → already O(p) from the CHOLMOD factor (`logdet(cholesky(H))`).
- the dense `H⁻¹`/trace → **`Σ = takahashi_selinv(cholesky(Symmetric(H)))`** (or
  `takahashi_diag` where only the diagonal is needed), then contract `Σ` against each
  sparse `∂H/∂θ` on-pattern.

This is precisely the pattern the **Gaussian** phylo path already uses —
`node_grad(::SparsePhyState)` assembles its `O(p)` gradient via the Takahashi
selected inverse (`src/node_gradient.jl`, `src/sparse_phy_grad.jl`,
`src/takahashi_selinv.jl`). Mirror it for the Poisson `H`. Expected effect: the
"dense exact trace/logdet pieces" that dominate the large cell drop from `O(p²–p³)`
to ~`O(p)` on a tree — the main lever to recover scaling against `gllvmTMB`.

*Caveat already noted in `sparse_phy_grad.jl`:* the current selected-inverse helper
is used for the leaf-block inverse and the explicit O(p) Takahashi follow-up for the
full gradient is itself a planned optimization (presently O(p²) in places). The
Poisson swap should land on the same substrate so both benefit from the eventual
multi-shape "Workflow-Q" selected-inverse path.

### 4b. Boundary-aware σ²

Symptom (issue #61): the large estimated-σ² cell needs `--iterations=400` to report
`converged=true` because `σ²` sits near the boundary. Options, cheapest first:

1. **Nested 1-D profile on `log σ²`** per outer `(β, Λ)` step (scalar → cheap Newton
   with a lower floor), mirroring the Gaussian σ_eps profile-out in `src/profile.jl`
   (lme4 / MixedModels pattern). Removes the stiff coordinate from the outer problem.
2. **Boundary-aware reparam** — `σ = softplus(θ)` with a small floor, or a
   variance-ratio parameterization, so the optimizer doesn't crawl along `log σ² →
   −∞`.
3. **Penalized/REML-style boundary step** if recovery shows bias at small σ².

Start with (1) — it reuses an existing, validated pattern and directly addresses the
iteration-count blow-up.

## Reporting rule (item 6, applies now)

In any doc/README/bench summary: **fixed-σ² rows are speed isolation only, NOT
likelihood parity** (Julia fixes `σ²=0.35`, R estimates it). Estimated-σ² rows are
the parity rows (loglik diffs ≤ ~2.4e-7 in the handoff). Never mix them in a single
"X× faster" claim. **Do not advertise public phylogenetic Poisson support** until
ADEMP recovery + multi-shape Workflow-Q + allocation evidence land (Rose verdict:
PASS WITH NOTES, internal only).
