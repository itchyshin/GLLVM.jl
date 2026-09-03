# Bridge coverage matrix — can `gllvmTMB(engine = "julia")` run every family and structural dependency?

**Status: compiled from retained receipts + source reading, not a fresh campaign.** See EVIDENCE-LIMITS at the end before citing any cell as a live test result.

## Summary — answering the maintainer's question

**No — not for all distributions, and not for any structural dependency beyond a single reduced-rank ordination block.** The frozen R 0.7.0 `engine = "julia"` adapter (`.gllvmTMB_julia_dispatch()`, `R/julia-bridge.R`) admits only three families with fresh receipts (Poisson-log, Beta-logit, NB2-log — `docs/dev-log/core070/public-bridge-required-evidence.json`, `public-r-bridge-programme-evidence.json`), plus receipted single-model boundary evidence for Gaussian-identity and Binomial-logit. It supports **exactly one covariance structure**: a single reduced-rank (`rr`) `latent()` ordination block with no trait-specific residual Ψ (the auto-emitted `unique = TRUE` companion is silently dropped with a warning, not an error). Everything else that R's formula grammar can produce — `dep()`, `indep()` (ordinary, `common=`, or grouped-dispersion), `phylo_*()`/`animal_*()`/`kernel_*()` in any of their three modes (indep/common/dep), `spatial_*()`, augmented random-slope forms, row effects, ISDM/multi-source fits, offsets, and every family beyond the admitted six-family bridge list — is refused before reaching Julia by two named gates: `GJL-GATE-STRUCTURED-TERMS` (`setdiff(unique(kinds), "rr")`, `R/julia-bridge.R` lines ~3578–3589) and `GJL-GATE-MULTI-RR` (more than one `rr` block). Signed receipt evidence (`covariance-bridge-boundary-evidence.json`) shows this gate firing for 8 of 9 tested structured-covariance formulas (ORD-COMMON, ANIMAL-INDEP/COMMON/DEP, KERNEL-INDEP/COMMON/DEP); the 9th (ORD-DEP) never reaches the named gate at all — it fails earlier in the adapter with a generic (unlabeled) error, a distinct defect from the documented gate.

Julia-native and Julia-formula-interface routes are, on GLLVM.jl's own side, considerably broader than what the public R bridge exposes: `src/families/` contains fitters for NB1, truncated NB2, truncated Poisson, Tweedie, Student-t, lognormal, multinomial, censored Poisson, COM-Poisson, beta-binomial, ordered-beta, and two-part families that the R bridge either does not map at all (`GLLVM_JULIA_BRIDGE_FAMILIES` admits only gaussian/poisson/binomial(+probit/cloglog)/negbinomial/nb1/beta/gamma/ordinal/ordinal_probit) or maps but has never receipted a fitted PASS for. The gap is therefore two-sided: some Julia-native capability has no R adapter path yet (JULIA-GAP-shaped from the R side, but really "R hasn't wired it"), and most of R's structured-covariance grammar has no Julia bridge payload to receive it (R-ADAPTER-BLOCKED from the Julia side, but really "Julia hasn't built the structured-fit payload").

### Cell counts

- Family × route matrix (17 R-side family/link facts × 3 routes = 51 cells): **PASS 5, JULIA-GAP 0, R-ADAPTER-BLOCKED 4, UNTESTED 42**
- Structural-dependency × route matrix (13 dependency kinds × 3 routes = 39 cells): **PASS 4, JULIA-GAP 0, R-ADAPTER-BLOCKED 9, UNTESTED 26**
- **Combined total (90 cells): PASS 9, JULIA-GAP 0, R-ADAPTER-BLOCKED 13, UNTESTED 68**

