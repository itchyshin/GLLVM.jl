#!/usr/bin/env python3
"""Reconcile GLLVM.jl's public export surface against R's gllvmTMB, at a named git ref.

Ported from DRM.jl's tools/parity_ledger.py (the drmTMB<->DRM.jl catch-up
countdown), adapted to the gllvmTMB<->GLLVM.jl pair. Reads gllvmTMB's
`NAMESPACE` at a named git ref and GLLVM.jl's own `export` block in
`src/GLLVM.jl`, then reports BOTH directions:

  FORWARD -- R exports with no Julia twin (genuinely owed)
  REVERSE -- Julia exports with no R twin (genuinely ahead)

Each unmatched name is run through written, per-name (or per-pattern) reason
tables -- ALIASES (a twin exists under a different spelling), NOT_CAPABILITY
and DELIBERATELY_NOT_PORTED (forward: R-idiom helpers or accounted absences),
RENAMED_AWAY (forward: the Julia name is deliberately NOT the R name -- see
docs/dev-log/core070/api-rename-notes.md), and AHEAD_EXPLICIT / AHEAD_PATTERNS
(reverse: Julia-only names with a written class) -- so the countdown reports
"genuinely owed"/"genuinely ahead" separately from "accounted for in writing",
rather than summing them into one number that overstates the gap.

Always reads gllvmTMB through `git show <ref>:NAMESPACE` rather than the
working tree -- a working checkout can sit hundreds of commits behind
`origin/main` (VERIFIED 2026-09-02: the frozen 0.7.0 oracle NAMESPACE has 160
export() lines; origin/main has 168).

Value-add over the DRM.jl original: every FORWARD name is cross-checked
against docs/dev-log/core070/required-source-case-map.json's
`namespace/export/<name>` rows, so a forward gap that is already a tracked
ledger row (with a disposition) is distinguished from one that is UNTRACKED.

    python3 tools/parity_ledger.py --ref origin/main
    python3 tools/parity_ledger.py --self-test
"""

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

DEFAULT_GLLVMTMB = "/Users/z3437171/Dropbox/Github Local/gllvmTMB"
DEFAULT_REF = "b4d5fee64def88bc768dda1f1f77c29b295edd86"  # frozen 0.7.0 oracle

# ---------------------------------------------------------------------------
# FORWARD direction: R name -> Julia symbol, where the twin exists under a
# different name. Seeded from docs/src/gllvmtmb-parity.md
# "## R bridge: parameterization map" (the quantity/family-naming
# conventions the R<->Julia bridge already reconciles) plus obvious
# family-constructor renames documented in the same file.
# ---------------------------------------------------------------------------
ALIASES = {
    # parity-map row: NB2 dispersion phi (R) <-> r=1/phi (Julia); same family
    "nbinom2": "NBFit",
    "nbinom1": "NB1",
    "truncated_nbinom2": "TruncatedNegBin2",
    "truncated_poisson": "TruncatedPoisson",
    # parity-map row: Tweedie power nu (R) <-> p (Julia); same family
    "tweedie": "TweedieFit",
    # parity map + families list: R's `student()` <-> Julia's StudentT marker
    "student": "StudentT",
    "betabinomial": "BetaBinom",
    # "Ordinal and ordinal-probit bridge rows..." -- same fitter, link arg
    "ordinal_probit": "OrdinalFit",
    "cumulative_logit": "Ordinal",
    # the fitting verb
    "gllvmTMB": "fit_gllvm",
    "gllvm_julia_fit": "bridge_fit",
}

# FORWARD, R-idiom helpers with no meaningful Julia counterpart: control-object
# constructors, screen/meta helpers with no ported analogue, gradient plumbing.
# Mirrors DRM.jl's NOT_CAPABILITY entries "drm_control"/"gr"/"meta_known_V"
# one-for-one where gllvmTMB carries the same concept.
NOT_CAPABILITY = {
    "gr": "R gradient/generic helper; not a distinct Julia-facing capability",
    "gllvmTMBcontrol": "R control-object constructor (fit-option bag); Julia takes options as keyword args, no matching constructor export",
    "screen_control": "R control-object constructor for screen_gllvmTMB(); same shape as gllvmTMBcontrol, no Julia analogue",
    "meta_known_V": "meta-analysis known-V helper; not a GLLVM engine capability (DRM.jl carries the identical exclusion for its own meta_known_V)",
}

