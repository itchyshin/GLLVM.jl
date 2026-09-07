using GLLVM, Test, Random, LinearAlgebra, SparseArrays

# Phylo transport S3-ANIMAL — 12-individual pedigree / sparse Ainv fixture.
#
# Proven fixture: animal-keyword.R examples (id / sire / dam, i1..i12,
# two founder pairs). Sparse Ainv is assembled as raw Henderson/Quaas
# triplets in this test only — not a production pedigree parser — and
# admitted through the PrecisionPhy payload. Replay is against the
# existing dense animal path (Henderson A / relatedness_cov). Diagnostic
# only; does not lift the R phylo_rr gate and does not claim true parity.
#
# This two-generation example has F = 0 (unrelated founders). The
# two-parent Mendelian branch still runs (d_i = 0.5 for the eight
# progeny). Unphenotyped-ancestor rows keep the FULL precision
# (subsetting Ainv would condition, not marginalise).

const _S3ANIMAL_IDS = ["i$k" for k in 1:12]
const _S3ANIMAL_SIRE = Union{String,Nothing}[
    nothing, nothing, nothing, nothing,
    "i1", "i2", "i1", "i2", "i1", "i2", "i1", "i2",
]
const _S3ANIMAL_DAM = Union{String,Nothing}[
    nothing, nothing, nothing, nothing,
    "i3", "i4", "i3", "i4", "i3", "i4", "i3", "i4",
]

function _s3animal_parent_index(ids, parents)
    idmap = Dict(ids[i] => i for i in eachindex(ids))
    return [p === nothing ? 0 : idmap[p] for p in parents]
end

# Henderson tabular A (ancestors-first). Test-only oracle; not exported.
function _s3animal_henderson_A(ids, sire, dam)
    n = length(ids)
    sire_i = _s3animal_parent_index(ids, sire)
    dam_i = _s3animal_parent_index(ids, dam)
    A = zeros(Float64, n, n)
    for i in 1:n
        for j in 1:(i - 1)
            dr = dam_i[i] == 0 ? 0.0 : A[dam_i[i], j]
            sr = sire_i[i] == 0 ? 0.0 : A[sire_i[i], j]
            A[i, j] = A[j, i] = 0.5 * (dr + sr)
        end
        if sire_i[i] == 0 || dam_i[i] == 0
            A[i, i] = 1.0
        else
            A[i, i] = 1.0 + 0.5 * A[sire_i[i], dam_i[i]]
        end
    end
    return A, sire_i, dam_i
end

# Henderson/Quaas sparse Ainv from F = diag(A) − 1. Test-only; not exported.
# Mirrors pedigree-precision.R:187-207 (sums duplicate triplets).
function _s3animal_quaas_Ainv(A, sire_i, dam_i)
    n = size(A, 1)
    Finb = diag(A) .- 1
    ri = Int[]
    ci = Int[]
    vx = Float64[]
    push_t(r, c, v) = (push!(ri, r); push!(ci, c); push!(vx, v); nothing)
    for i in 1:n
        s = sire_i[i]
        d = dam_i[i]
        has_s = s > 0
        has_d = d > 0
        d_i = if has_s && has_d
            0.5 - 0.25 * (Finb[s] + Finb[d])
        elseif has_s
            0.75 - 0.25 * Finb[s]
        elseif has_d
            0.75 - 0.25 * Finb[d]
        else
            1.0
        end
        b = 1 / d_i
        push_t(i, i, b)
        if has_s
            push_t(i, s, -0.5 * b)
            push_t(s, i, -0.5 * b)
            push_t(s, s, 0.25 * b)
        end
        if has_d
            push_t(i, d, -0.5 * b)
            push_t(d, i, -0.5 * b)
            push_t(d, d, 0.25 * b)
        end
        if has_s && has_d
            push_t(s, d, 0.25 * b)
            push_t(d, s, 0.25 * b)
        end
    end
    return sparse(ri, ci, vx, n, n)
end

function _s3animal_payload(Ainv, ids; tips = eachindex(ids))
    n_aug = size(Ainv, 1)
    n_leaves = length(tips)
    I, J, V = findnz(Ainv)
    log_det = logdet(cholesky(Symmetric(Matrix(Ainv))))
    return (
        i = collect(Int, I),
        j = collect(Int, J),
        x = collect(Float64, V),
        n_aug = n_aug,
        n_leaves = n_leaves,
        species_aug_id = collect(Int, tips) .- 1,
        node_labels = collect(String, ids),
        scale = 1.0,
        log_det = log_det,
    )
end

_s3animal_dense_negll(A, y, μ, σ²_phy, σ²_eps) = begin
    p = length(y)
    Σ = Symmetric(σ²_eps .* Matrix(1.0I, p, p) .+ σ²_phy .* A)
    0.5 * (p * log(2π) + logdet(Σ) + dot(y .- μ, Σ \ (y .- μ)))
end

