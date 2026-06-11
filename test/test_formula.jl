# Tests for the @formula / DataFrame front-end (src/formula.jl, lane A4).
#
# Verifies that a formula/table-built fit is byte-for-byte the matrix-API fit
# (PARITY), that the WIDE and LONG table layouts agree, that a Gaussian formula
# recovers a planted covariate effect, and that a non-Gaussian + covariate
# request raises the clear deferral error (GUARDRAIL).

using GLLVM, Test, DataFrames, Distributions, Random, LinearAlgebra

@testset "formula/table front-end" begin

    # ----- shared simulated Gaussian data (wide + long views of the same Y).
    Random.seed!(20240601)
    p, n, K = 4, 90, 2
    Λtrue = 0.8 .* randn(p, K)
    Ztrue = randn(K, n)
    Yg = Λtrue * Ztrue .+ 0.4 .* randn(p, n)

    wide_g = DataFrame()
    for t in 1:p
        wide_g[!, Symbol("y", t)] = Yg[t, :]
    end
    resp_syms = [Symbol("y", t) for t in 1:p]

    # long view: trait key + site key + value (sorted-unique trait/site → p×n).
    long_g = DataFrame(species = String[], plot = Int[], value = Float64[])
    for t in 1:p, s in 1:n
        push!(long_g, (string("y", t), s, Yg[t, s]))
    end

    @testset "PARITY: Gaussian formula-fit == matrix-fit" begin
        ff = gllvm(wide_g; responses = resp_syms, K = K)
        fm = fit_gaussian_gllvm(Yg; K = K)
        @test ff isa GllvmFormulaFit
        @test ff.fit isa GllvmFit
        @test ff.fit.logLik ≈ fm.logLik atol = 1e-8
        @test getLoadings(ff.fit) ≈ getLoadings(fm) atol = 1e-6
        @test ff.responses == resp_syms          # names preserved, in p-order
        @test ff.layout === :wide
    end

    @testset "PARITY: Poisson formula-fit == matrix-fit" begin
        Random.seed!(11)
        Λp = 0.5 .* randn(p, 1); βp = randn(p)
        ηp = βp .+ Λp * randn(1, n)
        Yc = [rand(Poisson(exp(clamp(ηp[t, s], -3, 3)))) for t in 1:p, s in 1:n]
        wide_c = DataFrame()
        for t in 1:p
            wide_c[!, Symbol("c", t)] = Yc[t, :]
        end
        ff = gllvm(wide_c; responses = [Symbol("c", t) for t in 1:p],
                   K = 1, family = Poisson())
        fm = fit_poisson_gllvm(Matrix{Int}(Yc); K = 1)
        @test ff.fit isa PoissonFit
        @test ff.fit.loglik ≈ fm.loglik atol = 1e-8
        @test getLoadings(ff.fit) ≈ getLoadings(fm) atol = 1e-6
    end

    @testset "PARITY: mixed [Normal, Poisson, Binomial] formula-fit == matrix-fit" begin
        Random.seed!(13)
        pmix = 3
        Λx = 0.7 .* randn(pmix, 1)
        zz = randn(1, n)
        eta = Λx * zz
        y_norm = 1.0 .+ eta[1, :] .+ 0.3 .* randn(n)
        y_pois = [rand(Poisson(exp(clamp(0.2 + eta[2, s], -3, 3)))) for s in 1:n]
        y_binom = [rand() < 1 / (1 + exp(-(0.1 + eta[3, s]))) ? 1 : 0 for s in 1:n]
        dfm = DataFrame(a = y_norm, b = y_pois, c = y_binom)
        fams = [Normal(), Poisson(), Binomial()]

        ff = gllvm(dfm; responses = [:a, :b, :c], K = 1, family = fams)

        Ymat = Matrix{Float64}(undef, pmix, n)
        Ymat[1, :] = y_norm
        Ymat[2, :] = Float64.(y_pois)
        Ymat[3, :] = Float64.(y_binom)
        fm = fit_mixed_gllvm(Ymat; families = fams, K = 1)

        @test ff.fit isa MixedFamilyFit
        @test ff.fit.loglik ≈ fm.loglik atol = 1e-8
        @test ff.fit.Λ ≈ fm.Λ atol = 1e-6
        @test ff.fit.β ≈ fm.β atol = 1e-6
        @test ff.responses == [:a, :b, :c]
    end

    @testset "WIDE ≡ LONG: same data, same fit" begin
        fw = gllvm(wide_g; responses = resp_syms, K = K)
        fl = gllvm(long_g; response = :value, trait = :species, site = :plot, K = K)
        @test fl.layout === :long
        @test fl.fit.logLik ≈ fw.fit.logLik atol = 1e-8
        @test getLoadings(fl.fit) ≈ getLoadings(fw.fit) atol = 1e-6
        # long pivot recovers trait names as Symbols (sorted unique trait levels).
        @test fl.responses == resp_syms
    end

    @testset "COVARIATE (Gaussian): recovers planted β" begin
        Random.seed!(17)
        x = randn(n)
        β_true = 1.7
        # one shared covariate effect across all traits (matches the (p,n,q) X
        # contract: covariates are site-level, shared by every trait row).
        Yx = (β_true .* x') .+ Λtrue * Ztrue .+ 0.3 .* randn(p, n)
        dfx = DataFrame()
        for t in 1:p
            dfx[!, Symbol("y", t)] = Yx[t, :]
        end
        dfx.temp = x
        ff = gllvm(dfx; responses = resp_syms, K = K,
                   formula = @formula(0 ~ 0 + temp))
        @test ff.coefnames == ["temp"]
        @test length(ff.fit.pars.β) == 1
        @test ff.fit.pars.β[1] ≈ β_true atol = 0.1   # planted-β recovery

        # parity with the equivalent explicit matrix X call.
        Xarr = Array{Float64, 3}(undef, p, n, 1)
        for s in 1:n, t in 1:p
            Xarr[t, s, 1] = x[s]
        end
        fm = fit_gaussian_gllvm(Yx; K = K, X = Xarr)
        @test ff.fit.logLik ≈ fm.logLik atol = 1e-8
        @test ff.fit.pars.β ≈ fm.pars.β atol = 1e-6
    end

    @testset "GUARDRAIL: non-Gaussian + covariate raises clear deferral error" begin
        Random.seed!(19)
        Yc = [rand(0:4) for _ in 1:p, _ in 1:n]
        dfc = DataFrame()
        for t in 1:p
            dfc[!, Symbol("c", t)] = Yc[t, :]
        end
        dfc.temp = randn(n)
        err = try
            gllvm(dfc; responses = [Symbol("c", t) for t in 1:p], K = 1,
                  family = Poisson(), formula = @formula(0 ~ 1 + temp))
            nothing
        catch e
            e
        end
        @test err isa ArgumentError
        @test occursin("deferred", sprint(showerror, err))
        @test occursin("A1-Xβ", sprint(showerror, err))

        # mixed family + covariate is also guarded (per-trait Xβ deferred).
        dfmix = DataFrame(a = randn(n), b = [rand(0:3) for _ in 1:n], temp = randn(n))
        @test_throws ArgumentError gllvm(dfmix; responses = [:a, :b], K = 1,
            family = [Normal(), Poisson()], formula = @formula(0 ~ 1 + temp))
    end

    @testset "input validation" begin
        # missing layout keywords
        @test_throws ArgumentError gllvm(wide_g; K = K)
        # both layouts at once
        @test_throws ArgumentError gllvm(wide_g; responses = resp_syms,
            response = :value, K = K)
        # unknown response column
        @test_throws ArgumentError gllvm(wide_g; responses = [:nope], K = K)
        # family vector length mismatch
        @test_throws DimensionMismatch gllvm(wide_g; responses = resp_syms,
            K = K, family = [Normal(), Normal()])
        # N only meaningful for Binomial
        @test_throws ArgumentError gllvm(wide_g; responses = resp_syms, K = K,
            N = ones(Int, p, n))
    end

    @testset "REML through the formula front-end (Gaussian + covariate)" begin
        Random.seed!(31999)
        x = randn(n); β_true = 1.3
        Yx = (β_true .* x') .+ Λtrue * Ztrue .+ 0.4 .* randn(p, n)
        dfx = DataFrame()
        for t in 1:p
            dfx[!, Symbol("y", t)] = Yx[t, :]
        end
        dfx.temp = x
        ff = gllvm(dfx; responses = resp_syms, K = K,
                   formula = @formula(0 ~ 0 + temp), reml = true)
        # parity with the explicit matrix REML call: reml flows through kwargs...
        Xarr = Array{Float64, 3}(undef, p, n, 1)
        for s in 1:n, t in 1:p
            Xarr[t, s, 1] = x[s]
        end
        fm = fit_gaussian_gllvm(Yx; K = K, X = Xarr, reml = true)
        @test ff.fit isa GllvmFit
        @test ff.fit.logLik ≈ fm.logLik atol = 1e-8
        @test ff.fit.pars.β ≈ fm.pars.β atol = 1e-6
    end
end
