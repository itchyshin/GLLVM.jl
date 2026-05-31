using Documenter
using DocumenterVitepress
using GLLVM

makedocs(;
    sitename = "GLLVM.jl",
    authors  = "Shinichi Nakagawa",
    modules  = [GLLVM],
    format   = MarkdownVitepress(
        repo      = "https://github.com/itchyshin/GLLVM.jl",
        devbranch = "main",
        devurl    = "dev",
    ),
    pages    = [
        "Home"        => "index.md",
        "Get started" => "quickstart.md",
        "Articles"    => [
            "Model"                    => "model.md",
            "Covariance & correlation" => "covariance-correlation.md",
            "Benchmarks"               => "benchmarks.md",
            "Comparison vs gllvmTMB"   => "comparison.md",
        ],
        "Roadmap"     => "roadmap.md",
        "Reference"   => "api.md",
        "Changelog"   => "changelog.md",
    ],
    warnonly = true,   # pilot: don't fail the build on small doc issues
)

deploydocs(;
    repo         = "github.com/itchyshin/GLLVM.jl.git",
    target       = "build",   # DocumenterVitepress compiles the site here
    devbranch    = "main",
    branch       = "gh-pages",
    push_preview = true,
)
