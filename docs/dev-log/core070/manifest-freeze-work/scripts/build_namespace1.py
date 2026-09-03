import json

ANNEX = "docs/dev-log/core070/namespace-required-case-plan.json"

def row(source_id, classification, case_ids=None, specs=None, rationale="", reclassify=None, uncertain=False):
    return {
        "source_id": source_id,
        "planned_case_ids": case_ids or [],
        "case_plan_annex": ANNEX,
        "case_specs": specs or [],
        "rationale": rationale,
        "reclassify": reclassify,
        "uncertain": uncertain,
    }

def spec(case_id, r_call, julia_surface, comparands, evidence_kind):
    return {
        "case_id": case_id,
        "r_call": r_call,
        "julia_surface": julia_surface,
        "comparands": comparands,
        "evidence_kind": evidence_kind,
    }

rows = []

# ---- S3 methods: gllvmTMB_julia (bridge readback of a Julia GLLVM.jl fit) ----
julia_bridge_methods = [
    ("coef", "COEF"), ("confint", "CONFINT"), ("fitted", "FITTED"),
    ("logLik", "LOGLIK"), ("predict", "PREDICT"), ("residuals", "RESIDUALS"),
    ("simulate", "SIMULATE"),
]
for gen, tag in julia_bridge_methods:
    sid = f"namespace/S3method/{gen},gllvmTMB_julia"
    cid = f"CORE070-NAMESPACE-{tag}-JULIA-BRIDGE-COMPARE"
    rows.append(row(
        sid, "required_core", [cid],
        [spec(cid,
              f"{gen}.gllvmTMB_julia(object, ...) on an R6/list bridge object returned by julia-bridge.R fit_gllvmTMB_julia()",
              f"GLLVM.jl native postfit accessor exercised through R/JuliaCall (e.g. StatsAPI.{gen if gen not in ('logLik',) else 'loglikelihood'} on the fitted GllvmFit)",
              ["R bridge method output", "direct Julia call via JuliaCall on the same fit"],
              "bridge")],
        f"{gen}.gllvmTMB_julia is the R-side readback of a live Julia GLLVM.jl fit (julia-bridge.R); its numeric output must match calling the equivalent Julia accessor directly on the same fitted object."))

rows.append(row(
    "namespace/S3method/print,gllvmTMB_julia", "compatibility_adapter", [], [],
    "print.gllvmTMB_julia (julia-bridge.R) only formats already-bridged numeric content for console display; it has no independent Julia surface beyond the coef/logLik/fitted rows already required above.",
    reclassify={"to": "compatibility_adapter", "reason": "Pure R-side console formatting of bridge-object fields that are separately covered as required_core (coef/confint/fitted/logLik/predict/residuals/simulate,gllvmTMB_julia). No numeric parity target of its own."}))

rows.append(row(
    "namespace/S3method/summary,gllvmTMB_julia", "required_core",
    ["CORE070-NAMESPACE-SUMMARY-JULIA-BRIDGE-COMPARE"],
    [spec("CORE070-NAMESPACE-SUMMARY-JULIA-BRIDGE-COMPARE",
          "summary.gllvmTMB_julia(object, ...) (julia-bridge.R:3417), which assembles a summary.gllvmTMB_julia list from the bridge object's coef/SE/loadings fields",
          "GLLVM.jl postfit summary content (coef table, SEs) assembled from the same GllvmFit via postfit.jl accessors",
          ["fields of the R summary.gllvmTMB_julia object", "the underlying Julia accessor outputs it is built from"],
          "bridge")],
    "summary.gllvmTMB_julia computes a numeric summary object (not just prints it); its content must match the Julia postfit accessors it is assembled from."))

rows.append(row(
    "namespace/S3method/print,summary.gllvmTMB_julia", "compatibility_adapter", [], [],
    "print.summary.gllvmTMB_julia (julia-bridge.R:3457) only formats the already-validated summary.gllvmTMB_julia object for console display.",
    reclassify={"to": "compatibility_adapter", "reason": "Console formatting of a summary object whose numeric content is separately required_core (summary,gllvmTMB_julia). No distinct Julia surface."}))

# ---- S3 methods: gllvmTMB_multi (native R multi-response fit) ----
multi_numeric_methods = [
    ("coef", "COEF"), ("confint", "CONFINT"), ("deviance", "DEVIANCE"),
    ("fitted", "FITTED"), ("logLik", "LOGLIK"), ("predict", "PREDICT"),
    ("residuals", "RESIDUALS"), ("simulate", "SIMULATE"),
    ("summary", "SUMMARY"), ("tidy", "TIDY"), ("vcov", "VCOV"),
]
for gen, tag in multi_numeric_methods:
    sid = f"namespace/S3method/{gen},gllvmTMB_multi"
    cid = f"CORE070-NAMESPACE-{tag}-MULTI-NATIVE"
    rows.append(row(
        sid, "required_core", [cid],
        [spec(cid,
              f"{gen}.gllvmTMB_multi(object, ...) on a native R multi-response gllvmTMB fit (methods-gllvmTMB.R / vcov-coef.R / z-confint-gllvmTMB.R)",
              f"GLLVM.jl equivalent postfit accessor on the corresponding multi-response GllvmFit",
              ["R native gllvmTMB_multi method output", "GLLVM.jl postfit accessor on a formula-equivalent fit"],
              "formula")],
        f"{gen}.gllvmTMB_multi is a required accessor on the native multi-response fit object; its numeric output is the R-side comparand for the matching GLLVM.jl postfit accessor."))

