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
original native NB2 cases; the other95 specifications keep these fields null
until their exact fitted contract is established. The native bindings include
seed, dimensions, parameterization, fixture hash and required-runner evidence. The native entry calls are historical leads,
not fitted-model calls: some useK1 while their legacy fixture usesK2.

## What must happen next

1. Bind the native cases to exact reference/Julia calls and fixtures. Use existing
   seeded fits only when means, links, nuisance parameters, curvature and
   identification agree. The original required NB2/truncated-NB2 pair is verified;
   this does not establish its formula or public R bridge routes.
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
