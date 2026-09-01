# bridge_fit "sources" payload — Julia-side design (read-only scout)

Status: DESIGN ONLY, not implemented. Written by a read-only scout against
`/private/tmp/GLLVM.jl-core070-aghq-20260830`. Every claim below cites the file
and line it is grounded in.

## 1. The native target

### `fit_gaussian_sources` (src/source_fit.jl:290-382)

```julia
fit_gaussian_sources(Y::AbstractMatrix{<:Real}; sources, X=nothing,
    coefficient_names=nothing, start=nothing, sigma_eps_fixed=nothing,
    g_tol::Real=1e-6, iterations::Integer=500)
```

`Y` is traits × units (`p, n = size(Y)`, src/source_fit.jl:293). `sources` is a
`Vector{SourceCovariance}` (validated `all(s -> s isa SourceCovariance, sources)`,
src/source_fit.jl:298); source names must be unique (line 299). Each source's
`.projection` row count must equal `n` (line 306:
`all(s->size(s.projection,1)==n,ss) || throw(DimensionMismatch(...))`).
`X` is either `nothing` (default per-trait-intercept mean, `_trait_mean_design`,
src/source_fit.jl:137-143) or a `p*n × q` matrix / `p × n × q` array
(`_source_mean_design`, lines 147-169; 3-D arrays are reshaped `reshape(X,m,size(X,3))`
at line 155, i.e. traits vary fastest — the SAME flattening convention as
`_trait_mean_design`, which places `trait+p*(unit-1)` at row index (line 139)).
`sigma_eps_fixed` (nothing or a finite positive real, validated by
`_source_fixed_sigma`, lines 95-106) fixes the residual SD instead of estimating it.

### `SourceCovariance` constructor (src/source_covariance.jl:1-58)

```julia
SourceCovariance(C, projection; name=:source, mode=:latent, rank=nothing,
                  unique=false, common=false)
SourceCovariance(C; groups, kwargs...)   # builds a one-hot projection from groups
```

Fields actually stored (src/source_covariance.jl:18-26): `name::Symbol`,
`covariance::Matrix{Float64}`, `projection::Matrix{Float64}`, `mode::Symbol`,
`rank::Int`, `unique::Bool`, `common::Bool`.

R must supply, per source:

| Field | Type / shape | Validation (file:line) |
|---|---|---|
| `C` (covariance) | square `Matrix`, nonempty | `size(C,1)==size(C,2) && size(C,1)>0` (line 31); finite + `issymmetric(C)` (line 33); `isposdef(Symmetric(A))` (line 47, **exact** symmetry required, no jitter added — also stated in the docstring line 9 "No jitter or loading ridge is added") |
| `projection` (P) or `groups` | `P`: units × source-nodes matrix, `size(P,2)==size(C,1) && size(P,1)>0` (line 32); OR `groups`: integer vector, one-based, `1<=g<=size(C,1)` (lines 52-53) — builds a one-hot `P` (lines 55-56) |
| `name` | `Symbol`, default `:source`; must be distinct across the whole `sources` vector at fit time (`fit_gaussian_sources` line 299) |
| `mode` | `Symbol` ∈ `(:latent, :indep, :dep)` (line 35) |
| `rank` | only for `mode=:latent`; default `1`; positive `Integer`, not `Bool` (line 40); rejected if supplied for `:indep`/`:dep` (line 42); at fit time `rank <= p` is also enforced (`_source_nparams`, line 62) |
| `unique` | `Bool`; only valid with `mode===:latent` (line 36: `unique && mode!==:latent && throw(...)`) |
| `common` | `Bool`; only valid when `mode===:indep` or (`mode===:latent && unique`) (line 37) — **never a shared scalar field on its own** (also stated in the docstring, line 14) |

Free-parameter count per source, `_source_nparams` (lines 60-69):
- `:latent`: `rr_theta_len(p, rank) + (unique ? (common ? 1 : p) : 0)`
- `:dep`: `rr_theta_len(p, p)` (full lower-triangular loadings)
- `:indep`: `common ? 1 : p`

