# GLLVModels transition correction — check log

| Gate | Evidence | Verdict |
| --- | --- | --- |
| Canonical Julia selection | In the renamed checkout, `Base.find_package("GLLVModels")` resolves `src/GLLVModels.jl`; `Base.find_package("GLLVM")` is `nothing`; the canonical-first selector prints `GLLVModels`. | PASS |
| R bridge syntax | `Rscript -e 'parse(file = ...)'` parsed both `r/gllvmjl.R` and `r/gllvmtmb_julia.R`. | PASS |
| Static scope | `git diff --check` passed. The loader activates a selected checkout before selecting `GLLVModels` or an absent-only legacy fallback; it does not catch or mask import failures. | PASS |
| Reader documentation | Rebuilt Documenter locally from an empty ignored build directory. A source and rendered-page scan found no tracker, lane, campaign, or developer-record identifiers in the served reader surface. | PASS |
| Live transport | JuliaConnectoR is not installed locally, so no fresh R-to-Julia session ran. | NOT RUN |

No merge, release, registry action, stable Pages deployment, or book publication occurred in this correction.
