using Test
include(joinpath(@__DIR__, "fixtures", "destination_b_reference.jl"))

@testset "Destination B independent dense reference fixtures" begin
    f = destination_b_grouping_fixture()
    c = f.source_covariance
    # vec(response) is trait-within-observation: (trait s, observation i).
    ix(s, i) = s + (i - 1) * 2
    @test isposdef(Symmetric(f.covariance))
    @test f.labels.unit[1] == f.labels.unit[3] && f.labels.unit[3] == "g3"
    @test f.covariance[ix(1, 1), ix(1, 3)] == c.unit[1,1] + c.nested[1,1] + c.crossed[1,1] + c.cluster2[1]
    # cluster2 shares repeated labels across observations but is diagonal in traits.
    @test f.labels.cluster2[1] == f.labels.cluster2[3]
    @test f.covariance[ix(1, 1), ix(2, 3)] == c.unit[1,2] + c.nested[1,2] + c.crossed[1,2]
    @test f.covariance[ix(1, 1), ix(1, 8)] == c.unit[1,1] + c.crossed[1,1] + c.cluster2[1]
    @test isfinite(f.exact_nll)
    @test isapprox(f.exact_nll, 15.477822651708259; atol = 1e-12, rtol = 0)
    @test destination_b_grouping_draw(17) == destination_b_grouping_draw(17)

    perm = [6, 2, 8, 1, 7, 3, 5, 4]
    permuted_index = reduce(vcat, ((2i - 1):(2i) for i in perm))
    reconstructed = Matrix{Float64}(undef, 16, 16)
    for t in 1:2, s in 1:2, j in 1:8, i in 1:8
        reconstructed[ix(s,i), ix(t,j)] = _db_grouping_entry(perm[i], s, perm[j], t;
            unit = f.labels.unit, observation = f.labels.observation,
            crossed = f.labels.crossed, cluster2 = f.labels.cluster2,
            unit_covariance = c.unit, nested_covariance = c.nested,
            crossed_covariance = c.crossed, cluster2_variance = c.cluster2,
            residual_variance = c.residual)
    end
    @test reconstructed == f.covariance[permuted_index, permuted_index]

    wrong_unit = copy(f.labels.unit); wrong_unit[3] = "g4"
    wrong = copy(f.covariance)
    for t in 1:2, s in 1:2, j in 1:8, i in 1:8
        wrong[ix(s,i), ix(t,j)] = _db_grouping_entry(i, s, j, t; unit = wrong_unit,
            observation = f.labels.observation, crossed = f.labels.crossed, cluster2 = f.labels.cluster2,
            unit_covariance = c.unit, nested_covariance = c.nested, crossed_covariance = c.crossed,
            cluster2_variance = c.cluster2, residual_variance = c.residual)
    end
    @test wrong != f.covariance
    @test destination_b_exact_nll(f.vectorized_response, f.vectorized_mean, wrong) != f.exact_nll

    p = destination_b_precision_fixture()
    @test isposdef(Symmetric(p.covariance))
    @test p.observation_nodes[1] == p.observation_nodes[3] && p.observation_nodes[3] == 3
    @test 5 in p.unobserved_nodes && !(5 in p.observation_nodes)
    @test p.vectorized_response == vec(p.response)
    @test isapprox(p.exact_nll, 8.771113846727065; atol = 1e-12, rtol = 0)
    @test destination_b_precision_draw(23) == destination_b_precision_draw(23)
end

println("destination-b-reference-tests-ok")
