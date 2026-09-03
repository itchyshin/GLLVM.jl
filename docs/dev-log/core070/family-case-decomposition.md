# Family cases: planned scope, not executable coverage

The [case plan](family-required-case-plan.json) turns all69 frozen family facts
into explicit interface obligations. The master source map links these through
`planned_case_ids`; its `executable_case_ids` remain empty. No fit, rejection,
or interface result is inferred from a linked fixture.

| Frozen facts | Planned cases | Required distinction |
|---|---:|---|
| 21 admitted descriptors | 63 | One native model, Julia formula and public R bridge case per descriptor |
| 1 Beta alias | 1 | Equivalent information; no need to duplicate R spelling in Julia |
| 33 rejected descriptors | 33 | R rejects; Julia must either reject or explicitly document and test a supported extension |
| 14 constructor-only exclusions | 0 | Preserve the approved exclusion; a constructor alone is not an admitted R model |

These97 case specifications do not form an assumed Cartesian product of models.
They cover the family/link/descriptor axis only. Covariance modes, dispersion
grouping, mixed responses, predictors, inference and other combinations remain
separate required contracts. Fixed/shared/per-trait Tweedie power, fixed/free
Student degrees of freedom and Gaussian mean/variance choices cannot replace
one another. Fixed-effects multinomial remains only a baseline for its required
latent and structured models.

Every planned case has a stable ID, source row hash, reference descriptor and
expected admission, owner, coverage role, candidate native entry/fixture where
known, dependencies, acceptance requirements and missing contract fields.
`fixture`, `r_call` and `julia_call` are bound for the two freshly verified
original native NB2 cases and the intercept-only NB2 formula required case;
sixteen separately verified domain/link boundaries also bind their exact calls;
the other78 specifications keep these fields null
until their exact fitted contract is established. The native bindings include
seed, dimensions, parameterization, fixture hash and required-runner evidence. The native entry calls are historical leads,
not fitted-model calls: some useK1 while their legacy fixture usesK2.

## What must happen next

1. Bind the native cases to exact reference/Julia calls and fixtures. Use existing
   seeded fits only when means, links, nuisance parameters, curvature and
   identification agree. The original required NB2/truncated-NB2 pair is verified;
   the NB2 formula is now verified in the required runner on the same original data.
   The public R bridge remains unpaid.
2. Keep probit and cloglog cases separate from the legacy logit fixture. The six
   declared binomial link/trial cases are candidate evidence; explicit observed
   cloglog is not default-Fisher equivalence.
3. Bind formula and bridge cases to the same model contract as the native case,
   then replay actual fits. Missing interfaces stay visible rather than becoming
   entry probes or skipped tests.
4. Resolve each rejected descriptor's Julia disposition. A valid Julia extension
   should not be disabled merely because the R reference rejects it.
5. Complete the other source domains and independent scope review before freeze.

## Repaired freeze check

A regression showed that the prior checker accepted a family source fact linked
only to an entry probe when the synthetic scope-review record was otherwise
complete. The checker now requires native/formula/bridge roles and fitted
acceptance levels for admitted family facts, bound to matching model contracts
and real fixture paths. Multiple model variants are allowed only when each has
the required interfaces. Alias and rejection facts have separate roles.

This is structural validation, not proof of scientific correctness. The actual
scope reviewer must still assess source semantics; run receipts must establish
numerical and interface behavior. `tools/core070_verify_family_decomposition.py`
reproduces the old failure using the archived checker, runs11 current regression
tests, checks all752 source facts and verifies that no planned case has been
promoted. The full manifest remains DRAFT with698 non-excluded facts lacking
complete executable coverage.

## Separate required interface registry

The runner retains17 family IDs and registers the original NB2 formula under
`CORE070-FAMILY-05-LOG-FORMULA-INTERFACE`. Default selection requests all18
registered cases; this is still a subset of the full programme. Selecting exactly
17 arbitrary IDs cannot earn the `all17` family label. Shared fixture assertion
counts remain deduplicated by execution group. Formula and native NB2 artifacts
use different filenames, and a formula-only selection hashes its original NB2
data-generation source as an explicit dependency.

