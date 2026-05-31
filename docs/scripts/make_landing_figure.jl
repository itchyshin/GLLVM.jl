# Renders the landing-page figure: a model-implied cross-response correlation
# heatmap from a small simulated two-factor Gaussian GLLVM fit.
#
# This is NOT part of the Documenter build (keeps CairoMakie out of the docs
# environment / CI). Run it by hand to regenerate the committed PNG:
#
#   mkdir -p /tmp/landingfig
#   julia --project=/tmp/landingfig -e 'using Pkg; Pkg.develop(path="."); Pkg.add("CairoMakie")'
#   julia --project=/tmp/landingfig docs/scripts/make_landing_figure.jl
#
# Output: docs/src/assets/correlation_heatmap.png

using GLLVM, CairoMakie, Random

Random.seed!(42)
n, p, K = 120, 6, 2

# Two interpretable blocks of three responses, each loading on one factor.
Λ_true = vcat(
    [1.2 0.0; 0.9 0.2; 0.7 0.1],
    [0.1 1.3; 0.2 1.0; 0.0 0.8],
)
Z = randn(K, n)
Y = Λ_true * Z .+ 0.6 .* randn(p, n)        # p × n: responses × sites (GLLVM convention)

fit = fit_gaussian_gllvm(Y; K = K)
R   = correlation(fit)                       # p × p, symmetric, entries in [-1, 1]

labels = ["Sp $i" for i in 1:p]

fig = Figure(size = (560, 480), backgroundcolor = :white)
ax  = Axis(fig[1, 1];
           xticks = (1:p, labels), yticks = (1:p, labels),
           xticklabelrotation = π / 4,
           xgridvisible = false, ygridvisible = false,
           title = "Model-implied cross-response correlations", titlesize = 15)
hm = heatmap!(ax, R; colormap = :RdBu, colorrange = (-1, 1))
Colorbar(fig[1, 2], hm; label = "ρ", width = 14)
for i in 1:p, j in 1:p
    text!(ax, string(round(R[i, j]; digits = 2));
          position = (i, j), align = (:center, :center),
          fontsize = 10, color = abs(R[i, j]) > 0.6 ? :white : :black)
end

assets = joinpath(@__DIR__, "..", "src", "assets")
mkpath(assets)
save(joinpath(assets, "correlation_heatmap.png"), fig; px_per_unit = 2)
println("wrote ", joinpath(assets, "correlation_heatmap.png"))