@testset "phylo transport S3-ANIMAL: pedigree Ainv fixture" begin
    A, sire_i, dam_i = _s3animal_henderson_A(_S3ANIMAL_IDS, _S3ANIMAL_SIRE, _S3ANIMAL_DAM)
    Ainv = _s3animal_quaas_Ainv(A, sire_i, dam_i)
    p = length(_S3ANIMAL_IDS)
    @test p == 12
    @test size(A) == (12, 12)
    @test size(Ainv) == (12, 12)
    @test maximum(abs.(diag(A) .- 1)) <= 1e-12   # F = 0 on this two-generation draw
    @test maximum(abs.(Matrix(Ainv) * A - I(p))) <= 1e-10

    payload = _s3animal_payload(Ainv, _S3ANIMAL_IDS)
    @test payload.n_aug == 12
    @test payload.n_leaves == 12
    @test payload.n_aug != 2 * payload.n_leaves - 2   # not the tree 2p−2 convention

    @testset "admit raw Ainv triplets (tip-only animal)" begin
        admitted = GLLVM.admit_phylo_precision_payload(payload)
        @test admitted.n_aug == 12
        @test admitted.n_leaves == 12
        @test admitted.species_aug_id == collect(1:12)
        @test admitted.node_labels == _S3ANIMAL_IDS
        @test admitted.scale == 1.0
        @test Matrix(admitted.Q) ≈ Matrix(Ainv) atol = 1e-12
        recomputed, shipped, abs_diff = precision_logdet_check(admitted)
        @test abs_diff <= 1e-8
        @test isapprox(recomputed, shipped; atol = 1e-8)
        packed = GLLVM.phylo_precision_payload(admitted)
        readmitted = GLLVM.admit_phylo_precision_payload(packed)
        @test Matrix(readmitted.Q) ≈ Matrix(admitted.Q) atol = 1e-12
    end

    @testset "n_aug < n_leaves still raises DIM" begin
        bad = merge(payload, (; n_aug = 11))
        err = try
            GLLVM.admit_phylo_precision_payload(bad)
            nothing
        catch e
            e
        end
        @test err isa ArgumentError
        @test occursin("GJL-GATE-PHYLO-PAYLOAD-DIM", err.msg)
    end

    admitted = GLLVM.admit_phylo_precision_payload(payload)

    @testset "replay vs dense Henderson A (existing animal path)" begin
        Random.seed!(20260907)
        y = 0.35 .+ cholesky(Symmetric(1.2 .* A .+ 0.45 .* I(p))).L * randn(p)
        Σ_rel = relatedness_cov(A; jitter = 0.0)
        @test Matrix(Σ_rel) ≈ A atol = 1e-12

        for (σ²_phy, σ²_eps, μ) in ((0.3, 0.4, 0.0), (1.2, 0.45, 0.35), (2.5, 0.8, -0.2))
            st = GLLVM._build_precision_phy_fit_state(admitted, fill(sqrt(σ²_phy), p), σ²_eps)
            nll_pp = GLLVM._phylo_negll(st, y, μ)
            nll_A = _s3animal_dense_negll(A, y, μ, σ²_phy, σ²_eps)
            @test isfinite(nll_pp) && isfinite(nll_A)
            @test nll_pp != 0.0 || nll_A != 0.0
            @test isapprox(nll_pp, nll_A; atol = 1e-8, rtol = 1e-8)
        end
    end

    @testset "unphenotyped ancestors keep full Ainv (do not subset)" begin
        # Drop founders i1,i2 from the phenotype map; keep the 12×12 precision.
        tips = 3:12
        anc_payload = _s3animal_payload(Ainv, _S3ANIMAL_IDS; tips = tips)
        @test anc_payload.n_aug == 12
        @test anc_payload.n_leaves == 10
        admitted_anc = GLLVM.admit_phylo_precision_payload(anc_payload)
        @test admitted_anc.n_aug == 12
        @test admitted_anc.n_leaves == 10
        @test admitted_anc.species_aug_id == collect(tips)

        A_marg = A[tips, tips]   # correct: marginalise, do not condition
        Random.seed!(20260907)
        y10 = randn(10)
        st = GLLVM._build_precision_phy_fit_state(admitted_anc, fill(1.0, 10), 0.5)
        nll_pp = GLLVM._phylo_negll(st, y10, 0.0)
        nll_A = _s3animal_dense_negll(A_marg, y10, 0.0, 1.0, 0.5)
        @test isapprox(nll_pp, nll_A; atol = 1e-8, rtol = 1e-8)

        # Subsetting the precision (the wrong move) must NOT match A_marg.
        Ainv_sub = Ainv[tips, tips]
        I, J, V = findnz(Ainv_sub)
        wrong = PrecisionPhy(I, J, V, 10, 10, _S3ANIMAL_IDS[tips],
                             logdet(cholesky(Symmetric(Matrix(Ainv_sub)))),
                             1.0, collect(1:10))
        st_wrong = GLLVM._build_precision_phy_fit_state(wrong, fill(1.0, 10), 0.5)
        nll_wrong = GLLVM._phylo_negll(st_wrong, y10, 0.0)
        @test abs(nll_wrong - nll_A) > 1e-4
    end

    @testset "fit_phylo_gaussian on admitted animal Ainv" begin
        Random.seed!(20260907)
        ysim = 0.35 .+ cholesky(Symmetric(1.2 .* A .+ 0.45 .* I(p))).L * randn(p)
        fit_pp = fit_phylo_gaussian(admitted, ysim)
        @test fit_pp.converged
        @test isfinite(fit_pp.negll) && fit_pp.negll != 0.0
        nll_dense = _s3animal_dense_negll(A, ysim, fit_pp.μ, fit_pp.σ²_phy, fit_pp.σ²_eps)
        @test isapprox(fit_pp.negll, nll_dense; atol = 1e-8, rtol = 1e-8)

        nll_pp = GLLVM._phylo_negll(
            GLLVM._build_precision_phy_fit_state(admitted, fill(sqrt(1.2), p), 0.45),
            ysim, 0.35)
        nll_A = _s3animal_dense_negll(A, ysim, 0.35, 1.2, 0.45)
        @test isapprox(nll_pp, nll_A; atol = 1e-8, rtol = 1e-8)

        br = GLLVM.bridge_fit(; y = ysim, family = "gaussian", phylo = payload)
        @test br.converged === true
        @test isapprox(br.negll, fit_pp.negll; atol = 1e-8, rtol = 1e-8)
        @test br.diagnostic_only === true
    end
end
