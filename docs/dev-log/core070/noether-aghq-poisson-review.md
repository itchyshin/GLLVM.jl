# Noether — Poisson AGHQ adapter review

Fresh native default agent noether_aghq_poisson, explicit gpt-5.6-terra/high,
fork_turns=none. One bounded numerical public-source review and one follow-up;
no implementation child, fits, private history or runtime evidence inspection.
Parent owns implementation and live verification; this is not a completion panel.

Initial findings: P1 normal-range tests could miss eta clipping; add a target
outside [-30,30]. P2 make 400-pass cap explicit and guard internal-only status.
Concern about missing source/attempt hashes was withdrawn after parent explained
the immutable launcher/supervisor; full per-pass trace still added for inspection.
Concern about needing an exposed joint helper was withdrawn: actual source
computes unclipped joint AD gradient/H and independent analytic tests cross-check.

Repairs: tests at beta=+35 and -35 with zero loading verify normalized objective
and frozen beta/loading gradients, failing any inherited predictor clip. Explicit
n_adapt=400 plus bound assertion; no-export assertion; full trace in hashed TOML.
Tuple invalid-control fixtures avoid Bool-to-Int coercion. Runner token corrected.

Follow-up verdict: all listed findings resolved; no remaining actionable
numerical/API defect in reviewed public files. Reviewer confirmed normalized
constants, unclipped exp(eta), actual joint AD score/H, SPD rejection without
repair and frozen-cache semantics. Reviewer did not run tests or inspect the
separate runtime receipts; parent verified those independently with the gate.
