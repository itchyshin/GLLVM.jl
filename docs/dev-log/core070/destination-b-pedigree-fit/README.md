# Frozen pedigree Gaussian fitted pilot — not qualified

Model: three traits, eight observed animals with two replicates, rank-one
phylogenetic loadings, one shared residual variance, full12node pedigree
precision retaining four unobserved founders. Seed20260907. Reference is the
preserved gllvmTMB0.7.0 build b4d5fee64def88bc768dda1f1f77c29b295edd86.

## Retained outcomes

1. R attempt01 failed before optimization: direct Ainv syntax rewrites to an
   unexported helper inaccessible in the formula environment. Error and data
   retained. SHA0b0d8059d9083fc63e3564f9dfb40bf03acddf01b2513910a16357a45823abd4.
2. R attempt02 uses the public pedigree argument with exactly the same data,
   pedigree, canonical precision, model and seed. Its model/mapping checks
   pass, but optimizer status is1, "singular convergence (7)". Gradient norm
   8.847417306685823e-5. It is NOT a successful paired-fit receipt.
   SHAb8d5f2e884720ad86f3a0d0d562ec5b25248113d0e641825803e4d5cee8e5a06.
3. Cross-evaluation passes: fixed NLL21.94892854578277 exactly equal;
   R-returned NLL14.802810611470429 versus Julia14.802810611470427.
   Checker15/15 assertions pass, including deliberate bad inputs. This does
   not turn R's failed optimizer status into success.
4. Independent Julia fit starts from its own defaults, converges in21iterations
   with gradient4.426331427382245e-6. NLL14.80281061142237 differs from R's
   returned value by-4.8059334289973776e-11. All12displayed Wald rows are
   available (10distinct estimands; the shared residual repeats per trait),
   condition161.9353597. Fit0.109s plus interval1.624s excludes startup and is
   not a campaign estimate. SHA3e7dc59a5f5a5c2437cceca8c6409a14451113a0efd1de69e0dbf127959012f1.

Both R JSONs and the independent Julia JSON preserve original byte hashes.
The comparison copy adds only a terminal newline: durable SHA
c6f32e270264445bfc23ae3d4e039194cf9f269d310282ccda4ad09ef96c5ee3,
original SHAcec1a5b2aebb0179c4c402470d6cbe165b2b90eab22d7911e410ef71fe4ee177.
Original R attempt RDSs and all records remain in the ignored pedigree-fit ledger.

## Remaining gates

The predeclared same-data optimizer investigation is now recorded. An exact
baseline replay still returns status 1; its marginal Hessian is positive
definite (minimum eigenvalue 1.672476, condition 161.9353). One public BFGS
attempt, starting from R's own defaults, returns status 0 and gradient
1.8572321931484726e-7. Its NLL is 14.802810611422183. Cross-evaluation at
that point differs by 1.2434497875801753e-14; the previously retained
independent Julia optimum differs by 1.865175e-13, with maximum aligned
loading relative difference 1.631598e-7. No Julia refit was needed.

The baseline and BFGS policies remain distinct: the baseline fails the
successful-fit policy; BFGS passes it. Targeted checker session 95556 passed
23/23 assertions, including failed status, nonfinite gradient, mismatched
data hash and altered loading controls. This is one paired point-estimate
pilot, not a general optimizer recommendation or interval certification.
The numerical Hessian is diagnostic, not a substitute for supported intervals.

New retained SHA256 values:

- r-nlminb-diagnostic-01.json: bcda7b1a9f9ee3d9b66d58178e9083a6a608ec91d6f19bf622274e4a003a4a30
- r-bfgs-attempt-01.json: 55ebb6e89461dcb6693d2b70d8c845d6ec1c1c3447fbaf20c6c58caaf9f221d3
- bfgs-comparison-01.json: 7c56a765d389e17d752aec0e4713d7be7fb38aa63e53adfeda8502d73df09149

Independently review the tooling and complete the paired/inference/retained-recovery requirements before
admission. No frozen R engine or parser edits were made. Direct Ainv syntax
remains a recorded limitation. Feasible intervals on one dataset do not imply
nominal coverage or programme completion. External review transmission is still
awaiting explicit approval. No push, merge or public qualification has occurred.
