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
            "Morphometrics"            => "morphometrics.md",
            "Working with a fit"       => "working-with-a-fit.md",
            "Covariance & correlation" => "covariance-correlation.md",
            "Structured dependence"    => "structured-dependence.md",
            "Response families"        => "response-families.md",
            "Confidence intervals"     => "confidence-intervals.md",
            "Common pitfalls"          => "pitfalls.md",
            "Benchmarks"               => "benchmarks.md",
            "Comparison vs gllvmTMB"   => "comparison.md",
            "Capability parity"        => "gllvmtmb-parity.md",
        ],
        "Roadmap"     => "roadmap.md",
        "Reference"   => "api.md",
        "Changelog"   => "changelog.md",
    ],
    warnonly = true,   # pilot: don't fail the build on small doc issues
)

# Use DocumenterVitepress.deploydocs (NOT Documenter's): it flattens the Vitepress
# build output (build/1/*) into the version root on gh-pages and rewrites the
# site `base`. Plain Documenter.deploydocs deploys build/ verbatim, which lands
# the site under dev/1/ with base=/dev/ — every asset/nav link then 404s.
DocumenterVitepress.deploydocs(;
    repo         = "github.com/itchyshin/GLLVM.jl.git",
    target       = joinpath(@__DIR__, "build"),
    devbranch    = "main",
    branch       = "gh-pages",
    push_preview = true,
)
