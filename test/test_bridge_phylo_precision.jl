using GLLVM, Test, Random, LinearAlgebra, SparseArrays

# Phylo transport S3a — Julia-side precision-payload admission.
#
# Proven fixture: the same 8-tip ultrametric balanced tree as S1
# (`test/test_phylo_precision.jl`). Height ≠ 1 so a dropped `scale` cannot
# hide. This slice admits the already-canonical PrecisionPhy bundle as a
# JuliaCall-flat payload; it does not lift the R `phylo_rr` gate and does
# not claim true parity.
#
# Frozen field meanings (gllvmTMB 0.7.0, oracle
# `b4d5fee64def88bc768dda1f1f77c29b295edd86`):
#   i, j, x            — 1-based sparse triplets of `Ainv_phy_rr`
#                        (R `Matrix` / Julia `findnz` convention)
#   n_aug              — `n_aug_phy` = 2p − 2
#   n_leaves           — tip count p
#   species_aug_id     — 0-indexed tip → row map (`fit-multi.R:4638`,
#                        `DATA_IVECTOR` in `src/gllvmTMB.cpp:852`)
#   node_labels        — length-n_aug labels aligned with Q
#   scale              — height actually applied to Q
#   log_det            — shipped `log_det_A_phy_rr`

const _S3A_NEWICK = "(((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1):0.1,((E:0.1,F:0.1):0.1,(G:0.1,H:0.1):0.1):0.1);"
const _S3A_PAYLOAD_KEYS = (
    :i, :j, :x, :n_aug, :n_leaves, :species_aug_id,
    :node_labels, :scale, :log_det,
)

function _s3a_fixture()
    phy = augmented_phy(_S3A_NEWICK)
    pp = PrecisionPhy(phy; correlation = false)
    return phy, pp
end

function _s3a_expect_gate(f, tag)
    err = try
        f()
        nothing
    catch e
        e
    end
    @test err isa ArgumentError
    @test occursin(tag, err.msg)
    return err
end

