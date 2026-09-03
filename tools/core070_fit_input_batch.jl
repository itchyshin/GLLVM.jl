# Fixed-coordinate density verification for the fit-input manifest area's
# EXECUTABLE_NOW case_ids. Consolidates, without changing the numerics,
# test/parity/test_gaussian_fixed_point.jl (GAUSS-DEFAULT/COMMON/LOADINGS)
# and test/parity/test_source_fixed_point.jl (ANIMAL-LATENT, KERNEL-ONE,
# KERNEL-TWO) into one script, called by tools/core070_fit_input_batch.R via
# a plain subprocess (no JuliaCall). Not fitted-model or recovery evidence.
using GLLVM, Test, LinearAlgebra, ForwardDiff
@assert realpath(Base.pkgdir(GLLVM)) == realpath(pwd())
root = ARGS[1]
readrows(p) = split.(readlines(p)[2:end], '\t')
readmatrix(p) = reduce(vcat, [permutedims(parse.(Float64, r)) for r in readrows(p)])

total_pass = 0
total_fail = 0

@testset "fit-input batch: frozen fixed-point model identity" begin
    @testset "Gaussian family" begin
        for model in ("DEFAULT", "COMMON", "LOADINGS"), point in 1:2
            id = "GAUSS-$model-P$point"
            dir = joinpath(root, id)
            dr = readrows(joinpath(dir, "data.tsv"))
            Y = fill(NaN, 3, 18)
            for row in dr
                Y[parse(Int, row[1]), parse(Int, row[2])] = parse(Float64, row[3])
            end
            pr = readrows(joinpath(dir, "parameters.tsv"))
            names_ = [r[1] for r in pr]
            θ = [parse(Float64, r[2]) for r in pr]
            rg = [parse(Float64, r[3]) for r in pr]
            c = only(readrows(joinpath(dir, "contract.tsv")))
            sigma = parse(Float64, c[4])
            psi = c[5] == "1"
            common = c[6] == "1"
            rnll = parse(Float64, c[7])
            rdense = parse(Float64, c[8])
            @test Set(names_) == Set(psi ? ["b_fix", "theta_rr_B", "theta_diag_B"] : ["b_fix", "theta_rr_B", "log_sigma_eps"])
            bi = findall(==("b_fix"), names_)
            li = findall(==("theta_rr_B"), names_)
            di = findall(==("theta_diag_B"), names_)
            si = findall(==("log_sigma_eps"), names_)
            @test length(bi) == 3 && length(li) == 3 && length(di) == (psi ? (common ? 1 : 3) : 0) && length(si) == (psi ? 0 : 1)
            function quantities(t)
                β = t[bi]
                Λ = reshape(t[li], 3, 1)
                s = psi ? sigma : exp(only(t[si]))
                d = psi ? (common ? fill(exp(2 * only(t[di])), 3) : exp.(2 .* t[di])) : zeros(eltype(t), 3)
                return β, Λ, s, d
            end
            function native(t)
                β, Λ, s, d = quantities(t)
                -GLLVM.gaussian_marginal_loglik(Y .- β, Λ, s; σ²_B=d)
            end
            function dense(t)
                β, Λ, s, d = quantities(t)
                V = Λ * Λ' + Diagonal(d .+ s^2)
                r = Y .- β
                (length(Y) * log(2π) + size(Y, 2) * logdet(Symmetric(V)) + sum(r .* (V \ r))) / 2
            end
            jnll = native(θ)
            dnll = dense(θ)
            jg = ForwardDiff.gradient(native, θ)
            dg = ForwardDiff.gradient(dense, θ)
            error = maximum(abs.(jg .- rg) ./ (1 .+ abs.(rg)))
            @test abs(jnll - rnll) <= 1e-6
            @test abs(jnll - rdense) <= 1e-6
            @test abs(jnll - dnll) <= 1e-8
            @test error <= 1e-6
            @test maximum(abs.(jg .- dg) ./ (1 .+ abs.(dg))) <= 1e-8
            altered = copy(θ)
            altered[first(bi)] += 0.2
            altered_delta = abs(native(altered) - rnll)
            @test altered_delta > 1e-6
            println(id, " abs_delta=", abs(jnll - rnll), " scaled_gradient_error=", error)
            println("NEGCTRL ", id, " shifted_intercept_mismatch delta=", altered_delta, " mismatch=", altered_delta > 1e-6)
        end
    end

    @testset "Source family" begin
        for model in ("ANIMAL-LATENT", "KERNEL-ONE", "KERNEL-TWO"), point in 1:2
            id = "$model-P$point"
            dir = joinpath(root, id)
            d = readrows(joinpath(dir, "data.tsv"))
            trait = [parse(Int, r[1]) for r in d]
            site = [parse(Int, r[2]) for r in d]
            group = [parse(Int, r[3]) for r in d]
            y = [parse(Float64, r[4]) for r in d]
            c = only(readrows(joinpath(dir, "contract.tsv")))
            nr = parse(Int, c[4])
            rnll = parse(Float64, c[5])
            rdense = parse(Float64, c[6])
            Cs = [readmatrix(joinpath(dir, "source-$r.tsv")) for r in 1:nr]
            p = readrows(joinpath(dir, "parameters.tsv"))
            names_ = [r[1] for r in p]
            θ = [parse(Float64, r[2]) for r in p]
            rg = [parse(Float64, r[3]) for r in p]
            bi = findall(==("b_fix"), names_)
            li = findall(==(nr == 2 ? "theta_rr_kernel" : "theta_rr_phy"), names_)
            si = findall(==("log_sigma_eps"), names_)
            @test length(bi) == 3 && length(li) == 3nr && length(si) == 1 && length(θ) == 4 + 3nr
            function covariance(t)
                Λ = reshape(t[li], 3, nr)
                s2 = exp(2 * only(t[si]))
                V = Matrix(Diagonal(fill(s2, length(y))))
                for r in 1:nr
                    v = Λ[trait, r]
                    V = V + (v * v') .* Cs[r][group, group]
                end
                V
            end
            function dense(t)
                V = covariance(t)
                resid = y - t[bi][trait]
                ch = cholesky(Symmetric(V))
                (length(y) * log(2π) + logdet(ch) + dot(resid, ch \ resid)) / 2
            end
            value = dense(θ)
            g = ForwardDiff.gradient(dense, θ)
            error = maximum(abs.(g .- rg) ./ (1 .+ abs.(rg)))
            @test abs(value - rnll) <= 1e-6
            @test abs(value - rdense) <= 1e-8
            @test error <= 1e-6
            @test isposdef(Symmetric(covariance(θ)))
            altered = copy(θ)
            altered[first(bi)] += 0.2
            altered_delta = abs(dense(altered) - rnll)
            @test altered_delta > 1e-6
            println(id, " abs_delta=", abs(value - rnll), " scaled_gradient_error=", error)
            println("NEGCTRL ", id, " shifted_intercept_mismatch delta=", altered_delta, " mismatch=", altered_delta > 1e-6)
        end
    end
end

println("CORE070_FIT_INPUT_BATCH_JULIA_PASS")