rows.append(row(
    "namespace/S3method/stats::nobs,gllvmTMB_multi", "required_core",
    ["CORE070-NAMESPACE-NOBS-MULTI-NATIVE"],
    [spec("CORE070-NAMESPACE-NOBS-MULTI-NATIVE",
          "nobs.gllvmTMB_multi(object, ...) (methods-gllvmTMB.R), the stats::nobs S3 method",
          "number of observations recoverable from a GLLVM.jl GllvmFit's stored design (size(fit.y, 1) or equivalent)",
          ["R nobs() value", "Julia fit's observation count"],
          "native")],
    "nobs.gllvmTMB_multi reports sample size used in the fit; trivial but required for interface parity checks that key off n."))

for gen, cls, reason in [
    ("ordiplot", "required_core", None),
    ("plot", "intentionally_excluded", "plot.gllvmTMB_multi (plot-gllvmTMB.R) renders a generic diagnostic/residual plot; it is a visualization-only S3 method with no distinct numeric Julia parity target beyond the residuals/fitted accessors already required above."),
]:
    sid = f"namespace/S3method/{gen},gllvmTMB_multi"
    if gen == "ordiplot":
        cid = "CORE070-NAMESPACE-ORDIPLOT-MULTI-SCORES"
        rows.append(row(
            sid, cls, [cid],
            [spec(cid,
                  "ordiplot.gllvmTMB_multi(x, ...) (output-methods.R:384), which computes/extracts ordination scores and loadings before rendering",
                  "GLLVM.jl ordiplot()/ordination() (src/ordination.jl), which returns the same rotated latent-variable score matrix",
                  ["ordination scores/loadings feeding the R plot", "GLLVM.jl ordination() score matrix on the same fit"],
                  "postfit-readback")],
            "GLLVM.jl has its own ordiplot()/ordination() (src/ordination.jl) returning rotated LV scores; the required case compares the underlying score/loading data the R plot consumes, not the rendered pixels."))
    else:
        rows.append(row(sid, "intentionally_excluded", [], [], reason,
                         reclassify={"to": "intentionally_excluded", "reason": reason}))

rows.append(row(
    "namespace/S3method/plot,gllvmTMBmesh", "intentionally_excluded", [], [],
    "plot.gllvmTMBmesh (mesh.R:447) renders an SPDE mesh diagram; it is display-only.",
    reclassify={"to": "intentionally_excluded", "reason": "Rendering of a spatial SPDE mesh (mesh.R). GLLVM.jl's SPDE surface (src/spde.jl, src/spde_mesh.jl) is exercised by its own construction/fitting cases; the plot method itself has no numeric parity target."}))

rows.append(row(
    "namespace/S3method/plot,sdmTMBmesh", "intentionally_excluded", [], [],
    "plot.sdmTMBmesh (mesh.R:462) renders the sdmTMB-flavoured mesh object; display-only, same as plot.gllvmTMBmesh.",
    reclassify={"to": "intentionally_excluded", "reason": "Rendering-only S3 method for a spatial mesh object; no independent numeric Julia parity target."}))

rows.append(row(
    "namespace/S3method/plot,profile_derived", "intentionally_excluded", [], [],
    "plot.profile_derived (profile-derived-curves.R:1104) renders the profile-likelihood curve for a derived quantity; the underlying CI values are already required via confint_derived.",
    reclassify={"to": "intentionally_excluded", "reason": "Visualization of profile_ci_derived() output already covered by GLLVM.jl's src/confint_derived.jl profile-CI required cases; the plot itself renders no new numeric content."}))

rows.append(row(
    "namespace/S3method/plot,profile_loadings", "intentionally_excluded", [], [],
    "plot.profile_loadings (loading-profile.R:321) renders profile CIs on loadings; underlying values covered by confint_profile.",
    reclassify={"to": "intentionally_excluded", "reason": "Visualization of profile-CI-on-loadings values already covered by GLLVM.jl's src/confint_profile.jl required cases; no independent numeric target."}))

# ---- print,* diagnostic-object formatters (compatibility_adapter) ----
print_diag = [
    ("gllvmTMB_Sigma_phy_slope", "extract-sigma.R", "the phylogenetic-slope Sigma table already covered by extract_Sigma-family required cases"),
    ("gllvmTMB_check_consistency", "check-consistency.R", "check_gllvmTMB()'s internal consistency diagnostic, already required_core via check_gllvmTMB"),
    ("gllvmTMB_confint_inspect", "confint-inspect.R", "the confint_inspect() object, already required_core via confint_inspect"),
    ("gllvmTMB_coverage_study", "coverage-study.R", "a simulation coverage-study summary object (dev/reporting tooling, not a fitted-model accessor)"),
    ("gllvmTMB_identifiability", "diagnose.R", "an identifiability-diagnostic object produced by check_gllvmTMB()"),
    ("gllvmTMB_reportable_table", "reportable-table.R", "a formatted reporting table assembled from already-validated diagnostic values"),
    ("gllvmTMB_slope_ci", "slope-sd-ci.R", "the slope-SD CI object, already required_core via the slope confint machinery"),
]
for cls_name, src_file, desc in print_diag:
    sid = f"namespace/S3method/print,{cls_name}"
    reason = f"print.{cls_name} ({src_file}) only formats an already-computed R diagnostic object ({desc}) for console display; it carries no independent numeric content."
    rows.append(row(sid, "compatibility_adapter", [], [], reason,
                     reclassify={"to": "compatibility_adapter", "reason": reason}))