Trait-covariance parameterisation, `_source_trait_covariances` (lines 71-92):
`:indep`/unique-diagonal blocks use packed **logSD**; `:latent`/`:dep` blocks use
packed lower-triangular loadings (`unpack_lambda`/`pack_lambda`, shared with the
reduced-rank Λ packing elsewhere in the package) and build `B = L*L'`
(`+ Diagonal(d)` when `unique`).

### R-transported latent-bare case (tools/core070_latent_bare_model.jl:1-150)

`core070_latent_bare_julia(Y)` (lines 122-150) is loaded into the SAME Julia
session R drives via JuliaCall (comment, lines 1-3: "loaded by
`core070_latent_bare_model.R` through JuliaCall"). It builds the source
**natively in Julia**, not by deserialising an R-transported struct:

```julia
source = SourceCovariance(Matrix{Float64}(I, 18, 18); groups=1:18,
    mode=:latent, rank=1, unique=false, name=:ordinary_latent)
native = fit_gaussian_sources(Y; sources=[source], g_tol=1e-7, iterations=2000)
```

`Y` itself crosses the R→Julia boundary as a plain `3×18` matrix (dimension
checked at line 133: `size(Y) == (3, 18)`) and is SHA-256 hashed for transport
provenance (`_core070_matrix_sha256`, lines 22-24, `reinterpret(UInt8, vec(...))`
— i.e. it hashes column-major `vec`, so if R's `matrix` arrives already
transposed relative to Julia's column-major layout the hash would not catch a
silent transpose; it only proves R and Julia agree on SOME fixed byte order,
not which one).

Only a `SourceCovariance` in `mode ∈ {:latent, :indep}` and a **rank-one, fixed
identity C with a 1:1 groups vector** is exercised here — this is the ONE
qualified transport shape today (`MODE-ORD-INDEP`/`MODE-ORD-COMMON`, see §3).
There is no evidence anywhere in this repo of an R-side `SourceCovariance`
struct being serialised across JuliaCall; the R side has never had to build one
— the covariance-mode fitted cases (§3) build sources **natively in Julia too**
(`tools/core070_covariance_mode_fits.jl:58-62`,
`_source_for_case`: `SourceCovariance(C; groups=Int.(groups), name=..., mode=...,
common=...)`), reading `C`/`groups` back OUT of R's fit object via `RCall`
(`rcopy(Matrix{Float64}, R".core070_C_effective")`, line 205) rather than R
constructing a Julia `SourceCovariance` value directly. **This is the key
finding for the bridge design: no prior art passes a `SourceCovariance` object
itself across the boundary — every existing route rebuilds it Julia-side from
plain matrices/vectors R also has.** The bridge should follow the same
pattern: R sends the covariance matrix + groups + mode as plain data,
`bridge_fit` constructs `SourceCovariance` internally.

## 2. Bridge conventions today (src/bridge.jl)

### Options plumbing

`_bridge_get(options, key, default)` (lines 114-123): `options` is
`nothing` → default; else an `AbstractDict` looked up by both the string key
and `Symbol(key)` (R/JuliaCall dicts can arrive keyed either way) — else falls
through to `default`. There is no schema validation beyond each specific
option's own reader (e.g. `_bridge_ci_method`, lines 318-325, which validates
against `_BRIDGE_CI_METHODS` and throws `ArgumentError` on an unknown value).
Boolean-ish flags go through `_bridge_truthy` (lines 127-131) to absorb R's
`TRUE`/`"true"`/`1` renderings.

### Matrix/array transport conventions actually used

- `y` arrives as a `p × n` matrix, converted via `Matrix{Float64}(y)`
  (`_bridge_fit_onepart`, line 791). No transpose is applied — the bridge
  trusts the caller sends traits-as-rows, units-as-columns, matching
  `fit_gaussian_sources`'s own `(p, n) = size(Y)` convention.
- Fixed-effect `X` for Gaussian is a **3-D `p × n × q` array**
  (`Array{Float64,3}(X)`, line 900; shape asserted at lines 901-902), i.e. the
  SAME `p × n × q` convention `_source_mean_design` accepts for
  `fit_gaussian_sources`'s own `X` (src/source_covariance.jl:152-155). This is
  the established idiom to reuse for any per-source "projection as an array"
  transport, though sources use a 2-D `units × source-nodes` matrix, not 3-D.
