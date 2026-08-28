# After-task — the full-parity ultracode campaign day (2026-08-28)

Ada reporting. Perspectives engaged: Gauss (engine), Fisher (adjudication),
Curie (tests), Hopper (R↔Julia parity), Jason/Ranga (ecosystem + grounded
search), Rose (adversarial pre-commit review, twice). Covers PR #273
(14 commits, open at `d7831f8a`) and the session handover to Cursor.

## 1. Goal

Drive GLLVM.jl toward full capability parity with the gllvmTMB 0.7.0 twin,
with the headline being the STRUCTURAL death of the Fisher-vs-observed
Laplace fault class — "one architectural defect wearing eight family
costumes".

## 2. Implemented

- **The fault class CLOSED.** Tweedie and Binomial-probit flipped to
  `:observed` on the maintainer's word; census `KNOWN_OPEN` is now EMPTY.
  GP-1 remains Fisher BY DECISION (recorded with evidence), cloglog the
  documented intrinsic-saturation exception.
- **Arc 2 residue cleared**: Gaussian PosDef sentinel screened out of the
  convergence verdict; CMP `logZ` cap closed via the Shmueli asymptotic;
  all ten two-part entry points expose `hessian`; grouped fit structs record
  their selector and their CI adapters rebuild the fit's own objective.
- **AGHQ unparked, Slice 0 executed**: the parked module's unconditional
  Fisher weight (written before the selector rollout) now takes the selector.
- **Delta `predictor = :shared`** twin-identity mode (packing change only)
  and the live parity measurement for cells 12/13.
- **JuliaCall/Totoro embedding segfault root-caused and repaired**
  (system libunwind binding over Julia's inside embedded R).
- Ledger honesty: `capability-status.md`'s curvature table corrected.
- Handover to Cursor + AGENTS.md snapshot.

## 3a. Decisions and Rejected Alternatives

The maintainer answered four gates in one sitting
(`docs/dev-log/decisions/2026-08-28-arc-decision-batch.md`), which is what
unblocked the day: both flips YES, delta twin identity as a MODE (not a
replacement), AGHQ UNPARK, L47 PROMOTE; non-Gaussian REML and delta
latent-scale advertising STAY REJECTED. Tweedie's *admit* (STOP #234) was
deliberately left fenced — the curvature flip is not the admit.

Rejected in flight: aligning Tweedie's grouped route to the new default
(it carries recorded defects — fenced honestly in three places instead);
building any public `aghq=` surface (Slices 2–4 need their own decisions).

## 4. Files Touched

30 files on PR #273 — see the handover's Files section for the full list.

## 5. Checks Run

- Totoro full suites: **6955/0/4** (tree `dc1ee936`) and **6997/0/4** (tree
  `db3b90ad`), both exit 0, ~85 min each. A third run covering the AGHQ and
  delta commits was still in flight at handover (declared CARRIED-OVER).
- Targeted: flips 538/538 · AGHQ 403/403 · delta mode 329/329 · grouped
  310/310 · mop-up 284 across five files. FD gates ≤2.5e-7 on both new
  weights. Live R parity: two new env-gated cells, numbers published.
- PR #273 CI: Documenter + deploy pass; Julia matrix still running at close.

## 6. Tests of the Tests

Two adversarial review rounds paid for themselves outright. The first (3
lenses + refutation) caught, before commit: seven new kwargs shipped with
ZERO tests (the cascade blocker), three missed `_cov` fitters, and an
`InexactError` on integer arguments to an exported function that the full
suite could not see because nothing called it with integers. The second
round was mine, checking a fence's wording, and found the curvature ledger
four flips stale.

The flip engineer also refuted the premise I gave it (probit sign-changing
curvature) with BigFloat evidence and a citation. An agent that codes to a
wrong brief is worth less than one that argues with it.

## 7a. Issue Ledger

None opened. Queued maintainer decisions are recorded in the handover and
the decision batch, not as issues.

## 8. Consistency Audit

CHANGELOG, check-log, census, contract pins, both `docs/src` pages, and
`capability-status.md` now state the same curvature facts. The convention
cascade gained a lesson: it names tutorial/reference surfaces but not the
internal design ledger, which is exactly where the drift hid.

## 9. What Did Not Go Smoothly

1. **A near-false-green.** I almost stamped a 6955 tally onto the grouped
   slice; that run predated the slice by one commit. Caught at the last
   step; the check-log now says which tree each tally covers.
2. **A check-log prepend swallowed the previous entry's heading**, silently
   merging two entries. Found by grepping headings after the fact.
3. Two sub-agents armed monitors and then stopped, which kills the very
   children they were waiting on. Both needed a nudge back into the loop.
4. A `perl -pi` tally substitution ran before I had verified which entry it
   would land on — the honesty fix in (1) was the cleanup.
5. `handoff_gate.sh` and `lane_preflight.sh` both needed `bash` explicitly
   (a `zsh` syntax error and a path-vs-name argument).

## 10. Known Residuals

- Suite run C in flight; two check-log tallies still say
  `[tally on full-suite green]`.
- Delta cells 12/13 measured but NOT paid — the twin fits per-trait
  dispersion, we fit a shared scalar (Δ −1.92 / −2.57). Closure shape is a
  maintainer decision.
- L47 promote (authorised, not yet done) · parity-in-CI · student-ν ·
  Arc 4 structured dependence · the four undamped grouped Newton loops ·
  Student-t confint adapter · TWOPART_KNOWN_OPEN observed weights.
- The stranded CI commit needs `gh auth refresh -s workflow`.

## 11. Team Learning

- **Reviewer severity labels are claims, not verdicts.** The Int-args
  regression was graded "minor" and therefore skipped the refutation stage;
  reproducing it live took one command and reclassified it as a real
  exported-surface break.
- **A tally is a claim about a TREE, not about a day.** Rsync-then-test
  means the evidence corresponds to the commit you shipped, not the commit
  you have now.
- **Brief your agents with premises they are free to refute**, and ask for
  the refutation explicitly — twice today that produced better physics than
  my instructions contained.

## 12. Cross-Product Coverage

The coupled-flip template is now executed six times and fully documented —
directly reusable for DRM.jl. The libunwind diagnosis applies to ANY
R-embedded-Julia work on Totoro (drmTMB↔DRM.jl bridges included). The
"expose the kwarg with an honest no-op scope + bit-identity test" pattern
generalises to any selector landing ahead of its specialised kernels.