rows.append(row(
    "namespace/S3method/print,gllvmTMB_multi", "compatibility_adapter", [], [],
    "print.gllvmTMB_multi (methods-gllvmTMB.R) formats the native multi-response fit for console display; numeric content is separately required via coef/confint/logLik/etc.,gllvmTMB_multi.",
    reclassify={"to": "compatibility_adapter", "reason": "Console formatting only; underlying numeric accessors are separately required_core."}))

rows.append(row(
    "namespace/S3method/print,summary.gllvmTMB_multi", "compatibility_adapter", [], [],
    "print.summary.gllvmTMB_multi formats the summary.gllvmTMB_multi object already required_core via summary,gllvmTMB_multi.",
    reclassify={"to": "compatibility_adapter", "reason": "Console formatting only; the summary object's numeric content is separately required_core."}))

rows.append(row(
    "namespace/S3method/imputed,gllvmTMB", "required_core",
    ["CORE070-NAMESPACE-IMPUTED-MISSING-PREDICTOR"],
    [spec("CORE070-NAMESPACE-IMPUTED-MISSING-PREDICTOR",
          "imputed.gllvmTMB(object, ...) (missing-predictor.R), returning FIML-style imputed predictor values from a fit with missing covariates",
          "GLLVM.jl missing-predictor imputation (src/missing_predictor_fiml.jl / missing_predictor_multi.jl / missing_predictor_phylo.jl)",
          ["R imputed predictor values", "Julia missing-predictor imputed values on the same design"],
          "native")],
    "imputed.gllvmTMB exposes the FIML imputed-covariate values; GLLVM.jl has a dedicated missing-predictor family of modules that must reproduce the same imputed values."))

# ---- export/ functions ----

def E(name, cls, case_ids, specs, rationale, reclassify=None, uncertain=False):
    rows.append(row(f"namespace/export/{name}", cls, case_ids, specs, rationale, reclassify, uncertain))

E(".proportions_bootstrap_ci", "required_core",
  ["CORE070-NAMESPACE-PROPORTIONS-BOOTSTRAP-CI"],
  [spec("CORE070-NAMESPACE-PROPORTIONS-BOOTSTRAP-CI",
        ".proportions_bootstrap_ci(...) (proportions-ci.R:423), the parametric-bootstrap CI for extract_proportions() shared/unique variance splits",
        "GLLVM.jl src/confint_derived.jl bootstrap_ci_derived() applied to proportions(fit; component=...)",
        ["R bootstrap CI bounds for a proportions component", "Julia bootstrap_ci_derived on proportions()"],
        "native")],
  "Internal-but-exported bootstrap CI helper behind extract_proportions(); its bounds must match GLLVM.jl's bootstrap_ci_derived applied to the Julia proportions() function.")

E(".proportions_wald_ci", "required_core",
  ["CORE070-NAMESPACE-PROPORTIONS-WALD-CI"],
  [spec("CORE070-NAMESPACE-PROPORTIONS-WALD-CI",
        ".proportions_wald_ci(...) (proportions-ci.R:247), the transformed-scale Wald CI for a proportions/ICC-like component",
        "GLLVM.jl src/confint_derived_wald.jl icc_wald_ci() / transformed_wald_ci_derived() (logit-transformed for [0,1] quantities per CLAUDE.md)",
        ["R Wald CI bounds", "Julia icc_wald_ci / transformed_wald_ci_derived bounds on the same fit"],
        "native")],
  "Matches GLLVM.jl's documented logit-transformed Wald CI for bounded derived quantities (confint_derived_wald.jl).")

E("Beta", "required_core",
  ["CORE070-NAMESPACE-BETA-FAMILY-NATIVE-MODEL"],
  [spec("CORE070-NAMESPACE-BETA-FAMILY-NATIVE-MODEL",
        "Beta(link = \"logit\") (families.R:213) used as a family= argument in gllvmTMB()",
        "GLLVM.jl families/beta.jl Beta-family fit driver",
        ["R Beta-family fit log-likelihood/estimates", "GLLVM.jl Beta-family fit on the same simulated data"],
        "formula")],
  "GLLVM.jl already implements a dense-Laplace Beta family (families/beta.jl); the R Beta() constructor's fitted output is a direct required parity target.")

