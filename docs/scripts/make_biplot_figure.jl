# Renders docs/src/assets/ordination_biplot.png — a model-based ordination
# biplot (site scores + species loadings in latent space) from a two-factor
# Gaussian GLLVM fit. Not part of the docs build; run in the throwaway
# CairoMakie env (reuse /tmp/landingfig):
#   julia --project=/tmp/landingfig docs/scripts/make_biplot_figure.jl

using GLLVM, CairoMakie, Random

Random.seed!(11)
n, p, K = 150, 8, 2
Λ_true = vcat([1.2 0.1; 1.0 0.2; 0.9 0.0; 0.7 0.3],
              [0.1 1.2; 0.2 1.0; 0.0 0.9; 0.3 0.7])
Y = Λ_true * randn(K, n) .+ 0.5 .* randn(p, n)   # p×n traits × sites

fit = fit_gaussian_gllvm(Y; K = K)
Z = getLV(fit, Y)            # n×2 site scores
L = getLoadings(fit)         # p×2 species loadings

sc = 0.9 * maximum(abs, Z) / maximum(abs, L)      # biplot scaling for loadings

fig = Figure(size = (560, 520), backgroundcolor = :white)
ax  = Axis(fig[1, 1]; xlabel = "Latent factor 1", ylabel = "Latent factor 2",
           title = "Model-based ordination (biplot)", titlesize = 15,
           xgridvisible = false, ygridvisible = false)
hlines!(ax, [0]; color = (:grey, 0.3), linewidth = 0.5)
vlines!(ax, [0]; color = (:grey, 0.3), linewidth = 0.5)
scatter!(ax, Z[:, 1], Z[:, 2]; color = (:grey55, 0.5), markersize = 6)
for t in 1:p
    x, y = sc * L[t, 1], sc * L[t, 2]
    lines!(ax, [0, x], [0, y]; color = :steelblue, linewidth = 1.5)
    text!(ax, "Sp$t"; position = (x, y), fontsize = 11, color = :steelblue,
          align = (:center, :center))
end

assets = joinpath(@__DIR__, "..", "src", "assets")
mkpath(assets)
save(joinpath(assets, "ordination_biplot.png"), fig; px_per_unit = 2)
println("wrote ", joinpath(assets, "ordination_biplot.png"))
