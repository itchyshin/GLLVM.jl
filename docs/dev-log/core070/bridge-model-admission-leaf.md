# Model-specific bridge admission leaf

Status: implementation and independent regression tests in progress. Full manifest remains draft.

Owns: Ada tools/core070_bridge_admission.py, core070_manifest_coverage.py,
core070_family_case_plan.py and programme records. Hopper exclusively owns
new tools/test_core070_bridge_admission.py. No numerical engine or oracle edits.

Two frozen-reference boundaries may satisfy the public_r_bridge role with
acceptance_level=reference_bridge_boundary: original Gaussian unique model
changes to the warned reduced model; original truncatedNB2 family rejects.
Every model requires nonempty identical model_contract definitions across its three roles, not just a shared ID.
Every model still requires native_model paired_fit and formula_interface
paired_fit_interface. A boundary cannot cover either numerical role or a
different model. Mapped keys, generic errors and missing fixtures are not proof.

The boundary case binds an exact contract file/hash, source fact, model ID,
native model contract, fixture, calls, disposition and acceptance. The checker
rebuilds the contract from pinned source bindings and reruns the appropriate
raw receipt verifier; cached status JSON cannot authorize it. Full freezing
still requires the independent source-scope review, all case mappings and runs.

CHECK: python3 -m unittest discover -s tools -p test_core070_bridge_admission.py
EXPECT: valid bound boundaries pass; native/formula omission or weakened level,
wrong model, stale contract, source mismatch, raw verifier failure and unknown
boundary fail. Existing family coverage and interface tests remain passing.
CHECK: python3 tools/core070_bridge_admission.py --verify
EXPECT: two independently bound reference boundaries verified, not model parity.
CHECK: python3 tools/core070_family_case_plan.py
EXPECT: original native/formula requirements retained, two extra boundary
bindings explicitly distinguished from three successful public bridge fits.

No fits or compilation; metadata/receipt checks locally estimated under30seconds.
Failures retain old evidence and stop promotion, not the surrounding programme.
No change to full-manifest FROZEN state, release authorization or >30minute compute.