E("add_utm_columns", "compatibility_adapter", [], [],
  "add_utm_columns (crs.R) is an R-only CRS/UTM coordinate-conversion helper for spatial covariate prep; GLLVM.jl has no geographic-projection surface to compare against.",
  reclassify={"to": "compatibility_adapter", "reason": "Pure R coordinate-system convenience utility outside GLLVM.jl's modeling surface (no CRS/UTM equivalent in src/)."})

E("animal_dep", "required_core",
  ["SLOPE-ANIMAL-DEP-BAR", "SLOPE-ANIMAL-DEP-DBAR"],
  [],
  "animal_dep(formula, pedigree=...) (animal-keyword.R:297) builds a dependent-covariance animal-model term; already exercised by the existing SLOPE-ANIMAL-DEP-* cases in docs/dev-log/core070/slopes-required-case-plan.json, reused here rather than renamed per that annex's stated reuse rule.")

E("animal_indep", "required_core",
  ["SLOPE-ANIMAL-INDEP-BAR", "SLOPE-ANIMAL-INDEP-DBAR"],
  [],
  "animal_indep(formula, pedigree=...) (animal-keyword.R:193); reuses the existing SLOPE-ANIMAL-INDEP-* cases from slopes-required-case-plan.json.")

E("animal_latent", "required_core",
  ["SLOPE-ANIMAL-LAT-DEFAULT", "SLOPE-ANIMAL-LAT-NOUNIQUE", "SLOPE-ANIMAL-LAT-RANK4"],
  [],
  "animal_latent(...) (animal-keyword.R:249); reuses the existing SLOPE-ANIMAL-LAT-* cases from slopes-required-case-plan.json.")

E("animal_scalar", "required_core", [], [],
  "animal_scalar(id, pedigree=...) (animal-keyword.R:85) builds a scalar (single-trait) animal-model random effect. No existing SLOPE-ANIMAL-* case ID is named for the scalar (single-response) variant specifically -- the slopes plan's SLOPE-ANIMAL-* IDs all appear to be multi-trait (BAR/DBAR/LAT/MULTIGAUSS/MULTIPOIS). Needs confirmation against animal-keyword.R and the slopes plan before a new case ID is minted.",
  uncertain=True)

E("animal_slope", "required_core", [], [],
  "animal_slope(formula, pedigree=...) (animal-keyword.R:349) builds a random-slope animal-model term. Unclear which existing SLOPE-ANIMAL-* case (if any) specifically exercises the random-slope-on-pedigree grammar path versus the random-intercept animal_dep/animal_indep paths; needs source cross-check before minting or reusing a case ID.",
  uncertain=True)

E("animal_unique", "required_core", [], [],
  "animal_unique(id, pedigree=...) (animal-keyword.R:147) builds a per-species-unique-effect animal-model term. No SLOPE-ANIMAL-UNIQUE case exists in slopes-required-case-plan.json (closest is LAT-NOUNIQUE, which looks like the opposite grammar path); needs source cross-check before minting a case ID.",
  uncertain=True)

E("betabinomial", "required_core", [], [],
  "betabinomial(link=\"logit\") (families.R:578) constructs a beta-binomial family. GLLVM.jl's supported family set (Gaussian, Binomial, Poisson, NegBin, Beta, Gamma, Ordinal) does not include beta-binomial; AGENTS.md/CLAUDE.md list two-part/overdispersion-mixture families as future work, not implemented.",
  reclassify={"to": "intentionally_excluded", "reason": "Beta-binomial is not among GLLVM.jl's implemented families (README/CLAUDE.md family list); no Julia surface exists to compare against until it ships."})

E("block_V", "required_core", [], [],
  "block_V(study_id, sampling_var, rho_within=0.5) (two-stage.R:55) builds a block-structured sampling-variance matrix for a two-stage meta-analytic pipeline, a use case distinct from GLLVM's per-observation latent-variable model.",
  reclassify={"to": "intentionally_excluded", "reason": "Two-stage meta-analytic block-variance construction utility, outside GLLVM.jl's GLLVM/phylogenetic modeling scope (no meta-analysis two-stage pipeline in src/)."})

E("bootstrap_Sigma", "required_core",
  ["CORE070-NAMESPACE-BOOTSTRAP-SIGMA-NATIVE"],
  [spec("CORE070-NAMESPACE-BOOTSTRAP-SIGMA-NATIVE",
        "bootstrap_Sigma(...) (bootstrap-sigma.R:196), the parametric-bootstrap CI for the fitted Sigma_y covariance",
        "GLLVM.jl src/confint_bootstrap.jl parametric-bootstrap CI applied to sigma_y_site() (src/confint_derived.jl)",
        ["R bootstrap Sigma CI bounds", "Julia confint_bootstrap.jl bounds on sigma_y_site()"],
        "native")],
  "Directly maps to GLLVM.jl's confint_bootstrap.jl bootstrap-CI machinery applied to the Sigma_y accessor.")

E("categorical", "compatibility_adapter", [], [],
  "categorical() (missing-predictor.R:143) is a formula-grammar sentinel marking a predictor's imputation type; R-side sugar with no independent Julia numeric surface.")

E("check_auto_residual", "required_core", [], [],
  "check_auto_residual(fit) (check-auto-residual.R:60) auto-selects/validates the residual type for a fit. GLLVM.jl's link_residual.jl implements family-specific residuals, but no single function name maps one-to-one to R's auto-selection logic; needs source comparison before a case can be specified precisely.",
  uncertain=True)

