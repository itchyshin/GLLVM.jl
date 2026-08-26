using GLLVM, Random, Distributions, Printf, LinearAlgebra
const G = GLLVM

# How often does Beta's OBSERVED Laplace curvature go negative at realistic
# operating points, and does flipping the default break the marginal?
settings = [(phi=4.0,  lam=0.6, tag="phi=4  loose"),
            (phi=8.0,  lam=0.5, tag="phi=8  mid"),
            (phi=12.0, lam=0.4, tag="phi=12 tight"),
            (phi=25.0, lam=0.3, tag="phi=25 very tight")]

p, K, n = 8, 2, 60
println("Beta GLLVM: p=$p K=$K n=$n | 5 seeds per setting\n")
@printf("%-18s %6s %10s %12s %14s %12s\n",
        "setting","seed","neg-W %","ll(:fisher)","ll(:observed)","delta")

summary = Dict{String,Vector{Float64}}()
for st in settings
    negs = Float64[]; broke = 0; deltas = Float64[]
    for seed in 1:5
        Random.seed!(1000 + seed)
        beta  = 0.8 .* randn(p)
        Lam   = st.lam .* randn(p, K)
        Z     = randn(K, n)
        Y = Matrix{Float64}(undef, p, n)
        eta = Matrix{Float64}(undef, p, n)
        for s in 1:n, t in 1:p
            e = beta[t] + dot(Lam[t,:], Z[:,s]); eta[t,s] = e
            mu = 1/(1+exp(-e))
            Y[t,s] = clamp(rand(Beta(mu*st.phi, (1-mu)*st.phi)), 1e-6, 1-1e-6)
        end
        # observed curvature at the TRUE operating point
        nneg = 0
        for s in 1:n, t in 1:p
            mu = 1/(1+exp(-eta[t,s])); me = mu*(1-mu)
            w = G._glm_obs_weight(Beta(st.phi,1.0), mu, 1, me, Y[t,s], G.LogitLink(), eta[t,s])
            w < 0 && (nneg += 1)
        end
        pct = 100nneg/(p*n); push!(negs, pct)

        llf = G.beta_marginal_loglik_laplace(Y, Lam, beta, st.phi; hessian=:fisher)
        llo = G.beta_marginal_loglik_laplace(Y, Lam, beta, st.phi; hessian=:observed)
        isfinite(llo) || (broke += 1)
        isfinite(llo) && push!(deltas, llo-llf)
        @printf("%-18s %6d %9.2f%% %12.4f %14s %12s\n", st.tag, seed, pct, llf,
                isfinite(llo) ? @sprintf("%.4f",llo) : "-Inf",
                isfinite(llo) ? @sprintf("%+.4f",llo-llf) : "BROKE")
    end
    summary[st.tag] = [sum(negs)/length(negs), broke, isempty(deltas) ? NaN : sum(deltas)/length(deltas)]
end

println("\n=== SUMMARY ===")
@printf("%-18s %12s %12s %14s\n","setting","mean neg-W%","-Inf fits","mean delta")
for st in settings
    v = summary[st.tag]
    @printf("%-18s %11.2f%% %12d %14s\n", st.tag, v[1], Int(v[2]),
            isnan(v[3]) ? "n/a" : @sprintf("%+.4f", v[3]))
end
