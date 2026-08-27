using GLLVM, Random, Distributions, LinearAlgebra
Random.seed!(191)
p, K, n = 8, 2, 300
β = 0.3 .* randn(p); Λ = 0.4 .* randn(p, K); Z = randn(K, n)
η = β .+ Λ * Z
Y = [rand(Exponential(exp(η[t, s]))) for t in 1:p, s in 1:n]
fams = [Gamma(1.0, 1.0) for t in 1:p]
y = Y[:, 284]
link = GLLVM.LogLink()

z = zeros(K)
for it in 1:20
    global z
    ηz  = GLLVM._clamp_eta.(β .+ Λ * z)
    μ  = GLLVM._clamp_mu.(fams, GLLVM.linkinv.(Ref(link), ηz))
    me = GLLVM.mu_eta.(Ref(link), ηz)
    Wf = GLLVM._gamma_grouped_laplace_weight.(Ref(:fisher), fams, μ, me, y, Ref(link))
    s  = GLLVM._glm_score.(fams, μ, ones(Int,p), me, y)
    A  = Symmetric(Λ' * (Wf .* Λ) + I)
    Δ  = GLLVM._safe_solve(A, Λ'*s .- z)
    println("it=$it  z=$z  |Δ|=", maximum(abs,Δ), "  score-residual Λ's-z = ", Λ'*s .- z)
    z = z .+ Δ
end
