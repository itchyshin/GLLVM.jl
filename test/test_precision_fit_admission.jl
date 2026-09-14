using GLLVM, Test, LinearAlgebra, SparseArrays

function _pfia_raw(Q::AbstractMatrix; n_leaves::Integer = 2,
        node_labels = ["ancestor", "tip_a", "tip_b"],
        species_aug_id = [2, 3], scale::Real = 1.0,
        log_det::Real = logdet(cholesky(Symmetric(Matrix(Q)))))
    q = sparse(Float64.(Q))
    I, J, V = findnz(q)
    return PrecisionPhy(I, J, V, size(q, 1), n_leaves, node_labels,
        log_det, scale, species_aug_id)
end

function _pfia_public_standalone(Y, phy)
    return fit_gllvm(Y; phylo = phy, phylo_rank = 1,
        species_id = [1, 2, 1, 2], iterations = 0)
end

function _pfia_public_grouped(Y, phy)
    terms = [GroupingTerm(:unit; mode = :indep, common = false)]
    return fit_gllvm(Y; phylo = phy, phylo_rank = 1,
        species_id = [1, 2, 1, 2], grouping = terms,
        unit = [1, 2, 1, 2], iterations = 0)
end

@testset "precision-fit input admission" begin
    Q = [3.0 -1.0 0.0;
        -1.0 3.0 -1.0;
         0.0 -1.0 2.0]
    valid = _pfia_raw(Q)

    @testset "valid snapshots retain canonical Q and scale" begin
        admitted = GLLVM._validate_precision_fit_input(valid)
        @test admitted !== valid
        @test admitted.Q !== valid.Q
        @test admitted.species_aug_id !== valid.species_aug_id
        @test admitted.node_labels !== valid.node_labels
        @test Matrix(admitted.Q) == Matrix(valid.Q)
        @test admitted.scale == valid.scale
        @test admitted.species_aug_id == valid.species_aug_id

        # Non-unit-height tree scaling is already baked into Q. Admission
        # checks metadata but neither applies scale again nor inverts Q.
        tree = augmented_phy("((A:0.3,B:0.3):0.4,(C:0.3,D:0.3):0.4);")
        nonunit = PrecisionPhy(tree; correlation = true)
        admitted_tree = GLLVM._validate_precision_fit_input(nonunit)
        @test admitted_tree.scale == 0.7
        @test Matrix(admitted_tree.Q) == Matrix(nonunit.Q)

        # One unphenotyped founder and two observed pedigree members. The
        # full inverse relationship precision must stay intact.
        A = [1.0 0.0 0.5;
             0.0 1.0 0.5;
             0.5 0.5 1.0]
        pedigree = _pfia_raw(inv(A); n_leaves = 2,
            node_labels = ["founder_1", "founder_2", "offspring"],
            species_aug_id = [2, 3])
        admitted_pedigree = GLLVM._validate_precision_fit_input(pedigree)
        @test admitted_pedigree.n_aug == 3
        @test admitted_pedigree.n_leaves == 2
        @test admitted_pedigree.species_aug_id == [2, 3]
        @test Matrix(admitted_pedigree.Q) ≈ inv(A) atol = 1e-12
    end

    @testset "raw construction remains permissive; fitting admission rejects malformed state" begin
        wrong_det = _pfia_raw(Q; log_det = valid.log_det + 0.1)
        @test wrong_det isa PrecisionPhy
        @test_throws ArgumentError GLLVM._validate_precision_fit_input(wrong_det)

        # Symmetric(Matrix(Q)) would silently retain this triangle. Require
        # sparse Q itself to be symmetric before the PD/checksum path.
        asymmetric_Q = [3.0 -1.0 0.0;
                        -0.75 3.0 -1.0;
                         0.0 -1.0 2.0]
        asymmetric = _pfia_raw(asymmetric_Q; log_det = valid.log_det)
        @test asymmetric isa PrecisionPhy
        @test_throws ArgumentError GLLVM._validate_precision_fit_input(asymmetric)

        # A positive residual contribution can make a downstream augmented
        # system positive definite even though the phylogenetic prior Q is
        # not. Admission must reject the prior itself before that masking.
        indefinite_Q = [-1.0 0.0; 0.0 2.0]
        augmented_J = indefinite_Q + 2.0I
        @test !issuccess(cholesky(Symmetric(indefinite_Q); check = false))
        @test issuccess(cholesky(Symmetric(augmented_J); check = false))
        indefinite = _pfia_raw(indefinite_Q; n_leaves = 2,
            node_labels = ["tip_a", "tip_b"], species_aug_id = [1, 2], log_det = 0.0)
        @test_throws ArgumentError GLLVM._validate_precision_fit_input(indefinite)

        duplicate_map = _pfia_raw(Q; species_aug_id = [2, 2])
        @test_throws ArgumentError GLLVM._validate_precision_fit_input(duplicate_map)

        empty_label = _pfia_raw(Q; node_labels = ["ancestor", "", "tip_b"])
        @test_throws ArgumentError GLLVM._validate_precision_fit_input(empty_label)

        nonpositive_scale = _pfia_raw(Q; scale = 0.0)
        @test_throws ArgumentError GLLVM._validate_precision_fit_input(nonpositive_scale)

        nonfinite_Q = _pfia_raw([NaN 0.0 0.0;
                                  0.0 2.0 -1.0;
                                  0.0 -1.0 2.0]; log_det = 0.0)
        @test_throws ArgumentError GLLVM._validate_precision_fit_input(nonfinite_Q)

        # Direct field construction can violate the struct's own Q/n_aug
        # invariant; the public fit boundary must not trust its type alone.
        malformed_shape = PrecisionPhy{Float64}(2, 3, sparse(Q[1:2, 1:2]),
            0.0, 1.0, [1, 2], ["a", "b", "c"])
        @test_throws ArgumentError GLLVM._validate_precision_fit_input(malformed_shape)
    end

    @testset "public standalone and grouped routes cannot bypass admission" begin
        Y = [0.2 0.1 0.3 0.0;
             -0.1 0.2 0.0 0.1]
        wrong_det = _pfia_raw(Q; log_det = valid.log_det + 0.1)
        asymmetric = _pfia_raw([3.0 -1.0 0.0;
                                 -0.75 3.0 -1.0;
                                  0.0 -1.0 2.0]; log_det = valid.log_det)
        indefinite = _pfia_raw([-1.0 0.0; 0.0 2.0]; n_leaves = 2,
            node_labels = ["tip_a", "tip_b"], species_aug_id = [1, 2], log_det = 0.0)

        for invalid in (wrong_det, asymmetric, indefinite)
            @test_throws ArgumentError _pfia_public_standalone(Y, invalid)
            @test_throws ArgumentError _pfia_public_grouped(Y, invalid)
        end

        standalone = _pfia_public_standalone(Y, valid)
        grouped = _pfia_public_grouped(Y, valid)
        standalone_Q = copy(standalone.phy.Q)
        grouped_Q = copy(grouped.phy.Q)
        standalone_labels = copy(standalone.phy.node_labels)
        grouped_labels = copy(grouped.phy.node_labels)
        valid.Q.nzval[1] += 0.25
        valid.species_aug_id[1] = 3
        valid.node_labels[1] = "mutated-after-fit"
        @test standalone.phy.Q == standalone_Q
        @test grouped.phy.Q == grouped_Q
        @test standalone.phy.node_labels == standalone_labels
        @test grouped.phy.node_labels == grouped_labels
        @test standalone.phy.Q !== valid.Q
        @test grouped.phy.Q !== valid.Q
    end
end