E("check_gllvmTMB", "required_core",
  ["CORE070-NAMESPACE-CHECK-GLLVMTMB-DIAGNOSTIC"],
  [spec("CORE070-NAMESPACE-CHECK-GLLVMTMB-DIAGNOSTIC",
        "check_gllvmTMB(...) (diagnose.R:1548), the top-level post-fit diagnostic wrapper (convergence, gradient, Hessian, identifiability checks)",
        "GLLVM.jl src/fit_verdict.jl / src/postfit.jl convergence and identifiability diagnostics on the same fit",
        ["R check_gllvmTMB() verdict fields", "Julia fit_verdict.jl verdict on the same fit"],
        "native")],
  "check_gllvmTMB is the primary R diagnostic wrapper; GLLVM.jl has an analogous fit_verdict.jl/postfit.jl diagnostic surface that must agree on convergence/identifiability verdicts for matched fits.")

for name, target_desc in [
    ("compare_Sigma_table", "compares two already-extracted Sigma tables"),
    ("compare_dep_vs_two_psi", "cross-checks the dep vs. two-psi covariance parameterizations against each other (an R-internal consistency check between two R parameterizations)"),
    ("compare_indep_vs_two_psi", "cross-checks the indep vs. two-psi covariance parameterizations against each other"),
    ("compare_loadings", "compares two already-extracted loadings matrices (Lambda_a, Lambda_b) generically"),
]:
    reason = f"{name} operates on already-extracted R objects and {target_desc}; it is a comparison/diagnostic utility, not itself a fitted-model accessor with an independent Julia numeric surface."
    E(name, "required_core", [], [], reason,
      reclassify={"to": "compatibility_adapter", "reason": reason})

E("confint_inspect", "required_core",
  ["CORE070-NAMESPACE-CONFINT-INSPECT-NATIVE"],
  [spec("CORE070-NAMESPACE-CONFINT-INSPECT-NATIVE",
        "confint_inspect(...) (confint-inspect.R:128), a diagnostic that inspects CI construction (bracket search, convergence) for a fit",
        "GLLVM.jl src/confint_profile.jl bracket-then-bisect diagnostics on the same fit",
        ["R confint_inspect() diagnostic fields", "Julia confint_profile.jl bracket/bisect trace on the same fit"],
        "native")],
  "confint_inspect exercises the profile-CI bracket search machinery that GLLVM.jl's confint_profile.jl also implements; required for CI-construction parity, distinct from the printed report (print,gllvmTMB_confint_inspect is separately reclassified compatibility_adapter).")

E("confirmatory_lambda", "required_core", [], [],
  "confirmatory_lambda(species, ...) (confirmatory-lambda.R:72) builds a confirmatory-factor-analysis Lambda constraint specification (fixed-zero pattern). It is unclear whether GLLVM.jl currently supports user-specified confirmatory loading constraints (vs. only the default lower-triangular identifiability convention in packing.jl); needs source confirmation.",
  uncertain=True)

E("cumulative_logit", "compatibility_adapter", [], [],
  "cumulative_logit() (missing-predictor.R:104) is a formula-grammar link-name sentinel used when parsing ordinal formulas; the underlying cumulative-logit likelihood itself is already required_core via the Ordinal family plan (GLLVM.jl families/ordinal.jl), so this specific sentinel constructor carries no independent numeric content.")

E("delta_gamma", "required_core", [], [],
  "delta_gamma(link1, link2, ...) (families.R:419) constructs a two-part delta-Gamma family. AGENTS.md/CLAUDE.md list two-part/delta families explicitly as future work (\"Add two-part / zero-inflated / delta families\" under Planned next), not yet implemented in GLLVM.jl.",
  reclassify={"to": "intentionally_excluded", "reason": "Two-part delta-Gamma family is not implemented in GLLVM.jl (see AGENTS.md \"Planned next\"); no Julia surface exists to compare against yet."})

E("delta_lognormal", "required_core", [], [],
  "delta_lognormal(link1, link2, ...) (families.R:478) constructs a two-part delta-lognormal family; same status as delta_gamma.",
  reclassify={"to": "intentionally_excluded", "reason": "Two-part delta-lognormal family is not implemented in GLLVM.jl (see AGENTS.md \"Planned next\"); no Julia surface exists to compare against yet."})

E("dep", "required_core",
  ["CORE070-NAMESPACE-DEP-FORMULA-KEYWORD"],
  [spec("CORE070-NAMESPACE-DEP-FORMULA-KEYWORD",
        "dep(formula) (brms-sugar.R:1756), the formula-grammar keyword marking a dependent (correlated) latent-variable covariance structure",
        "GLLVM.jl src/formula.jl covariance-structure keyword parsing for the dependent-structure path",
        ["R-parsed covariance structure from dep(...)", "GLLVM.jl formula.jl parsed structure on an equivalent formula"],
        "formula")],
  "dep() is core formula grammar selecting the dependent-covariance code path; GLLVM.jl's formula.jl must parse the equivalent structure identically for formula-interface parity.")

