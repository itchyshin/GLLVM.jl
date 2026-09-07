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

Investigate R's optimizer status on unchanged data, independently review the
tooling, and complete the paired/inference/retained-recovery requirements before
admission. No frozen R engine or parser edits were made. Direct Ainv syntax
remains a recorded limitation. Feasible intervals on one dataset do not imply
nominal coverage or programme completion. External review transmission is still
awaiting explicit approval. No push, merge or public qualification has occurred.
