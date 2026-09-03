"""Build the source-bound, non-promoting Core070 covariance case plan.

The frozen R subset records parser/helper admission facts.  This annex makes
their unpaid model obligations explicit; it never turns a helper pass into a
native, formula, or public-bridge parity claim.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "docs/dev-log/core070/"
SUBSET = PREFIX + "covariance-admission-subset.json"
PLAN = PREFIX + "covariance-required-case-plan.json"
FIXTURE = "test/parity/fixtures/core070_covariance_admission.R"
READBACK = ".unlazy/core070-aghq/oracle-source/readback"
RELATED = [
    PREFIX + "slopes-required-case-plan.json",
    PREFIX + "structured-required-case-plan.json",
    PREFIX + "covariance-mode-fits-contract.md",
]


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def canonical_sha(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def read(path):
    return json.loads((ROOT / path).read_text())


def subset():
    return read(SUBSET)


def need(condition, message):
    if not condition:
        raise ValueError(message)


def domain(fact):
    ident = fact["id"]
    if match := re.fullmatch(r"COV-SLOPE-F(\d{2})-L([012])", ident):
        family_id, link_code = (int(value) for value in match.groups())
        return {
            "kind": "augmented_slope_family_gate",
            "family_id": family_id,
            "link_code": link_code,
            "parameterisation": "R .augmented_slope_family_allowed(family_id, link_code) predicate; future models must pin family/link and the augmented slope random block.",
            "model_domain": "Required family/slope cell; a helper predicate is not a fitted non-Gaussian parity result.",
        }
    if "SPATIAL" in ident:
        return {
            "kind": "spatial_covariance",
            "parameterisation": "SPDE source with independent, low-rank, or dependent trait covariance; pin mesh, coordinates, unique/common flags and family/link.",
            "model_domain": "Spatial cell; Gaussian structured evidence is a narrow candidate only, never generic spatial grammar/interface support.",
        }
    if "ANIMAL" in ident:
        return {
            "kind": "animal_relatedness_covariance",
            "parameterisation": "Relatedness/pedigree source plus diagonal, low-rank, or dependent trait covariance; pin source alignment and unique/common flags.",
            "model_domain": "Animal source cell; fitted evidence must retain the source matrix/pedigree and family/link.",
        }
    if "KERNEL" in ident:
        return {
            "kind": "known_kernel_covariance",
            "parameterisation": "Named known covariance kernel plus diagonal, low-rank, or dependent trait covariance; pin matrix alignment, definiteness and unique/common flags.",
            "model_domain": "Known-kernel cell; candidate Gaussian evidence does not cover arbitrary kernels, interfaces, or non-Gaussian families.",
        }
    if "PHYLO" in ident:
        return {
            "kind": "phylogenetic_covariance",
            "parameterisation": "Tree or VCV relatedness source plus diagonal, low-rank, or dependent trait covariance; pin tip order, source representation and unique flags.",
            "model_domain": "Phylogenetic source cell; tree and dense VCV routes require separate qualification.",
        }
    if "META" in ident:
        return {
            "kind": "known_sampling_covariance_adapter",
            "parameterisation": "Known sampling variance/covariance transport; pin dimension, row alignment and the estimator's covariance convention.",
            "model_domain": "Known-V adapter; helper rewrite is not fit-stage matrix validation.",
        }
    if ident == "COV-SLOPE-LENGTH":
        return {
            "kind": "augmented_slope_family_gate_input_boundary",
            "parameterisation": "R .augmented_slope_family_allowed() requires family_id and link_code vectors of equal length; this is an input-boundary fact, not a slope-level contract.",
            "model_domain": "Reference helper input boundary; no fitted covariance model is implied.",
        }
    if "SLOPE" in ident:
        return {
            "kind": "ordinary_augmented_slope",
            "parameterisation": "Ordinary latent augmented intercept/slope block; pin predictor design, rank, unique flag and family/link.",
            "model_domain": "Augmented-slope covariance model; preserve Gaussian and non-Gaussian requirements separately.",
        }
    if "HELPER" in ident:
        return {
            "kind": "rejected_reference_helper_grammar",
            "parameterisation": "Reference parser rejection only.",
            "model_domain": "Boundary policy; Julia need not parse literal R helper syntax.",
        }
    return {
        "kind": "ordinary_trait_covariance",
        "parameterisation": "Ordinary diagonal, low-rank, or dependent trait covariance; pin trait basis, unique/common flags, residual convention and family/link.",
        "model_domain": "Ordinary covariance cell; a parser fact does not demonstrate a fitted Julia route.",
    }


def unresolved(role, fact):
    descriptions = {
        "native_model": "a native model fixture with frozen family/link, layout, source inputs, constraints and acceptance comparison",
        "formula_interface": "a Julia formula fixture proving its documented syntax yields the identical native model contract",
        "public_r_bridge": "a public R bridge process fixture proving transfer, fit, extract and failure behaviour",
    }
    return "UNRESOLVED: %s for %s" % (descriptions[role], fact["id"])


def admission_obligation(fact, source_id):
    return {
        "id": "CORE070-COV-" + fact["id"] + "-ADMISSION",
        "source_fact_id": source_id,
        "classification": fact["classification"],
        "status": "SOURCE_ADMISSION_ONLY",
        "required_roles": ["reference_admission"],
        "acceptance_level": "helper_parser_check",
        "reference": {"kind": "pinned_admission_expression", "expression": fact["expression"], "expected": fact["expected"]},
        "fixture": FIXTURE,
        "fixture_sha256": sha(ROOT / FIXTURE),
        "model_domain_spec": domain(fact),
        "parameterisation": domain(fact)["parameterisation"],
        "model_domain": domain(fact)["model_domain"],
        "owner": fact["owner"],
        "acceptance_rule": "Evaluate the pinned R admission expression with the frozen fixture. This helper/parser result establishes no fitted model, numerical parity, or public interface support.",
        "executable_case_ids": [],
        "unresolved_dependency": "A helper-only admission receipt cannot satisfy the separate model/interface obligation.",
    }


def model_obligation(fact, source_id):
    roles = ["native_model", "formula_interface", "public_r_bridge"]
    return {
        "id": "CORE070-COV-" + fact["id"] + "-MODEL",
        "source_fact_id": source_id,
        "classification": fact["classification"],
        "status": "REQUIRED_NOT_CERTIFIED",
        "required_roles": roles,
        "acceptance_level": "paired_model_or_boundary",
        "reference": {"kind": "pinned_admission_expression", "expression": fact["expression"], "expected": fact["expected"]},
        "fixture": FIXTURE,
        "fixture_sha256": sha(ROOT / FIXTURE),
        "model_domain_spec": domain(fact),
        "parameterisation": domain(fact)["parameterisation"],
        "model_domain": domain(fact)["model_domain"],
        "owner": fact["owner"],
        "acceptance_rule": "For each required role, use one declared same-model fixture and compare the frozen R reference and Julia route under identical family/link, design, covariance source, constraints and normalization. Helper/parser checks cannot satisfy this obligation.",
        "routes": {role: {"status": "UNRESOLVED", "call_or_missing": unresolved(role, fact)} for role in roles},
        "executable_case_ids": [],
        "unresolved_dependency": "No model fixture or qualifying Julia route exists for all three required roles; do not promote any existing Gaussian native evidence to formula, bridge, generic grammar, or non-Gaussian coverage.",
    }


def boundary_obligation(fact, source_id):
    return {
        "id": "CORE070-COV-" + fact["id"] + "-BOUNDARY",
        "source_fact_id": source_id,
        "classification": fact["classification"],
        "status": "REQUIRED_REFERENCE_BOUNDARY",
        "required_roles": ["reference_boundary"],
        "acceptance_level": "reference_boundary_or_documented_extension",
        "reference": {"kind": "pinned_admission_expression", "expression": fact["expression"], "expected": fact["expected"], "error_contains": fact.get("error_contains")},
        "fixture": FIXTURE,
        "fixture_sha256": sha(ROOT / FIXTURE),
        "model_domain_spec": domain(fact),
        "parameterisation": domain(fact)["parameterisation"],
        "model_domain": domain(fact)["model_domain"],
        "owner": fact["owner"],
        "acceptance_rule": "Preserve the frozen R rejection as a reference boundary, or qualify a documented Julia extension. Literal R syntax parsing is not required for Julia.",
        "executable_case_ids": [],
        "unresolved_dependency": "Decide and document the Julia boundary/extension policy before assigning a Julia model or parser case.",
    }


def adapter_obligation(fact, source_id):
    return {
        "id": "CORE070-COV-" + fact["id"] + "-ADAPTER",
        "source_fact_id": source_id,
        "classification": fact["classification"],
        "status": "REQUIRED_ADAPTER_POLICY_NOT_CERTIFIED",
        "required_roles": ["interface_policy"],
        "acceptance_level": "reference_adapter_or_documented_extension",
        "reference": {"kind": "pinned_admission_expression", "expression": fact["expression"], "expected": fact["expected"]},
        "fixture": FIXTURE,
        "fixture_sha256": sha(ROOT / FIXTURE),
        "model_domain_spec": domain(fact),
        "parameterisation": domain(fact)["parameterisation"],
        "model_domain": domain(fact)["model_domain"],
        "owner": fact["owner"],
        "acceptance_rule": "Preserve the canonical R adapter boundary or document the Julia-level equivalent; no literal R syntax parser is required, and a rewrite check is not fitted parity.",
        "executable_case_ids": [],
        "unresolved_dependency": "Name the Julia-level adapter or documented-extension policy and a model fixture if the adapter becomes public.",
    }


def known_evidence_catalogue():
    return [
        {"evidence_path": PREFIX + "source-fixed-residual-final-evidence.json", "case_ids": ["MODE-ORD-INDEP", "MODE-ORD-COMMON"], "scope": "Gaussian fixed-noise native models only; retained separately from the full-rank FIT-MODE cases."},
        {"evidence_path": PREFIX + "covariance-mode-fits-evidence.json", "case_ids": ["FIT-MODE-ORD-DEP", "FIT-MODE-ANIMAL-INDEP", "FIT-MODE-ANIMAL-COMMON", "FIT-MODE-ANIMAL-DEP", "FIT-MODE-KERNEL-INDEP", "FIT-MODE-KERNEL-COMMON", "FIT-MODE-KERNEL-DEP"], "scope": "Gaussian native fitting evidence only; no formula, bridge, generic grammar, recovery, inference, or non-Gaussian claim."},
        {"evidence_path": PREFIX + "structured-input-evidence.json", "case_ids": ["STRUCT-PHY-TREE-RR", "STRUCT-PHY-DENSE-RR", "STRUCT-PHY-TREE-PROPTO", "STRUCT-ANI-PED-SPARSE", "STRUCT-KER-SINGLE-PSI", "STRUCT-KER-MULTI"], "scope": "Retained structured reference models; source/input coverage is not a qualified Julia interface or parity result."},
        {"evidence_path": PREFIX + "source-design-formula-evidence.json", "case_ids": ["SOURCE-MEAN-KERNEL-INDEP-X"], "scope": "Direct, wide and reversed-long fixture candidate; does not cover other sources, families, or public interfaces."},
    ]


def related_case_plan_inventory():
    slopes = read(PREFIX + "slopes-required-case-plan.json")
    structured = read(PREFIX + "structured-required-case-plan.json")
    return {
        "slopes": {
            "path": PREFIX + "slopes-required-case-plan.json",
            "sha256": sha(ROOT / PREFIX / "slopes-required-case-plan.json"),
            "status": slopes["status"],
            "case_ids": [case["id"] for case in slopes["cases"]],
            "reuse_rule": "Existing slope IDs remain the authoritative model contracts; covariance admission rows add source-bound obligations without renaming them.",
        },
        "structured": {
            "path": PREFIX + "structured-required-case-plan.json",
            "sha256": sha(ROOT / PREFIX / "structured-required-case-plan.json"),
            "status": structured["status"],
            "case_ids": [case["id"] for case in structured["cases"]],
            "reuse_rule": "Existing structured IDs retain their declared Gaussian/reference scope; they are not automatic coverage of every covariance admission row.",
        },
        "fixed_noise_gaussian_native_evidence": {
            "path": PREFIX + "source-fixed-residual-final-evidence.json",
            "sha256": sha(ROOT / PREFIX / "source-fixed-residual-final-evidence.json"),
            "case_ids": ["MODE-ORD-INDEP", "MODE-ORD-COMMON"],
            "reuse_rule": "These original fixed-noise Gaussian native cases remain separate from full-rank FIT-MODE evidence and cannot discharge formula, bridge, generic grammar, or non-Gaussian obligations.",
        },
        "gaussian_native_evidence": {
            "path": PREFIX + "covariance-mode-fits-evidence.json",
            "sha256": sha(ROOT / PREFIX / "covariance-mode-fits-evidence.json"),
            "case_ids": ["FIT-MODE-ORD-DEP", "FIT-MODE-ANIMAL-INDEP", "FIT-MODE-ANIMAL-COMMON", "FIT-MODE-ANIMAL-DEP", "FIT-MODE-KERNEL-INDEP", "FIT-MODE-KERNEL-COMMON", "FIT-MODE-KERNEL-DEP"],
            "reuse_rule": "These are Gaussian native-only contracts. They remain candidate evidence and cannot discharge formula, bridge, generic grammar, or non-Gaussian obligations.",
        },
    }


def build():
    frozen = subset()
    obligations, source_rows = [], []
    for fact in frozen["cases"]:
        source_id = "covariance/" + fact["id"]
        rows = [admission_obligation(fact, source_id)]
        if fact["classification"] == "required_core":
            rows.append(model_obligation(fact, source_id))
        elif fact["classification"] == "rejected":
            rows.append(boundary_obligation(fact, source_id))
        else:
            rows.append(adapter_obligation(fact, source_id))
        obligations.extend(rows)
        source_rows.append({
            "source_fact_id": source_id,
            "source_row_sha256": canonical_sha(fact),
            "classification": fact["classification"],
            "stage": fact["stage"],
            "obligation_ids": [row["id"] for row in rows],
            "executable_case_ids": [],
            "remaining_obligation": rows[-1]["unresolved_dependency"],
        })
    return {
        "schema": 1,
        "status": "REQUIRED_COVARIANCE_CASE_PLAN_NOT_FROZEN",
        "reference_commit": frozen["reference_commit"],
        "source_subset": SUBSET,
        "source_subset_sha256": sha(ROOT / SUBSET),
        "source_pins": frozen["source_pins"],
        "fixture": FIXTURE,
        "fixture_sha256": sha(ROOT / FIXTURE),
        "existing_case_plans": [{"path": path, "sha256": sha(ROOT / path)} for path in RELATED],
        "related_case_plan_inventory": related_case_plan_inventory(),
        "source_rows": source_rows,
        "obligations": obligations,
        "known_evidence_catalogue": known_evidence_catalogue(),
        "unpaid": frozen["unpaid"],
        "boundary": "This annex is required-contract planning only. It does not freeze the full manifest, certify any route, or approve scope independently.",
    }


def validate(data):
    frozen = subset()
    need(data.get("reference_commit") == frozen["reference_commit"], "wrong frozen reference commit")
    for path, digest in data.get("source_pins", {}).items():
        need(sha(ROOT / READBACK / path) == digest, "stale frozen source " + path)
    need(data.get("fixture") == FIXTURE and data.get("fixture_sha256") == sha(ROOT / FIXTURE), "fixture drift")
    expected_ids = {"covariance/" + fact["id"] for fact in frozen["cases"]}
    actual_ids = {row.get("source_fact_id") for row in data.get("source_rows", [])}
    need(len(data.get("source_rows", [])) == frozen["expected_case_count"] and actual_ids == expected_ids, "source facts omitted or duplicated")
    obligations = {row.get("id"): row for row in data.get("obligations", [])}
    need(len(obligations) == len(data.get("obligations", [])), "duplicate obligation id")
    for fact in frozen["cases"]:
        source_id = "covariance/" + fact["id"]
        source_row = next(row for row in data["source_rows"] if row["source_fact_id"] == source_id)
        need(source_row.get("source_row_sha256") == canonical_sha(fact), "source row drift " + source_id)
        need(source_row.get("executable_case_ids") == [], "unresolved dependency cannot have executable promotion " + source_id)
        linked = [obligations.get(item) for item in source_row.get("obligation_ids", [])]
        need(all(linked), "missing classified obligation " + source_id)
        need(linked[0].get("acceptance_level") == "helper_parser_check", "missing admission obligation " + source_id)
        if fact["classification"] == "required_core":
            model = linked[-1]
            need(model.get("acceptance_level") == "paired_model_or_boundary", "helper cannot satisfy model parity " + source_id)
            need(model.get("required_roles") == ["native_model", "formula_interface", "public_r_bridge"], "required interface roles missing " + source_id)
            need(model.get("executable_case_ids") == [] and model.get("unresolved_dependency"), "unresolved dependency missing " + source_id)
            need(all(route.get("status") == "UNRESOLVED" and route.get("call_or_missing", "").startswith("UNRESOLVED:") for route in model.get("routes", {}).values()), "fake runnable Julia call " + source_id)
        elif fact["classification"] == "rejected":
            boundary = linked[-1]
            need(boundary.get("acceptance_level") == "reference_boundary_or_documented_extension", "rejected grammar lost boundary policy " + source_id)
            need(boundary.get("required_roles") == ["reference_boundary"], "rejected grammar gained unsupported interface role " + source_id)
            need("documented Julia extension" in boundary.get("acceptance_rule", ""), "rejected grammar lacks extension policy " + source_id)
        else:
            adapter = linked[-1]
            need(adapter.get("acceptance_level") == "reference_adapter_or_documented_extension", "adapter policy missing " + source_id)
    required = {row["source_fact_id"] for row in data["source_rows"] if row["classification"] == "required_core"}
    need({"covariance/COV-SLOPE-F01-L1", "covariance/COV-SPATIAL-LATENT", "covariance/COV-SPATIAL-DEP"} <= required, "required augmented-slope or spatial cell dropped")
    expected = build()
    need(data == expected, "covariance required case plan differs from source-bound generator")


def read_generated():
    return read(PLAN)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.write:
        path = ROOT / PLAN
        need(not path.exists(), "refusing to overwrite existing covariance required-case plan")
        path.write_text(json.dumps(build(), indent=2) + "\n")
    elif args.check:
        validate(read_generated())
        print("CORE070_COVARIANCE_REQUIRED_CASE_PLAN_OK 95 source facts; model/interface obligations remain unresolved")
    else:
        parser.error("use --write or --check")
