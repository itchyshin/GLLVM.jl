# Renders docs/src/assets/communality_bars.png — per-trait communality from a
# simulated two-factor morphometric fit (the Morphometrics article figure).
# Not part of the Documenter build; see make_landing_figure.jl for the run recipe
# (reuse the same /tmp/landingfig env — CairoMakie is already precompiled there).
#
#   julia --project=/tmp/landingfig docs/scripts/make_morphometrics_figure.jl

using GLLVM, CairoMakie, Random, Statistics

Random.seed!(7)
n, p, K = 150, 8, 2
size_axis  = [0.9, 0.8, 1.0, 0.7, 0.85, 0.75, 0.95, 0.8]
shape_axis = [0.7, 0.6, 0.5, 0.0, 0.0, -0.5, -0.6, -0.7]
Λ_true = hcat(size_axis, shape_axis)
Z = randn(K, n)
Y = Λ_true * Z .+ 0.4 .* randn(p, n)        # p × n: traits × individuals

fit = fit_gaussian_gllvm(Y; K = K)
c   = communality(fit)                       # p-vector, each in [0,1]

labels = ["T$i" for i in 1:p]
fig = Figure(size = (560, 360), backgroundcolor = :white)
ax  = Axis(fig[1, 1];
           xticks = (1:p, labels), ylabel = "communality (shared fraction)",
           title = "Per-trait shared variance", titlesize = 15,
           xgridvisible = false, limits = (nothing, (0, 1)))
barplot!(ax, 1:p, c; color = (:steelblue, 0.85))
hlines!(ax, [mean(c)]; color = :grey40, linestyle = :dash)

assets = joinpath(@__DIR__, "..", "src", "assets")
mkpath(assets)
save(joinpath(assets, "communality_bars.png"), fig; px_per_unit = 2)
println("wrote ", joinpath(assets, "communality_bars.png"))
