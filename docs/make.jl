using Documenter
using GLLVM

makedocs(
    sitename = "GLLVM.jl",
    authors  = "Shinichi Nakagawa",
    modules  = [GLLVM],
    repo     = "https://github.com/itchyshin/GLLVM.jl/blob/{commit}{path}#L{line}",
    format   = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical  = "https://itchyshin.github.io/GLLVM.jl/stable/",
    ),
    pages    = [
        "Home"            => "index.md",
        "Quick start"     => "quickstart.md",
        "Model"           => "model.md",
        "API reference"   => "api.md",
        "Benchmarks"      => "benchmarks.md",
        "Comparison"      => "comparison.md",
    ],
    warnonly = true,   # pilot: don't fail docs build on small issues
)

deploydocs(
    repo = "github.com/itchyshin/GLLVM.jl.git",
    devbranch = "main",
    push_preview = true,
)