- `mask` is `p × n` `Bool` (`_bridge_mask`, lines 777-786).
- Every returned array is forced back to `Matrix{Float64}`/`Vector{Float64}`/
  plain `String`/`Bool`/`Int` before being placed in the returned
  `NamedTuple` (file header, lines 4-8: "returns a FLAT NamedTuple of
  JuliaCall-convertible primitives only ... no Julia struct ever crosses the
  language boundary"). This is the hard rule any `sources` addition must obey
  on the return side, and it is exactly why `_source_for_case` in the
  covariance-mode tool constructs `SourceCovariance` FROM plain matrices
  rather than the bridge ever handing one back.
- Row/col-major: nothing in `bridge.jl` transposes; `Matrix{Float64}(y)` and
  `Array{Float64,3}(X)` assume JuliaCall has already delivered the array in
  Julia's native column-major layout with R's `dim()` order preserved
  (R arrays are also stored column-major, so `array(y, dim=c(p,n))` in R and
  `Matrix{Float64}` in Julia agree element-for-element without an explicit
  transpose — this is asserted by convention, not tested anywhere in
  `bridge.jl` itself).

### Where a "sources" option would slot in

`bridge_fit`'s Gaussian branch (lines 848-990) currently forks on
`X_lv !== nothing` (line 849), `X !== nothing` (line 894), `reml` option
(line 935), else the plain no-X path (line 974). A `sources` route is a
**fifth Gaussian fork**, structurally parallel to the `X` fork: it needs its
own guard block (mutual exclusion with `X_lv`, `reml`, `mask` — none of
`fit_gaussian_sources`' signature takes those), dispatches to
`fit_gaussian_sources` instead of `fit_gaussian_gllvm`, and returns through
`_bridge_assemble` (lines 1907-1953) the same way every other branch does.
`_bridge_assemble` is family-agnostic (it takes `alpha`, `dispersion`,
`sigma_eps`, `Sigma`, `corr`, `comm`, `scores`, `df`, `loglik`, `converged`,
`iterations`, `note`, optional `loadings`, `families`, `ci`) — nothing in it
assumes reduced-rank Λ; the existing `loadings === nothing ? _bridge_loadings(fit)
: loadings` escape hatch (line 1915) exists precisely because non-`GllvmFit`
objects (this would include `GaussianSourcesFit`) have no
`getLoadings`/rotate story, so a sources route must pass `loadings` explicitly
(likely `zeros(p, 0)` or a documented sentinel, since `GaussianSourcesFit` has
no reduced-rank loadings at all — see §5).

### What the R side needs to build a `gllvmTMB_julia` object

Two evidence points on what "the covariance-mode R comparisons" (the "R
truth" the bridge must reproduce) actually consume:

1. **`_bridge_assemble`'s standard fields** (`trait_covariances` does not
   exist as a bridge key today — the closest analogue is `Sigma`, the p×p
   latent-scale trait covariance, at line 1936). A `sources` payload's
   natural `Sigma` analogue is `sum(source.trait_covariances)` (plus
   `sigma_eps^2 I` folded separately, since `Sigma` in the existing contract
   is latent-scale, not observation-scale) — but `GaussianSourcesFit` can
   have MULTIPLE named sources (§3: `sources=[source]` is currently always
   length 1 in the qualified evidence, but the constructor and fitter both
   admit a `Vector`), so a single `Sigma` matrix loses per-source identity.
2. **`tools/core070_covariance_mode_fits.jl`'s R↔Julia comparison fields**
   (lines 267-336) are the closest existing precedent for what "the R side
   needs to build a comparator": `beta` (per-trait means), `covariance`
   (`_rows(rU)`/`_rows(only(native.trait_covariances))` — ROW-major nested
   arrays via `_rows`, lines 31-32: `[collect(Float64,row) for row in
   eachrow(A)]`), `residual_sd`/`residual_variance`, `loglik`,
   `gradient_max`≡`native.gradient_norm`, `converged`, `dof`≡`GLLVM.dof(native)`,
   `parameters` (the raw packed optimizer vector). Note `_rows` is a
   ROW-major transport shape (list-of-rows), the opposite of the flat
   column-major `Matrix{Float64}` the rest of `bridge.jl` returns — any new
   `sources` payload must pick ONE of these and say so explicitly, because
   silently mixing conventions across `Sigma` (column-major matrix) and a new
   `source_covariances` field (row-major nested list, if copying `_rows`)
   is exactly the kind of transport bug this design must foreclose.
3. **Loading crossproducts, not raw loadings**: `tools/core070_latent_bare_model.jl`
   line 40 explicitly returns `"loading_crossproduct" => covariance` (i.e.
   `only(fit.trait_covariances)`, the `Λ Λ'` product), with a code comment
   (lines 38-39) "This is the invariant estimand for a rank-one latent
   source. Do not add raw loading values to this retained route record." —
   raw `Λ` has a sign/rotation ambiguity the crossproduct does not. A bridge
   payload MUST expose `trait_covariances` (the crossproduct/estimated
   covariance per source), never raw per-source loadings.

## 3. What the 9 qualified covariance cells prove

Two "fixed-noise" native Gaussian cases (`docs/dev-log/core070/source-fixed-residual-contract.md`,
lines 8-17; case IDs `MODE-ORD-INDEP`, `MODE-ORD-COMMON` per
`docs/dev-log/core070/covariance-required-case-plan.json`
`fixed_noise_gaussian_native_evidence.case_ids`) use
`fit_gaussian_sources(...; sigma_eps_fixed=reference_sd)` with 6 and 4 free
coordinates respectively, and pass declared health checks with absolute
likelihood differences 2.56e-11 / 3.98e-13 — but these predate and are kept
explicitly SEPARATE from the seven fitted-mode cases (contract doc line 15:
"supersedes the earlier ... statement for these two native models only").

The seven fitted cases (`test/parity/test_covariance_modes_required.jl`,
which just `include`s `tools/core070_covariance_mode_fits.jl` inside a test
module) are IDs `FIT-MODE-ORD-DEP`, `FIT-MODE-ANIMAL-{INDEP,COMMON,DEP}`,
`FIT-MODE-KERNEL-{INDEP,COMMON,DEP}`
(`tools/core070_covariance_mode_fits.jl:25-29`). Together the 2 + 7 = **9
qualified cells** span all three sources (ORD/ANIMAL/KERNEL) crossed with
all three modes (INDEP/COMMON/DEP), with ORD-DEP, ORD-INDEP, ORD-COMMON,
ANIMAL-{INDEP,COMMON,DEP}, KERNEL-{INDEP,COMMON,DEP} — i.e. NOT a full 3×3
grid from ONE harness; ORD's INDEP/COMMON cells come from the older
fixed-residual harness and ORD-DEP plus both ANIMAL and KERNEL come from
the newer free-residual harness.

Per-case construction (`tools/core070_covariance_mode_fits.jl:58-62`,
`_source_for_case`):

```julia
native_mode = mode == "DEP" ? :dep : :indep
SourceCovariance(C; groups=Int.(groups), name=Symbol(replace(id,'-'=>'_')),
    mode=native_mode, common = mode == "COMMON")
```

i.e. R-string modes `"INDEP"/"COMMON"/"DEP"` map to native `mode=:indep,
common=false` / `mode=:indep, common=true` / `mode=:dep` (no `common=` for
`:dep`, matching the constructor's own restriction, src/source_covariance.jl:37).
**`:latent` mode is NOT exercised by any of the 9 qualified cells** — only
`:indep` and `:dep` (`common` distinguishes INDEP from COMMON within `:indep`).
The R fixture's expected covariance for ORD is `Matrix{Float64}(I,36,36)` with
`groups=collect(1:36)` (identity/one-per-unit — `n=36` units,
`tools/core070_covariance_mode_fits.jl:228-230`); ANIMAL/KERNEL use a `12×12`
matrix plus `1e-8 * I` jitter (line 229: `input_C + 1e-8*I(12)`) with
`groups=repeat(1:12, inner=3)` (3 traits share each of 12 groups, line 230) —
note the **jitter is added on the R/native comparison side, not inside
`SourceCovariance`** (which forbids automatic jitter, §1), so the bridge must
NOT silently add jitter either; if R already regularises `C` before sending
it, that is the R side's decision, and the bridge should reject non-PD input
the same way `SourceCovariance` does today.

The comparisons actually checked (lines 267-315): `expected_id`, fixture
shape/ordering, `source_groups` (per-site group consistency), `source_effective_matrix`
(`≤1e-12` vs R's Cholesky-derived effective covariance), `r_code==0`,
`r_gradient` (`≤1e-4`), free-parameter counts (7/5/10 for
INDEP/COMMON/DEP), `native_health` (`converged && gradient_norm≤1e-7`),
`likelihood` (`≤1e-6`), `beta` (`≤1e-5` rtol/atol), `native_free_parameters`
(`dof(native)==length(router)`), `native_objective_at_r_coordinates`
(re-evaluating the native NLL AT the R optimum, `≤1e-6`), and finally either
`ordinary_total_covariance` (ORD: only `U+σ²I` is identifiable) or
`structured_source_covariance`/`structured_residual_variance` (ANIMAL/KERNEL:
`U` and `σ²` separately, `≤1e-5`). **These are exactly the fixtures the bridge
`sources` route must reproduce byte-for-byte** — same `C`, same `groups`,
same `mode`/`common`, same free-parameter count, same likelihood/beta/dof at
convergence.

## 4. Proposed minimal payload contract

### `bridge_fit` new keyword

```julia
bridge_fit(; y, family, d=1, N=nothing, X=nothing, X_lv=nothing, mask=nothing,
           trait_names=nothing, unit_names=nothing, sources=nothing,
           options=Dict{String,Any}())
```

`sources` defaults to `nothing` (byte-identical contract for existing callers,
matching every other optional key's convention in this file, e.g. line 60:
"When not `\"none\"` ... so existing callers are unchanged"). When
`family != "gaussian"`, `sources !== nothing` is an `ArgumentError` (no
non-Gaussian source route exists — `fit_gaussian_sources` is Gaussian-only,
src/source_fit.jl title). When `sources !== nothing`, it is mutually exclusive
with `X`, `X_lv`, `mask`, and `reml=true` (none of these compose with
`fit_gaussian_sources`'s own signature), following the existing pattern at
lines 517-519 / 822-824 that reject `X` + `X_lv` together.

### `sources` shape — a `Vector` of plain dicts (JuliaCall-safe, no struct crosses the boundary)

```julia
sources = [
    Dict(
        "name"       => "ord",                  # String; -> Symbol(name)
        "covariance" => C1,                      # k1 x k1 Float64 matrix, exactly symmetric PD
        "groups"     => g1,                      # length-n Int vector, 1-based, in 1:k1
        # OR, instead of groups:
        # "projection" => P1,                    # n x k1 Float64 matrix (units x source-nodes)
        "mode"       => "indep",                 # "latent" | "indep" | "dep"  (String, lowercased)
        "rank"       => nothing,                 # only for mode=="latent"; positive Int or nothing (-> default 1)
        "unique"     => false,                   # Bool; only mode=="latent"
        "common"     => false,                   # Bool; only mode=="indep" or (mode=="latent" && unique)
    ),
    # ... one dict per source, R may supply 1+ ...
]
```

Rationale for a `Vector{<:AbstractDict}` rather than a matrix-of-sources: the
existing bridge idiom for heterogeneous per-item metadata is
`AbstractDict` + `_bridge_get` (lines 114-123), and sources genuinely vary in
shape (`covariance` size differs per source, `groups` length is fixed at `n`
but `covariance` size is NOT). A parallel-arrays encoding (separate
`source_covariances::Vector{Matrix}`, `source_groups::Matrix{Int}`, ...) is
rejected because JuliaCall already round-trips R lists of named lists into
`Vector{Dict}`/`Vector{OrderedDict}` cleanly (this is exactly the shape
`options` itself takes today, §2), and it keeps validation errors scoped to
one source at a time (mirroring `SourceCovariance`'s own per-object
validation, §1) rather than needing index bookkeeping across five parallel
vectors.

`bridge_fit` translates each dict into a native `SourceCovariance` via
`_bridge_source_from_dict` (new internal helper), then calls
`fit_gaussian_sources(Yf; sources=native_sources, X=nothing,
sigma_eps_fixed=residual_fixed_option, ...)`. `X` inside `fit_gaussian_sources`
stays `nothing` (default trait-intercept mean) for the v1 slice — combining
`sources` with a bridge `X` fixed-effect design is a documented follow-up, not
in this slice (mirrors how `X` and `X_lv` are already mutually exclusive at
the bridge, §2).

### Return payload — new keys merged via `_bridge_assemble`

```
source_names          :: Vector{String}         -- one per source, in order
source_modes          :: Vector{String}          -- "latent"/"indep"/"dep" per source
source_common         :: Vector{Bool}
source_unique         :: Vector{Bool}
source_rank           :: Vector{Int}             -- 0 for indep/dep (matches internal .rank field, source_covariance.jl:43)
trait_covariances     :: Vector{Matrix{Float64}} -- WARNING: not JuliaCall-flat; see below
sigma_eps             :: Float64                 -- already an existing bridge key (line 26)
Sigma                 :: Matrix{Float64}         -- sum of projected source covariances + sigma_eps^2 I, p x p, OBSERVATION-scale total (documented as such, since it is not the latent-scale RR Sigma the rest of the contract implies)
```

**Blocking issue to flag, not silently resolve**: the file header states
"no Julia struct ever crosses the language boundary" and every existing
key is a flat scalar/array (lines 4-8). `Vector{Matrix{Float64}}` (a
vector of matrices, ragged if sources have different trait-block sizes —
though here every source's block is always `p × p`, so it is NOT ragged)
still is not one of the documented primitive types. Two options, and this
design does not silently pick one:
  (a) restrict v1 to `sources` of length 1 (matching every qualified case in
      §3, which are all single-source) and return a flat `source_covariance
      :: Matrix{Float64}` (singular, p×p) — narrowest slice, matches 100% of
      current evidence;
  (b) support `sources` of length ≥1 and stack per-source `p×p` covariances
      into one `p × p × nsrc` `Array{Float64,3}` field `source_covariances`,
      reusing the exact 3-D convention `X`/`Xarr` already use (§2, line 900).

Recommendation: **(a) for the first red/green slice**, since it exactly
matches the 9 qualified cells (all `length(sources)==1`) and defers the
ragged/stacking design question until a genuinely multi-source qualified
case exists. `source_names`/`source_modes`/etc. above still stay `Vector`
(length 1) so the contract is forward-compatible with (b) without a
breaking rename.

### 3-5 red tests to pin the contract

1. **Transport round-trip / negative control — malformed source throws
   `ArgumentError`.** Pass `sources = [Dict("name"=>"bad", "covariance"=>[1.0
   0.2; 0.1 1.0], "groups"=>[1,1], "mode"=>"indep")]` (asymmetric covariance,
   same malformed shape as `tools/core070_latent_bare_model.jl`'s
   `"asymmetric_source"` negative control, line 91) and assert `bridge_fit`
   raises `ArgumentError` with a message naming "symmetric" (not
   `MethodError`/`KeyError` — i.e. the dict→`SourceCovariance` translation
   must produce the SAME clear error class `SourceCovariance` itself raises,
   src/source_covariance.jl:33).

2. **Exact loglik parity — a source spec identical to `FIT-MODE-ORD-INDEP`
   reproduces the native fit's loglik exactly.** Build `y` from the ORD
   fixture's `Y` (`tools/core070_covariance_mode_fits.jl` row for
   `FIT-MODE-...` with `mode=="INDEP"`, source `"ORD"` — i.e. `C =
   Matrix{Float64}(I,36,36)`, `groups = collect(1:36)`), call
   `bridge_fit(y=Y, family="gaussian", sources=[Dict("name"=>"ord",
   "covariance"=>I(36), "groups"=>1:36, "mode"=>"indep")])`, and assert
   `result.loglik == native.loglik` (bit-identical, since both call the exact
   same `fit_gaussian_sources` with the exact same default start — this is
   a transport-fidelity test, not a numerical-tolerance test) where `native`
   is the direct `fit_gaussian_sources(Y; sources=[SourceCovariance(I(36);
   groups=1:36, mode=:indep)])` call.

3. **`groups` and `projection` are alternative, equivalent inputs.** Same
   fixture, but pass `"projection" => Matrix{Float64}(I,36,36)[groups,:]`
   instead of `"groups"`; assert identical `loglik`/`beta`/`trait_covariances`
   to test 2 — pins that the bridge's dict-to-`SourceCovariance` translation
   correctly dispatches to `SourceCovariance(C, P; ...)` vs
   `SourceCovariance(C; groups=..., ...)` (src/source_covariance.jl:28 vs 51)
   without a silent shape mismatch.

4. **`mode`/`common`/`unique` string marshalling.** `Dict("mode"=>"DEP")`
   (uppercase, as R's `mode="DEP"` string columns arrive in
   `tools/core070_covariance_mode_fits.jl` fixtures, e.g. `mode == "DEP"` at
   line 44) must be accepted case-insensitively (lowered before
   `Symbol(...)`) and rejected with `ArgumentError` (not a bare `MethodError`
   from `mode in (:latent,:indep,:dep)` failing on an unexpected `Symbol`)
   for an unrecognised string like `"randomwalk"`.

5. **`sigma_eps_fixed` and `sources` compose.** Pass
   `options=Dict("sigma_eps_fixed"=>reference_sd)` alongside a single INDEP
   source matching `MODE-ORD-INDEP`'s fixture (§3, 6 free coordinates) and
   assert the returned `df`/free-parameter count matches `GLLVM.dof(native)`
   from the direct `fit_gaussian_sources(...; sigma_eps_fixed=reference_sd)`
   call, and `sigma_eps == reference_sd` exactly (residual held fixed, not
   estimated) — pins that a NEW bridge option (`sigma_eps_fixed`, not
   previously read by `_bridge_get` anywhere in `bridge.jl`) is wired
   correctly rather than silently ignored.

## 5. Risks

- **Dimension-order traps (p×n vs n×p).** `fit_gaussian_sources` takes `Y` as
  `p × n` (traits × units), matching the bridge's existing `y` convention
  (§2) — LOW risk for `y` itself. HIGHER risk for `groups`/`projection`:
  `groups` must have length `n` (units), NOT `p` — a caller who confuses
  "one group per trait" with "one group per unit" (a very natural R-side
  mistake, since `gllvmTMB`'s own random-effect grouping is usually per-site)
  will get a silent WRONG fit (not an error) if `n == p` happens to hold in a
  test fixture, or a `DimensionMismatch` if not. Nothing in `SourceCovariance`
  itself defends against "right length, wrong semantic axis" — only against
  wrong length (`size(P,1)==n` check at `fit_gaussian_sources` line 306 fires
  only after construction). Mitigate by requiring the bridge always compute
  `n` from `y` first and validate `length(groups)==n` before constructing
  `SourceCovariance`, with an error message naming BOTH `p` and `n` so a
  transposed caller sees the mismatch immediately rather than a cryptic
  `DimensionMismatch("group index outside source covariance")`.

- **Groups indexing base.** R is 1-based, matching `SourceCovariance`'s own
  1-based contract (`1<=g<=size(C,1)`, src/source_covariance.jl:53) — LOW
  risk, no translation needed, unlike a 0-based transport language would need.
  But JuliaCall integer round-tripping of R's `integer()` vs `numeric()`
  vectors is a known footgun elsewhere in this bridge (`_bridge_zib_trials`,
  lines 588-615, exists ENTIRELY to normalise numeric-vs-integer N from R) —
  the `groups` reader must `round.(Int, ...)` rather than assume R sends
  exact integers, and must reject non-integer group values loudly (mirroring
  `SourceCovariance`'s own `g isa Integer && !(g isa Bool)` check, line 53,
  which a raw `Float64` `groups` vector from R would fail if passed through
  unconverted).

- **Mode symbol marshalling from R strings.** Already covered in test 4
  above; the risk is specifically that `Symbol(lowercase(mode_string))`
  silently produces a syntactically valid but WRONG symbol (e.g. a typo
  `"indpe"` becomes `:indpe`, which `SourceCovariance`'s own
  `mode in (:latent,:indep,:dep)` check (line 35) WILL catch and reject —
  so this risk is actually already defended by the constructor itself,
  PROVIDED the bridge does not catch and swallow that error).

- **`unique`/`common` defaults and cross-validation.** `SourceCovariance`
  defaults `unique=false, common=false` (constructor keyword defaults,
  src/source_covariance.jl:30) — if the bridge dict omits these keys, using
  `get(dict, "unique", false)` reproduces the native default correctly. The
  REAL risk is the CROSS-validation between `mode`, `unique`, and `common`
  (lines 36-37: `unique` requires `mode===:latent`; `common` requires
  `mode===:indep` or `(mode===:latent && unique)`) — a bridge translation
  that reads these three keys independently and passes them straight through
  to the constructor will correctly inherit these checks FOR FREE (the
  constructor validates them, lines 36-37), so the only bridge-side risk is
  if the translation coerces `nothing`/missing R values to something OTHER
  than the constructor's own defaults (e.g. `common = get(dict, "common",
  missing)` producing `missing` instead of `false`, which fails `common &&
  ...` with a `TypeError` rather than a clean `ArgumentError`).

- **`rank` for non-`:latent` modes.** The constructor REJECTS an explicit
  `rank` for `:indep`/`:dep` (line 42: `rank===nothing || throw(...)`) — if
  the bridge dict always includes a `"rank"` key (even `nothing`/R's `NA`)
  for uniformity across sources, an INDEP/DEP source dict with
  `"rank" => NA` translated to Julia `missing` (not `nothing`) will fail
  the `rank===nothing` check with a WRONG error message ("rank is only
  specified for mode=:latent" is correct semantically, but `missing !== nothing`
  in Julia, so `get(dict, "rank", nothing)` from an R `NA` might arrive as
  `missing`, not `nothing`, tripping the check for the WRONG reason). The
  bridge dict-to-source translator must normalise R's `NA`/`NULL` for `rank`
  to Julia `nothing` explicitly, not rely on the constructor's own check to
  paper over it.

- **State `fit_gaussian_sources` assumes that the bridge won't have "for
  free".** Two structural gaps, both explicit in the fitter's own docstring
  (src/source_fit.jl:281-288: "does not implement random source slopes, R
  source-term grammar, the R/Julia bridge, tree/pedigree/mesh parsing,
  estimated source kernels, missing responses, loading masks, non-Gaussian
  families or intervals"):
  (1) **no CI engine** — `fit_gaussian_sources` returns Hessian diagnostics
  (`hessian_min_eigenvalue`, `hessian_positive_definite`) but there is no
  `confint`/`profile_ci`/`bootstrap_ci` method dispatching on
  `GaussianSourcesFit` anywhere in this repo (unlike `GllvmFit`, which has
  three, §2 lines 393-425) — so `ci_method != "none"` must be REJECTED
  loudly for a `sources` bridge call, exactly like the existing
  `_bridge_ci_guard_lognormal`/`_bridge_ci_guard_truncated_poisson` pattern
  (lines 625-639), not silently ignored;
  (2) **missing responses** — `fit_gaussian_sources` requires
  `all(isfinite, Y)` (src/source_fit.jl:295) with NO mask parameter at all,
  unlike every other one-part bridge family (`_BRIDGE_MASK_FAMILIES`, line
  541) — the bridge must reject `mask !== nothing` with `sources` outright,
  not attempt to pre-filter `Y` before calling the fitter (which would
  silently change `n`, breaking the `groups`/`projection` row alignment the
  caller sent).

## Grounding index

- `src/source_fit.jl` (fitter, `GaussianSourcesFit`, `_gaussian_sources_nll`)
- `src/source_covariance.jl` (`SourceCovariance` constructor + `_source_nparams`
  + `_source_trait_covariances`)
- `src/bridge.jl` (options plumbing, Gaussian branch, `_bridge_assemble`,
  file-header contract comment)
- `tools/core070_latent_bare_model.jl` (only existing R→Julia source-model
  transport precedent; loading-crossproduct-not-raw-loadings rule)
- `test/parity/test_covariance_modes_required.jl` +
  `tools/core070_covariance_mode_fits.jl` (the 9 qualified covariance cells'
  exact source specs and R/native comparison fields)
- `docs/dev-log/core070/source-fixed-residual-contract.md`,
  `docs/dev-log/core070/covariance-required-case-plan.json`
  (case-ID inventory for the 9 qualified cells)
- `docs/dev-log/decisions/2026-08-30-gaussian-source-evaluator.md`
  (mathematical contract for the underlying evaluator)