# FORWARD, R name -> Julia's *deliberately different* name. Source:
# docs/dev-log/core070/api-rename-notes.md (maintainer decision, round2-3
# item #5): these 6 renames free the plain R-matching name for a future TRUE
# mirror, because the current Julia function computes a different quantity /
# has a different call shape than R's function of the same old name. A row
# here is NOT a covered twin -- it documents why the obvious alias is wrong.
RENAMED_AWAY = {
    "getREsd": ("latent_score_sd",
                "R's getREsd(fit, block=) covers auxiliary RE blocks; Julia's "
                "computes latent factor-score conditional SDs instead -- "
                "different quantity (api-rename-notes.md)"),
    "compare_Sigma_table": ("compare_fits_Sigma_table",
                "R compares a fit against a supplied ground-truth matrix; "
                "Julia's is a two-fit bridge -- different signature (api-rename-notes.md)"),
    "compare_dep_vs_two_psi": ("compare_fits_dep_vs_two_psi",
                "R refits an alternative phylogenetic two-psi model internally; "
                "Julia's is a generic two-fit bridge -- different model class (api-rename-notes.md)"),
    "compare_indep_vs_two_psi": ("compare_fits_indep_vs_two_psi",
                "indep counterpart of compare_dep_vs_two_psi; same two-psi mismatch (api-rename-notes.md)"),
    "diagnostic_table": ("fit_diagnostic_table",
                "R requires x to already carry gllvmTMB_diagnostic metadata from a "
                "prior call; Julia takes the raw fit and computes everything -- "
                "different call shape (api-rename-notes.md)"),
    "profile_targets": ("profile_curve_targets",
                "renamed alongside the diagnostics.jl round2-3 pass (api-rename-notes.md)"),
}

# FORWARD, genuinely absent but accounted for in writing (not owed, and why).
# Kept short and conservative: only claims this pass can actually ground.
DELIBERATELY_NOT_PORTED = {
    "make_mesh": "R-side geospatial mesh prep (sf, CRS) before any fit; SPDE fitters take a mesh/precision Julia already has, not this constructor",
    "get_crs": "R-side CRS/projection accessor for geospatial prep; no fitting-engine analogue",
    "add_utm_columns": "R-side coordinate-projection convenience for geospatial prep; no fitting-engine analogue",
    "impute_model": "missing-data imputation-model surface; structurally separate from GLLVM.jl's Laplace/VA family fitters",
    "imputed": "missing-data surface; same as impute_model",
    "categorical": "an imputation family (categorical missingness), not a response family; same missing-data surface as impute_model",
    "miss_control": "missing-data control-object constructor; same missing-data surface as impute_model",
}


# ---------------------------------------------------------------------------
# REVERSE direction: Julia exports with no R twin. AHEAD_EXPLICIT carries
# hand-written per-name reasons (mirrors StatsAPI/Base generics or a small
# number of named structs, exactly as DRM.jl's AHEAD_ACCOUNTED does).
# AHEAD_PATTERNS classifies the much larger Julia-only surface (400+ exports
# vs. gllvmTMB's 160) by regex, each with a written class -- a Julia package
# this size cannot get one bespoke sentence per export within this pass, so
# the class itself is the written reason, applied uniformly and disclosed as
# a design choice in the run's markdown record.
# ---------------------------------------------------------------------------
AHEAD_EXPLICIT = {
    "predict": "mirrors Base/StatsAPI predict; gllvmTMB reaches it via S3method(predict, gllvmTMB), never export()",
    "fitted": "mirrors stats::fitted; gllvmTMB reaches it via S3method(fitted, gllvmTMB), never export()",
    "residuals": "mirrors stats::residuals; gllvmTMB reaches it via S3method(residuals, gllvmTMB), never export()",
    "aic": "mirrors stats::AIC; gllvmTMB reaches it via S3method(AIC, gllvmTMB), never export()",
    "bic": "mirrors stats::BIC; gllvmTMB reaches it via S3method(BIC, gllvmTMB), never export()",
    "simulate": "mirrors stats::simulate; gllvmTMB reaches it via S3method(simulate, gllvmTMB), never export()",
    "coef": "mirrors stats::coef; gllvmTMB reaches it via S3method(coef, gllvmTMB), never export()",
    "vcov": "mirrors stats::vcov; gllvmTMB reaches it via S3method(vcov, gllvmTMB), never export()",
    "nobs": "mirrors stats::nobs; gllvmTMB reaches it via S3method(nobs, gllvmTMB), never export()",
    "dof": "StatsAPI naming for a fixed-effect parameter count; gllvmTMB computes this internally for AIC/BIC without exposing an accessor",
    "loglikelihood": "StatsAPI naming for stats::logLik; gllvmTMB reaches it via S3method(logLik, gllvmTMB), never export()",
    "stderror": "StatsAPI generic for per-parameter SEs; gllvmTMB surfaces the same values through printed summary()/coeftable(), not a queryable function",
    "coeftable": "StatsAPI generic for the coefficient table; gllvmTMB prints the same via summary.gllvmTMB, no separate accessor",
    "deviance": "mirrors stats::deviance; gllvmTMB reaches it via S3method(deviance, gllvmTMB), never export()",
    "tidy": "broom-style generic; gllvmTMB has no broom method, this is a Julia-ecosystem convenience",
    "@formula": "StatsModels macro mirroring R's built-in ~ formula literal; base R syntax needs no export",
    "StatsAPI": "re-exported package name (Julia convention for extending a shared interface), not a gllvmTMB-comparable symbol",
}

