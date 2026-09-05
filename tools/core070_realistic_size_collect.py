#!/usr/bin/env python3
"""core070_realistic_size_collect.py -- T4 realistic-size grid collector stub.

Pairs the Nibi Julia-side outputs (out/<tag>_julia_summary.txt,
out/<tag>_julia_terms.csv, out/<tag>_julia_vcov_beta.csv) with the Totoro
R-side outputs (out/<tag>_r_summary.txt, out/<tag>_r_fixed.csv,
out/<tag>_r_vcov_beta.csv) by cell tag (from
tools/core070_realistic_size_cells.tsv), and prints one row per cell with:
logLik both engines, max rel dSE (beta block), vcov rel Frobenius, max
|dWald endpoint|, cond(H) both engines, wall time both engines, convergence
flags. Does NOT gate on any tolerance -- these are receipts, not a parity
claim (see docs/dev-log/core070/realistic-size-prerun-2026-09-03.md).

Usage:
    python3 core070_realistic_size_collect.py <julia_out_dir> <r_out_dir> \
        [--cells tools/core070_realistic_size_cells.tsv] [--csv out.csv]

<julia_out_dir> and <r_out_dir> may be the same directory once the two
engines' out/ trees are consolidated onto one host (rsync the Nibi array's
out/ back to Totoro's realsize-01/out/, or vice versa).
"""
import argparse
import csv
import math
import os
import re
import sys


def read_summary(path):
    d = {}
    if not os.path.exists(path):
        return d
    with open(path) as f:
        for line in f:
            line = line.strip()
            if "=" not in line:
                continue
            k, v = line.split("=", 1)
            d[k] = v
    return d


def read_terms_csv(path, term_prefix=None, term_col="term", se_col="se"):
    if not os.path.exists(path):
        return []
    rows = list(csv.DictReader(open(path)))
    if term_prefix:
        rows = [r for r in rows if r[term_col].startswith(term_prefix)]
    return rows


def read_matrix(path):
    if not os.path.exists(path):
        return None
    rows = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            rows.append([float(x) for x in line.split(",")])
    return rows


def frob_rel(J, R):
    if J is None or R is None:
        return float("nan")
    n = len(R)
    if len(J) != n:
        return float("nan")
    num = 0.0
    den = 0.0
    for i in range(n):
        for j in range(len(R[i])):
            d = J[i][j] - R[i][j]
            num += d * d
            den += R[i][j] * R[i][j]
    return math.sqrt(num) / math.sqrt(den) if den > 0 else float("nan")



def parse_seed_from_summary(d):
    """Extract integer seed from summary key=value lines."""
    if "seed" in d:
        try:
            return int(float(d["seed"]))
        except ValueError:
            pass
    for v in d.values():
        if isinstance(v, str):
            m = re.search(r"seed=(\d+)", v)
            if m:
                return int(m.group(1))
    return None


def julia_beta_rows(jterms, p_int):
    beta = [r for r in jterms if r.get("term", "").startswith("beta[")]
    if len(beta) == p_int:
        return beta
    return []


def r_trait_rows(rterms, p_int):
    if len(rterms) == p_int:
        return rterms
    trows = [r for r in rterms if re.match(r"^t\d+$", r.get("term", ""))]
    if len(trows) == p_int:
        return sorted(trows, key=lambda r: int(r["term"][1:]))
    return []


