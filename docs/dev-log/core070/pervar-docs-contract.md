# Per-variance example and strict local documentation contract

Status: EXECUTED_EXAMPLE_AND_STRICT_LOCAL_BUILD_NOT_DOCS_COMPLETE.

The named `@example pervar_design` block in `docs/src/response-families.md` is the fixture. The standalone tool extracts and executes those exact bytes; it does not maintain a second example. It checks convergence, five coefficients, thirteen parameters, AIC/BIC consistency and finite coefficients. Eighteen unchanged neighboring AIC/BIC assertions run separately. Page/code hashes and process exits bind the evidence.

The strict Documenter build uses `docs/make.jl --local`, fixes the docs root explicitly, disables remote discovery only locally, and never invokes deployment. Content warnings are errors. The low-level reference registers previously undocumented bindings without promoting helpers to supported public estimators. In particular internal AGHQ helpers are not public Stage 1a support.

## Runtime and results
Totoro, Julia1.12.6, one Julia/BLAS thread. Example and neighbor commands:20.77s/35.15s,6+18 assertions PASS. Dependency setup38.68s. Strict build59.29s, VitePress bundle7.87s. All runs fit their declared bounded estimates; no full suite or campaign.

The standalone example uses the qualified core Manifest. The isolated `.docenv` build resolves Optim1.13.3 and ForwardDiff0.10.39, unlike the qualified core environment. These are separately pinned environments, not interchangeable package-check evidence. All94 copied static artifacts have verified checksums.

## Acceptance commands
```sh
python3 tools/core070_verify_pervar_docs.py --example
python3 tools/core070_verify_pervar_docs.py --build
python3 tools/core070_test_pervar_docs_gate.py
```
The gate rejects false completion, missing process, fabricated metrics, unsupported deployment, a corrupted static inventory, and a failed process even with a valid checksum. Raw failed example/build attempts remain in `.unlazy/core070-aghq/pervar-docs/`.

## Presentation and limits
Desktop1280px and mobile390px Gaussian-section screenshots, section navigation and low-level-reference navigation inspected. Mobile document width and scroll width both390px; no page-wide horizontal overflow. Executed coefficient output exists in rendered HTML. No console errors observed; this is not proof that network assets all loaded: local versions.js returned404.

Remaining: logo/favicon, explicit package.json, large bundle warning, search/version selector, full mobile code/output inspection, other-page visual audit and broader executed tutorials. No deployment, whole-site C2 completion, independent numerical sign-off, full package checks, R parity or performance claim. Previous whole-source parity receipts still require integrated revalidation after the prior engine change.
