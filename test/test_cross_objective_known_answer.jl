using Test, GLLVM, LinearAlgebra, TOML

# Known-answer gate for the cross-objective identity tool (panel 2026-09-01):
# on the frozen COV-ORD-LATENT-BARE case, GLLVM.jl's objective evaluated at the
# RETAINED fitted coordinates of (a) its own native route and (b) the frozen R
# reference must reproduce each route's retained log-likelihood. (b) is the
# likelihood-function identity claim itself, at the R optimum.
#
# Skips (with an honest message, never a silent pass) when the retained
# attempt06 evidence is not present in this checkout.
include(joinpath(@__DIR__, "..", "tools", "core070_cross_objective.jl"))

const _XOBJ_FIXTURE = joinpath(@__DIR__, "fixtures",
    "core070_latent_bare_retained.toml")

@testset "cross-objective known answer (COV-ORD-LATENT-BARE)" begin
    if !isfile(_XOBJ_FIXTURE)
        @warn "retained-coordinate fixture absent; known-answer gate NOT RUN" _XOBJ_FIXTURE
        @test_skip false
    else
        res = TOML.parsefile(_XOBJ_FIXTURE)
        # Rebuild the frozen 3x18 response from the invariant test fixture used
        # by test_source_fit_optimizer_health.jl (same INPUT-GAUSS-LOADINGS).
        yrow = include(joinpath(@__DIR__, "fixtures", "input_gauss_loadings_y.jl"))
        Y = collect(reshape(yrow, 18, 3)')
        source = SourceCovariance(Matrix{Float64}(I, 18, 18); groups = 1:18,
            mode = :latent, rank = 1, unique = false, name = :ordinary_latent)
        for route in ("native_julia", "r_reference")
            r = res[route]
            crossprod = Matrix{Float64}(reduce(hcat, [Vector{Float64}(c) for c in r["crossprod"]]))
            nll = gaussian_sources_nll_at(Y, source;
                beta = Vector{Float64}(r["beta"]),
                crossprod = crossprod,
                residual_variance = Float64(r["residual_variance"]))
            @test isfinite(nll)
            # Retained coordinates are serialized at ~15 significant digits and
            # the objective's curvature is O(10); 1e-8 is far below any
            # likelihood-function discrepancy and far above serialization noise.
            @test abs(-nll - Float64(r["loglik"])) <= 1e-8
        end
    end
end