AHEAD_PATTERNS = [
    (re.compile(r"Fit$"), "struct suffix: backs a fitted model; R represents the same as an S3 class tag, never a matching export"),
    (re.compile(r"marginal_loglik"), "internal marginal-likelihood kernel; reached only from within the fit driver, never an R-facing name"),
    (re.compile(r"^fit_"), "Julia fitting-verb entry point for one family/structure; R dispatches the same concept through gllvmTMB()'s family= argument, not a separate export per family"),
    (re.compile(r"^confint(_|$)"), "CI-machinery entry point (Wald/profile/bootstrap); gllvmTMB reaches CIs via S3method(confint, gllvmTMB), never a family of separate exports"),
    (re.compile(r"^extract_"), "named accessor for a value gllvmTMB exposes as a raw fitted-object field or printed summary() text, not a separate function"),
    (re.compile(r"Link$"), "Julia link-function marker type; R represents the same link as a string argument (e.g. link=\"logit\"), no type export"),
    (re.compile(r"_grad(!)?$"), "hand-coded analytic-gradient kernel; engine internal, never reached by an R-facing name"),
    (re.compile(r"_logpdf$|_logz$|_cdf$"), "distribution-kernel helper (log-density/normalizer/CDF); engine internal"),
    (re.compile(r"_wald_ci$|_ci$"), "named Wald/profile CI accessor for one derived quantity; gllvmTMB reaches CIs generically via confint(), not per-quantity exports"),
    (re.compile(r"^em_|_squarem"), "EM/SQUAREM alternative-solver internals; gllvmTMB's TMB path never uses this solver family"),
    (re.compile(r"^spde_|^Q_|Precision$|precision$"), "SPDE/Matern spatial substrate; a GLLVM.jl capability gllvmTMB's TMB template does not implement (per docs/src/gllvmtmb-parity.md \"Honest gaps\")"),
    (re.compile(r"^phylo_|^augmented_|^felsenstein|Contrasts$|^EdgePhy$|^edge_|^branch_|^Branch|^clade_|^blup"), "phylogenetic engine substrate (sparse/contrasts/edge-incidence); a GLLVM.jl capability with no gllvmTMB analogue"),
    (re.compile(r"^coevolution|^Coevo|^make_cross_kernel"), "coevolution/cross-kernel substrate; a GLLVM.jl capability with no gllvmTMB analogue"),
]


def git_show(repo: Path, ref: str, path: str) -> str:
    out = subprocess.run(
        ["git", "-C", str(repo), "show", f"{ref}:{path}"],
        capture_output=True, text=True,
    )
    if out.returncode != 0:
        sys.exit(f"cannot read {path} at {ref} in {repo}: {out.stderr.strip()}")
    return out.stdout


def norm(s: str) -> str:
    return re.sub(r"[_.]", "", s).lower()


def r_exports(repo: Path, ref: str) -> list[str]:
    ns = git_show(repo, ref, "NAMESPACE")
    return sorted(re.findall(r"^export\((.+?)\)", ns, re.M))


def julia_exports(root: Path) -> list[str]:
    """Parse export block(s) in src/GLLVM.jl (checked to hold them all; no
    other included src/ file carries its own top-level `export` line as of
    this port -- verified by grep across src/)."""
    names: list[str] = []
    src_files = [root / "src" / "GLLVM.jl"]
    for f in src_files:
        text = f.read_text()
        for block in re.findall(r"^export\s+(.+?)(?=\n\s*\n|\nexport|\Z)", text, re.M | re.S):
            block = re.sub(r"#.*", "", block)
            names += [n.strip() for n in block.split(",") if n.strip()]
    return sorted(set(names))


def load_required_case_map(root: Path) -> dict:
    path = root / "docs" / "dev-log" / "core070" / "required-source-case-map.json"
    if not path.exists():
        return {}
    data = json.loads(path.read_text())
    rows = data.get("rows", [])
    return {row["source_id"]: row for row in rows if "source_id" in row}