E("diagnose_kernel_separability", "required_core", [], [],
  "diagnose_kernel_separability(...) (kernel-helpers.R:581) diagnoses whether a structured covariance kernel is separable. No matching Julia function name was found under src/ (structured_cov.jl covers kernel construction but not an explicit separability diagnostic); needs source comparison.",
  uncertain=True)

E("diagnostic_table", "required_core", [], [],
  "diagnostic_table(...) (diagnostic-tables.R:53) assembles already-computed check_gllvmTMB()/diagnostic values into a display table.",
  reclassify={"to": "compatibility_adapter", "reason": "Aggregates already-validated diagnostic values (from check_gllvmTMB and friends, separately required_core) into an R display table; no independent numeric content of its own."})

E("extract_Gamma", "required_core", [], [],
  "extract_Gamma(...) (extract-sigma.R:1719) extracts a Gamma-labelled matrix in a phylogenetic-comparative context (likely an evolutionary-rate matrix, not the Gamma response family). No unambiguous Julia counterpart was identified under src/ (coevolution_gamma in coevolution_glm.jl is a different, GLM-family-specific quantity); needs source read to confirm the intended comparand before specifying a case.",
  uncertain=True)

E("extract_ICC_site", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-ICC-SITE"],
  [spec("CORE070-NAMESPACE-EXTRACT-ICC-SITE",
        "extract_ICC_site(fit, link_residual=c(\"auto\",\"none\")) (extractors.R:101), site-level intraclass correlation",
        "GLLVM.jl src/confint_derived_wald.jl icc_wald_ci() point estimate on the same fit",
        ["R extract_ICC_site() point estimate", "Julia icc_wald_ci() point estimate"],
        "postfit-readback")],
  "GLLVM.jl's confint_derived_wald.jl implements icc_wald_ci(), a plausible direct comparand for the site-ICC point estimate; confidence is moderate given the R function also branches on link_residual.")

E("extract_Omega", "required_core", [], [],
  "extract_Omega(...) (extract-omega.R:189) extracts an Omega-labelled quantity (likely a residual/precision decomposition). No function named Omega (or synonymous export) was found under src/; needs source read of extract-omega.R and comparison against link_residual.jl / confint_derived.jl before a case can be specified.",
  uncertain=True)

E("extract_Sigma", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-SIGMA-NATIVE"],
  [spec("CORE070-NAMESPACE-EXTRACT-SIGMA-NATIVE",
        "extract_Sigma(...) (extract-sigma.R:686), the fitted Sigma_y (species covariance) matrix",
        "GLLVM.jl src/confint_derived.jl sigma_y_site()",
        ["R extract_Sigma() matrix", "Julia sigma_y_site() matrix on the same fit"],
        "postfit-readback")],
  "Direct match: GLLVM.jl's confint_derived.jl exports sigma_y_site(), the Sigma_y entries referenced in CLAUDE.md's confint_derived.jl description.")

E("extract_Sigma_B", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-SIGMA-B-TWOLEVEL"],
  [spec("CORE070-NAMESPACE-EXTRACT-SIGMA-B-TWOLEVEL",
        "extract_Sigma_B(fit) (extractors.R:31), the between-group covariance in a two-level model",
        "GLLVM.jl src/twolevel.jl between-group covariance underlying communality_B()",
        ["R extract_Sigma_B() matrix", "Julia twolevel.jl between-group Sigma_B on the same fit"],
        "postfit-readback")],
  "GLLVM.jl's twolevel.jl computes communality_B()/repeatability() from an internal between-group covariance; the required case compares that underlying Sigma_B matrix.")

E("extract_Sigma_W", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-SIGMA-W-TWOLEVEL"],
  [spec("CORE070-NAMESPACE-EXTRACT-SIGMA-W-TWOLEVEL",
        "extract_Sigma_W(fit) (extractors.R:66), the within-group covariance in a two-level model",
        "GLLVM.jl src/twolevel.jl within-group covariance underlying communality_W()",
        ["R extract_Sigma_W() matrix", "Julia twolevel.jl within-group Sigma_W on the same fit"],
        "postfit-readback")],
  "Mirrors extract_Sigma_B; GLLVM.jl's twolevel.jl computes the within-group covariance internally for communality_W().")

E("extract_Sigma_table", "required_core", [], [],
  "extract_Sigma_table(...) (extract-sigma-table.R:310) formats extract_Sigma()'s output (and related CI bounds) into a display/reporting table.",
  reclassify={"to": "compatibility_adapter", "reason": "Display-table wrapper around extract_Sigma() and its CIs, both separately required_core; no independent numeric content."})

E("extract_coevolution_modules", "required_core", [], [],
  "extract_coevolution_modules(...) (extract-sigma.R:2203) decomposes a fitted coevolution model into modules/blocks. GLLVM.jl's coevolution_glm.jl / coevolution_kronecker.jl fit coevolutionary models but no \"modules\" decomposition function was found; needs source read to confirm scope before specifying a case.",
  uncertain=True)

