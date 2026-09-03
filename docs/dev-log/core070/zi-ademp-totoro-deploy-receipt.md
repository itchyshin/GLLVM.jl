# ZI-Trio ADEMP Totoro Deploy Receipt

**Date:** 2026-09-02

## Purpose

Relocation of core070 ZI-trio ADEMP worker from Narval (no ControlMaster socket available) to Totoro (existing ssh socket, no auth prompt). Pre-run per D-139 (estimate before you run) before full-scale multi-seed campaigns.

## Host + Path

- **Host:** Totoro (snakagaw@totoro.biology.ualberta.ca)
- **Remote path:** `/home/snakagaw/core070-aghq-20260830/zi-ademp-01/repo`
- **Worker script:** `tools/core070_zi_ademp_chunk.jl`
- **Cell map:** `tools/zi-cells.txt`

## Deploy

**rsync summary:**
```
Transfer starting: 463 files
sent 26704 bytes  received 20 bytes  6518048 bytes/sec
total size is 4549973  speedup is 170.26
```

**Remote file verification (ls -l):**
```
-rw-r--r-- 1 snakagaw snakagaw 24088 Sep  1 17:39 Manifest.toml
-rw-r--r-- 1 snakagaw snakagaw  1005 Sep  1 17:41 Project.toml
-rw-r--r-- 1 snakagaw snakagaw  3554 Sep  2 02:53 tools/core070_zi_ademp_chunk.jl
-rw-r--r-- 1 snakagaw snakagaw   124 Sep  2 02:54 tools/zi-cells.txt
```

**Output directories created:**
```
zi-out/  (empty, for outputs)
logs/    (empty, for logs)
```

## Smoke Load

**Command:** `julia +1.10.10 --project=. -e "using Pkg; Pkg.instantiate(); using GLLVM; println(\"GLLVM_LOADED\")"`

**Output:** GLLVM_LOADED (success)

**Timing:**
- Elapsed (wall clock) time: 0:12.39
- Maximum resident set size: 417680 kbytes (407.5 MB)

## Pre-run (D-139)

Sequential runs at p=5, n=50, seeds 1–25 per family.

| Family | Exit | Wall (m:ss) | Max RSS (MB) | Status |
|--------|------|-------------|--------------|--------|
| zip    | 0    | 0:36.85    | 421.3        | OK     |
| zinb   | 0    | 1:21.27    | 434.2        | OK     |
| zib    | 0    | 0:21.85    | 422.2        | OK     |

## Output Inspection

**Remote ls -lh:**
```
-rw-rw-r-- 1 snakagaw snakagaw 3.6K Sep  2 05:53 zi-zib-p5-n50-s0001.csv
-rw-rw-r-- 1 snakagaw snakagaw 3.6K Sep  2 05:53 zi-zinb-p5-n50-s0001.csv
-rw-rw-r-- 1 snakagaw snakagaw 3.6K Sep  2 05:51 zi-zip-p5-n50-s0001.csv
```

**File content samples (first ~500 chars):**

**zi-zip-p5-n50-s0001.csv:**
```
family,p,n,seed,converged,loglik,betaz_bias,betaz_rmse,betac_bias,betac_rmse,crossprod_rel_err,fit_seconds,error
zip,5,50,1,true,-265.7748460175917,-3.943691933345724,9.645913069856865,-0.1445008615931263,0.574066534930809,1.6129859020802841,3.02,
zip,5,50,2,true,-282.58950013482865,-0.0821007129550966,0.7694537347046929,-0.10132010199887635,0.2968675351032147,0.6842071268782993,0.925,
zip,5,50,3,true,-298.24698265743086,-0.31764687703276856,0.42658491536427223,-0.20128291823691974,0.29374688937744814,1.3023954817560643,0.799,
zip,5,50,4,true,-266.17502369354435,-0.6002911170214225,1.2474397533981083,-0.4304731188101905,0.6960861934120315,1.845265640420852,0.979,
zip,5,50,5,true,-313.8089184559051,-0.3460150347177332,0.42351869454480906,-0.15068115553108968,0.35482581955151843,1.4057720252141603,0.98,
```

**zi-zinb-p5-n50-s0001.csv:**
```
family,p,n,seed,converged,loglik,betaz_bias,betaz_rmse,betac_bias,betac_rmse,crossprod_rel_err,fit_seconds,error
zinb,5,50,1,true,-259.4173949061392,0.3870461154908458,1.3248123435133168,0.07431956294901268,0.3173978833630156,1.4196011700438256,7.63,
zinb,5,50,2,true,-267.665946988219,0.06733142264718062,1.0207675516746293,-0.10691022223843386,0.895652365784575,2.5282265338916683,1.311,
zinb,5,50,3,true,-292.98129389911526,-0.46996391213852506,1.2396230930651475,-0.1511544964366251,0.537739871975165,1.4864017278160389,3.312,
zinb,5,50,4,true,-288.36958818090085,-3.428150603029791,5.15412508820598,-0.6764215921718852,0.8721366805202472,2.697525704304799,7.584,
zinb,5,50,5,true,-294.02819495081604,-0.5324590514978128,0.8633843368188514,-0.4134043688669015,0.9574854849949872,2.910558783284681,2.133,
```

**zi-zib-p5-n50-s0001.csv:**
```
family,p,n,seed,converged,loglik,betaz_bias,betaz_rmse,betac_bias,betac_rmse,crossprod_rel_err,fit_seconds,error
zib,5,50,1,true,-341.6440710635476,0.39464819160264053,0.6566255470003963,0.14951102960841536,0.28723850543368645,1.3993896492434732,2.461,
zib,5,50,2,true,-380.24015593796025,-0.1380667305837639,0.5076580095713268,0.0027562064912553088,0.151189039483794,0.5899070594873861,0.453,
zib,5,50,3,true,-379.37435160731525,-0.24175991271794062,0.4439366855184913,-0.007532365780473749,0.21174793292829186,0.6329148537114349,0.698,
zib,5,50,4,true,-346.7206572398327,0.28072566211159045,0.4896537087538797,0.09824202164299951,0.28077074960563475,0.9171694016890395,0.525,
zib,5,50,5,true,-360.25303638252035,0.23535598635432317,0.5426726481300813,0.1803337282144836,0.23014600488013018,0.426252227060072,0.366,
```

**Observations:**
- All three files are non-empty CSV files
- All contain numeric loglik values (finite, not NaN/Inf)
- All rows show converged=true
- All numeric fields are properly formatted
- File sizes (3.6K each) suggest ~25 seeds × 1 per family file at this stage

## Verdict

**PRE-RUN: OK** — max chunk wall = 1:21, max RSS = 434.2 MB

All three families (zip, zinb, zib) executed successfully. Wall times and RSS within expected bounds for small-scale pre-run (p=5, n=50, 25 seeds). Ready for full-scale campaigns at higher p/n grids.