def classify_ahead(name: str) -> str | None:
    if name in AHEAD_EXPLICIT:
        return AHEAD_EXPLICIT[name]
    for pattern, reason in AHEAD_PATTERNS:
        if pattern.search(name):
            return reason
    return None


def reconcile(r_names: list[str], j_names: list[str]):
    j_norm = {norm(x) for x in j_names}

    def has_twin(name: str) -> bool:
        if norm(name) in j_norm:
            return True
        alias = ALIASES.get(name)
        return bool(alias and norm(alias) in j_norm)

    unmatched = [x for x in r_names if not has_twin(x)]
    not_capability = [x for x in unmatched if x in NOT_CAPABILITY]
    renamed_away = [x for x in unmatched if x in RENAMED_AWAY]
    accounted = [x for x in unmatched
                 if x in DELIBERATELY_NOT_PORTED and x not in not_capability and x not in renamed_away]
    missing = [x for x in unmatched
               if x not in NOT_CAPABILITY and x not in RENAMED_AWAY and x not in DELIBERATELY_NOT_PORTED]

    r_norm = {norm(x) for x in r_names}
    alias_j_norm = {norm(v) for v in ALIASES.values()}

    def has_r_twin(name: str) -> bool:
        n = norm(name)
        return n in r_norm or n in alias_j_norm

    ahead_unmatched = [x for x in j_names if not has_r_twin(x)]
    ahead_classified = {x: classify_ahead(x) for x in ahead_unmatched}
    ahead_accounted = [x for x in ahead_unmatched if ahead_classified[x] is not None]
    ahead_missing = [x for x in ahead_unmatched if ahead_classified[x] is None]

    return {
        "missing": missing,
        "not_capability": not_capability,
        "renamed_away": renamed_away,
        "accounted": accounted,
        "ahead_missing": ahead_missing,
        "ahead_accounted": ahead_accounted,
        "ahead_classified": ahead_classified,
    }


def run(gllvmtmb: Path, ref: str, root: Path) -> int:
    sha = subprocess.run(
        ["git", "-C", str(gllvmtmb), "rev-parse", ref],
        capture_output=True, text=True,
    ).stdout.strip()
    desc = git_show(gllvmtmb, ref, "DESCRIPTION")
    m = re.search(r"^Version:\s*(\S+)", desc, re.M)
    version = m.group(1) if m else "?"

    r_names = r_exports(gllvmtmb, ref)
    j_names = julia_exports(root)
    result = reconcile(r_names, j_names)

    case_map = load_required_case_map(root)

    print(f"gllvmTMB {version} @ {ref} ({sha[:9] if sha else '?'})")
    print(f"  R exports: {len(r_names)}   GLLVM.jl exports: {len(j_names)}")
    print()

    print(f"FORWARD -- RENAMED AWAY ({len(result['renamed_away'])}) -- "
          "the R name is deliberately NOT the Julia name (api-rename-notes.md)")
    for name in result["renamed_away"]:
        new_name, reason = RENAMED_AWAY[name]
        print(f"  {name:<24} -> {new_name:<28} {reason}")
    print()

    print(f"FORWARD -- NOT CAPABILITY ({len(result['not_capability'])}) -- R-idiom helper, no engine analogue")
    for name in result["not_capability"]:
        print(f"  {name:<24} {NOT_CAPABILITY[name]}")
    print()

    print(f"FORWARD -- ACCOUNTED FOR IN WRITING ({len(result['accounted'])}) -- not owed, and why")
    for name in result["accounted"]:
        print(f"  {name:<24} {DELIBERATELY_NOT_PORTED[name]}")
    print()

    print(f"FORWARD -- gllvmTMB EXPORTS WITH NO GLLVM.jl TWIN ({len(result['missing'])}) -- genuinely owed")
    for name in result["missing"]:
        row = case_map.get(f"namespace/export/{name}")
        if row is None:
            status = "UNTRACKED"
        else:
            disp = row.get("disposition")
            cls = row.get("classification", "?")
            status = disp if disp else f"no disposition (classification={cls})"
        print(f"  {name:<28} {status}")
    print()

    print(f"REVERSE -- AHEAD OF gllvmTMB, ACCOUNTED FOR IN WRITING ({len(result['ahead_accounted'])}) -- not a gap, and why")
    for name in result["ahead_accounted"]:
        print(f"  {name:<32} {result['ahead_classified'][name]}")
    print()

    print(f"REVERSE -- GLLVM.jl EXPORTS WITH NO gllvmTMB TWIN ({len(result['ahead_missing'])}) -- genuinely ahead, unclassified")
    for name in result["ahead_missing"]:
        print(f"  {name}")
    print()

    untracked = [x for x in result["missing"]
                 if f"namespace/export/{x}" not in case_map]

    print(f"COUNTDOWN: {len(result['missing'])} export gaps genuinely owed "
          f"({len(untracked)} UNTRACKED of those) · "
          f"{len(result['renamed_away'])} renamed away · "
          f"{len(result['not_capability'])} not-capability · "
          f"{len(result['accounted'])} accounted for · "
          f"{len(result['ahead_missing'])} genuinely ahead · "
          f"{len(result['ahead_accounted'])} ahead-accounted")

    print(f"FORWARD={len(result['missing'])} REVERSE={len(result['ahead_missing'])}")
    return 0


