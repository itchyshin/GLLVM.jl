# After-task — REML ledger promote + Rose ledger honesty pass (2026-08-16)

**Operator:** Cursor (Ada voice; Rose + Fisher lenses)
**Lane:** `cursor/ledger-reml-20260816`
**Worktree:** `.worktrees/gllvmjl-ledger-reml-20260816`
**Base:** `origin/main` @ `51d5d310` (merge of #223; after #218 / #219 / #220)
**Mode:** Mac-light — focused local run only; the full `Pkg.test()` matrix is
GitHub CI's job. Automerge on green was authorised for this slice.

## Goal (as a check, before code)

Two cheap clears carried over from the #219 gap sheet's "second-priority
follow-ups":

1. `test_reml.jl` exists and passes, so the `REML (Gaussian pilot twin)` ledger
   row can move off `planned` **on evidence** rather than on say-so.
2. `docs/design/capability-status.md` tells the truth after the #218 / #220
   merges: bare MC tokens for `lognormal` / `censored_poisson`, no stale "ZIB has
   no `fit_gllvm`" claim, evidence pointers for rows that had none, and no
   invented twin Δ.

## What landed

### 1. `test/test_reml.jl` (new) + `test/runtests.jl` wiring

The lane check surfaced an existing `test/test_reml.jl` on the unmerged
`a1-nongaussian-ci` branch. Rather than fork a second REML test, this file is
**built on theirs**: same testset names and seeds (`31001`–`31004`) so that
branch rebases without a conflict, restricted to the REML surface `main`
actually ships, and extended with two checks their version does not carry:

- **span-of-`X` invariance** — adding `X*b` to the data leaves the criterion
  unchanged and moves `β̂_GLS` by exactly `b`. This is the defining property of a
  restricted likelihood, and it fails loudly if the `(q/2)log2π − ½logdet M`
  adjustment or the GLS profile is ever mis-wired.
- **bridge `reml = true`** — `bridge_fit(; family = "gaussian",
  options = Dict("reml" => true))` returns `model == "gaussian_reml_rr"` and its
  `loglik` / `alpha` / `sigma_eps` match `fit_gaussian_reml` to rtol 1e-8. The
  ledger note claimed a bridge REML path; nothing tested it until now.

Deliberately **left on the feature branch**: the
`fit_gaussian_gllvm(reml = true)` profile-engine testsets and the phylogenetic
REML rotation-trick oracle. Neither engine is on `main`; importing those
testsets would have been a green test for absent code. A scope note at the top
of the file records this.

Gates encoded (Workflow Q checks 1 and 2):

| Gate | Form | Result |
|---|---|---|
| Dense oracle | `gaussian_reml_loglik` vs hand-rolled dense Σ_y REML | rtol 1e-8 |
| GLS profile | `_gaussian_gls` β̂ and `logdet M` vs dense | rtol 1e-8 |
| Helper consistency | REML = ML-at-β̂ + adjustment | rtol 1e-10 |
| Error contrasts | criterion invariant to `y + X*b`; β̂ → β̂ + b | rtol 1e-9 / 1e-8 |
| FD gradient | central FD vs ForwardDiff on `[pack_lambda(Λ); log σ]` | ≤ 1e-6 |
| Recovery | β, σ_eps, and `cor(vec ΛΛ')` at p=6, K=2, n=120 | atol 0.15 / 0.3; cor > 0.8 |
| Validation | `K = 0`, `K = p`, wrong-`p` `X` throw | `ArgumentError` / `DimensionMismatch` |
| Bridge route | `gaussian_reml_rr` vs standalone fitter | rtol 1e-8 |

**Verify (printed tally, no tolerance widened):**

```
julia --project=. -e 'include("test/test_reml.jl")'
Test Summary: | Pass  Total   Time
Gaussian REML |   23     23  15.3s
```

### 2. `docs/design/capability-status.md`

- `REML (Gaussian pilot twin)`: `planned` → **`implemented`**. The recorded OWED
  was precisely "add `test_reml.jl` before promote"; that is now discharged. The
  note is rewritten to name the evidence and to fence the row to the standalone
  + bridge Gaussian path — `fit_gaussian_gllvm(reml = true)` and phylo REML are
  explicitly marked as *not* on `main`. Non-Gaussian REML stays `rejected`.
- ZIB note **de-staled**: it still said ZIB had "no `fit_gllvm`, `@formula`".
  #218 and #220 landed both for the no-X case. The note now says so and keeps
  ZIB+X on those surfaces, `bridge.jl`, `confint` under X, and any twin parity
  claim as OWED.
- Evidence pointers added for `lognormal`, `censored_poisson`, the ZIB no-X
  surface, and REML. Every path cited was checked to exist in this checkout.

**Not changed, and why:** `lognormal` and `censored_poisson` status cells were
*already* bare `implemented` on `main` (the ADMIT merge got there first), so no
token flip was needed — the honest gap was the missing evidence pointers, which
is what this PR fills. Two older branches (`cursor/family-admit-20260815`,
`fix/gamma-x-grouped-cov-20260803`) still carry pre-ADMIT versions of these rows;
`main` is ahead of both and nothing was reverted.

## Deferred, with the reason

**NB1 / BetaBinom no-X `_fit_gllvm` arms** — considered as an optional third
clear and **not** taken. It is not the surgical twin of ZIB #218:

1. Neither marker is exported (`ZIB` was). Exporting `NB1` / `BetaBinom` is a
   public-API change, which AGENTS.md puts behind maintainer approval.
2. `ZIB(N)` carries a *structural* scalar the fitter needs; `NB1(φ)` and
   `BetaBinom(φ)` carry a dispersion the fitters **estimate**. So an arm has to
   decide whether marker-`φ` is ignored, becomes `φ_init`, or is held fixed —
   a parameterisation decision that wants a `docs/dev-log/decisions/` note.
3. `BetaBinom` additionally needs the `p×n` trial matrix `N`, which is not on
   the marker at all.

Recommend a small own-G0 arc with a decision note, not a drive-by.

## Rose verdict

Claim-vs-evidence: **OK for this slice.**

- Every ledger sentence added here points at a file that exists in the tree.
- No twin light Δ asserted. `censored_poisson`'s stays **forbidden** (twin is
  constructor-only); `lognormal`'s stays **owed**.
- No ADEMP or coverage certificate claimed for the promoted REML row.
- No tolerance widened; no existing test edited.
- Verification is a focused-file tally plus the CI matrix, and the report says
  which is which. `Pkg.test()` was **not** run locally (Mac-light) — the promote
  therefore rests on the focused 23/23 plus GitHub CI green, and this report
  should not be read as claiming a local full-suite pass.

## Next

1. `bridge.jl` for `lognormal` (the one genuinely OWED bridge row named above).
2. NB1 / BetaBinom no-X arc with the marker-`φ` decision note.
3. The mixed-family / `mi()` ledger-verify pass — gap-sheet item (b), still zero
   engine cost.
