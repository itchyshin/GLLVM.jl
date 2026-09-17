using Test, GLLVModels, SparseArrays, LinearAlgebra, Distributions

@testset "joint grouped Laplace" begin
    @test isdefined(GLLVModels, :joint_grouped_laplace_loglik)

    @testset "trait-specific dispersion vector contract" begin
        X=ones(2,1); W=spzeros(2,0)
        beta_families=[Beta(4.,1.),Beta(12.,1.)]
        beta_result=GLLVModels.joint_grouped_laplace_loglik(beta_families,[.3,.6],ones(2),X,[0.],W; link=LogitLink())
        @test beta_result.status == :ok
        @test beta_result.loglik ≈ logpdf(Beta(2.,2.),.3)+logpdf(Beta(6.,6.),.6) atol=1e-12
        nb_families=[NegativeBinomial(2.,.5),NegativeBinomial(8.,.5)]
        nb_result=GLLVModels.joint_grouped_laplace_loglik(nb_families,[1.,4.],ones(2),X,[log(3.)],W; link=LogLink())
        @test nb_result.status == :ok
        @test nb_result.loglik ≈ logpdf(NegativeBinomial(2.,2/5),1)+logpdf(NegativeBinomial(8.,8/11),4) atol=1e-12
        @test !GLLVModels.joint_grouped_laplace_loglik(beta_families[1:1],[.3,.6],ones(2),X,[0.],W; link=LogitLink()).converged
        @test !GLLVModels.joint_grouped_laplace_loglik([Beta(4.,1.),NegativeBinomial(2.,.5)],[.3,.6],ones(2),X,[0.],W; link=LogitLink()).converged
    end

    @testset "family marker and conditional normalization contracts" begin
        X = ones(2,1); W = spzeros(2,0)
        for (family, y, trials, eta, link, distributions) in (
            (Binomial(), [1.,3.], [4.,5.], 0.2, LogitLink(),
             [Binomial(4,1/(1+exp(-0.2))), Binomial(5,1/(1+exp(-0.2)))]),
            (Beta(8.,1.), [.3,.6], ones(2), 0., LogitLink(), [Beta(4.,4.),Beta(4.,4.)]),
            (NegativeBinomial(2.,.5), [1.,3.], ones(2), log(3.), LogLink(),
             [NegativeBinomial(2.,.4),NegativeBinomial(2.,.4)]))
            result = GLLVModels.joint_grouped_laplace_loglik(family,y,trials,X,[eta],W; link=link)
            @test result.status == :ok && result.gradient_norm == 0.0
            @test result.loglik ≈ sum(logpdf.(distributions,y)) atol=1e-12
        end
        @test GLLVModels.joint_grouped_laplace_loglik(Beta(8.,2.), [.3,.6],ones(2),X,[0.],W;
            link=LogitLink()).status == :invalid_family
        @test GLLVModels.joint_grouped_laplace_loglik(NegativeBinomial(2.,.2), [1.,3.],ones(2),X,[0.],W;
            link=LogLink()).status == :invalid_family
    end

    @testset "incidence times trait factors preserves vec ordering" begin
        A = sparse([1.0 0.0; 1.0 1.0; 0.0 1.0])
        L = [1.0 2.0; 3.0 4.0]
        W = GLLVModels.grouped_trait_design(A, L)
        @test W == sparse(kron(A, L))
        # Second unit, second trait: both group columns are active, in the same
        # row of the one global design — the crossed-effect contract.
        @test collect(W[4, :]) == [3.0, 4.0, 3.0, 4.0]
    end

    @testset "zero grouped design retains response constants exactly" begin
        y = [2.0, 3.0]
        n = ones(2)
        X = ones(2, 1)
        beta = [log(2.5)]
        result = GLLVModels.joint_grouped_laplace_loglik(
            Poisson(), y, n, X, beta, spzeros(2, 0); link = LogLink())
        exact = sum(logpdf(Poisson(exp(beta[1])), Int(v)) for v in y)
        @test result.status === :ok
        @test result.converged
        @test isempty(result.mode)
        @test result.logdet_precision == 0.0
        @test result.loglik ≈ exact atol = 1e-12
    end

    @testset "one shared Poisson effect agrees with scalar quadrature" begin
        y = [4.0, 5.0]
        n = ones(2)
        X = ones(2, 1)
        beta = [log(3.0)]
        W = sparse(ones(2, 1))
        result = GLLVModels.joint_grouped_laplace_loglik(
            Poisson(), y, n, X, beta, W; link = LogLink())
        grid = range(-8.0, 8.0; length = 4001)
        dz = step(grid)
        exact = log(sum(exp(sum(logpdf(Poisson(exp(beta[1] + b)), Int(v)) for v in y)) *
                        pdf(Normal(), b) * dz for b in grid))
        @test result.status === :ok
        @test result.loglik ≈ exact atol = 0.08
    end

    @testset "each admitted family has a finite joint objective" begin
        common = (ones(1, 1), [0.0], sparse(ones(1, 1)))
        binomial = GLLVModels.joint_grouped_laplace_loglik(
            Binomial(), [3.0], [5.0], common...; link = LogitLink())
        beta = GLLVModels.joint_grouped_laplace_loglik(
            Beta(8.0, 1.0), [0.7], [1.0], common...; link = LogitLink())
        @test binomial.status === :ok
        @test beta.status === :ok
        @test isfinite(binomial.loglik) && isfinite(beta.loglik)
    end

    @testset "conditional score and observed Hessian match finite differences" begin
        # Independent conditional reference: no kernel state, Newton matrix, or
        # clamp helper is called here.  These cells are deliberately interior.
        specs = (
            (Poisson(), [3.0], [1.0], LogLink(), log(2.0)),
            (Binomial(), [3.0], [5.0], LogitLink(), 0.2),
            (Beta(8.0, 1.0), [0.7], [1.0], LogitLink(), 0.2),
            (NegativeBinomial(2.0, 0.5), [8.0], [1.0], LogLink(), log(2.0)),
        )
        h = 1e-4
        for (family, y, n, link, beta0) in specs
            X = ones(1, 1)
            beta = [beta0]
            W = sparse(ones(1, 1))
            b = [0.0]
            reference_logpost = z -> begin
                eta = beta0 + z
                mu = GLLVModels.linkinv(link, eta)
                GLLVModels._glm_logpdf(family, mu, n[1], y[1]) - 0.5 * z^2
            end
            state = GLLVModels._joint_grouped_state(family, X, beta, W, link, b)
            score, _, observed_precision = GLLVModels._joint_grouped_components(
                family, y, n, X, beta, W, link, b; state = state)
            qminus, qzero, qplus = reference_logpost(-h), reference_logpost(0.0), reference_logpost(h)
            grad_fd = (qplus - qminus) / (2h)
            hess_fd = (qplus - 2qzero + qminus) / h^2
            @test state[1] === :ok
            @test grad_fd ≈ score[1] - b[1] atol = 1e-6
            @test hess_fd ≈ -observed_precision[1, 1] atol = 1e-6
        end
    end

    @testset "crossed incidence produces one coupled global precision" begin
        A = sparse([1.0 1.0; 1.0 0.0; 0.0 1.0])
        W = GLLVModels.grouped_trait_design(A, ones(1, 1))
        result = GLLVModels.joint_grouped_laplace_loglik(
            Poisson(), [3.0, 4.0, 2.0], ones(3), ones(3, 1), [log(2.0)], W;
            link = LogLink())
        @test result.status === :ok
        @test length(result.mode) == 2
        @test result.precision[1, 2] > 0 # impossible under independent per-unit modes
    end

    @testset "NB2 determinant uses observed rather than Fisher curvature" begin
        y = [8.0]
        beta = [log(2.0)]
        family = NegativeBinomial(2.0, 0.5)
        result = GLLVModels.joint_grouped_laplace_loglik(
            family, y, ones(1), ones(1, 1), beta, sparse(ones(1, 1)); link = LogLink())
        eta = GLLVModels._clamp_eta(beta[1] + result.mode[1])
        mu = exp(eta)
        observed = mu * (1 + y[1] / family.r) / (1 + mu / family.r)^2
        fisher = mu * family.r / (family.r + mu)
        @test result.status === :ok
        @test result.precision[1, 1] ≈ 1 + observed atol = 1e-11
        @test abs(result.precision[1, 1] - (1 + fisher)) > 1e-5
    end

    @testset "bad input and exhausted Newton return diagnostics" begin
        bad_y = GLLVModels.joint_grouped_laplace_loglik(
            Poisson(), [-1.0], [1.0], ones(1, 1), [0.0], sparse(ones(1, 1)); link = LogLink())
        bad_n = GLLVModels.joint_grouped_laplace_loglik(
            Binomial(), [0.0], [0.0], ones(1, 1), [0.0], sparse(ones(1, 1)); link = LogitLink())
        stalled = GLLVModels.joint_grouped_laplace_loglik(
            Poisson(), [3.0], [1.0], ones(1, 1), [0.0], sparse(ones(1, 1));
            link = LogLink(), maxiter = 0)
        @test (!bad_y.converged && bad_y.status === :invalid_data && bad_y.loglik == -Inf)
        @test (!bad_n.converged && bad_n.status === :invalid_trials && bad_n.loglik == -Inf)
        @test (!stalled.converged && stalled.status === :nonconvergence && stalled.loglik == -Inf)
    end

    @testset "saturated predictors and nonfinite controls are rejected" begin
        specs = (
            (Poisson(), [3.0], [1.0], LogLink()),
            (Binomial(), [3.0], [5.0], LogitLink()),
            (Beta(8.0, 1.0), [0.7], [1.0], LogitLink()),
            (NegativeBinomial(2.0, 0.5), [8.0], [1.0], LogLink()),
        )
        for (family, y, n, link) in specs
            saturated = GLLVModels.joint_grouped_laplace_loglik(
                family, y, n, ones(1, 1), [40.0], sparse(ones(1, 1)); link = link)
            @test !saturated.converged
            @test saturated.status === :saturated_domain
            @test saturated.loglik == -Inf
        end
        bad_tol = GLLVModels.joint_grouped_laplace_loglik(
            Poisson(), [3.0], [1.0], ones(1, 1), [0.0], sparse(ones(1, 1));
            link = LogLink(), tol = Inf)
        @test !bad_tol.converged && bad_tol.status === :invalid_control
    end
end