The prior standalone formula and native-refresh summaries are retained as
historical snapshots. Current bindings use `nb2-formula-required-evidence.json`;
no independent review or full-family promotion follows from this integration.

## Shape boundaries resolved separately from fitted models

`family-boundary-contract.json` retains all33 frozen rejected descriptors. Nine
shape rows have named-fitter checks: Tweedie powers1,2,Inf,NaN and vector[2,3];
Student degrees of freedom1,Inf,NaN and vector[2,3]. Seven reject before reading
responses. Julia intentionally admits finite fixed Student nu1 and a vector
whose length matches the two traits; these are documented extensions, not R
parity. The nu1 density agrees with the independent Cauchy density across36
location/scale/residual combinations. Neither entry checks nor this scalar
identity prove successful fitting or recovery for those extensions.

`family-boundary-evidence.json` binds50 assertions to the source-pinned Totoro
run and all69 frozen R descriptor results. At the shape-check checkpoint,24 link/descriptor rejections remained unresolved;
the subsequent link sweep below resolves seven. The nine boundary cases are verified separately;
integration into the complete required evidence collection is still pending.
They do not increase the17-family or fitted-model counts. That checkpoint bound2 native,1 formula and9 domain-boundary cases. Full source coverage and independent scope review remain unpaid.

## Native link boundaries and ordinal guard

The remaining24 reference rejections now have explicit dispositions in
`family-link-boundary-contract.json`. Seven corresponding native link requests
reject, ten reach native code but remain **unvalidated**, and seven have no
Julia selector to request the R option. The last group is Gaussian-log and the
six delta-family link/type options. No invented R-style Julia keyword is tested.
These missing controls and the public R bridge contract remain unresolved.

Ordinal only implements logit and probit CDF/density/quantile kernels. Its three
named fitters now reject other links before response access. This propagates
through the unified and wide-formula routes; long formulas also return the clear
error after constructing their response table. The original supported models
are unchanged. Regression red13pass/36fail becomes49pass; native link admission
adds21pass, including positive controls. The original ordinal-probit fixture
passes5 assertions with likelihood difference5.48e-9, without a broader
fit-health or recovery claim.

Current-source NB2 and shape receipts were replayed after the guard change;
use `nb2-formula-required-link-refresh.json` and `family-boundary-link-refresh.json`.
Older summaries remain historical. The plan now has2 native,1 formula and16
boundary bindings, leaving78 specifications unbound. Required collection
integration, full source mapping and final review remain incomplete.

## Poisson/Beta original-model health qualification

`poisson-beta-health-evidence.json` records a separate qualification of the
unchanged original Poisson (seed44,p5,K2,n60) and Beta (seed45,p5,K1,n60) models.
Both original R fits pass likelihood and optimizer-flag checks but fail raw
gradient <=1e-4. The original failures remain retained. Public start_from with
nlminb rel.tol1e-12 refines both without changing data, map or free parameters;
native fits remain byte-identical. The refined packet passes32 checks, including
both gradients, step-size stability, same-point objectives and raw R readback.

Before-fit SHA locks protect the original contracts, fixtures and DGP blocks.
This packet does not yet replace the two light checks in runparity.jl; therefore
it does not change the19 bound cases or78 unbound case specifications above.
Next integration must preserve the original failure receipts and expose the R
control policy. It cannot imply formula, bridge or recovery qualification.

## Required integration supersedes the qualification-only status

The new Poisson/Beta wrappers now run all32 qualified health assertions through
`runparity.jl`, with their original required IDs. The original DGP fixtures and
native fit controls are unchanged; public R refinement is explicit, and the
original R failures remain retained. `poisson-beta-required-evidence.json` binds
that execution. The earlier standalone packet remains historical qualification.

Use `nb2-formula-required-pb-refresh.json`, `family-boundary-pb-refresh.json` and
`family-link-boundary-pb-refresh.json` for the refreshed shared-harness pins.
Current family bindings are4 native,1 formula and16 boundaries:21 bound and76
unbound of97 planned cases. No formula/bridge/recovery or full-family promotion
is implied, and the complete programme manifest is still unfrozen.
