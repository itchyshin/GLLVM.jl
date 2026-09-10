# 2026-09-10 — B1 balanced complete-crossed source alignment

**PRE-RUN CONSTRUCTION ONLY.** This fixes a new B1 fixture; it is not a fit,
frozen-R receipt, paired R-to-Julia result, recovery result, or qualification.

`test/fixtures/destination_b_b1_balanced_complete_crossed_design.jl` fixes two
traits, `U=12`, `W=3`, `C=10`, `D=10`, the complete product `(u,w,c,d)`,
`unit=u`, `obs=paste(u,w)`, `cluster=c`, and `cluster2=d`: 3,600 wide and
7,200 long rows. It fixes seed `20260915`, beta `(-0.20,0.27)`, loading
`(0.72,-0.51)`, observation SDs `(0.36,0.27)`, cluster SDs `(0.43,0.32)`,
cluster2 SDs `(0.38,0.29)`, residual SD `0.17`, Gaussian ML (`REML=FALSE`),
and the formula

```r
value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) +
  indep(0 + trait | obs) + indep(0 + trait | cluster_id) +
  indep(0 + trait | cluster2_id)
```

The response SHA-256 is
`0fa63f69d7256b3c4e900cc91db1bf67c1ba41c56d0e0fde64de2c6a11ad738a`.
The normalized ten-channel tensor-kernel has rank 10 and minimum eigenvalue
`0.3408784387221166 >= 0.30`. This is a static construction screen, not
Fisher-information, convergence, recovery, interval, or likelihood evidence.

If explicitly authorized later, run **one** frozen-R ML control only:
`n_init=1`, `se=FALSE`, `optimizer="nlminb"`, `eval_max=iter_max=100000`, and
`rel_tol=x_tol=xf_tol=1e-12`. It passes only with `convergence == 0` and
`max(abs(gr)) <= 1e-6`. Otherwise stop and retain the nonqualifying receipt:
no reseed, restart, optimizer/data/tolerance change, or paired Julia fit.

## Formula-column and frozen provenance repair

The long construction now exposes formula-exact `cluster_id` and `cluster2_id`
columns (not ambiguous aliases). The grouping tuple `(unit, obs, cluster_id,
cluster2_id)` occurs once in the 3,600-row wide construction; it necessarily
occurs twice in long form because each wide row has two traits, while the
trait-qualified long tuple occurs once. The focused test asserts all three
facts.

Before any future fit, the no-fit helper
`tools/destination_b/b1_balanced_complete_crossed_preflight.R` must verify the
frozen source commit, DESCRIPTION version, archive SHA, installed DLL SHA,
four frozen-library marker fields, and the retained stationary reference-runner
SHA. Those values are retrieved from the retained B1 stationary receipt:
`b4d5fee64def88bc768dda1f1f77c29b295edd86`, version `0.7.0`, archive
`0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc`, DLL
`3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30`, and
runner `9d1f1fa95655bd8887d7e04d2c2d10c0311fac094205a4d47dd7ee6ebb9ca585`.
The helper imports no `gllvmTMB` namespace and calls no fit.

## Authorized execution outcome — stopped before fit

The external provenance preflight passed with every documented thread cap set
to one. The export had one retained mechanical failure (`open(..., "x")` is
unsupported by Julia 1.10), then exported the exact 7,200-row input and passed
static runner/control checks. Two explicitly absent JSON targets were then
passed to the unchanged single-control runner. Both stopped at its no-clobber
guard before the embedded preflight, package load, `gllvmTMB()`, or optimizer;
both raw logs say `Refusing to overwrite an existing B1 receipt.` No result
JSON exists. This is a runner-guard execution failure, not a failed fit.

The authorized control is not eligible for further invocation under this
protocol. No seed, data, start, mapping, optimizer, tolerance, or Julia action
was changed after either pre-fit failure.

## Runner-guard repair (no fit)

The defect was the predicate `!file.exists(output) && !nzchar(Sys.readlink(output))`:
for an absent ordinary path `Sys.readlink(output)` is `NA`, so the expression
does not admit a new receipt target. The pure helper
`b1_balanced_control_output_occupied()` now returns false for an absent plain
path, true for an existing regular file, and true for a symlink (including a
dangling symlink). Its focused R test and static runner parse pass. This repair
does not invoke preflight, load `gllvmTMB`, construct data, or fit a model.

The two failed pre-fit logs remain immutable. The repaired predicate is ready
for independent review only; no third control invocation is authorized yet.

## One authorized frozen-R control — negative result

After a fresh authorization, the repaired runner's no-fit preflight passed and
one (and only one) fixed B1 frozen-R ML control wrote
`frozen-r070-b1-balanced-complete-crossed-single-control-20260910-02.json`.
The receipt and its hard-linked no-clobber marker have SHA-256
`ab090669922d2868469e4aef1b245ed492e9db6ac3c30b578334034af7931d73`; the
preflight and control raw-log SHA-256 values are respectively
`8058692230a6bb73297562172a7c789f0b3982498803bfc9910c6b8618b20612` and
`29748552d10906d68027a95df94834063c5c6be3253c3e8da0322166e3bfafb7`.

The fit returned `status = "success"` but is **not qualified**:
`convergence = 1` (`singular convergence (7)`) and
`max(abs(gr)) = 0.00092870391764413951`, exceeding the immutable gate
`convergence == 0 && max(abs(gr)) <= 1e-6`. It completed in
`0.94606304168701172` seconds, within the 60-minute hard stop. This negative
receipt records neither a paired result nor B1 qualification. It ends this
protocol: no retry, reseed, restart, start/mapping/optimizer/data/tolerance
change, or Julia paired fit is authorized.
