# Qualify explicit-source Gaussian formula routes

OWNS: Boole exclusively owns test/parity/covariance_formula_cases.jl and optional
pure payload tests. Ada owns wrapper fixtures, registry/runner, contract generator,
central manifest/map, independent verifier, evidence and developer records.

Nine existing native/R Gaussian covariance contracts remain unchanged. Each gains
one formula-interface case exercising wide input and reversed long input with
`gllvm(@formula(y~1), ...; sources=...)`. Native cases must run first in the same
process; reuse their actual retained R fits, never synthesize an R success.
Fixed ordinary cases retain fixed residual. Full-rank ordinary dependent compares
total covariance only. Other structured modes compare source covariance/residual.
Every formula fit must converge with maxgradient<=1e-7, |deltaLLtoR|<=1e-6,
matching freecounts/design/shapes and beta/identifiablecovariance atol/rtol1e-5.
Wide/long agreement is additional evidence, not a substitute for matching R.

CHECK: julia --startup-file=no test/test_core070_covariance_formula_registry.jl
EXPECT: missing formula registry fails before integration; afterwards exact9IDs,
native dependencies and complete execution groups pass. Required-fit checks run
through test/parity/runparity.jl with all18native/formula IDs and nonzero failures.
CHECK: python3 tools/core070_verify_covariance_formulas.py
EXPECT: CORE070_COVARIANCE_FORMULAS_VERIFIED, independent raw/native/formula values,
actual supervised exit, exact artifacts, omittedcase/stalesource/dependency controls.
Missing R or any required case is a failure, never an optional-test skip.

Target Totoro, Julia/BLAS1thread, estimate3–6minutes, cap600seconds; no installation.
Estimate applies to9existingR/native fits plus18formula fits. Stop on timeout;
retain failed rows/logs/receipts. No DRAC/fullsuite/campaign/release or foreign edits.
Fullmanifest stays DRAFT. No publicbridge/nonGaussian/random-source-slope or broad
recovery/performance claim; required bridge roles stay unpaid.
