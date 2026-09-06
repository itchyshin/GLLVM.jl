#!/usr/bin/env python3
"""Write per-cell P6 grid receipt JSON + MD from pulled Totoro outputs."""
from __future__ import annotations

import argparse
import csv
import json
import math
import re
import sys
from datetime import date
from pathlib import Path


def read_summary(path: Path) -> dict[str, str]:
    d: dict[str, str] = {}
    if not path.exists():
        return d
    for line in path.read_text().splitlines():
        line = line.strip()
        if "=" not in line:
            continue
        k, v = line.split("=", 1)
        d[k.strip()] = v.strip()
    return d


def read_matrix(path: Path) -> list[list[float]] | None:
    if not path.exists():
        return None
    rows = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        rows.append([float(x) for x in line.split(",")])
    return rows


def read_terms(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open() as f:
        return list(csv.DictReader(f))


def frob_rel(jv: list[list[float]] | None, rv: list[list[float]] | None) -> float:
    if jv is None or rv is None:
        return float("nan")
    n = len(rv)
    if len(jv) != n:
        return float("nan")
    num = den = 0.0
    for i in range(n):
        for j in range(len(rv[i])):
            d = jv[i][j] - rv[i][j]
            num += d * d
            den += rv[i][j] * rv[i][j]
    return math.sqrt(num) / math.sqrt(den) if den > 0 else float("nan")


def parse_bool(s: str | None) -> bool | None:
    if s is None:
        return None
    s = s.lower()
    if s in ("true", "yes", "1"):
        return True
    if s in ("false", "no", "0"):
        return False
    return None


def parse_float(s: str | None) -> float | None:
    if s is None or s == "" or s.lower() == "na":
        return None
    try:
        return float(s)
    except ValueError:
        return None


def eoo_pass(
    family: str,
    jl_conv: bool | None,
    r_conv: bool | None,
    vcov_rel: float,
    max_rel_dse: float | None,
    r_cond: float | None,
) -> tuple[bool, list[str]]:
    issues: list[str] = []
    if jl_conv is not True:
        issues.append("julia_not_converged")
    if r_conv is not True:
        issues.append("r_not_converged")
    scale = 1.0
    if r_cond is not None and r_cond > 1e3:
        scale = r_cond / 1e3
    vcov_tol = 0.01 * scale
    if math.isnan(vcov_rel):
        if family != "gaussian":
            issues.append("vcov_rel_missing")
    elif vcov_rel > vcov_tol:
        issues.append(f"vcov_rel_{vcov_rel:.3g}_gt_{vcov_tol:.3g}")
    if max_rel_dse is not None and not math.isnan(max_rel_dse):
        se_tol = 0.01 * scale
        if max_rel_dse > se_tol:
            issues.append(f"se_rel_{max_rel_dse:.3g}_gt_{se_tol:.3g}")
    return len(issues) == 0, issues


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--receipt-dir", required=True)
    ap.add_argument("--family", required=True)
    ap.add_argument("--p", type=int, required=True)
    ap.add_argument("--n", type=int, required=True)
    ap.add_argument("--K", type=int, required=True)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--git-head", default="unknown")
    ap.add_argument("--launch-log", default=None)
    ap.add_argument("--host", default="totoro.biology.ualberta.ca")
    ap.add_argument("--remote-base", default="/home/snakagaw/core070-aghq-20260830/t4-p6-grid-01/repo")
    args = ap.parse_args()

    out_dir = Path(args.out_dir)
    receipt_dir = Path(args.receipt_dir)
    tag = f"{args.family}_p{args.p}_n{args.n}_K{args.K}"

    js = read_summary(out_dir / f"{tag}_julia_summary.txt")
    rs = read_summary(out_dir / f"{tag}_r_summary.txt")
    if not js or not rs:
        print(f"SKIP {tag}: missing summary (jl={bool(js)} r={bool(rs)})", file=sys.stderr)
        return 1

    jl_loglik = parse_float(js.get("logLik"))
    r_loglik = parse_float(rs.get("logLik"))
    loglik_delta = jl_loglik - r_loglik if jl_loglik is not None and r_loglik is not None else None

    p_int = args.p
    jterms = [r for r in read_terms(out_dir / f"{tag}_julia_terms.csv") if r.get("term", "").startswith("beta[")]
    rterms = read_terms(out_dir / f"{tag}_r_fixed.csv")
    trows = [r for r in rterms if re.match(r"^t\d+$", r.get("term", ""))]
    if len(trows) == p_int:
        rterms = sorted(trows, key=lambda r: int(r["term"][1:]))
    max_rel_dse = None
    max_dwald = None
    if len(jterms) == p_int and len(rterms) == p_int:
        max_rel_dse = 0.0
        max_dwald = 0.0
        for jt, rt in zip(jterms, rterms):
            se_j, se_r = float(jt["se"]), float(rt["se"])
            if se_r != 0:
                max_rel_dse = max(max_rel_dse, abs(se_j - se_r) / abs(se_r))
            max_dwald = max(
                max_dwald,
                abs(float(jt["lower"]) - float(rt["lower"])),
                abs(float(jt["upper"]) - float(rt["upper"])),
            )

    jv = read_matrix(out_dir / f"{tag}_julia_vcov_beta.csv")
    if jv is None:
        jfull = read_matrix(out_dir / f"{tag}_julia_vcov_full.csv")
        if jfull is not None and len(jfull) >= p_int:
            jv = [row[:p_int] for row in jfull[:p_int]]
    rv = read_matrix(out_dir / f"{tag}_r_vcov_beta.csv")
    vcov_rel = frob_rel(jv, rv)

    r_cond = parse_float(rs.get("cond_H"))
    jl_cond = parse_float(js.get("cond_H"))
    jl_conv = parse_bool(js.get("converged"))
    r_conv = parse_bool(rs.get("converged"))
    smoke_pass, smoke_issues = eoo_pass(args.family, jl_conv, r_conv, vcov_rel, max_rel_dse, r_cond)

    receipt = {
        "claim_boundary": "T4 P6 grid cell — RSZ scaling + second-order tolerance evidence; NOT true-parity or gate-tier promotion",
        "receipt_id": f"t4-p6-{args.family}-p{args.p}-n{args.n}-K{args.K}",
        "cell_id": tag,
        "family": args.family,
        "p": args.p,
        "n": args.n,
        "K": args.K,
        "seed": args.seed,
        "tier": "each-own-optimum",
        "host": args.host,
        "oracle": "gllvmTMB 0.7.0 @ b4d5fee64def88bc768dda1f1f77c29b295edd86",
        "git_head": args.git_head,
        "receipt_date": str(date.today()),
        "launch_log": args.launch_log,
        "remote_base": args.remote_base,
        "jl_converged": jl_conv,
        "r_converged": r_conv,
        "jl_logLik": jl_loglik,
        "r_logLik": r_loglik,
        "loglik_delta_jl_minus_r": loglik_delta,
        "wall_fit_julia_sec": parse_float(js.get("wall_fit_sec")),
        "wall_confint_julia_sec": parse_float(js.get("wall_confint_sec")),
        "wall_fit_r_sec": parse_float(rs.get("wall_fit_sec")),
        "wall_confint_r_sec": parse_float(rs.get("wall_confint_sec")),
        "native_condition_number": jl_cond,
        "r_condition_number": r_cond,
        "pd_hessian_native": parse_bool(js.get("pd_hessian")),
        "pd_hessian_r": parse_bool(rs.get("pd_hessian")),
        "r_has_sd_report": True,
        "vcov_frobenius_relative_delta": vcov_rel if not math.isnan(vcov_rel) else None,
        "se_max_relative_delta": max_rel_dse,
        "ci_endpoint_max_delta": max_dwald,
        "eoo_smoke_pass": smoke_pass,
        "eoo_smoke_issues": smoke_issues,
        "result": "PASS" if smoke_pass else "FAIL",
        "outputs_local": "docs/dev-log/core070/t4-p6-out",
    }

    stem = f"t4-p6-{args.family}-p{args.p}-n{args.n}-K{args.K}-receipt-{date.today()}"
    json_path = receipt_dir / f"{stem}.json"
    md_path = receipt_dir / f"{stem}.md"
    receipt_dir.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(receipt, indent=2) + "\n")

    result = "PASS" if smoke_pass else "FAIL"
    md = f"""# T4 P6 grid receipt — {args.family} p={args.p} n={args.n} K={args.K}

**Date:** {date.today()}  
**Shape:** {args.family} · p={args.p} · n={args.n} · K={args.K} · seed={args.seed}  
**Host:** {args.host}  
**Claim boundary:** RSZ scaling + tolerance evidence — **NOT** true-parity promotion.

## Result

**{result}** ({', '.join(smoke_issues) if smoke_issues else 'within each-own-optimum contract'})

| Quantity | Julia | R | Delta |
|---|---:|---:|---:|
| logLik | {jl_loglik} | {r_loglik} | {loglik_delta} |
| cond(H) | {jl_cond} | {r_cond} | recorded |
| vcov Fro rel | — | — | **{vcov_rel if not math.isnan(vcov_rel) else 'NA'}** |
| max rel dSE (β) | — | — | {max_rel_dse} |
| converged | {jl_conv} | {r_conv} | — |

## seff (measured)

| Step | Wall (s) |
|---|---:|
| Julia fit | {receipt['wall_fit_julia_sec']} |
| Julia confint | {receipt['wall_confint_julia_sec']} |
| R fit | {receipt['wall_fit_r_sec']} |

## Outputs

Local: `docs/dev-log/core070/t4-p6-out/`
"""
    md_path.write_text(md)
    print(f"wrote {json_path.name} {md_path.name} -> {result}")
    return 0 if smoke_pass else 2


if __name__ == "__main__":
    raise SystemExit(main())
