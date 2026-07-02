# After Task: Phylo x Poisson Structural LV S2 Manifest

## 1. Goal

Convert the private S1 phylo x Poisson structural-LV finite-endpoint canary into
a predeclared S2 diagnostic manifest, without launching compute or widening any
public/R/bridge surface.

## 2. Implemented

Added a manifest-only bench helper and a durable ADEMP-style S2 decision note.
The helper writes a 20-row task grid and can dry-run task metadata, but it
intentionally performs no random draw, model fit, profile refit, Totoro launch,
or DRAC launch.

Implemented claim: an S2 diagnostic is now predeclared and auditable. No S2
statistical result exists.

## 3a. Decisions and Rejected Alternatives

Decision: keep S2 as a tiny Totoro-only diagnostic plan after explicit
maintainer authorization. Use profile-LR selected-entry `B_eta_realized` as the
uncertainty route.

Rejected alternatives:

- Rejected immediate Totoro launch; this slice is manifest/dry-run only.
- Rejected DRAC claim evidence; S3 can be planned only after S2 is green and
  separately authorized.
- Rejected bootstrap rescue; bootstrap is not the S2 uncertainty engine.
- Rejected public `phylo_latent(..., lv = ~ env)` or bridge promotion; S2 is a
  private Julia diagnostic plan.
- Rejected changing the DGP surface away from S1; S2 should test replicated
  stability before adding more axes.

## 3b. Mathematical Contract

The diagnostic target remains:

```text
B_eta_realized = slope_X(Lambda * Z_truth')
Z_truth        = X_lv * alpha_lv + epsilon
```

The predeclared S2 cell is:

```text
family/source: Poisson(log) x augmented phylogeny
p: 6
n_sites: 28
K: 1
q_lv: 1
K_phy: 1
sigma2_phy: 0.35
alpha_lv: 0.45
Lambda: [0.22, -0.18, 0.20, -0.16, 0.14, -0.12]
selected entries: 1,2,5
replicates: 20
denominator: 60 selected-entry profiles
```

## 4. Files Touched

- `bench/phylo_poisson_xlv_s2_manifest.jl` - manifest writer and dry-run
  reader.
- `docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s2-manifest.md`
  - ADEMP-style S2 decision note.
- `docs/dev-log/check-log.md` - manifest preflight log.
- `docs/dev-log/after-task/2026-07-02-phylo-poisson-structural-lv-s2-manifest.md`
  - this report.

External operating-board files refreshed in `gllvmTMB`:

- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`

## 5. Checks Run

```text
julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --write-params /tmp/phylo_poisson_xlv_s2_manifest_params.csv --reps 20 --seed0 20260702 --selected-entries 1,2,5 --profile-iterations 700 --iterations 250
wrote 20 S2 manifest tasks to /tmp/phylo_poisson_xlv_s2_manifest_params.csv

julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --params /tmp/phylo_poisson_xlv_s2_manifest_params.csv --task-id 1 --dry-run
S2 dry-run task 1 / 20
family=poisson_log source=augmented_phylo host=Totoro-diagnostic-only
seed=20260702 p=6 n_sites=28 K=1 q_lv=1
sigma2_phy=0.35 alpha_lv=0.45 epsilon_sd=0.08
Lambda=0.22;-0.18;0.20;-0.16;0.14;-0.12
selected_entries=1;2;5 level=0.95
future budgets: iterations=250 profile_iterations=700 newton=120/1e-10
target=B_eta_realized; method=private _phylo_poisson_xlv_profile_eta_realized
dry-run only: no model fit, no random draw, no Totoro/DRAC launch

julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --help
help printed expected usage and manifest-only warning

julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 4.8s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 13.5s

julia --project=. --startup-file=no test/test_phylo_glm.jl
Phylogenetic GLM (augmented-state joint Laplace): 6 passed, 0 failed, 0 errored, 4.1s

julia --project=. --startup-file=no test/test_phylo_eta_realized.jl
phylo Model A eta-realized target: 7 passed, 0 failed, 0 errored, 2.5s

julia --project=. --startup-file=no -e 'using GLLVM; println("load-ok")'
load-ok

git diff --check

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R"); main_check_after_task("docs/dev-log/after-task/2026-07-02-phylo-poisson-structural-lv-s2-manifest.md")'
after-task structure check passed

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/rose-pattern-scan.R"); main_rose_pattern_scan(".")'
Rose pattern scan passed

python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json

sh tools/start-mission-control.sh --background
GLLVM mission-control dashboard already available at http://127.0.0.1:8770/
Synced dashboard files to /tmp/gllvm-dashboard
Mirrored disposable live output to /private/tmp/gllvm-dashboard

curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

Browser preview at `http://127.0.0.1:8770/` confirmed the S2 manifest row,
selected entries `1,2,5`, the 60-entry denominator, no outcome-producing
compute, no public fitter, and no Totoro/DRAC launch language.

## 6. Tests of the Tests

The dry-run helper was exercised in both writer and reader modes, with a task-id
lookup against the generated 20-row grid. The dry-run explicitly prints that it
does not fit the model or launch compute, so a future result cannot be confused
with this manifest artifact.

This slice did not add an outcome-producing simulation runner, so no stochastic
test or coverage denominator exists yet.

## 7a. Issue Ledger

- Open: S2 compute is not authorized and has not run.
- Open: A future outcome runner still needs to connect each manifest row to
  `_fit_phylo_poisson_xlv` and `_phylo_poisson_xlv_profile_eta_realized`.
- Open: S3/DRAC claim evidence is blocked until S2 is green and explicitly
  approved.
- Closed: S2 selected entries, seeds, denominator, and host role are no longer
  implicit.

## 8. Consistency Audit

The notes keep the claim boundary intact: private route only, `B_eta_realized`
only, profile-LR first, Totoro diagnostic-only, DRAC separate, no source-
specific grammar, no bridge transport, no bootstrap rescue, and no denominator
pooling.

## 9. What Did Not Go Smoothly

The initial helper default picked entries `1,3,5`, which all had positive
loadings in the six-species DGP. I corrected the manifest to `1,2,5` before
banking the decision note, so the denominator includes both loading signs.

## 10. Known Residuals

This is not an implementation of the S2 runner. It is a pre-compute manifest
and dry-run artifact. S2 still needs explicit maintainer authorization, a
bounded host plan, and later reduction/audit code before any result can be
claimed.

## 11. Team Learning

Ada kept the slice as a planning gate. Fisher kept profile-LR as the
uncertainty engine. Curie made the denominator explicit. Gauss kept the cell
tiny because the current route is private/dense. Grace kept Totoro diagnostic
and DRAC claim evidence separate. Rose blocked support language until an actual
authorized S2 result exists.
