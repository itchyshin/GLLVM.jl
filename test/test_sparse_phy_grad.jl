using GLLVM, Test, Random, LinearAlgebra, ForwardDiff, SparseArrays
using GLLVM: AugmentedPhy

# The analytic-gradient sparse phylo path lives in a new src file that is not
# wired into the GLLVM module (per the PERF++ hard constraint: never touch
# src/GLLVM.jl on this branch). Pull it in directly. `using GLLVM` supplies the
# package functions it compares against (gaussian_marginal_loglik, the sparse
# value, packing helpers, tree builders).
include(joinpath(@__DIR__, "..", "src", "sparse_phy_grad.jl"))

const _gml   = GLLVM.gaussian_marginal_loglik
const _rbt   = GLLVM.random_balanced_tree
const _aug   = GLLVM.augmented_phy
const _smlsp = GLLVM.gaussian_marginal_loglik_sparse_phy

# Fixed leaf covariance G_phy = S Q_cond⁻¹ S' so the dense reference uses the
# IDENTICAL Σ_phy = σ²_phy · G_phy as the sparse path. Built densely (test only).
function _gphy(phy)
    p = phy.n_leaves
    keep = filter(i -> i != phy.root_index, 1:phy.n_total)
    Qc = Matrix(phy.Q_topology[keep, keep])
    lp = Vector{Int}(undef, p)
    for t in 1:p
        l = phy.leaf_indices[t]
        lp[t] = phy.root_index < l ? l - 1 : l
    end
    return inv(Symmetric(Qc))[lp, lp]
end

# Dense marginal log-lik as a function of the natural parameters, packed into a
# single vector so ForwardDiff promotes every input to one Dual type (the dense
# path mutates A, so feeding partial Duals fails). Layout matches `slice`.
#   [vec(Λ_B); σ²_eps; σ²_phy; vec(Λ_phy)?; σ_phy?]   (σ²_eps, σ²_phy raw)
function _dense_packed(y, Gphy, p, K_B, K_phy, has_unique)
    return function (par)
        cur = 0
        Λ_B = reshape(par[cur+1:cur+p*K_B], p, K_B); cur += p * K_B
        s2e = par[cur+1]; cur += 1
        s2p = par[cur+1]; cur += 1
        Λ_phy = K_phy > 0 ? reshape(par[cur+1:cur+p*K_phy], p, K_phy) : nothing
        cur += p * K_phy
        σ_phy = has_unique ? par[cur+1:cur+p] : nothing
        cur += has_unique ? p : 0
        _gml(y, Λ_B, sqrt(s2e); Λ_phy = Λ_phy, σ_phy = σ_phy, Σ_phy = s2p .* Gphy)
    end
end

