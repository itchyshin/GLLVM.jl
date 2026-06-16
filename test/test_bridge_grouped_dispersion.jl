using Test
using GLLVM

@testset "bridge grouped dispersion default" begin
    K = 1
    cases = (
        (
            family = "negbinomial",
            y = Float64.([0 1 2 3 1 0 2 4 1 3
                          4 2 1 0 3 5 2 1 4 3]),
            parameter = "r",
            engine = "mu + mu^2 / r",
            public = "1 / sqrt(r)",
        ),
        (
            family = "nb1",
            y = Float64.([0 1 1 2 3 1 0 2 4 1
                          3 2 4 1 0 3 5 2 1 4]),
            parameter = "phi",
            engine = "mu * (1 + phi)",
            public = "identity",
        ),
        (
            family = "beta",
            y = [0.12 0.18 0.25 0.33 0.41 0.52 0.63 0.72 0.81 0.88
                 0.82 0.76 0.69 0.61 0.55 0.47 0.36 0.28 0.20 0.14],
            parameter = "phi",
            engine = "mu * (1 - mu) / (1 + phi)",
            public = "1 / sqrt(phi)",
        ),
        (
            family = "gamma",
            y = [0.8 1.0 1.4 1.7 2.2 2.6 3.0 3.4 3.9 4.3
                 4.2 3.7 3.2 2.8 2.4 2.0 1.6 1.3 1.1 0.9],
            parameter = "alpha",
            engine = "mu^2 / alpha",
            public = "1 / sqrt(alpha)",
        ),
    )

    for case in cases
        @testset "$(case.family)" begin
            Y = case.y
            p = size(Y, 1)
            br = bridge_fit(; y = Y, family = case.family, d = K)

            @test br.df == p + GLLVM.rr_theta_len(p, K) + p
            @test br.dispersion_group_id == collect(1:p)
            @test length(br.dispersion_group) == p
            @test br.dispersion == br.dispersion_group[br.dispersion_group_id]
            @test br.dispersion_parameter == case.parameter
            @test occursin(case.engine, br.dispersion_engine_scale)
            @test occursin(case.public, br.dispersion_public_scale)
            @test !(:ci_method in keys(br))

            err = try
                bridge_fit(; y = Y, family = case.family, d = K,
                           options = Dict("ci_method" => "wald"))
                nothing
            catch e
                e
            end
            @test err isa ArgumentError
            @test occursin("grouped-dispersion", sprint(showerror, err))
        end
    end
end
