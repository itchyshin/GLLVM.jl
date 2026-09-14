# After Task: B1 Gaussian `unit` source-alignment checkpoint

## 1. Goal

Retain a source-attested, fixed-coordinate contract for the existing Gaussian
rank-one `unit` grouping route, without claiming fitted R--Julia parity or a
qualified Destination B capability row.

## 2. Implemented

Added a public Julia regression that independently forms the dense marginal
covariance and Gaussian negative log likelihood for one rank-one shared-unit
source, then checks the existing sparse public route at supplied coordinates.
It includes a changed-membership control.  Added an audited frozen-R 0.7.0
receipt runner that uses the matching repeated-site long-data layout and
records its source/build lineage.  No Julia production source or gllvmTMB
engine source changed.

## 3a. Decisions and Rejected Alternatives

The R and Julia fixtures share the grouping partition and model definition,
but do not yet share one numeric response fixture or compare fitted output.
They are therefore source alignment, not paired numerical parity.  The frozen
R runner archives the exact Git object and, for a new explicit library,
installs it with `R CMD INSTALL --preclean`; reusing a merely version-matched
installed package was rejected because it would not bind the executing code to
the frozen SHA.

The R long data retain four repeated `site` levels and two distinct
`site_species` replicate cells per site.  `site_species` identifies an
observation cell; it does not silently add a second fitted covariance source.
The wrong-map control moves exactly one Julia observation from `:b` to `:a`.
A complete relabelling would be invariant and was rejected as a control.

### Mathematical Contract

For traits `t`, observations `i`, and grouping partition `g(i)`, this narrow
route uses

\[
Y_{ti} = \beta_t + \lambda_t z_{g(i)} + \epsilon_{ti},\qquad
z_g \sim \mathcal N(0,1),\quad
\epsilon_{ti} \sim \mathcal N(0,\sigma_\epsilon^2),
\]

with `unique=false`, so
`Sigma_unit = Lambda * Lambda'` and

\[
V_{(t,i),(u,j)} =
\mathbf{1}\{g(i)=g(j)\}(\Lambda\Lambda^\mathsf T)_{tu} +
\mathbf{1}\{i=j, t=u\}\sigma_\epsilon^2.
\]

The retained alignment record is
`docs/dev-log/decisions/2026-09-08-destination-b-b1-unit-symbolic-alignment.md`.

## 4. Files Touched

- `test/test_destination_b_public.jl` — independent dense-NLL and
  changed-membership public-route regression.
- `tools/destination_b/b1_unit_gaussian_reference.R` — frozen-R receipt
  builder with archive/DLL provenance checks.
- `docs/dev-log/decisions/2026-09-08-destination-b-b1-unit-symbolic-alignment.md`
  — source-alignment and identification contract.
- `docs/dev-log/core070/destination-b-b1/frozen-r070-unit-gaussian-receipt.json`
  — retained frozen-R formula receipt.
- `docs/dev-log/core070/destination-b-b1/README.md` — reproducibility entry
  point and exact fixture scope.
- `docs/dev-log/check-log.md` and this report — evidence and scope boundary.

## 5. Checks Run

- `GLLVM_TEST_SHARD=153/292 julia --startup-file=no --history-file=no
  --warn-overwrite=no --project=. -e 'using Pkg; Pkg.test(; julia_args=Cmd(["--warn-overwrite=no"]))'`
  passed 18/18 in 11.0 s and again in 10.9 s through the B1 ledgers.
- `Rscript --vanilla tools/destination_b/b1_unit_gaussian_reference.R
  --source /private/tmp/destination-b-20260907-r-frozen --library
  /private/tmp/gllvmTMB-frozen-r070-b1-library-20260908-archive --output
  docs/dev-log/core070/destination-b-b1/frozen-r070-unit-gaussian-receipt.json`
  exited 0 and wrote the retained receipt.
- A separate JSON assertion checked the frozen source SHA/version, 4-site ×
  2-replicate × 2-trait shape, and `Sigma_B = Lambda_B * Lambda_B'`; it printed
  `B1_R_RECEIPT_ASSERTIONS_OK`.