E("extract_communality", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-COMMUNALITY-NATIVE"],
  [spec("CORE070-NAMESPACE-EXTRACT-COMMUNALITY-NATIVE",
        "extract_communality(...) (extractors.R:212), per-species communality c^2",
        "GLLVM.jl src/confint_derived.jl communality()",
        ["R extract_communality() vector", "Julia communality() vector on the same fit"],
        "postfit-readback")],
  "Direct match: GLLVM.jl's confint_derived.jl exports communality(), matching CLAUDE.md's documented c^2 derived quantity.")

E("extract_correlations", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-CORRELATIONS-NATIVE"],
  [spec("CORE070-NAMESPACE-EXTRACT-CORRELATIONS-NATIVE",
        "extract_correlations(...) (extract-correlations.R:392), the fitted trait-correlation matrix",
        "GLLVM.jl src/confint_derived.jl correlation()",
        ["R extract_correlations() matrix", "Julia correlation() matrix on the same fit"],
        "postfit-readback")],
  "Direct match: GLLVM.jl's confint_derived.jl exports correlation().")

E("extract_cross_correlations", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-CROSS-CORRELATIONS-NATIVE"],
  [spec("CORE070-NAMESPACE-EXTRACT-CROSS-CORRELATIONS-NATIVE",
        "extract_cross_correlations(fit, level=\"unit\", contrasts=FALSE, ...) (extract-correlations.R:884)",
        "GLLVM.jl src/confint_derived.jl correlation() restricted/contrasted to the cross-trait subset",
        ["R extract_cross_correlations() matrix", "Julia correlation()-derived cross-trait entries"],
        "postfit-readback")],
  "Matches CLAUDE.md's documented cross-trait correlation derived quantity, built on the same correlation() primitive as extract_correlations.")

E("extract_cutpoints", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-CUTPOINTS-ORDINAL"],
  [spec("CORE070-NAMESPACE-EXTRACT-CUTPOINTS-ORDINAL",
        "extract_cutpoints(fit, quiet=FALSE) (extract-cutpoints.R:66), the fitted ordinal cutpoints",
        "GLLVM.jl families/ordinal.jl fitted cutpoints tau (OrdinalFit / OrdinalPerTraitFit)",
        ["R extract_cutpoints() tau vector/matrix", "Julia OrdinalFit tau on the same fit"],
        "postfit-readback")],
  "Direct match: GLLVM.jl's Ordinal family (families/ordinal.jl) stores fitted cutpoints tau (shared or per-trait), the natural comparand.")

E("extract_loadings", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-LOADINGS-NATIVE"],
  [spec("CORE070-NAMESPACE-EXTRACT-LOADINGS-NATIVE",
        "extract_loadings(...) (output-methods.R:87), the fitted Lambda loadings matrix",
        "GLLVM.jl src/packing.jl Lambda unpack on the same fit",
        ["R extract_loadings() matrix", "Julia unpacked Lambda on the same fit"],
        "postfit-readback")],
  "Loadings are GLLVM.jl's core packed parameter (src/packing.jl); extract_loadings is a required parity target for every fitted model.")

E("extract_lv_effects", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-LV-EFFECTS-NATIVE"],
  [spec("CORE070-NAMESPACE-EXTRACT-LV-EFFECTS-NATIVE",
        "extract_lv_effects(...) (extractors.R:641), fitted latent-variable site scores",
        "GLLVM.jl postfit.jl / ordination.jl latent-variable score matrix",
        ["R extract_lv_effects() score matrix", "Julia LV score matrix on the same fit"],
        "postfit-readback")],
  "Latent-variable scores are a core postfit quantity; GLLVM.jl's postfit.jl/ordination.jl expose the equivalent score matrix.")

E("extract_ordination", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-ORDINATION-NATIVE"],
  [spec("CORE070-NAMESPACE-EXTRACT-ORDINATION-NATIVE",
        "extract_ordination(...) (extractors.R:482), rotated ordination scores/loadings for plotting",
        "GLLVM.jl src/ordination.jl ordination(fit, Y; rotate=true)",
        ["R extract_ordination() scores/loadings", "Julia ordination() scores/loadings on the same fit"],
        "postfit-readback")],
  "Direct match: GLLVM.jl's ordination.jl exports ordination(), including the rotate option mirrored in extract_ordination.")

E("extract_phylo_signal", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-PHYLO-SIGNAL-NATIVE"],
  [spec("CORE070-NAMESPACE-EXTRACT-PHYLO-SIGNAL-NATIVE",
        "extract_phylo_signal(...) (extract-omega.R:463), per-trait phylogenetic signal H^2",
        "GLLVM.jl src/confint_derived.jl phylo_signal()",
        ["R extract_phylo_signal() H^2 vector", "Julia phylo_signal() H^2 vector on the same phylogenetic fit"],
        "postfit-readback")],
  "Direct match: GLLVM.jl's confint_derived.jl exports phylo_signal(), matching CLAUDE.md's documented H^2 derived quantity.")

E("extract_proportions", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-PROPORTIONS-NATIVE"],
  [spec("CORE070-NAMESPACE-EXTRACT-PROPORTIONS-NATIVE",
        "extract_proportions(...) (extract-omega.R:725), shared/unique variance-proportion decomposition",
        "GLLVM.jl src/confint_derived.jl proportions(fit; component=:shared)",
        ["R extract_proportions() values", "Julia proportions() values on the same fit"],
        "postfit-readback")],
  "Direct match: GLLVM.jl's confint_derived.jl exports proportions(component=...), the natural comparand.")