def self_test() -> int:
    """Synthetic NAMESPACE + export block in a temp dir; assert forward/reverse
    counts, then mutate one alias and assert the count changes (negative
    control -- proves the reconciliation logic actually discriminates, rather
    than always reporting the same numbers regardless of input)."""
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp) / "r_repo"
        repo.mkdir()
        subprocess.run(["git", "-C", str(repo), "init", "-q"], check=True)
        subprocess.run(["git", "-C", str(repo), "config", "user.email", "t@t.t"], check=True)
        subprocess.run(["git", "-C", str(repo), "config", "user.name", "t"], check=True)
        (repo / "NAMESPACE").write_text(
            "export(fit_thing)\n"
            "export(aliased_thing)\n"
            "export(r_only_thing)\n"
            "export(gr)\n"
        )
        (repo / "DESCRIPTION").write_text("Package: test\nVersion: 9.9.9\n")
        subprocess.run(["git", "-C", str(repo), "add", "-A"], check=True)
        subprocess.run(["git", "-C", str(repo), "commit", "-q", "-m", "init"], check=True)

        jroot = Path(tmp) / "j_repo"
        (jroot / "src").mkdir(parents=True)
        (jroot / "src" / "GLLVM.jl").write_text(
            "module GLLVM\nexport fit_thing, AliasedThingJl, julia_only_thing\n\nend\n"
        )

        # local test-only aliasing (does not touch module-level ALIASES)
        old_aliases = dict(ALIASES)
        old_not_cap = dict(NOT_CAPABILITY)
        ALIASES.clear()
        ALIASES.update({"aliased_thing": "AliasedThingJl"})
        NOT_CAPABILITY.clear()
        NOT_CAPABILITY.update({"gr": "test stand-in for R-idiom helper"})
        try:
            r_names = r_exports(repo, "HEAD")
            j_names = julia_exports(jroot)
            result = reconcile(r_names, j_names)
            # forward: r_only_thing is the only genuine gap (fit_thing twinned
            # directly, aliased_thing twinned via ALIASES, gr excluded via
            # NOT_CAPABILITY)
            assert result["missing"] == ["r_only_thing"], result["missing"]
            assert result["not_capability"] == ["gr"], result["not_capability"]
            # reverse: julia_only_thing is the only genuine Julia-ahead gap
            assert result["ahead_missing"] == ["julia_only_thing"], result["ahead_missing"]

            # negative control: mutate the alias so it no longer matches the
            # Julia name -- aliased_thing must now show up as a genuine forward
            # gap, proving has_twin() actually depends on ALIASES rather than
            # always reporting the same answer.
            ALIASES["aliased_thing"] = "SomethingElseEntirely"
            result2 = reconcile(r_names, j_names)
            assert "aliased_thing" in result2["missing"], result2["missing"]
            assert result2["missing"] != result["missing"]
        finally:
            ALIASES.clear()
            ALIASES.update(old_aliases)
            NOT_CAPABILITY.clear()
            NOT_CAPABILITY.update(old_not_cap)

    print("SELFTEST_OK")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--gllvmtmb", default=DEFAULT_GLLVMTMB, type=Path,
                     help="path to the gllvmTMB repo")
    ap.add_argument("--ref", default=DEFAULT_REF,
                     help="git ref to read (default: frozen 0.7.0 oracle; also accepts origin/main)")
    ap.add_argument("--root", default=Path(__file__).resolve().parents[1], type=Path,
                     help="path to the GLLVM.jl repo root")
    ap.add_argument("--self-test", action="store_true",
                     help="run the synthetic self-test instead of reading real repos")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    return run(args.gllvmtmb, args.ref, args.root)


if __name__ == "__main__":
    raise SystemExit(main())