- The three B1 ledgers reverified with `ALL MET (3 met)`.
- Full package `Pkg.test()`, documentation build, JET, Allocs, and Aqua were
  not run: this checkpoint changes no Julia production source, public API,
  dependency, export, or documentation page.  The repository-wide after-task
  executable remains separately blocked by older malformed Unlazy ledgers.

### Benchmark Numbers

Benchmarks: N/A — no model or numerical hot path changed.  The focused Julia
test shard took 10.9–11.0 s and the frozen-R reuse run completed in seconds;
both are below the 30-minute compute gate.

### R-Parity Verdict

Parity: N/A — the frozen R formula receipt and Julia fixed-coordinate oracle
are intentionally separate.  No shared-data fitted R--Julia likelihood or
parameter comparison was performed.

### JET / Allocs / Aqua Verdicts

- JET: N/A — no Julia `src/` hot path changed.
- Allocs: N/A — no Julia inner loop changed.
- Aqua: N/A — no exports, dependencies, or project metadata changed.

## 6. Tests of the Tests

The Julia test has an independent dense covariance/Cholesky NLL oracle and a
wrong partition that moves only one membership.  Both the dense and grouped
objectives must change while agreeing with their respective independently
assembled covariance.  This satisfies the independent-calculation and
failure/control clauses; it is not a red/green test for a new production fix.

## 7a. Issue Ledger

No issue action needed.  This is an evidence checkpoint in the approved local
Destination B lane; the user did not authorise a push, merge, release, or
public capability claim.

## 8. Consistency Audit

Ran `rg -n --glob '!docs/dev-log/**' 'Gaussian only|not yet implemented|planned
next|TODO|FIXME' README.md docs CLAUDE.md` and
`rg -n --glob '!docs/dev-log/**' '340.?x|machine precision|closed.?form|gllvmTMB|R
reference|read.?only reference' README.md docs/src docs/PERF-plus-design.md
CLAUDE.md`.  The results were existing, scoped Gaussian and R-reference
language; B1 changes no user-facing documentation.  This report, the decision
record, and the check log explicitly state the nonqualification boundary.

## 9. What Did Not Go Smoothly

The initial three acceptance ledgers declared `CWD: .`, which the checker
correctly resolved relative to each ledger folder rather than the package root.
It exposed the commands as unable to find the Julia project/R runner.  The
ledger CWD was corrected to the exact worktree root and all gates were freshly
reverified.  A one-off R assertion initially treated JSON nested lists as a
numeric matrix; inspecting its structure showed the checker needed `unlist`,
after which it printed its success marker.  The final file audit also found an
untracked B1 README still describing an obsolete 12-site/3-trait draft; the
script and receipt have always used the retained 4-site × 2-replicate ×
2-trait design, and the README was corrected before staging.  None of these
incidents changed model code or evidence scope.

## 10. Known Residuals

- This checkpoint is not a fitted same-data R--Julia comparison or optimizer
  agreement.
- It has no interval, recovery, coverage, or real-data evidence.
- It covers only Gaussian rank-one `unit`, not `unit_obs`, `cluster`,
  `cluster2`, non-Gaussian grouping, S3b/S4, tree/pedigree/dense-`vcv`, FRK,
  0.7.1, or a Destination B capability qualification.
- The parent programme’s independent gates and older unrelated ledger parser
  state remain open.
- The handover's named G0 decision remains absent.  This checkpoint does not
  authorise any next grouping, S3b/S4, dense-`vcv`, or FRK leaf.

## 11. Team Learning

For source-attested reference checks, bind the executable package payload as
well as the source revision, and make the ledger’s command working directory
explicit rather than relying on relative-path intuition.

## 12. Cross-Product Coverage

B1 covers one two-trait, four-unit, two-replicate Gaussian rank-one source
shape and one changed-membership control.  It does not cover all grouping
levels jointly, any response family beyond Gaussian, interval feasibility,
recovery, coverage, public R bridge admission, S3b/S4, dense `vcv`, FRK, or
any release/parity claim.

## Rose Verdict

Rose verdict: PASS WITH NOTES — the narrow source-alignment checkpoint is
independently reviewed and all three declared gates reverify, while fitted
parity, statistical evidence, and the parent Destination B programme remain
explicitly open.
