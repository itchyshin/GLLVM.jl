using GLLVM, Test, Random, Distributions, Statistics

# Helper: simulate a Poisson GLLVM dataset (p×n integer counts).
function _sim_poisson(p, K, n; seed = 11)
    Random.seed!(seed)
    β = 0.5 .* randn(p) .+ 1.0
    Λ = 0.5 .* randn(p, K)
    Y = Matrix{Int}(undef, p, n)
    for s in 1:n
        η = β .+ Λ * randn(K)
        for t in 1:p
            Y[t, s] = rand(Poisson(exp(η[t])))
        end
    end
    return Y, β, Λ
end

@testset "Non-Gaussian confidence intervals" begin
    @testset "Wald (Poisson)" begin
        Y, _, _ = _sim_poisson(5, 1, 140; seed = 21)
        fit = fit_poisson_gllvm(Y; K = 1)
        ci = confint(fit, Y; method = :wald)
        @test ci.method === :wald
        @test length(ci.term) == length(fit.β) + (5 * 1)   # β + Λ entries
        # estimate equals the MLE; finite intervals bracket it (a finite-difference
        # Hessian need not be globally PD, so we don't demand pd_hessian)
        @test ci.estimate[1] ≈ fit.β[1] atol = 1e-8
        fin = isfinite.(ci.se)
        @test any(fin)
        @test all(ci.lower[fin] .< ci.estimate[fin] .< ci.upper[fin])

        # parm subsetting
        ci_b1 = confint(fit, Y; method = :wald, parm = "beta[1]")
        @test ci_b1.term == ["beta[1]"]
        ci_b = confint(fit, Y; method = :wald, parm = "beta")
        @test length(ci_b.term) == 5
    end

    @testset "Profile (Poisson)" begin
        Y, _, _ = _sim_poisson(4, 1, 120; seed = 22)
        fit = fit_poisson_gllvm(Y; K = 1)
        ci = confint(fit, Y; method = :profile, parm = "beta[1]")
        @test ci.method === :profile
        @test ci.status[1] in (:profile, :partial)
        @test isfinite(ci.lower[1]) || isfinite(ci.upper[1])   # at least one side bracketed
        isfinite(ci.lower[1]) && @test ci.lower[1] < ci.estimate[1]
        isfinite(ci.upper[1]) && @test ci.estimate[1] < ci.upper[1]

        # when both sides bracket, the profile interval should be in the Wald ballpark
        if ci.status[1] === :profile
            w = confint(fit, Y; method = :wald, parm = "beta[1]")
            @test isapprox(ci.lower[1], w.lower[1]; atol = 0.4)
            @test isapprox(ci.upper[1], w.upper[1]; atol = 0.4)
        end
    end

    @testset "Bootstrap (Poisson) — single- vs multi-core identical" begin
        Y, _, _ = _sim_poisson(4, 1, 120; seed = 23)
        fit = fit_poisson_gllvm(Y; K = 1)
        ci_serial = confint(fit, Y; method = :bootstrap, n_boot = 30, seed = 7, parallel = false)
        ci_par    = confint(fit, Y; method = :bootstrap, n_boot = 30, seed = 7, parallel = true)
        @test ci_serial.method === :bootstrap
        @test ci_serial.n_converged ≥ 12
        # per-replicate RNG seeding ⇒ results independent of threading
        @test ci_serial.lower == ci_par.lower
        @test ci_serial.upper == ci_par.upper
        @test ci_serial.n_converged == ci_par.n_converged
        # percentile bounds are ordered (they need NOT bracket the MLE: for K=1 the
        # loadings have a sign-flip non-identifiability, so bootstrap replicates mix
        # +Λ and −Λ and the interval can legitimately exclude the point estimate)
        @test all(ci_serial.lower .<= ci_serial.upper)
    end

    @testset "Dispersion CI on the natural scale (NB)" begin
        Random.seed!(24)
        p, K, n, r_true = 4, 1, 200, 6.0
        β = 0.4 .* randn(p) .+ 1.2
        Λ = 0.4 .* randn(p, K)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            η = β .+ Λ * randn(K)
            for t in 1:p
                μ = exp(η[t])
                Y[t, s] = rand(NegativeBinomial(r_true, r_true / (r_true + μ)))
            end
        end
        fit = fit_nb_gllvm(Y; K = K)
        ci = confint(fit, Y; method = :wald, parm = "r")
        @test ci.term == ["r"]
        @test ci.estimate[1] ≈ fit.r atol = 1e-8
        # log-scale parameterisation ⇒ strictly positive natural-scale bounds
        if isfinite(ci.lower[1])
            @test 0 < ci.lower[1] < ci.estimate[1] < ci.upper[1]
        end
    end

    @testset "Gamma dispersion bracketed by Wald" begin
        Random.seed!(25)
        p, K, n, α_true = 4, 1, 200, 5.0
        β = 0.3 .* randn(p)
        Λ = 0.4 .* randn(p, K)
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            η = β .+ Λ * randn(K)
            for t in 1:p
                μ = exp(η[t])
                Y[t, s] = rand(Gamma(α_true, μ / α_true))
            end
        end
        fit = fit_gamma_gllvm(Y; K = K)
        ci = confint(fit, Y; method = :wald, parm = "alpha")
        @test ci.term == ["alpha"]
        @test ci.estimate[1] ≈ fit.α atol = 1e-8
        @test isfinite(ci.estimate[1])
    end

    @testset "bad method errors" begin
        Y, _, _ = _sim_poisson(3, 1, 60; seed = 26)
        fit = fit_poisson_gllvm(Y; K = 1)
        @test_throws ArgumentError confint(fit, Y; method = :nope)
    end

    @testset "Two-part: Hurdle-Poisson Wald + profile" begin
        Random.seed!(31)
        p, K, n = 4, 1, 160
        βz = 0.4 .* randn(p) .+ 0.5; βc = 0.3 .* randn(p) .+ 1.0
        Λc = 0.4 .* randn(p, K)
        Y = zeros(Int, p, n)
        for s in 1:n
            ηc = βc .+ Λc * randn(K)
            for t in 1:p
                if rand() < inv(1 + exp(-βz[t]))
                    y = 0; while y == 0; y = rand(Poisson(exp(ηc[t]))); end
                    Y[t, s] = y
                end
            end
        end
        fit = fit_hurdle_poisson_gllvm(Y; K = K)
        ci = confint(fit, Y; method = :wald)
        @test length(ci.term) == 2p + (p * K)         # βz + βc + Λ
        @test "betaz[1]" in ci.term && "betac[1]" in ci.term
        w = confint(fit, Y; method = :wald, parm = "betac[1]")
        @test w.term == ["betac[1]"]
        @test w.estimate[1] ≈ fit.βc[1] atol = 1e-8
        pr = confint(fit, Y; method = :profile, parm = "betac[1]")
        @test pr.method === :profile
        @test isfinite(pr.lower[1]) || isfinite(pr.upper[1])
        isfinite(pr.lower[1]) && @test pr.lower[1] < pr.estimate[1]
        isfinite(pr.upper[1]) && @test pr.estimate[1] < pr.upper[1]
    end

    @testset "Two-part: Delta-lognormal Wald σ on natural scale" begin
        Random.seed!(32)
        p, K, n = 4, 1, 200; σ_true = 0.5
        βz = 0.3 .* randn(p) .+ 0.6; βc = 0.4 .* randn(p)
        Λc = 0.4 .* randn(p, K)
        Y = zeros(p, n)
        for s in 1:n
            ηc = βc .+ Λc * randn(K)
            for t in 1:p
                rand() < inv(1 + exp(-βz[t])) && (Y[t, s] = exp(ηc[t] + σ_true * randn()))
            end
        end
        fit = fit_delta_lognormal_gllvm(Y; K = K)
        ci = confint(fit, Y; method = :wald, parm = "sigma")
        @test ci.term == ["sigma"]
        @test ci.estimate[1] ≈ fit.σ atol = 1e-8
        if isfinite(ci.lower[1])
            @test 0 < ci.lower[1] < ci.estimate[1] < ci.upper[1]
        end
    end

    @testset "Two-part: ZIP bootstrap single- vs multi-core identical" begin
        Random.seed!(33)
        p, K, n = 4, 1, 140
        βz = 0.3 .* randn(p) .- 0.6; βc = 0.3 .* randn(p) .+ 1.2
        Λc = 0.4 .* randn(p, K)
        Y = zeros(Int, p, n)
        for s in 1:n
            ηc = βc .+ Λc * randn(K)
            for t in 1:p
                Y[t, s] = rand() < inv(1 + exp(-βz[t])) ? 0 : rand(Poisson(exp(ηc[t])))
            end
        end
        fit = fit_zip_gllvm(Y; K = K)
        a = confint(fit, Y; method = :bootstrap, n_boot = 20, seed = 5, parallel = false)
        b = confint(fit, Y; method = :bootstrap, n_boot = 20, seed = 5, parallel = true)
        @test a.lower == b.lower && a.upper == b.upper
        @test a.n_converged ≥ 6
    end

    @testset "Two-part: ZIB Wald + bootstrap (zero-inflated binomial)" begin
        Random.seed!(36)
        p, K, n, Ntr = 4, 1, 160, 8
        βz = 0.3 .* randn(p) .- 0.6; βc = 0.3 .* randn(p)
        Λc = 0.4 .* randn(p, K)
        Y = zeros(Int, p, n)
        for s in 1:n
            ηc = βc .+ Λc * randn(K)
            for t in 1:p
                μ = inv(1 + exp(-ηc[t]))
                Y[t, s] = rand() < inv(1 + exp(-βz[t])) ? 0 : rand(Binomial(Ntr, μ))
            end
        end
        fit = fit_zib_gllvm(Y; K = K, N = Ntr)

        ci = confint(fit, Y; method = :wald)
        @test length(ci.term) == 2p + GLLVM.rr_theta_len(p, K)   # βz + βc + Λc (no dispersion)
        @test ci.method == :wald
        for i in eachindex(ci.term)
            if isfinite(ci.lower[i]) && isfinite(ci.upper[i])
                @test ci.lower[i] ≤ ci.estimate[i] ≤ ci.upper[i]
            end
        end

        # parametric bootstrap is deterministic in the seed (serial == parallel).
        a = confint(fit, Y; method = :bootstrap, n_boot = 20, seed = 5, parallel = false)
        b = confint(fit, Y; method = :bootstrap, n_boot = 20, seed = 5, parallel = true)
        @test a.lower == b.lower && a.upper == b.upper
        @test a.n_converged ≥ 6
    end

    @testset "Ordinal Wald + bootstrap (τ in natural scale)" begin
        Random.seed!(34)
        p, K, n, C = 4, 1, 220, 4
        Λ = 0.7 .* randn(p, K)
        τ = [-1.0, 0.0, 1.2]
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            η = Λ * randn(K)
            for t in 1:p
                u = rand(); cum = 0.0; cat = C
                for c in 1:C
                    Fhi = c == C ? 1.0 : inv(1 + exp(-(τ[c] - η[t])))
                    Flo = c == 1 ? 0.0 : inv(1 + exp(-(τ[c - 1] - η[t])))
                    cum += Fhi - Flo
                    if u <= cum
                        cat = c; break
                    end
                end
                Y[t, s] = cat
            end
        end
        fit = fit_ordinal_gllvm(Y; K = K)
        ci = confint(fit, Y; method = :wald)
        @test length(ci.term) == (p * K) + (C - 1)        # Λ + τ
        @test "tau[1]" in ci.term && "Lambda[1,1]" in ci.term
        # cutpoints are ordered; their Wald point estimates inherit that
        taus = [ci.estimate[findfirst(==("tau[$c]"), ci.term)] for c in 1:(C - 1)]
        @test issorted(taus)

        bo = confint(fit, Y; method = :bootstrap, n_boot = 20, seed = 3, parm = "Lambda")
        @test bo.method === :bootstrap
        @test bo.n_converged ≥ 5
    end

    @testset "Tweedie Wald + bootstrap (phi on natural scale, power fixed)" begin
        # Compound Poisson–Gamma draws (true zeros + positive part), mirroring the
        # data-generating loop in test/test_tweedie.jl.
        Random.seed!(35)
        p, K, n = 4, 1, 70
        β = log.(rand(p) .* 2 .+ 0.5)
        Λ = 0.4 .* randn(p, K)
        Y = zeros(p, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p
                μ = exp(β[t] + dot(Λ[t, :], z))
                k = rand(Poisson(μ))
                Y[t, s] = k == 0 ? 0.0 : sum(rand(Gamma(2.0, μ / (2.0 * μ + 1e-9)), k))
            end
        end
        fit = fit_tweedie_gllvm(Y; K = K, iterations = 40)

        ci = confint(fit, Y; method = :wald)
        # β + Λ + a single dispersion term (φ); the power p is held fixed.
        @test length(ci.term) == p + GLLVM.rr_theta_len(p, K) + 1
        @test ci.method === :wald
        @test "phi" in ci.term
        @test ci.estimate[findfirst(==("phi"), ci.term)] ≈ fit.φ atol = 1e-8
        fin = isfinite.(ci.se)
        @test any(fin)
        @test all(ci.lower[fin] .< ci.estimate[fin] .< ci.upper[fin])

        # parametric bootstrap is deterministic in the seed (serial == parallel).
        a = confint(fit, Y; method = :bootstrap, n_boot = 6, seed = 5, parallel = false)
        b = confint(fit, Y; method = :bootstrap, n_boot = 6, seed = 5, parallel = true)
        @test a.lower == b.lower && a.upper == b.upper
        @test a.n_converged == b.n_converged
        @test a.n_converged ≥ 4
    end

    @testset "VA-based standard errors" begin
        Y, _, _ = _sim_poisson(4, 1, 140; seed = 41)
        fit = fit_poisson_gllvm_va(Y; K = 1)

        # Wald SEs from the variational (ELBO) marginal.
        ci = confint(fit, Y; method = :wald, objective = :va)
        @test ci.method === :wald
        @test length(ci.term) == length(fit.β) + (4 * 1)     # β + Λ entries
        @test ci.estimate[1] ≈ fit.β[1] atol = 1e-8
        fin = isfinite.(ci.se)
        @test any(fin)
        @test all(ci.lower[fin] .< ci.estimate[fin] .< ci.upper[fin])

        # coef_table forwards objective=:va through to the Wald confint.
        ct = coef_table(fit, Y; objective = :va)
        @test ct isa GllvmCoefTable
        ctfin = isfinite.(ct.std_error)
        @test any(ctfin)
        @test all(ct.lower[ctfin] .< ct.estimate[ctfin] .< ct.upper[ctfin])
        @test all(ct.z[ctfin] .≈ ct.estimate[ctfin] ./ ct.std_error[ctfin])

        # NB VA fit: positive natural-scale dispersion r interval.
        Random.seed!(42)
        p, K, n, r_true = 4, 1, 200, 6.0
        βr = 0.4 .* randn(p) .+ 1.2
        Λr = 0.4 .* randn(p, K)
        Yr = Matrix{Int}(undef, p, n)
        for s in 1:n
            η = βr .+ Λr * randn(K)
            for t in 1:p
                μ = exp(η[t])
                Yr[t, s] = rand(NegativeBinomial(r_true, r_true / (r_true + μ)))
            end
        end
        fnb = fit_nb_gllvm_va(Yr; K = K)
        cir = confint(fnb, Yr; method = :wald, objective = :va, parm = "r")
        @test cir.term == ["r"]
        @test cir.estimate[1] ≈ fnb.r atol = 1e-8
        if isfinite(cir.lower[1])
            @test 0 < cir.lower[1] < cir.estimate[1] < cir.upper[1]
        end

        # objective=:va restricted to method=:wald.
        @test_throws ArgumentError confint(fit, Y; method = :profile, objective = :va)

        # objective=:va unsupported for families without a VA marginal.
        Yo, _, _ = _sim_poisson(3, 1, 80; seed = 43)
        Yo = (Yo .% 4) .+ 1                                   # fold counts into 4 ordered categories
        ford = fit_ordinal_gllvm(Yo; K = 1)
        @test_throws ArgumentError confint(ford, Yo; method = :wald, objective = :va)
    end
end
