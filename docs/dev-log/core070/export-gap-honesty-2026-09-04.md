# Export-gap honesty note — 2026-09-04

Tool: `python3 tools/parity_ledger.py --ref b4d5fee64def88bc768dda1f1f77c29b295edd86`

## Headline counts (frozen 0.7.0 oracle)

| Direction | Count | Meaning |
|---|---|---|
| FORWARD | **77** | R `NAMESPACE` exports with no Julia twin (genuinely owed after written dispositions) |
| REVERSE | **85** | Julia exports with no R twin (written ahead list; not owed work here per T1) |

**0 UNTRACKED** forward gaps — each FORWARD name maps to a ledger row or a written
`NOT_CAPABILITY` / `DELIBERATELY_NOT_PORTED` / `RENAMED_AWAY` / `ALIASES` entry in
`tools/parity_ledger.py`.

## What FORWARD=77 is not

- Not a promise to port all 77 before any release.
- Not the same as capability-status CLOSURE (that join uses `docs/design/capability-status.md` @ `origin/main`, 48 matched rows).
- Not symmetric with REVERSE=85 — qualification claim is one-directional (T1).

## Major FORWARD buckets (plain language)

| Bucket | Examples | Disposition class |
|---|---|---|
| Missing-data / imputation surface | `impute_model`, `imputed`, `miss_control` | DELIBERATELY_NOT_PORTED — separate engine |
| Geospatial prep helpers | `make_mesh`, `get_crs`, `add_utm_columns` | DELIBERATELY_NOT_PORTED — R-side prep |
| Renamed-away (different quantity) | `getREsd`, `compare_Sigma_table`, `diagnostic_table` | RENAMED_AWAY — Julia computes different estimand |
| Formula / wide-data grammar | `traits()`, keyword grid helpers | BLOCKED_NEEDS_JULIA_SURFACE — change-control |
| iSDM / spatial / column_coef family | large post-0.7.0 R surface | R-only until explicit Julia arc (071 gap sheet) |
| True gaps | remaining names after tables above | Ledger `namespace/export/*` rows |

Full per-name tables live in `tools/parity_ledger.py` run output and
`docs/dev-log/core070/required-source-case-map.json`.

## Honest programme state

- Core070 ledger: **REQUIRED=497 FREE=0** after D4 AGHQ reclassify slice (was 505).
- True parity: **not done** — see `true-parity-decision-map.md` and `gllvmtmb-parity.md` §What parity does NOT mean.
