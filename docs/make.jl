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
        "Model"       => "model.md",
        "Reference"   => "api.md",
        "Benchmarks"  => "benchmarks.md",
        "Comparison"  => "comparison.md",
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