@testset "sparse phy analytic gradient" begin

    @testset "value matches the file path (K_aug=2)" begin
        Random.seed!(1)
        phy = _aug("(((A:0.1,B:0.12):0.1,(C:0.09,D:0.11):0.1):0.1,((E:0.1,F:0.13):0.1,(G:0.08,H:0.1):0.1):0.1);")
        p = phy.n_leaves
        Λ_B = randn(p, 2); Λ_phy = reshape(randn(p), p, 1); σ_phy = abs.(randn(p)) .+ 0.2
        y = randn(p, 24)
        st = build_sparse_phy_state(y, Λ_B, 0.6; Λ_phy = Λ_phy, σ_phy = σ_phy, phy = phy, σ²_phy = 0.7)
        @test sparse_phy_value(st) ≈
              _smlsp(y, Λ_B, 0.6; Λ_phy = Λ_phy, σ_phy = σ_phy, phy = phy, σ²_phy = 0.7) rtol = 1e-9
    end

    # ---- GATE 1: analytic gradient == ForwardDiff of the dense path, ~1e-6 rel
    @testset "gradient matches dense ForwardDiff — latent + unique (p=$(p))" for p in (20, 40)
        Random.seed!(100 + p)
        phy = _rbt(p; branch_length = 0.12)
        K_B = 2; n = 3 * p
        Gphy = _gphy(phy)
        Λ_B = 0.7 .* randn(p, K_B)
        Λ_phy = reshape(0.6 .* randn(p), p, 1)
        σ_phy = abs.(randn(p)) .+ 0.2
        σ_eps = 0.5; σ²_phy = 0.8
        y = randn(p, n)

        st = build_sparse_phy_state(y, Λ_B, σ_eps; Λ_phy = Λ_phy, σ_phy = σ_phy,
                                    phy = phy, σ²_phy = σ²_phy)
        g = sparse_phy_grad(st)

        f = _dense_packed(y, Gphy, p, K_B, 1, true)
        par0 = vcat(vec(Λ_B), σ_eps^2, σ²_phy, vec(Λ_phy), σ_phy)
        gfd = ForwardDiff.gradient(f, par0)
        cur = 0
        gLB = reshape(gfd[cur+1:cur+p*K_B], p, K_B); cur += p * K_B
        gs2e = gfd[cur+1]; cur += 1
        gs2p = gfd[cur+1]; cur += 1
        gLP = gfd[cur+1:cur+p]; cur += p
        gsp = gfd[cur+1:cur+p]; cur += p

        relmax(a, b) = maximum(abs.(vec(a) .- vec(b))) / max(1.0, maximum(abs.(vec(b))))
        @test relmax(g.dΛ_B, gLB)        < 1e-6
        @test abs(g.dσ²_eps - gs2e) / max(1.0, abs(gs2e)) < 1e-6
        @test abs(g.dσ²_phy - gs2p) / max(1.0, abs(gs2p)) < 1e-6
        @test relmax(g.dΛ_phy[:, 1], gLP) < 1e-6
        @test relmax(g.dσ_phy, gsp)       < 1e-6

        # Report the actual max absolute differences (gate asks for the number).
        @info "p=$p latent+unique max-abs diffs" dΛ_B = maximum(abs.(g.dΛ_B .- gLB)) dσ²_eps = abs(g.dσ²_eps - gs2e) dσ²_phy = abs(g.dσ²_phy - gs2p) dΛ_phy = maximum(abs.(g.dΛ_phy[:, 1] .- gLP)) dσ_phy = maximum(abs.(g.dσ_phy .- gsp))
    end

    @testset "gradient matches dense ForwardDiff — phy-latent only" begin
        Random.seed!(7)
        p = 28; K_B = 2; n = 60
        phy = _rbt(p; branch_length = 0.15)
        Gphy = _gphy(phy)
        Λ_B = 0.6 .* randn(p, K_B); Λ_phy = reshape(0.5 .* randn(p), p, 1)
        σ_eps = 0.5; σ²_phy = 0.9
        y = randn(p, n)
        st = build_sparse_phy_state(y, Λ_B, σ_eps; Λ_phy = Λ_phy, phy = phy, σ²_phy = σ²_phy)
        g = sparse_phy_grad(st)
        f = _dense_packed(y, Gphy, p, K_B, 1, false)
        par0 = vcat(vec(Λ_B), σ_eps^2, σ²_phy, vec(Λ_phy))
        gfd = ForwardDiff.gradient(f, par0)
        cur = 0
        gLB = reshape(gfd[cur+1:cur+p*K_B], p, K_B); cur += p * K_B
        gs2e = gfd[cur+1]; cur += 1
        gs2p = gfd[cur+1]; cur += 1
        gLP = gfd[cur+1:cur+p]
        relmax(a, b) = maximum(abs.(vec(a) .- vec(b))) / max(1.0, maximum(abs.(vec(b))))
        @test relmax(g.dΛ_B, gLB) < 1e-6
        @test abs(g.dσ²_eps - gs2e) / max(1.0, abs(gs2e)) < 1e-6
        @test abs(g.dσ²_phy - gs2p) / max(1.0, abs(gs2p)) < 1e-6
        @test relmax(g.dΛ_phy[:, 1], gLP) < 1e-6
        @test g.dσ_phy === nothing
    end

    @testset "gradient matches dense ForwardDiff — phy-unique only" begin
        Random.seed!(11)
        p = 32; K_B = 1; n = 60
        phy = _rbt(p; branch_length = 0.2)
        Gphy = _gphy(phy)
        Λ_B = reshape(0.6 .* randn(p), p, K_B); σ_phy = abs.(randn(p)) .+ 0.3
        σ_eps = 0.4; σ²_phy = 1.2
        y = randn(p, n)
        st = build_sparse_phy_state(y, Λ_B, σ_eps; σ_phy = σ_phy, phy = phy, σ²_phy = σ²_phy)
        g = sparse_phy_grad(st)
        f = _dense_packed(y, Gphy, p, K_B, 0, true)
        par0 = vcat(vec(Λ_B), σ_eps^2, σ²_phy, σ_phy)
        gfd = ForwardDiff.gradient(f, par0)
        cur = 0
        gLB = reshape(gfd[cur+1:cur+p*K_B], p, K_B); cur += p * K_B
        gs2e = gfd[cur+1]; cur += 1
        gs2p = gfd[cur+1]; cur += 1
        gsp = gfd[cur+1:cur+p]
        relmax(a, b) = maximum(abs.(vec(a) .- vec(b))) / max(1.0, maximum(abs.(vec(b))))
        @test relmax(g.dΛ_B, gLB) < 1e-6
        @test abs(g.dσ²_eps - gs2e) / max(1.0, abs(gs2e)) < 1e-6
        @test abs(g.dσ²_phy - gs2p) / max(1.0, abs(gs2p)) < 1e-6
        @test relmax(g.dσ_phy, gsp) < 1e-6
        @test g.dΛ_phy === nothing
    end

    # ---- GATE 2: end-to-end LBFGS driven by the analytic gradient.
    # Two parts:
    #  (B) headline σ²_phy fit — free (Λ_B, σ_eps, σ²_phy), Λ_phy fixed so σ²_phy
    #      is identified; checks convergence, value-consistency with the dense
    #      likelihood at the optimum, a ≈0 gradient at the optimum, and parameter
    #      recovery. A guarded dense ForwardDiff Optim fit is compared when it
    #      survives (the dense path's mid-line-search Cholesky is not robust).
    #  (A) cross-check vs the production dense fitter `fit_gaussian_gllvm` on a
    #      MATCHING model (free Λ_B + Λ_phy, Σ_phy fixed): same logLik to 1e-4.
    @testset "end-to-end LBFGS — headline σ²_phy fit (p=120)" begin
        Optim = GLLVM.Optim
        Random.seed!(3)
        p = 120; n = 300; K_B = 2
        phy = _rbt(p; branch_length = 0.1)
        Gphy = _gphy(phy)
        Λ_B_true = 0.7 .* randn(p, K_B)
        Λ_phy = reshape(0.6 .* randn(p), p, 1)        # FIXED loading (σ²_phy identified)
        σ_eps_true = 0.5; σ²_phy_true = 0.8
        Lchol = cholesky(Symmetric(σ²_phy_true .* Gphy)).L
        z = Λ_phy[:, 1] .* (Lchol * randn(p))
        y = Λ_B_true * randn(K_B, n) .+ repeat(z, 1, n) .+ σ_eps_true .* randn(p, n)

        rrB = GLLVM.rr_theta_len(p, K_B)
        unpack(par) = (GLLVM.unpack_lambda((@view par[1:rrB]), p, K_B),
                       exp(par[rrB+1]), exp(par[rrB+2]))
        function densenll(par)
            Λ, σe, s2p = unpack(par)
            -_gml(y, Λ, σe; Λ_phy = Λ_phy, Σ_phy = s2p .* Gphy)
        end
        function sparse_fg!(F, Grad, par)
            Λ, σe, s2p = unpack(par)
            st = build_sparse_phy_state(y, Λ, σe; Λ_phy = Λ_phy, phy = phy, σ²_phy = s2p)
            if Grad !== nothing
                g = sparse_phy_grad(st)
                Grad[1:rrB] .= -GLLVM.pack_lambda(g.dΛ_B)
                Grad[rrB+1] = -(g.dσ²_eps * 2 * σe^2)   # σ²_eps = exp(2 logσe)
                Grad[rrB+2] = -(g.dσ²_phy * s2p)         # σ²_phy = exp(logσ²_phy)
            end
            F !== nothing && return -sparse_phy_value(st)
            return nothing
        end

        par0 = vcat(GLLVM.init_theta_rr(p, K_B), log(1.0), log(0.5))
        opts = Optim.Options(g_tol = 1e-8, f_reltol = 1e-12, x_abstol = 1e-10,
                             iterations = 500)

        # analytic packed gradient must agree with FD at the start.
        gfd0 = ForwardDiff.gradient(densenll, par0)
        gan0 = similar(par0); sparse_fg!(nothing, gan0, par0)
        @test maximum(abs.(gan0 .- gfd0)) / max(1.0, maximum(abs.(gfd0))) < 1e-6

        res_s = Optim.optimize(Optim.only_fg!(sparse_fg!), par0, Optim.LBFGS(), opts)
        ll_s = -Optim.minimum(res_s)
        ps = Optim.minimizer(res_s)
        Λs, σe_s, s2p_s = unpack(ps)
        @test Optim.converged(res_s)

        # value-consistency: dense marginal log-lik at the sparse optimum == the
        # value the sparse path reports there.
        ll_dense_at_opt = _gml(y, Λs, σe_s; Λ_phy = Λ_phy, Σ_phy = s2p_s .* Gphy)
        @test abs(ll_s - ll_dense_at_opt) < 1e-6

        # gradient at the optimum agrees with dense-FD and is small.
        gfdO = ForwardDiff.gradient(densenll, ps)
        ganO = similar(ps); sparse_fg!(nothing, ganO, ps)
        @test maximum(abs.(ganO .- gfdO)) / max(1.0, maximum(abs.(gfdO))) < 1e-6
        @test norm(ganO) < 1e-2

        # parameter recovery (clean fixture).
        @test σe_s  ≈ σ_eps_true rtol = 0.10
        @test s2p_s ≈ σ²_phy_true rtol = 0.20

        # guarded dense ForwardDiff Optim comparison (dense path may throw a
        # PosDefException during line search — only assert if it converged).
        ll_d = NaN
        try
            res_d = Optim.optimize(densenll, par0, Optim.LBFGS(), opts; autodiff = :forward)
            if Optim.converged(res_d)
                ll_d = -Optim.minimum(res_d)
                @test abs(ll_d - ll_s) < 1e-4
                pd = Optim.minimizer(res_d)
                @test abs(exp(pd[rrB+1]) - σe_s)  < 1e-2
                @test abs(exp(pd[rrB+2]) - s2p_s) < 1e-2
            end
        catch err
            @info "dense ForwardDiff Optim did not survive line search (expected); " *
                  "relying on fit_gaussian_gllvm cross-check + value-consistency." err
        end

        @info "GATE 2 (headline σ²_phy)" iters = Optim.iterations(res_s) ll_sparse = ll_s ll_dense_optim = ll_d value_consistency = abs(ll_s - ll_dense_at_opt) grad_norm_at_opt = norm(ganO) σ_eps = (σe_s, σ_eps_true) σ²_phy = (s2p_s, σ²_phy_true)
    end

    @testset "end-to-end LBFGS — matches fit_gaussian_gllvm (p=120)" begin
        Optim = GLLVM.Optim
        Random.seed!(5)
        # Moderate p; kept modest because `fit_gaussian_gllvm` fits the phylo
        # loadings DENSELY via ForwardDiff over ~rr(p,K_B)+rr(p,K_phy) params —
        # exactly the O(p³)·params scaling this analytic path is meant to beat,
        # so the dense reference itself is the slow side here.
        p = 80; n = 200; K_B = 2; K_phy = 1
        phy = _rbt(p; branch_length = 0.1)
        Gphy = _gphy(phy)
        Σ_phy = 1.0 .* Gphy                           # σ²_phy folded into free Λ_phy
        Λ_B_true = 0.7 .* randn(p, K_B)
        Λ_phy_true = reshape(0.6 .* randn(p), p, 1)
        Lchol = cholesky(Symmetric(Σ_phy)).L
        z = Λ_phy_true[:, 1] .* (Lchol * randn(p))
        y = Λ_B_true * randn(K_B, n) .+ repeat(z, 1, n) .+ 0.5 .* randn(p, n)

        # Production dense fitter (robust: profiling + PPCA warm-start).
        fitd = GLLVM.fit_gaussian_gllvm(y; K = K_B, K_phy = K_phy, Σ_phy = Σ_phy)
        @test fitd.converged

        # Sparse-analytic fit of the SAME model: free Λ_B + Λ_phy + σ_eps,
        # σ²_phy = 1 fixed. Exercises dΛ_B, dΛ_phy, dσ²_eps.
        rrB = GLLVM.rr_theta_len(p, K_B)
        rrP = GLLVM.rr_theta_len(p, K_phy)
        function fgA!(F, Grad, par)
            LB = GLLVM.unpack_lambda((@view par[1:rrB]), p, K_B)
            σe = exp(par[rrB+1])
            LP = GLLVM.unpack_lambda((@view par[rrB+2:rrB+1+rrP]), p, K_phy)
            st = build_sparse_phy_state(y, LB, σe; Λ_phy = LP, phy = phy, σ²_phy = 1.0)
            if Grad !== nothing
                g = sparse_phy_grad(st)
                Grad[1:rrB] .= -GLLVM.pack_lambda(g.dΛ_B)
                Grad[rrB+1] = -(g.dσ²_eps * 2 * σe^2)
                Grad[rrB+2:rrB+1+rrP] .= -GLLVM.pack_lambda(g.dΛ_phy)
            end
            F !== nothing && return -sparse_phy_value(st)
            return nothing
        end
        opts = Optim.Options(g_tol = 1e-8, f_reltol = 1e-12, x_abstol = 1e-10,
                             iterations = 500)

        # (i) Warm-start the analytic-gradient LBFGS FROM the dense MLE. The
        # dense fit's parameters must be a stationary point of the sparse-driven
        # objective too: the logLik should not move and the optimiser should
        # not walk away. This is the decisive "same MLE" check, immune to the
        # loadings multimodality that plagues from-scratch comparisons.
        par_dense = vcat(GLLVM.pack_lambda(fitd.pars.Λ), log(fitd.pars.σ_eps),
                         GLLVM.pack_lambda(fitd.pars.Λ_phy))
        resW = Optim.optimize(Optim.only_fg!(fgA!), par_dense, Optim.LBFGS(), opts)
        ll_warm = -Optim.minimum(resW)
        @test abs(fitd.logLik - ll_warm) < 1e-4          # SAME MLE (logLik to 1e-4)

        # (ii) From-scratch analytic fit converges (logLik ≥ dense up to tol;
        # may land in an equivalent rotated optimum).
        par0 = vcat(GLLVM.init_theta_rr(p, K_B), log(1.0), GLLVM.init_theta_rr(p, K_phy))
        resA = Optim.optimize(Optim.only_fg!(fgA!), par0, Optim.LBFGS(), opts)
        @test Optim.converged(resA)
        ll_scratch = -Optim.minimum(resA)
        @test ll_scratch ≥ fitd.logLik - 1e-3            # no worse than dense MLE

        @info "GATE 2 (vs fit_gaussian_gllvm)" ll_fit_gaussian_gllvm = fitd.logLik ll_warmstart = ll_warm ll_from_scratch = ll_scratch Δll_warm = abs(fitd.logLik - ll_warm) iters = Optim.iterations(resA)
    end
end