def read_cells(path):
    cells = []
    with open(path) as f:
        header = f.readline()
        for line in f:
            line = line.strip()
            if not line:
                continue
            idx, fam, p, n, K, seed = line.split("\t")
            cells.append(dict(idx=idx, family=fam, p=p, n=n, K=K, seed=seed))
    return cells


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("julia_out_dir")
    ap.add_argument("r_out_dir")
    ap.add_argument("--cells", default="tools/core070_realistic_size_cells.tsv")
    ap.add_argument("--csv", default=None, help="optional path to write a CSV of the collected rows")
    args = ap.parse_args()

    cells = read_cells(args.cells)
    out_rows = []
    for c in cells:
        tag = f"{c['family']}_p{c['p']}_n{c['n']}_K{c['K']}"
        js = read_summary(os.path.join(args.julia_out_dir, f"{tag}_julia_summary.txt"))
        rs = read_summary(os.path.join(args.r_out_dir, f"{tag}_r_summary.txt"))
        row = dict(idx=c["idx"], family=c["family"], p=c["p"], n=c["n"], K=c["K"], seed=c["seed"])
        row["julia_present"] = bool(js)
        row["r_present"] = bool(rs)
        if js:
            row["julia_logLik"] = js.get("logLik")
            row["julia_wall_fit_sec"] = js.get("wall_fit_sec")
            row["julia_wall_confint_sec"] = js.get("wall_confint_sec")
            row["julia_cond_H"] = js.get("cond_H")
            row["julia_converged"] = js.get("converged")
            row["julia_pd_hessian"] = js.get("pd_hessian")
            row["julia_dispersion_boundary"] = js.get("dispersion_boundary")
            row["julia_boundary_terms"] = js.get("boundary_terms")
        if rs:
            row["r_logLik"] = rs.get("logLik")
            row["r_wall_fit_sec"] = rs.get("wall_fit_sec")
            row["r_cond_H"] = rs.get("cond_H")
            row["r_converged"] = rs.get("converged")
        if js.get("logLik") and rs.get("logLik"):
            row["logLik_delta"] = float(js["logLik"]) - float(rs["logLik"])

        p_int = int(c["p"])
        js_seed = parse_seed_from_summary(js)
        rs_seed = parse_seed_from_summary(rs)
        if js_seed is not None:
            row["julia_seed"] = js_seed
        if rs_seed is not None:
            row["r_seed"] = rs_seed
        if js_seed is not None and rs_seed is not None:
            row["seed_match"] = js_seed == rs_seed
            if js_seed != rs_seed:
                row["pairing_disposition"] = "wrong_r_seed_in_archive_not_optima_divergence"

        jterms_all = read_terms_csv(os.path.join(args.julia_out_dir, f"{tag}_julia_terms.csv"))
        rterms_all = read_terms_csv(os.path.join(args.r_out_dir, f"{tag}_r_fixed.csv"))
        jterms = julia_beta_rows(jterms_all, p_int)
        rterms = r_trait_rows(rterms_all, p_int)
        if jterms and rterms and len(jterms) == len(rterms):
            max_rel_dse = 0.0
            max_dwald = 0.0
            for jt, rt in zip(jterms, rterms):
                se_j, se_r = float(jt["se"]), float(rt["se"])
                if se_r != 0:
                    max_rel_dse = max(max_rel_dse, abs(se_j - se_r) / abs(se_r))
                max_dwald = max(max_dwald,
                                 abs(float(jt["lower"]) - float(rt["lower"])),
                                 abs(float(jt["upper"]) - float(rt["upper"])))
            row["max_rel_dSE_beta"] = max_rel_dse
            row["max_abs_dWald"] = max_dwald
        elif c["family"] == "gaussian":
            row["second_order_beta_block"] = "gaussian_julia_confint_has_no_trait_intercept_se_rows"

        Jv = read_matrix(os.path.join(args.julia_out_dir, f"{tag}_julia_vcov_beta.csv"))
        if Jv is None:
            Jfull = read_matrix(os.path.join(args.julia_out_dir, f"{tag}_julia_vcov_full.csv"))
            if Jfull is not None and len(Jfull) >= p_int:
                Jv = [row[:p_int] for row in Jfull[:p_int]]
        Rv = read_matrix(os.path.join(args.r_out_dir, f"{tag}_r_vcov_beta.csv"))
        row["vcov_rel_frobenius_beta"] = frob_rel(Jv, Rv)
        if c["family"] == "gaussian" and (Jv is None or Rv is None or math.isnan(row["vcov_rel_frobenius_beta"])):
            row["vcov_beta_note"] = "gaussian_vcov_block_not_aligned_julia_full_vs_r_trait_block"

        out_rows.append(row)

    fieldnames = sorted({k for r in out_rows for k in r.keys()})
    if args.csv:
        with open(args.csv, "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=fieldnames)
            w.writeheader()
            w.writerows(out_rows)
        print(f"wrote {args.csv} ({len(out_rows)} rows)")
    else:
        for r in out_rows:
            print(r)


if __name__ == "__main__":
    main()
