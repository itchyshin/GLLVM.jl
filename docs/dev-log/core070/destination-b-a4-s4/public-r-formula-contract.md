# S4 public R-formula paired-receipt contract

This is a structural scaffold, not a parity result.  The earlier A4/S4 records
are private and admission-closed; they cannot be converted into this receipt.
No R fit was run while creating this contract.

The only qualifying future input is one freshly executed public
\`gllvmTMB::gllvmTMB\` Gaussian formula:

\`\`\`r
cbind(trait_1, trait_2) ~ 1
\`\`\`

It must use exactly two traits and a three-tip, non-unit-ultrametric tree, and
must report observed-marginal transformed-Wald lower and upper endpoints for
exactly these seven canonical targets:

\`\`\`
beta[1], beta[2], phylo_cov[1,1], phylo_cov[2,1], phylo_cov[2,2],
residual_var_shared[1], residual_var_shared[2]
\`\`\`

The receipt must record the exact clean R source pin and installed DLL
SHA-256, mark the public formula as evaluated, and bind a Julia-side
observed-marginal endpoint vector.  Each corresponding lower and upper endpoint
must agree within the fixed absolute tolerance \(10^{-4}\).  A different
formula, a unit tree, a partial target set, non-Wald interval, altered tolerance,
or unattested source/DLL is rejected.

The structural check is intentionally available without R:

\`\`\`sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_destination_b_a4_s4_public_r_formula_receipt.jl
\`\`\`

The test constructs an in-memory contract fixture and tampered variants; it
does not run R, load \`gllvmTMB\`, or fit either implementation.  An external
receipt run remains gated by \`GLLVM_PARITY_TESTS=1\` and needs a separate
time estimate and approval if its fit could exceed 30 minutes.

A receipt that passes
\`validate_a4_s4_public_r_formula_receipt\` means only that its declared
structure, attestation fields, and endpoint comparison satisfy this contract.
It remains \`receipt_valid_not_publicly_promoted\`; it does not establish a
public parity claim, release readiness, or any change to \`gllvmTMB\`.