E("extract_repeatability", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-REPEATABILITY-TWOLEVEL"],
  [spec("CORE070-NAMESPACE-EXTRACT-REPEATABILITY-TWOLEVEL",
        "extract_repeatability(...) (extract-repeatability.R:83), the two-level repeatability estimate",
        "GLLVM.jl src/twolevel.jl repeatability(fit::TwoLevelFit)",
        ["R extract_repeatability() value", "Julia repeatability() value on the same two-level fit"],
        "postfit-readback")],
  "Direct match: GLLVM.jl's twolevel.jl exports repeatability() for a TwoLevelFit.")

E("extract_residual_cor", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-RESIDUAL-COR-NATIVE"],
  [spec("CORE070-NAMESPACE-EXTRACT-RESIDUAL-COR-NATIVE",
        "extract_residual_cor(fit, level=\"unit\") (output-methods.R:342)",
        "GLLVM.jl src/link_residual.jl residual correlation on the same fit",
        ["R extract_residual_cor() matrix", "Julia link_residual.jl residual correlation matrix"],
        "postfit-readback")],
  "GLLVM.jl's link_residual.jl computes family-specific residual covariance/correlation, the natural comparand.")

E("extract_residual_cov", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-RESIDUAL-COV-NATIVE"],
  [spec("CORE070-NAMESPACE-EXTRACT-RESIDUAL-COV-NATIVE",
        "extract_residual_cov(fit, level=\"unit\") (output-methods.R:336)",
        "GLLVM.jl src/link_residual.jl residual covariance on the same fit",
        ["R extract_residual_cov() matrix", "Julia link_residual.jl residual covariance matrix"],
        "postfit-readback")],
  "Companion to extract_residual_cor; same Julia comparand family (link_residual.jl).")

E("extract_residual_split", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-RESIDUAL-SPLIT-NATIVE"],
  [spec("CORE070-NAMESPACE-EXTRACT-RESIDUAL-SPLIT-NATIVE",
        "extract_residual_split(fit) (extract-omega.R:95), shared-vs-unique residual variance split",
        "GLLVM.jl src/confint_derived.jl proportions(fit; component=:shared/:unique)",
        ["R extract_residual_split() values", "Julia proportions() component values on the same fit"],
        "postfit-readback")],
  "Same underlying shared/unique variance decomposition as extract_proportions; comparand is GLLVM.jl's proportions() with the matching component.")

E("extract_rotated_loadings_table", "required_core",
  ["CORE070-NAMESPACE-EXTRACT-ROTATED-LOADINGS-NATIVE"],
  [spec("CORE070-NAMESPACE-EXTRACT-ROTATED-LOADINGS-NATIVE",
        "extract_rotated_loadings_table(...) (rotate-loadings.R:281), rotated loadings assembled into a table",
        "GLLVM.jl src/ordination.jl ordination(fit, Y; rotate=true) rotated loadings",
        ["R rotated-loadings values", "Julia ordination(rotate=true) rotated loadings on the same fit"],
        "postfit-readback")],
  "The rotation itself is numeric content (not just table formatting) and GLLVM.jl's ordination.jl performs an equivalent rotation via its rotate= option, so this is kept required_core rather than reclassified purely as a table formatter.")

E("flag_unreliable_loadings", "required_core",
  ["CORE070-NAMESPACE-FLAG-UNRELIABLE-LOADINGS-NATIVE"],
  [spec("CORE070-NAMESPACE-FLAG-UNRELIABLE-LOADINGS-NATIVE",
        "flag_unreliable_loadings(fit, ...) (loading-ci.R:363), flags loadings whose CI crosses zero / is unstable",
        "GLLVM.jl loading CIs from src/confint.jl / src/confint_profile.jl applied to unpacked Lambda entries",
        ["R flagged-loading indices/reliability", "Julia CI-crossing-zero flags on the same Lambda entries"],
        "postfit-readback")],
  "Reliability flags follow directly from the per-loading CI bounds, which GLLVM.jl already computes via confint.jl/confint_profile.jl on packed Lambda entries.")

E("getLV", "required_core",
  ["CORE070-NAMESPACE-GETLV-NATIVE"],
  [spec("CORE070-NAMESPACE-GETLV-NATIVE",
        "getLV(...) (output-methods.R:169), the fitted latent-variable score matrix accessor",
        "GLLVM.jl postfit.jl / ordination.jl latent-variable score matrix (same target as extract_lv_effects)",
        ["R getLV() score matrix", "Julia LV score matrix on the same fit"],
        "postfit-readback")],
  "getLV is the primary LV-score accessor (extract_lv_effects wraps/derives from it); same Julia comparand.")

out = {"area": "namespace-1", "rows": rows}
with open("/private/tmp/GLLVM.jl-core070-aghq-20260830/docs/dev-log/core070/manifest-freeze-work/drafts/namespace-1.json", "w") as f:
    json.dump(out, f, indent=1)
print("rows written:", len(rows))