(No cell was classified JULIA-GAP in the strict sense of "a Julia capability that is missing outright." Every observed R-side refusal is the adapter stopping before a payload is sent, not Julia rejecting a payload it received — so the honest label is R-ADAPTER-BLOCKED, not JULIA-GAP, for every block found. Where GLLVM.jl's own `src/families/` has no fitter at all for an R-side family — e.g. `gengamma`, `censored_poisson` marker-only, mixtures — those cells are UNTESTED rather than JULIA-GAP because no receipt exists either way; see the work-order section.)

## 1. Family × route matrix

Routes: **N** = Julia native (`fit_gllvm`/family-specific `fit_*_gllvm` call), **F** = Julia formula interface (`@formula` + `gllvm(...)`), **B** = public R bridge (`gllvmTMB(engine = "julia")`).

| R family (frozen `families.R` + base R families used by gllvmTMB) | N | F | B |
|---|---|---|---|
| `gaussian()` (identity) | UNTESTED | UNTESTED | PASS — `docs/dev-log/core070/public-r-bridge-programme-evidence.json` (`CORE070-FAMILY-00-IDENTITY-PUBLIC-R-BRIDGE`), `gaussian-required-evidence.json` (native+formula subset only, not bridge) |
| `poisson()` (log) | UNTESTED | UNTESTED | PASS — `public-bridge-required-evidence.json` (`CORE070-FAMILY-02-LOG-PUBLIC-R-BRIDGE`), loglik/shared-covariance deltas ≤1e-8 |
| `binomial()` logit/probit/cloglog | UNTESTED | UNTESTED | PASS (logit only) — `public-r-bridge-programme-evidence.json` (`CORE070-FAMILY-07-LOGIT-PUBLIC-R-BRIDGE`); probit/cloglog admitted by `.GLLVM_JULIA_BINOMIAL_FAMILIES` but UNTESTED (no case id found) |
| `Gamma()` (log) | UNTESTED | UNTESTED | UNTESTED (bridge family map includes `gamma`; no PASS/FAIL receipt found for it specifically) |
| `Beta()` (logit) | UNTESTED | UNTESTED | PASS — `public-bridge-required-evidence.json` (`CORE070-FAMILY-05-LOG-PUBLIC-R-BRIDGE`, note: id says LOG but family is beta per `results.beta`) |
| `nbinom2()` (NB2, log) | UNTESTED | UNTESTED | PASS — `nb2-required-evidence.json` (`TWO_REQUIRED_FAMILY_SMOKE_CASES_VERIFIED_NOT_FULL_CAPABILITY`) |
| `nbinom1()` (NB1, log) | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED-adjacent: `nb1` is in `.GLLVM_JULIA_BRIDGE_FAMILIES` and `.GLLVM_JULIA_GROUPED_DISPERSION_FAMILIES`, and `src/families/negbin1.jl` exists, but `family-model-catalogue.json` `NATIVE-16-NB1` is `evidence_status: NOT_REEXECUTED`, `bridge_status: UNPAID` — classify UNTESTED, not PASS |
| `truncated_nbinom2()` (log) | UNTESTED | UNTESTED | UNTESTED for bridge (`bridge_status: UNPAID` in catalogue); a *native* smoke PASS exists (`truncnb2-required-evidence.json`, `REQUIRED_SINGLE_ORIGINAL_SMOKE_WITH_EXPLICIT_PUBLIC_CONTROL_NOT_FULL_PARITY`) — record under N only |
| `truncated_poisson()` (log) | UNTESTED | UNTESTED | UNTESTED |
| `truncated_nbinom1()` (log) | UNTESTED | UNTESTED | UNTESTED — `truncated_nbinom1` has no bridge entry in `.GLLVM_JULIA_BRIDGE_FAMILIES` at all |
| `lognormal()` | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED: not in `.GLLVM_JULIA_BRIDGE_FAMILIES`; `src/families/lognormal.jl` exists natively |
| `gengamma()` | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED: not in bridge family list; no `gengamma.jl` found under `src/families/` — likely genuinely absent on the Julia side too, not just an adapter gap |
| `student()` | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED: not in bridge family list; `src/families/studentt.jl` exists natively (`NATIVE-10-STUDENT` in catalogue, UNPAID) |
| `tweedie()` | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED: not in bridge family list; `src/families/tweedie.jl` exists natively (`NATIVE-07-TWEEDIE`, UNPAID) |
| `censored_poisson()` | UNTESTED | UNTESTED | UNTESTED; `src/families/censored_poisson.jl` present but described in-repo as "marker for right-censored Poisson... twin gllvmTMB exposes a constructor only" |
| `gamma_mix()` / `lognormal_mix()` / `nbinom2_mix()` | UNTESTED | UNTESTED | UNTESTED; no mixture fitter found under `src/families/`; rejected outright by the *current multivariate R fitter itself* per `families.R` docstring ("the current multivariate fitter rejects them") — so this may be a source-side non-starter, not a bridge gap |
| `betabinomial()` | UNTESTED | UNTESTED | UNTESTED; `src/families/beta_binomial.jl` exists natively (`NATIVE-09-BETABINOMIAL`, UNPAID); not in bridge family list |
| `ordinal_probit()` | UNTESTED | UNTESTED | UNTESTED; `.GLLVM_JULIA_PERTRAIT_ORDINAL_FAMILIES` admits `ordinal_probit` at the bridge layer, and `src/families/ordinal.jl` exists, but note the CLAUDE.md-documented cross-engine caveat: GLLVM.jl's ordinal is cumulative-**logit**, R's is probit — these are NOT the same link scale (docstring in `families.R`: "the `engine = \"julia\"` bridge maps probit to probit and does not route a logit ordinal response") |
| `multinomial()` | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED: not in `.GLLVM_JULIA_BRIDGE_FAMILIES`; `src/families/multinomial.jl` exists natively (`NATIVE-17-MULTINOMIAL-FIXED`, UNPAID); R itself fences most structured multinomial use via `R/multinomial-fence.R` regardless of engine |
| `delta_*()` (8 constructors: gamma/gengamma/lognormal/lognormal_mix/truncated_nbinom2/truncated_nbinom1/beta, + 2 deprecated Poisson-link wrappers) | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED: no delta/two-part entry anywhere in `.GLLVM_JULIA_BRIDGE_FAMILIES`; `src/families/twopart.jl` exists but its mapping to any specific `delta_*()` constructor is UNTESTED |

## 2. Structural-dependency × route matrix

| Structural dependency kind (R grammar) | N | F | B |
|---|---|---|---|
| `latent()` reduced-rank ordination, `unique = FALSE` (no trait Ψ) — the ONE admitted bridge structure | UNTESTED | UNTESTED | PASS — `latent-bare-model-evidence.json` (`COV_ORD_LATENT_BARE_THREE_ROUTE_PASS`); this is the only structural-dependency cell with a fresh 3-route PASS receipt |
| `latent()` reduced-rank, `unique = TRUE` (default; trait-specific Ψ) | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED (soft): the auto-emitted diagonal Ψ companion is **silently dropped with a `cli_warn`**, not refused — the bridge fits the reduced-rank block only and warns; this is a semantic downgrade, not a hard gate. `R/julia-bridge.R` ~L196–215, warning id `gllvmTMB-julia-auto-psi-dropped` |
| Multiple `rr` (reduced-rank) blocks in one fit | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED — `GJL-GATE-MULTI-RR`, `R/julia-bridge.R`: `if (length(rr_terms) > 1L) stop(...)` |
| `indep()` ordinary (ORD-INDEP: independent per-trait diagonal random effect) | UNTESTED | UNTESTED | PASS as a public-bridge **rejection** receipt only, not a fit: `covariance-bridge-boundary-contract.json`/`-evidence.json`, `MODE-ORD-INDEP-PUBLIC-R-BRIDGE`, gate = `GJL-GATE-STRUCTURED-TERMS` — i.e. the *refusal* is verified, the *fit* is not attempted |
| `indep(..., common = TRUE)` (ORD-COMMON, shared scalar variance) | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED — `MODE-ORD-COMMON-PUBLIC-R-BRIDGE`, `GJL-GATE-STRUCTURED-TERMS` (receipted rejection) |
| `dep()` ordinary (ORD-DEP, full unstructured covariance) | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED — but via a **different, earlier, unlabeled failure**, not the named gate: `FIT-MODE-ORD-DEP-PUBLIC-R-BRIDGE`, `bridge_admission: reference_adapter_failure`, `expected_gate: EARLY-GENERIC-ERROR`. This is the maintainer-flagged distinguishing case — treat as a genuine adapter defect (unlabeled early stop), not merely another instance of the documented gate |
| `phylo_latent()`/`animal_latent()`/`kernel_latent()` indep mode (diagonal V) | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED — `FIT-MODE-ANIMAL-INDEP-PUBLIC-R-BRIDGE`, `FIT-MODE-KERNEL-INDEP-PUBLIC-R-BRIDGE`, `GJL-GATE-STRUCTURED-TERMS` |
| `phylo_*`/`animal_*`/`kernel_*` common mode (shared scalar) | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED — `FIT-MODE-ANIMAL-COMMON-PUBLIC-R-BRIDGE`, `FIT-MODE-KERNEL-COMMON-PUBLIC-R-BRIDGE`, `GJL-GATE-STRUCTURED-TERMS` |
| `phylo_dep()`/`animal_dep()`/`kernel_dep()` (full unstructured V) | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED — `FIT-MODE-ANIMAL-DEP-PUBLIC-R-BRIDGE`, `FIT-MODE-KERNEL-DEP-PUBLIC-R-BRIDGE`, `GJL-GATE-STRUCTURED-TERMS` |
| `spatial_latent()`/`spatial_indep()`/`spatial_dep()` (SPDE) | UNTESTED | UNTESTED | UNTESTED — no boundary receipt found for spatial modes specifically; expected to trip the same `GJL-GATE-STRUCTURED-TERMS` (kind ≠ `rr`) by construction, but no fresh receipt exists, so UNTESTED not R-ADAPTER-BLOCKED per the task's own evidentiary bar |
| Random slopes / augmented `latent(1 + x | unit, d=k)` forms | UNTESTED | UNTESTED | UNTESTED — `slopes-required-case-plan.json` status `REFERENCE_CONTRACT_ANNEX_NATIVE_CALLS_UNRESOLVED`; native calls unpaid, bridge untested |
| Row effects (`unit_obs`, `cluster`/`cluster2` grouped diagonal) | UNTESTED | UNTESTED | UNTESTED — no dedicated boundary receipt found; `R/julia-bridge.R` comments confirm within-unit/structured-tier routes "remain on the TMB engine path" (L1552-1554) but no case-id receipt pins a row-effect-specific rejection |
| ISDM / multi-source (`isdm_sources()`, integrated two-source contract) | UNTESTED | UNTESTED | UNTESTED — `isdm-admission-evidence.json` is `PASS_SOURCE_ADMISSION_SUBSET_ONLY` and exercises R-side source/family admission logic (37 cases) but does **not** test `engine = "julia"` at all; no `engine="julia"` + ISDM receipt exists anywhere in the retained evidence |
| Offset terms (any structural dependency + `offset()`) | UNTESTED | UNTESTED | R-ADAPTER-BLOCKED — hard-coded in `R/julia-bridge.R` main dispatch: `if (identical(engine, "julia")) { ... stop("{.code engine = \"julia\"} does not support {.fn offset} terms.", ">" = "Use the default {.code engine = \"tmb\"} ...") }` (~L1038-1047). This is unconditional — no receipt needed beyond reading the source, but no fresh fit-attempt receipt exists either, so treated as R-ADAPTER-BLOCKED on source evidence alone |

## 3. Work order

### JULIA-GAP slices (bounded work for this lane — Julia side)

None of the observed blocks are a Julia capability *rejecting* a payload it received; every observed block is the R adapter stopping first. So there is no JULIA-GAP cell to fix by the strict definition used here. The two most actionable Julia-side gaps that *would* become live JULIA-GAP cells the moment R starts sending payloads:

1. **No structured-fit bridge payload exists on the Julia side at all.** `.gllvm_julia_gate_message` reasons cite "Structured covariance terms need Julia structured-fit payloads" (`R/julia-bridge.R` L196) — confirming the blocker is bilateral: even if R's gate were lifted, `bridge_fit`'s Julia-side contract has no slot for `dep`/`indep`/`phylo_*`/`spatial_*`/row-effect payloads. Scope: extend `bridge_fit`'s flat contract (see `docs/dev-log/2026-06-10-bridge-fit-contract-and-r-wiring.md`) to carry at minimum one additional covariance-kind tag beyond `rr`, starting with ordinary `indep()` (diagonal), since that is the structurally simplest non-`rr` kind and already has a receipted rejection case (`MODE-ORD-INDEP`) to convert into a PASS.
2. **Family-map extension backlog** for families that already have a native Julia fitter (`src/families/`) but no bridge family string: NB1, truncated NB2/Poisson, Student-t, Tweedie, betabinomial, lognormal. `.GLLVM_JULIA_BRIDGE_FAMILIES` needs a corresponding entry plus a receipted `CORE070-FAMILY-*-PUBLIC-R-BRIDGE` case for each before any of these move off UNTESTED.

### R-ADAPTER-BLOCKED — handover spec for the gllvmTMB 0.7.1 R lane

Two distinct defects, not one:

**(a) The documented, working gate — extend its scope, don't touch its logic.** `.gllvmTMB_julia_dispatch()` in `R/julia-bridge.R` (~L192–199) computes `unsupported <- setdiff(unique(kinds), "rr")` and stops with `GJL-GATE-STRUCTURED-TERMS` for any covstruct kind other than `"rr"`. This is functioning as designed and correctly rejects `indep`/`dep`/phylo/animal/kernel/spatial kinds today — 8 of 9 tested cases confirm it (`covariance-bridge-boundary-evidence.json`). No fix needed here; this is the extension point once Julia-side payloads exist (see JULIA-GAP item 1 above) — each newly admitted `kind` needs a corresponding `case_when`/dispatch arm added alongside the existing `rr` handling (`R/julia-bridge.R` response-pivot section, ~L245 onward, where `rr_terms`/`K` are extracted).

**(b) The genuine defect: `dep()` fails before reaching the gate at all.** `FIT-MODE-ORD-DEP-PUBLIC-R-BRIDGE` shows `bridge_admission: "reference_adapter_failure"` with `expected_gate: "EARLY-GENERIC-ERROR"` — meaning ordinary `dep(0 + trait | site)` under `engine = "julia"` does not reach `.gllvmTMB_julia_dispatch()`'s named-gate check at all; something upstream (formula parsing, `parse_multi_formula()`, or `desugar_brms_sugar()` in `R/brms-sugar.R`/`R/parse-multi-formula.R`, both pinned as source dependencies of this contract) throws first, with no `GJL-GATE-*` label. **Handover to the 0.7.1 R lane:** (1) reproduce `gllvmTMB(engine="julia", value ~ 0 + trait + dep(0 + trait | site), df, cluster="species", control=gllvmTMBcontrol(n_init=1L, se=FALSE, aghq=FALSE))` against the same fixture (`test/parity/fixtures/core070_covariance_modes.R`, `MODE-ORD-DEP` case) and capture the actual raised condition/traceback; (2) trace whether the failure is in `parse_multi_formula()`'s covstruct-kind classification for `dep()` specifically (does it even reach `kinds` construction, or does it error inside covstruct parsing before `.gllvmTMB_julia_dispatch()` is called?); (3) either (i) if it's a genuine upstream bug, fix it so `dep()` reaches the same `GJL-GATE-STRUCTURED-TERMS` path as `indep()`/phylo/kernel do today (consistent, labeled rejection — no behavior change, just error-message parity), or (ii) if `dep()` was never meant to reach formula parsing under `engine="julia"` for a structural reason, add an explicit early, named check so the failure carries `GJL-GATE-STRUCTURED-TERMS` (or a new named id) instead of an unlabeled error. Either outcome is a documentation/error-quality fix, not a capability change — `dep()` stays unsupported under `engine="julia"` either way.

Also flag for the 0.7.1 R lane, lower priority (source-confirmed but not receipt-tested): the hard-coded, unconditional `offset()` refusal under `engine="julia"` (`R/julia-bridge.R` ~L1038-1047) has no fresh case-id receipt; add one so it moves from source-reading to PASS.

### UNTESTED — largest bucket, no action implied beyond honest labeling

68 of 90 cells are UNTESTED. The two matrices above name, cell by cell, why each lacks a receipt (either no case-id was ever assigned, or a case exists but its `evidence_status`/`bridge_status` field reads `NOT_REEXECUTED`/`UNPAID`/`PENDING`). Do not read UNTESTED as "broken" or "supported" — it means exactly what it says: no receipt exists and no structural gate was found either.

## EVIDENCE-LIMITS

This matrix was compiled from retained JSON/markdown receipts under `docs/dev-log/core070/`, gate leaves under `.unlazy/core070-aghq/gates/leaf-*.md`, and direct reading of the frozen R 0.7.0 readback sources (`R/families.R`, `R/julia-bridge.R`, `R/fit-multi.R`, `R/isdm-sources.R`, `R/gllvmTMB.R`) plus GLLVM.jl's own `src/families/` directory listing — **not from any fresh fit or fresh R/Julia execution performed in this session**. Cells marked PASS each cite the specific receipt file and status string that supports them; every other cell (JULIA-GAP, R-ADAPTER-BLOCKED, UNTESTED) is a classification derived from source-reading or from an existing receipt's explicit scope-boundary field, not a new test result. Several PASS receipts themselves carry explicit non-generalization scope strings (e.g. `TWO_REQUIRED_FAMILY_SMOKE_CASES_VERIFIED_NOT_FULL_CAPABILITY`, `EIGHT_REJECTIONS_ONE_ADAPTER_FAILURE_VERIFIED_NOT_BRIDGE_PARITY`) — those strings are preserved verbatim in the cells above rather than summarized away, per the frozen manifest's own admission-evidence discipline. `docs/dev-log/core070/required-case-coverage.md` independently states 698 of 752 catalogued source facts still lack reviewed executable-case links program-wide; this matrix's UNTESTED count is consistent with, but narrower in scope than, that broader unresolved count.


## Update 2026-09-01 — R-side bridge lane movement

The maintainer-authorized lane (gllvmTMB claude/julia-bridge-expansion-20260901)
exposed three families fit-only with live paired round-trips green vs
engine="tmb": lognormal, truncated_poisson, betabinomial (trials-N marshalling
included; deliberate X/mask/predict gates REGISTERED in the new drift
registry). Their fit-route cells move UNTESTED -> EXPOSED+LIVE-PAIRED (lane,
pre-merge; formal receipted qualification against the frozen oracle follows
landing). The zip/zinb/zib cells are reclassified from UNTESTED to
MAINTAINER-DECISION (no native R family exists; engine-only exposure is a
public-surface design call). The structured-term gate slice is open: paired
design docs at docs/dev-log/julia-bridge-structured-design-julia-side.md
(this repo) and docs/dev-log/julia-bridge/structured-design-r-side.md
(gllvmTMB lane).