@testset "phylo transport S3a: Julia precision payload" begin
    phy, pp = _s3a_fixture()
    p = pp.n_leaves
    @test p == 8

    @testset "payload schema uses frozen field meanings" begin
        payload = GLLVM.phylo_precision_payload(pp)
        for key in _S3A_PAYLOAD_KEYS
            @test haskey(payload, key)
        end
        @test payload.n_aug == 2p - 2
        @test payload.n_leaves == p
        @test length(payload.i) == length(payload.j) == length(payload.x)
        @test length(payload.x) == nnz(pp.Q)
        @test payload.i isa Vector{Int}
        @test payload.j isa Vector{Int}
        @test payload.x isa Vector{Float64}
        @test minimum(payload.i) >= 1
        @test maximum(payload.i) <= payload.n_aug
        @test minimum(payload.j) >= 1
        @test maximum(payload.j) <= payload.n_aug
        # Wire map is 0-indexed (R/TMB). Native PrecisionPhy is 1-indexed.
        @test payload.species_aug_id == pp.species_aug_id .- 1
        @test minimum(payload.species_aug_id) >= 0
        @test maximum(payload.species_aug_id) <= payload.n_aug - 1
        @test length(payload.node_labels) == payload.n_aug
        @test payload.scale == pp.scale
        @test payload.log_det == pp.log_det
        @test payload.node_labels == pp.node_labels
    end

    @testset "admit validates checksum and reconstructs PrecisionPhy" begin
        payload = GLLVM.phylo_precision_payload(pp)
        admitted = GLLVM.admit_phylo_precision_payload(payload)
        @test admitted.n_aug == pp.n_aug
        @test admitted.n_leaves == pp.n_leaves
        @test admitted.species_aug_id == pp.species_aug_id
        @test admitted.node_labels == pp.node_labels
        @test admitted.scale == pp.scale
        @test admitted.log_det == pp.log_det
        @test Matrix(admitted.Q) ≈ Matrix(pp.Q) atol = 1e-12
        recomputed, shipped, abs_diff = precision_logdet_check(admitted)
        @test abs_diff <= 1e-8
        @test shipped == payload.log_det
        @test isapprox(recomputed, shipped; atol = 1e-8)

        # JuliaCall typically ships string-keyed Dicts, not NamedTuples.
        as_dict = Dict{String,Any}(String(k) => getfield(payload, k) for k in _S3A_PAYLOAD_KEYS)
        admitted_dict = GLLVM.admit_phylo_precision_payload(as_dict)
        @test admitted_dict.species_aug_id == pp.species_aug_id
        @test Matrix(admitted_dict.Q) ≈ Matrix(pp.Q) atol = 1e-12

        # Raw triplet constructor stays a thin wrap (S1/S2 unchanged).
        I, J, V = findnz(pp.Q)
        loose = PrecisionPhy(I, J, V, pp.n_aug, pp.n_leaves, pp.node_labels,
                             pp.log_det + 0.25, pp.scale, pp.species_aug_id)
        @test loose.log_det == pp.log_det + 0.25
    end

    @testset "malformed payloads raise named gates" begin
        payload = GLLVM.phylo_precision_payload(pp)

        bad_dim = merge(payload, (; n_aug = payload.n_aug + 1))
        _s3a_expect_gate(() -> GLLVM.admit_phylo_precision_payload(bad_dim),
                         "GJL-GATE-PHYLO-PAYLOAD-DIM")

        bad_index = merge(payload, (; i = copy(payload.i)))
        bad_index.i[1] = 0
        _s3a_expect_gate(() -> GLLVM.admit_phylo_precision_payload(bad_index),
                         "GJL-GATE-PHYLO-PAYLOAD-INDEX")

        bad_tip = merge(payload, (; species_aug_id = copy(payload.species_aug_id)))
        bad_tip.species_aug_id[1] = payload.n_aug
        _s3a_expect_gate(() -> GLLVM.admit_phylo_precision_payload(bad_tip),
                         "GJL-GATE-PHYLO-PAYLOAD-TIPMAP")

        dup_tip = merge(payload, (; species_aug_id = fill(0, p)))
        _s3a_expect_gate(() -> GLLVM.admit_phylo_precision_payload(dup_tip),
                         "GJL-GATE-PHYLO-PAYLOAD-TIPMAP")

        bad_label = merge(payload, (; node_labels = payload.node_labels[1:(end - 1)]))
        _s3a_expect_gate(() -> GLLVM.admit_phylo_precision_payload(bad_label),
                         "GJL-GATE-PHYLO-PAYLOAD-LABEL")

        nan_x = merge(payload, (; x = copy(payload.x)))
        nan_x.x[1] = NaN
        _s3a_expect_gate(() -> GLLVM.admit_phylo_precision_payload(nan_x),
                         "GJL-GATE-PHYLO-PAYLOAD-NONFINITE")

        inf_scale = merge(payload, (; scale = Inf))
        _s3a_expect_gate(() -> GLLVM.admit_phylo_precision_payload(inf_scale),
                         "GJL-GATE-PHYLO-PAYLOAD-NONFINITE")

        bad_logdet = merge(payload, (; log_det = payload.log_det + 0.25))
        _s3a_expect_gate(() -> GLLVM.admit_phylo_precision_payload(bad_logdet),
                         "GJL-GATE-PHYLO-PAYLOAD-LOGDET")
    end

    @testset "replay agrees with AugmentedPhy at matched parameters" begin
        payload = GLLVM.phylo_precision_payload(pp)
        admitted = GLLVM.admit_phylo_precision_payload(payload)
        Random.seed!(20260906)
        K_B, n = 2, 10
        Λ_B = randn(p, K_B)
        Λ_phy = reshape(randn(p), p, 1)
        σ_eps = 0.4
        y = randn(p, n)
        for σ²_phy_test in (0.3, 1.0, 2.5)
            ll_aug = gaussian_marginal_loglik_sparse_phy(y, Λ_B, σ_eps;
                Λ_phy = Λ_phy, phy = phy, σ²_phy = σ²_phy_test)
            ll_pay = gaussian_marginal_loglik_sparse_phy(y, Λ_B, σ_eps;
                Λ_phy = Λ_phy, phy = admitted, σ²_phy = σ²_phy_test)
            @test isfinite(ll_aug)
            @test isfinite(ll_pay)
            @test ll_pay != 0.0 || ll_aug != 0.0
            @test isapprox(ll_pay, ll_aug; atol = 1e-8)
            rel = abs(ll_pay - ll_aug) / max(1.0, abs(ll_aug))
            @test rel <= 1e-8
        end
    end
end
